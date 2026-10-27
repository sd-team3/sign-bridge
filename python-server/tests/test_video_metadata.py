import unittest
from unittest.mock import patch
import numpy as np
from fastapi import HTTPException
from sign_api.video_api import evaluate_file


class Capture:
    def __init__(self,frames): self.frames=frames; self.index=0
    def get(self,key): return 15. if key==5 else 1000000000000.
    def grab(self): self.index+=1; return self.index<=self.frames
    def retrieve(self): return True,np.zeros((360,640,3),np.uint8)
    def release(self): pass


class Extractor:
    def __enter__(self): return self
    def __exit__(self,*args): pass
    def process(self,image):
        self.last_hands=np.zeros((2,21,3),np.float32)
        self.last_pose=None


class VideoMetadataTests(unittest.TestCase):
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
