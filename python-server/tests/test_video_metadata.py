import unittest
from unittest.mock import patch
import numpy as np
import cv2
from fastapi import HTTPException
from sign_api.video_api import evaluate_file


class Capture:
    def __init__(self,frames,fps=15.,step_ms=100.,opened=True):
        self.frames=frames; self.index=0; self.fps=fps; self.step_ms=step_ms; self.opened=opened
        self.released=False
    def isOpened(self): return self.opened
    def get(self,key):
        if key==cv2.CAP_PROP_FPS: return self.fps
        if key==cv2.CAP_PROP_POS_MSEC: return (self.index-1)*self.step_ms
        return 1000000000000.
    def grab(self): self.index+=1; return self.index<=self.frames
    def retrieve(self): return True,np.zeros((360,640,3),np.uint8)
    def release(self): self.released=True


class Extractor:
    def __enter__(self): return self
    def __exit__(self,*args): pass
    def process(self,image):
        self.last_hands=np.zeros((2,21,3),np.float32)
        self.last_pose=None


class VideoMetadataTests(unittest.TestCase):
    def test_missing_fps_uses_decoded_timestamps(self):
        for fps in (0.,float('nan'),1000.):
            with self.subTest(fps=fps), \
                 patch('sign_api.video_api.cv2.VideoCapture',return_value=Capture(30,fps=fps)), \
                 patch('sign_api.video_api.Extractor',Extractor), \
                 patch('sign_api.video_api.runtime.infer',return_value={'status':'retry'}) as infer:
                evaluate_file('unused','WORD0115',False,'timestamp-test')
                frames=infer.call_args.args[0].frames
                self.assertEqual(len(frames),30)
                self.assertEqual(frames[-1].timestamp_ms,2900.)

    def test_missing_fps_does_not_allow_long_video(self):
        with patch('sign_api.video_api.cv2.VideoCapture',return_value=Capture(220,fps=0.)), \
             patch('sign_api.video_api.Extractor',Extractor):
            with self.assertRaises(HTTPException) as error:
                evaluate_file('unused','WORD0115',False)
            self.assertEqual(error.exception.detail,'Video must be at most 20 seconds')

    def test_missing_fps_and_timestamps_is_rejected(self):
        capture=Capture(30,fps=0.,step_ms=0.)
        with patch('sign_api.video_api.cv2.VideoCapture',return_value=capture), \
             patch('sign_api.video_api.Extractor',Extractor):
            with self.assertRaises(HTTPException) as error:
                evaluate_file('unused','WORD0115',False)
            self.assertEqual(error.exception.detail,'Cannot determine video frame rate')
            self.assertTrue(capture.released)

    def test_unopened_file_reports_decode_error(self):
        capture=Capture(0,opened=False)
        with patch('sign_api.video_api.cv2.VideoCapture',return_value=capture):
            with self.assertRaises(HTTPException) as error:
                evaluate_file('unused','WORD0115',False)
            self.assertEqual(error.exception.detail,'Video decoding failed')
            self.assertTrue(capture.released)

    def test_bad_frame_count_metadata_does_not_reject_short_recording(self):
        with patch('sign_api.video_api.cv2.VideoCapture',return_value=Capture(30)), \
             patch('sign_api.video_api.Extractor',Extractor), \
             patch('sign_api.video_api.runtime.infer',return_value={'status':'retry'}) as infer:
            result=evaluate_file('unused','WORD0115',False,'meta-test')
            self.assertEqual(result['status'],'retry')
            self.assertEqual(len(infer.call_args.args[0].frames),30)

    def test_real_decoded_frame_limit_still_rejects_long_recording(self):
        with patch('sign_api.video_api.cv2.VideoCapture',return_value=Capture(400)),patch('sign_api.video_api.Extractor',Extractor):
            with self.assertRaises(HTTPException) as error: evaluate_file('unused','WORD0115',False)
            self.assertEqual(error.exception.status_code,422)
