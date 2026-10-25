"""Bounded local-demo video upload using the training-time Python extractor."""
import os
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

video_router = APIRouter(prefix='/api/v1/signs', tags=['Sign words'], dependencies=[Depends(authenticate)])
gate = threading.BoundedSemaphore(1)


@video_router.get('/reference/{word_id}')
def reference(word_id: str):
    code = word_id[4:] if word_id.startswith('WORD') else ''
    if code not in runtime.words:
        raise HTTPException(404, 'Unknown word')
    path = ROOT / 'assets' / 'videos' / f'{code}.mp4'
    if not path.exists():
        raise HTTPException(404, 'Reference video unavailable')
    return FileResponse(path, media_type='video/mp4')


def evaluate_file(path, word_id, use_llm):
    cap = cv2.VideoCapture(path)
    try:
        fps = cap.get(cv2.CAP_PROP_FPS)
        if not np.isfinite(fps) or not 1 <= fps <= 120:
            raise HTTPException(422, 'Cannot determine video frame rate')
        count = cap.get(cv2.CAP_PROP_FRAME_COUNT)
        if count > fps * 20 + 2:
            raise HTTPException(422, 'Video must be at most 20 seconds')
        stride = max(1, round(fps/15))
        frames, aspect = [], None
        with Extractor() as extractor:
            for index in range(int(fps*20)+2):
                ok = cap.grab()
                if not ok:
                    break
                if index >= fps*20:
                    raise HTTPException(422, 'Video must be at most 20 seconds')
                if index % stride:
                    continue
                ok, image = cap.retrieve()
                if not ok:
                    raise HTTPException(422, 'Video decoding failed')
                if image.shape[0]*image.shape[1] > 1920*1080:
                    raise HTTPException(422, 'Maximum resolution is 1920x1080')
                aspect = image.shape[1]/image.shape[0]
                extractor.process(image)
                frames.append(Frame(timestamp_ms=index*1000/fps,
                    hands=[h.tolist() if np.any(h) else None for h in extractor.last_hands],
                    pose=extractor.last_pose.tolist() if extractor.last_pose is not None else None))
        if len(frames) < 16:
            raise HTTPException(422, 'Record at least 2 seconds with your hands visible')
        if len(frames) > 300:
            frames = [frames[i] for i in np.linspace(0,len(frames)-1,300).round().astype(int)]
        return runtime.infer(Clip(attempt_id='video-'+os.urandom(8).hex(), aspect=aspect,
                                  target_word_id=word_id, frames=frames, use_llm=use_llm), True)
    finally:
        cap.release()


@video_router.post('/evaluate-video')
async def evaluate_video(target_word_id: str = Form(...), use_llm: bool = Form(False), video: UploadFile = File(...)):
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
        return await run_in_threadpool(evaluate_file, path, target_word_id, use_llm)
    finally:
        await video.close()
        if path:
            Path(path).unlink(missing_ok=True)
        gate.release()
