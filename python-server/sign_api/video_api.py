import os
import logging
from pathlib import Path
import tempfile
import threading
import cv2
import numpy as np
from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile
from fastapi.responses import FileResponse
from starlette.concurrency import run_in_threadpool
from .api import Clip, Frame, ROOT, authenticate, runtime
from .body_features import Extractor
from .legacy_capture import configure, model_hands
from .hand_tracking import VERSION

video_router = APIRouter(prefix='/api/v1/signs', tags=['Sign words'], dependencies=[Depends(authenticate)])
gate = threading.BoundedSemaphore(1)
LOG = logging.getLogger('uvicorn.error')

@video_router.get('/reference/{word_id}')
def reference(word_id: str):
    runtime.ready()
    code = word_id[4:] if word_id.startswith('WORD') else ''
    if code not in runtime.words:
        raise HTTPException(404, 'Unknown word')
    path = ROOT / 'assets' / 'videos' / f'{code}.mp4'
    if not path.exists():
        raise HTTPException(404, 'Reference video unavailable')
    return FileResponse(path, media_type='video/mp4')


@video_router.get('/reference/{word_id}/{subject}')
def reference_variant(word_id: str, subject: str):
    runtime.ready()
    code=word_id[4:] if word_id.startswith('WORD') else ''
    entries=runtime.reference_banks.get(code,[])
    if not any(r['subject']==subject for r in entries): raise HTTPException(404,'Unknown reference variant')
    name=f'{code}.mp4' if subject=='REAL01' else f'{code}_{subject}.mp4'
    path=ROOT/'assets/videos'/name
    if not path.is_file(): raise HTTPException(404,'Reference video unavailable')
    return FileResponse(path,media_type='video/mp4')

def evaluate_file(path, word_id, use_llm, attempt_id=None, include_comparison=False):
    cap = cv2.VideoCapture(path)
    try:
        if not cap.isOpened():
            raise HTTPException(422, 'Video decoding failed')
        fps = cap.get(cv2.CAP_PROP_FPS)
        valid_fps = np.isfinite(fps) and 1 <= fps <= 120
        sample_interval_ms = 1000/15
        next_sample_ms = 0.0
        frames, corrected_frames, aspect = [], [], None
        origin_ms, previous_ms = None, None
        tracking_stats = {'sampled_frames': 0, 'duplicate_label_frames': 0, 'recovered_hands': 0, 'recovery_attempts': 0, 'excess_candidate_frames': 0}
        with Extractor() as extractor:
            legacy_input=configure(extractor,getattr(runtime,'ckpt',{}))
            # Browser recordings may omit FPS metadata. In that case use decoded
            # presentation times, never an assumed FPS that changes motion speed.
            for index in range(int(fps*20)+2 if valid_fps else 2402):
                ok = cap.grab()
                if not ok:
                    break
                if valid_fps and index >= fps*20:
                    raise HTTPException(422, 'Video must be at most 20 seconds')
                if valid_fps and index*1000/fps + 1e-6 < next_sample_ms:
                    continue
                ok, image = cap.retrieve()
                if not ok:
                    raise HTTPException(422, 'Video decoding failed')
                timestamp_ms = index*1000/fps if valid_fps else cap.get(cv2.CAP_PROP_POS_MSEC)
                if not valid_fps:
                    if (not np.isfinite(timestamp_ms) or timestamp_ms < 0
                            or (previous_ms is not None and timestamp_ms <= previous_ms)):
                        raise HTTPException(422, 'Cannot determine video frame rate')
                    previous_ms = timestamp_ms
                    if origin_ms is None:
                        origin_ms = timestamp_ms
                    timestamp_ms -= origin_ms
                    if timestamp_ms >= 20000:
                        raise HTTPException(422, 'Video must be at most 20 seconds')
                    if timestamp_ms + 1e-6 < next_sample_ms:
                        continue
                next_sample_ms = (np.floor(timestamp_ms/sample_interval_ms + 1e-6)+1)*sample_interval_ms
                if image.shape[0]*image.shape[1] > 1920*1080:
                    raise HTTPException(422, 'Maximum resolution is 1920x1080')
                aspect = image.shape[1]/image.shape[0]
                extractor.process(image)
                trace=getattr(extractor,'last_tracking',{})
                tracking_stats['sampled_frames'] += 1
                tracking_stats['duplicate_label_frames'] += int(trace.get('duplicate_labels',False))
                tracking_stats['recovered_hands'] += trace.get('recovered',0)
                tracking_stats['recovery_attempts'] += int(trace.get('recovery_attempted',False))
                tracking_stats['excess_candidate_frames'] += int(trace.get('excess_candidates',0)>0)
                pose=extractor.last_pose.tolist() if extractor.last_pose is not None else None
                corrected_frames.append(Frame(timestamp_ms=timestamp_ms,
                    hands=[h.tolist() if np.any(h) else None for h in extractor.last_hands],pose=pose))
                frames.append(Frame(timestamp_ms=timestamp_ms,
                    hands=[h.tolist() if np.any(h) else None for h in model_hands(extractor)],pose=pose))
            else:
                raise HTTPException(422, 'Video must be at most 20 seconds')
        if len(frames) < 16:
            raise HTTPException(422, 'Record at least 2 seconds with your hands visible')
        if len(frames) > 300:
            selected=np.linspace(0,len(frames)-1,300).round().astype(int)
            frames=[frames[i] for i in selected]
            corrected_frames=[corrected_frames[i] for i in selected]
        result = runtime.infer(Clip(attempt_id=attempt_id or 'video-'+os.urandom(8).hex(), aspect=aspect,
                                   target_word_id=word_id, frames=frames, use_llm=use_llm), True)
        result['preprocessing'] = {'version': 'legacy_handedness_v1' if legacy_input else VERSION,
            'comparison_version': VERSION,'sampling_fps': 15,'tracking': tracking_stats}
        recognition=result.get('recognition') or {}
        if legacy_input and not use_llm and result.get('status')=='ok' and isinstance(recognition.get('target_score'),(int,float)):
            from .api import encode_frames
            from .feedback_policy import evaluate_feedback
            _,shapes=encode_frames(corrected_frames,aspect)
            indices=np.linspace(0,len(shapes)-1,min(80,len(shapes))).round().astype(int)
            result['feedback']=evaluate_feedback(runtime.reference_banks.get(word_id[4:],runtime.references.get(word_id[4:])),
                shapes[indices],runtime.words[word_id[4:]],recognition['predicted_label'],recognition['target_score'],
                ignore_resting=runtime.ckpt.get('input_policy')=='seated_active_v2',threshold=runtime.feedback_threshold,
                policy=runtime.ckpt.get('feedback_policy','geometry_v1'),recognition=recognition)
        if include_comparison and result.get('feedback') is not None:
            try:
                from .comparison_avatar import build_comparison
                result['feedback']['comparison'] = build_comparison(corrected_frames, aspect, word_id, runtime.words[word_id[4:]], result['feedback'])
            except Exception:
                LOG.exception('Comparison avatar unavailable for %s', word_id)
                result['feedback']['comparison'] = {'available': False, 'notice': '이번 촬영의 비교 화면을 준비하지 못했어요. 단어 인식 결과는 확인할 수 있어요.'}
        try:
            from .practice_diagnostics import save_diagnostics
            save_diagnostics(frames, aspect, result,corrected_frames if legacy_input else None)
        except Exception:
            LOG.exception('Coordinate diagnostics could not be saved')
        recognition = result.get('recognition') or {}
        similarity = (result.get('feedback') or {}).get('similarity') or {}
        LOG.info('Sign video attempt=%s target=%s fps=%s timing=%s frames=%d duration_ms=%.1f '
                 'model=%s status=%s quality=%s predicted=%s target_score=%s similarity=%s',
                 result.get('attempt_id'), word_id, fps, 'fps' if valid_fps else 'timestamps',
                 len(frames), frames[-1].timestamp_ms, result.get('model_id'), result.get('status'),
                 result.get('quality'), recognition.get('predicted_label'),
                 recognition.get('target_score'), similarity.get('score'))
        LOG.info('Sign decision attempt=%s accepted=%s top3=%s reason=%s margin=%s', result.get('attempt_id'), recognition.get('accepted'), recognition.get('top3'), (result.get('feedback') or {}).get('reason'), recognition.get('margin'))
        return result
    finally:
        cap.release()

@video_router.post('/evaluate-video')
async def evaluate_video(target_word_id: str = Form(...), use_llm: bool = Form(False), video: UploadFile = File(...), include_comparison: bool = Form(False),
                         attempt_id: str | None = Form(None, min_length=1, max_length=80, pattern=r'^[A-Za-z0-9_-]+$')):
    runtime.ready()
    if target_word_id not in {'WORD'+k for k in runtime.words}:
        raise HTTPException(422, 'Unknown target_word_id')
    if not gate.acquire(False):
        raise HTTPException(429, 'Another video is being analyzed. Retry shortly.')
    path = None
    try:
        with tempfile.NamedTemporaryFile(suffix='.video', delete=False) as tmp:
            path = tmp.name
            size = 0
            while chunk := await video.read(1024*1024):
                size += len(chunk)
                if size > 25*1024*1024:
                    raise HTTPException(413, 'Maximum video size is 25 MiB')
                tmp.write(chunk)
        return await run_in_threadpool(evaluate_file, path, target_word_id, use_llm, attempt_id, include_comparison)
    finally:
        await video.close()
        if path:
            Path(path).unlink(missing_ok=True)
        gate.release()
