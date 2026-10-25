import json
from pathlib import Path
import sys
import tempfile

import cv2
import numpy as np
from fastapi.testclient import TestClient

PACKAGE = Path(__file__).resolve().parents[1]
sys.path.insert(0,str(PACKAGE))
from sign_api.api import runtime
from sign_api.standalone import app
from sign_api.body_features import Extractor

def main():
    source=PACKAGE/'sign_api/assets/videos/0115.mp4'
    with tempfile.TemporaryDirectory() as directory:
        video=Path(directory)/'sample.mp4'
        cap=cv2.VideoCapture(str(source)); fps=cap.get(cv2.CAP_PROP_FPS)
        writer=cv2.VideoWriter(str(video),cv2.VideoWriter_fourcc(*'mp4v'),15,(640,360))
        if not writer.isOpened(): raise RuntimeError('Video encoder unavailable')
        index=0
        while cap.grab():
            if index % max(1,round(fps/15)) == 0:
                ok,image=cap.retrieve()
                if not ok: raise RuntimeError('Decode failed')
                writer.write(cv2.resize(image,(640,360)))
            index+=1
        cap.release(); writer.release()
        features=[]; frames=[]
        cap=cv2.VideoCapture(str(video))
        with Extractor() as extractor:
            while True:
                ok,image=cap.read()
                if not ok: break
                features.append(extractor.process(image))
                frames.append(dict(timestamp_ms=(len(features)-1)*1000/15,
                    hands=[h.tolist() if np.any(h) else None for h in extractor.last_hands],
                    pose=extractor.last_pose.tolist() if extractor.last_pose is not None else None))
        cap.release()
        with TestClient(app) as client:
            raw=client.post('/api/v1/signs/evaluate',json=dict(attempt_id='spring-raw-smoke',target_word_id='WORD0115',aspect=16/9,frames=frames))
            raw.raise_for_status(); raw=raw.json()
            with video.open('rb') as handle:
                uploaded=client.post('/api/v1/signs/evaluate-video',data=dict(attempt_id='spring-upload-smoke',target_word_id='WORD0115'),files={'video':('sample.mp4',handle,'video/mp4')})
            uploaded.raise_for_status(); uploaded=uploaded.json()
            assert raw['status'] == uploaded['status'] == 'ok'
            assert uploaded['attempt_id'] == 'spring-upload-smoke'
            assert uploaded['model_id'] == 'curriculum100_seated_active_v2'
            assert uploaded['feedback']['status'] != 'reference_unavailable'
            assert raw['recognition']['predicted_label'] == uploaded['recognition']['predicted_label']

            desktop=Path('D:/sign-lang')
            if (desktop/'practice50.py').is_file():
                sys.path.insert(0,str(desktop))
                from practice50 import assess
                expected=assess(features,runtime.model,runtime.ckpt,'커피')
                assert expected['predicted'] == raw['recognition']['predicted_label']
                assert abs(expected['score']-raw['recognition']['top3'][0]['score']) < 1e-6
            print(json.dumps(dict(status='VIDEO_SMOKE_OK',frames=len(frames),model_id=uploaded['model_id'],
                predicted=uploaded['recognition']['predicted_label'],attempt_id=uploaded['attempt_id'],
                feedback_status=uploaded['feedback']['status']),ensure_ascii=False))

if __name__ == '__main__': main()
