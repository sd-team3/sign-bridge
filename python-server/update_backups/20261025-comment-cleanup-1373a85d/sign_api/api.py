"""Raw landmark API. No client-supplied predictions, file paths or API keys."""
from __future__ import annotations

import asyncio
import json
import logging
import os
from pathlib import Path
import secrets
import threading
from typing import Literal

import numpy as np
import torch
from fastapi import APIRouter, Depends, Header, HTTPException, WebSocket, WebSocketDisconnect
from pydantic import BaseModel, ConfigDict, Field, model_validator, ValidationError
from starlette.concurrency import run_in_threadpool

from .body_features import encode
from .pose_feedback import geometry, compare
from .seated_features import prepare
from .sign_model import SignLSTM, resample_sequence
from .curriculum import load_catalog

LOG = logging.getLogger(__name__)
ROOT = Path(__file__).resolve().parent


def authorized(value):
    key = os.environ.get('SIGN_API_KEY', '')
    return not key or secrets.compare_digest(value or '', key)


def authenticate(x_sign_api_key: str | None = Header(default=None)):
    if not authorized(x_sign_api_key):
        raise HTTPException(401, 'Invalid service key')


class StrictModel(BaseModel):
    model_config = ConfigDict(extra='forbid', allow_inf_nan=False)


class Frame(StrictModel):
    timestamp_ms: float = Field(ge=0, le=20000)
    # Slots are MediaPipe Hands labels Left/Right on UNMIRRORED input.
    # These are not anatomical sides; geometry() resolves sides using Pose.
    hands: list[list[list[float]] | None] = Field(min_length=2, max_length=2)
    # Each Pose row is [x, y, visibility], NOT [x, y, z].
    pose: list[list[float]] | None = None

    @model_validator(mode='after')
    def validate_points(self):
        for hand in self.hands:
            if hand is not None:
                a = np.asarray(hand)
                if a.shape != (21, 3) or not np.isfinite(a).all() or np.abs(a).max() > 10:
                    raise ValueError('Each detected hand must contain 21 finite [x,y,z] points')
        if self.pose is not None:
            a = np.asarray(self.pose)
            if a.shape != (33, 3) or not np.isfinite(a).all() or np.abs(a[:, :2]).max() > 10:
                raise ValueError('Pose must contain 33 finite [x,y,visibility] points')
            if ((a[:, 2] < 0) | (a[:, 2] > 1)).any():
                raise ValueError('Pose visibility must be in [0,1]')
        return self


class Clip(StrictModel):
    attempt_id: str = Field(min_length=1, max_length=80, pattern=r'^[A-Za-z0-9_-]+$')
    schema_version: Literal['raw_mp_legacy_v1'] = 'raw_mp_legacy_v1'
    mirrored: Literal[False] = False
    aspect: float = Field(gt=.2, lt=5)
    target_word_id: str | None = Field(default=None, pattern=r'^WORD\d{4}$')
    frames: list[Frame] = Field(min_length=16, max_length=300)
    use_llm: bool = False

    @model_validator(mode='after')
    def chronological(self):
        stamps = [f.timestamp_ms for f in self.frames]
        if any(b <= a for a, b in zip(stamps, stamps[1:])):
            raise ValueError('Timestamps must be strictly increasing')
        return self


def encode_frames(frames, aspect):
    features, shapes = [], []
    for frame in frames:
        hands = np.asarray([h if h is not None else np.zeros((21, 3)) for h in frame.hands], np.float32)
        pose = np.asarray(frame.pose, np.float32) if frame.pose is not None else None
        features.append(encode(hands, pose, aspect))
        shapes.append(geometry(hands, pose, aspect))
    return np.asarray(features), np.asarray(shapes)


class Runtime:
    def __init__(self):
        self.model = None
        self.error = None
        self.references = {}
        self.words = {}
        self.curriculum = None
        self.chapter_by_word = {}
        self.gate = threading.BoundedSemaphore(1)

    def load(self):
        self.model = None
        self.references = {}
        self.words = {}
        self.curriculum = None
        self.chapter_by_word = {}
        try:
            torch.set_num_threads(2)
            # Only a trusted, operator-installed checkpoint is loaded.
            path = Path(os.environ.get('SIGN_MODEL_PATH', ROOT / 'assets' / 'best.pt'))
            ckpt = torch.load(path, map_location='cpu', weights_only=True)
            if ckpt.get('feature_schema') != 'hands_body_v1':
                raise ValueError('Expected hands_body_v1 model')
            if ckpt.get('input_policy', 'original') not in ('original', 'seated_v1', 'seated_active_v2'):
                raise ValueError('Unsupported input policy')
            self.words = json.loads((ROOT / 'assets' / 'labels.json').read_text(encoding='utf-8'))
            if set(self.words.values()) != set(ckpt['labels']):
                raise ValueError('Checkpoint and word manifest differ')
            catalog = ROOT / 'assets' / 'curriculum.json'
            if catalog.exists():
                self.curriculum = load_catalog(catalog, self.words)
                self.chapter_by_word = {w['word_id']: c['chapter_id'] for c in self.curriculum['chapters'] for w in c['words']}
            model = SignLSTM(len(ckpt['labels']), **ckpt['model_config'])
            model.load_state_dict(ckpt['model'])
            model.eval()
            self.ckpt = ckpt
            for code in self.words:
                ref = ROOT / 'assets' / 'references' / f'{code}.npy'
                if ref.exists():
                    a = np.load(ref, allow_pickle=False)
                    if a.ndim != 3 or a.shape[1:] != (2, 6) or len(a) > 96:
                        raise ValueError('Invalid reference geometry')
                    self.references[code] = a
            if self.curriculum and (len(self.references) != len(self.words) or
                    any(not (ROOT/'assets/videos'/f'{code}.mp4').is_file() for code in self.words)):
                raise ValueError('Curriculum requires a reference video and geometry for every word')
            self.model = model
            self.error = None
        except Exception:
            self.model = None
            self.error = 'model_unavailable'
            LOG.exception('Sign-word model initialization failed; jamo API stays available')

    def ready(self):
        if self.model is None:
            raise HTTPException(503, 'Sign model unavailable; inspect server startup log')

    def infer(self, clip, evaluate=False):
        self.ready()
        code = clip.target_word_id[4:] if clip.target_word_id else None
        if code is not None and code not in self.words:
            raise HTTPException(422, 'Unknown target_word_id')
        if evaluate and code is None:
            raise HTTPException(422, 'target_word_id is required for evaluation')
        if not self.gate.acquire(blocking=False):
            raise HTTPException(429, 'Inference busy; retry later', headers={'Retry-After': '1'})
        try:
            features, shapes = encode_frames(clip.frames, clip.aspect)
            quality = {'hand_frames': int(np.any(features[:, :126], axis=1).sum()),
                       'shoulder_frames': int((features[:, 153] > .5).sum()),
                       'total_frames': len(features)}
            if self.ckpt.get('input_policy') == 'seated_active_v2':
                from .seated_active_features import suppress_resting
                active = suppress_resting(features)
                quality['active_hand_frames'] = int(np.any(active[:,:126], axis=1).sum())
                quality['excluded_resting_slots'] = [slot for slot in (0,1)
                    if np.any(features[:,151+slot]>.5) and not np.any(active[:,151+slot]>.5)]
            if quality.get('active_hand_frames', quality['hand_frames']) < 16 or quality['shoulder_frames'] < 16:
                return {'attempt_id': clip.attempt_id, 'status': 'retry', 'quality': quality,
                        'model_id': self.ckpt.get('model_id'), 'target_word_id': clip.target_word_id,
                        'input_policy': self.ckpt.get('input_policy', 'original'),
                        'recognition': None, 'feedback': {'status': 'insufficient_tracking',
                        'message': '동작에 사용하는 손과 양쪽 어깨가 보이도록 전체 동작을 다시 촬영해 주세요. 쉬는 손은 내려놓아도 됩니다.'}}
            if self.ckpt.get('input_policy') == 'seated_active_v2':
                from .seated_active_features import prepare as prepare_active
                seq, mask = prepare_active(features, self.ckpt['sequence_length'])
            elif self.ckpt.get('input_policy') == 'seated_v1':
                seq, mask = prepare(features, self.ckpt['sequence_length'])
            else:
                seq, mask = resample_sequence(features, self.ckpt['sequence_length'])
            with torch.inference_mode():
                probs = self.model(torch.from_numpy(seq)[None], torch.from_numpy(mask)[None]).softmax(1)[0].numpy()
            top = []
            for i in np.argsort(probs)[-3:][::-1]:
                label = self.ckpt['labels'][int(i)]
                top.append({'label': label, 'word_ids': ['WORD'+k for k,v in self.words.items() if v == label],
                            'score': float(probs[i])})
            result = {'attempt_id': clip.attempt_id, 'status': 'ok', 'quality': quality,
                      'target_word_id': clip.target_word_id, 'model_id': self.ckpt.get('model_id'),
                      'input_policy': self.ckpt.get('input_policy', 'original'),
                      'recognition': {'top3': top, 'predicted_label': top[0]['label'],
                                      'target_matches_top1': top[0]['label'] == self.words[code] if code else None},
                      'feedback': None}
            if evaluate:
                if code not in self.references:
                    result['feedback'] = {'status': 'reference_unavailable', 'message': '이 단어의 비교 기준이 없습니다.'}
                else:
                    indices = np.linspace(0, len(shapes)-1, min(80,len(shapes))).round().astype(int)
                    feedback = compare(self.references[code], shapes[indices],
                                       ignore_resting=self.ckpt.get('input_policy') == 'seated_active_v2')
                    result['feedback'] = {'status': 'advice' if feedback['corrections'] else 'no_reliable_correction',
                                          'message': feedback['summary'], 'observations': feedback, 'source': 'rules'}
        finally:
            self.gate.release()
        if evaluate and clip.use_llm and result['feedback'].get('status') == 'advice':
            key = os.environ.get('GROQ_API_KEY', '')
            model_id = os.environ.get('GROQ_MODEL', '')
            if key and model_id:
                try:
                    from .groq_feedback import generate_feedback
                    result['feedback']['message'] = generate_feedback(
                        {'pose_feedback': result['feedback']['observations']}, {'api_key': key, 'model': model_id})
                    result['feedback']['source'] = 'groq'
                except ValueError:
                    result['feedback']['llm_status'] = 'fallback'
            else:
                result['feedback']['llm_status'] = 'not_configured'
        return result


runtime = Runtime()
router = APIRouter(prefix='/api/v1/signs', tags=['Sign words'], dependencies=[Depends(authenticate)])


@router.on_event('startup')
def startup():
    runtime.load()


@router.get('/health')
def health():
    return {'ready': runtime.model is not None, 'error': runtime.error,
            'classes': len(runtime.words), 'references': len(runtime.references),
            'input_schema': 'raw_mp_legacy_v1',
            'model_id': runtime.ckpt.get('model_id') if runtime.model is not None else None,
            'input_policy': runtime.ckpt.get('input_policy') if runtime.model is not None else None,
            'chapters': len(runtime.curriculum['chapters']) if runtime.curriculum else 0,
            'live_feedback': 'tracking_quality_only', 'completed_clip_feedback': 'reference_geometry'}


@router.get('')
def words():
    runtime.ready()
    return {'words': [word_info('WORD'+k) for k in runtime.words]}


def word_info(word_id):
    code = word_id[4:] if word_id.startswith('WORD') else ''
    if code not in runtime.words: raise HTTPException(404, 'Unknown word')
    return {'word_id': word_id, 'label': runtime.words[code],
            'chapter_id': runtime.chapter_by_word.get(word_id),
            'feedback_available': code in runtime.references,
            'reference_video_url': f'/api/v1/signs/reference/{word_id}',
            'evaluation_url': '/api/v1/signs/evaluate',
            'video_evaluation_url': '/api/v1/signs/evaluate-video'}


@router.get('/chapters')
def chapters():
    runtime.ready()
    if not runtime.curriculum: raise HTTPException(404, 'Curriculum unavailable')
    return {'curriculum_version': runtime.curriculum['version'],
            'total_words': len(runtime.words),
            'chapters': [{k:v for k,v in c.items() if k != 'words'} |
                         {'word_count': len(c['words']), 'detail_url': f'/api/v1/signs/chapters/{c["chapter_id"]}'}
                         for c in runtime.curriculum['chapters']]}


@router.get('/chapters/{chapter_id}')
def chapter_detail(chapter_id: str):
    runtime.ready()
    if not runtime.curriculum: raise HTTPException(404, 'Curriculum unavailable')
    chapter = next((c for c in runtime.curriculum['chapters'] if c['chapter_id'] == chapter_id), None)
    if chapter is None: raise HTTPException(404, 'Unknown chapter')
    return {k:v for k,v in chapter.items() if k != 'words'} | {
        'curriculum_version': runtime.curriculum['version'],
        'words': [word_info(w['word_id']) | {'order': w['order']} for w in chapter['words']]}


@router.get('/words/{word_id}')
def word_detail(word_id: str):
    runtime.ready()
    return word_info(word_id) | {'capture': {'max_duration_ms': 20000, 'min_frames': 16, 'max_frames': 300,
        'max_video_bytes': 25*1024*1024, 'mirrored': False, 'both_hands_required': False,
        'shoulders_required': True, 'guidance': '양쪽 어깨와 동작에 사용하는 손을 보여 주세요. 쉬는 손은 내려놓아도 됩니다.'},
        'feedback': {'live': 'tracking_quality_only', 'completed_clip': 'reference_geometry',
                     'score_meaning': 'classification_softmax_not_posture_accuracy'}}


@router.post('/predict')
def predict(clip: Clip):
    return runtime.infer(clip)


@router.post('/evaluate')
def evaluate(clip: Clip):
    return runtime.infer(clip, evaluate=True)


@router.websocket('/practice')
async def practice(ws: WebSocket):
    if not authorized(ws.headers.get('x-sign-api-key')):
        await ws.close(code=1008)
        return
    await ws.accept()
    frames, settings = [], None
    try:
        while True:
            raw = await asyncio.wait_for(ws.receive_text(), timeout=30)
            if len(raw.encode('utf-8')) > 128*1024:
                await ws.close(code=1009)
                return
            msg = None
            try:
                msg = json.loads(raw)
                if not isinstance(msg, dict):
                    raise ValueError('Object required')
                kind = msg.get('type')
                if kind == 'start':
                    if settings is not None:
                        raise ValueError('Finish/reset current attempt first')
                    settings = {k:v for k,v in msg.items() if k != 'type'}
                    # Validate metadata using synthetic empty tracking frames, without inference.
                    Clip(**settings, frames=[{'timestamp_ms': i, 'hands': [None,None]} for i in range(16)])
                    if not settings.get('target_word_id') or settings['target_word_id'][4:] not in runtime.words:
                        settings = None
                        raise ValueError('Known target_word_id required')
                    frames = []
                    await ws.send_json({'type': 'started', 'live_feedback': 'tracking_quality_only'})
                elif kind == 'frames':
                    if settings is None:
                        raise ValueError('Send start first')
                    batch = msg.get('frames', [])
                    if not isinstance(batch, list) or not 1 <= len(batch) <= 15 or len(frames)+len(batch) > 300:
                        raise ValueError('1..15 frames per batch, max 300 per attempt')
                    parsed = [Frame.model_validate(f) for f in batch]
                    stamps = ([frames[-1].timestamp_ms] if frames else []) + [f.timestamp_ms for f in parsed]
                    if any(b <= a for a,b in zip(stamps, stamps[1:])):
                        raise ValueError('Timestamps must increase')
                    frames.extend(parsed)
                    feature, _ = encode_frames(parsed[-1:], settings['aspect'])
                    hands, shoulders = int(feature[0,151:153].sum()), bool(feature[0,153])
                    await ws.send_json({'type': 'tracking', 'received_frames': len(frames),
                        'hands': hands, 'shoulders_visible': shoulders,
                        'message': '손을 화면 안에 보여주세요.' if not hands else
                                   '양쪽 어깨가 보이게 해주세요.' if not shoulders else '촬영 중입니다.'})
                elif kind == 'finish':
                    if settings is None:
                        raise ValueError('Send start first')
                    clip = Clip(**settings, frames=frames)
                    result = await run_in_threadpool(runtime.infer, clip, True)
                    await ws.send_json({'type': 'result', **result})
                    settings, frames = None, []
                elif kind == 'reset':
                    settings, frames = None, []
                    await ws.send_json({'type': 'reset'})
                else:
                    raise ValueError('Unknown message type')
            except (ValueError, TypeError, ValidationError) as exc:
                if isinstance(msg, dict) and msg.get('type') == 'start':
                    settings = None
                await ws.send_json({'type': 'error', 'code': 422, 'message': 'Invalid message or sequence; check API schema'})
            except HTTPException as exc:
                await ws.send_json({'type': 'error', 'code': exc.status_code, 'message': exc.detail})
    except asyncio.TimeoutError:
        await ws.close(code=1008, reason='Idle timeout')
    except WebSocketDisconnect:
        pass
