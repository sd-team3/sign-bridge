import hashlib
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import cv2
import numpy as np
from sign_api.comparison_avatar import reference_data


class ReferenceTrackingTests(unittest.TestCase):
    def test_model_with_different_extractor_version_is_rejected(self):
        from sign_api.api import Runtime
        for mismatch in [{'preprocessing_version':'incompatible'},{'extractor_code_id':'incompatible'},
                         {'extractor_dependencies':{'opencv':'incompatible'}}]:
            with self.subTest(mismatch=mismatch):
                runtime=Runtime()
                with patch('sign_api.api.torch.load',return_value=dict(feature_schema='hands_body_v1',**mismatch)), self.assertLogs('sign_api.api',level='ERROR'):
                    runtime.load()
                self.assertIsNone(runtime.model)
                self.assertEqual(runtime.error,'model_unavailable')

    def test_desktop_geometry_extraction_processes_all_frames(self):
        from sign_api.pose_feedback import extract_geometry
        class Extractor:
            processed=0
            def __enter__(self):return self
            def __exit__(self,*args):pass
            def process(self,image):
                type(self).processed+=1
                self.last_hands=np.zeros((2,21,3),np.float32);self.last_pose=None
        images=[np.zeros((32,32,3),np.uint8) for _ in range(100)]
        with patch('sign_api.body_features.Extractor',Extractor):result=extract_geometry(images)
        self.assertEqual(len(result),80)
        self.assertEqual(Extractor.processed,100)

    def test_reliable_reference_preferred_over_missing_reference(self):
        from sign_api.feedback_policy import evaluate_feedback
        geometry=np.zeros((24,2,6),np.float32)
        geometry[:,:,0]=[-.4,.4];geometry[:,:,1]=-.2;geometry[:,:,2:]=170
        refs=[dict(subject='REAL01',geometry=geometry,video_url='/one',tracking_quality={'needs_review':True}),
              dict(subject='REAL02',geometry=geometry,video_url='/two',tracking_quality={'needs_review':False})]
        result=evaluate_feedback(refs,geometry,'밥','밥',.99,policy='semantic_v1',recognition={'accepted':True})
        self.assertEqual(result['reference']['subject'],'REAL02')
        self.assertFalse(result['reference']['tracking_review'])

    def test_all_references_occluded_does_not_blame_user_or_give_joint_advice(self):
        from sign_api.feedback_policy import evaluate_feedback
        geometry=np.zeros((24,2,6),np.float32)
        geometry[:,:,0]=[-.4,.4];geometry[:,:,1]=-.2;geometry[:,:,2:]=170
        actual=geometry.copy();actual[:,:,1]+=.3
        refs=[dict(subject='REAL01',geometry=geometry,video_url='/one',tracking_quality={'needs_review':True})]
        result=evaluate_feedback(refs,actual,'밥','밥',.99,policy='semantic_v1',recognition={'accepted':True})
        self.assertFalse(result['similarity']['available'])
        self.assertEqual(result['observations']['corrections'],[])
        self.assertTrue(any('모범 영상' in note for note in result['reference_notes']))
        self.assertFalse(any('이번 촬영' in note for note in result['reference_notes']))

    def test_cache_rejects_old_extractor_and_tracks_unsampled_frames(self):
        class Capture:
            def __init__(self):self.i=0;self.released=False
            def isOpened(self):return True
            def get(self,key):return 60 if key==cv2.CAP_PROP_FRAME_COUNT else 30
            def grab(self):self.i+=1;return self.i<=60
            def retrieve(self):return True,np.zeros((64,64,3),np.uint8)
            def release(self):self.released=True
        class Extractor:
            processed=0
            def __enter__(self):return self
            def __exit__(self,*args):pass
            def process(self,image):
                type(self).processed+=1
                self.last_hands=np.ones((2,21,3),np.float32)*self.processed
                self.last_pose=np.ones((33,3),np.float32)
        with tempfile.TemporaryDirectory() as folder:
            root=Path(folder);(root/'assets/videos').mkdir(parents=True);cache=root/'cache';cache.mkdir()
            video=root/'assets/videos/1201.mp4';video.write_bytes(b'fake-video')
            np.savez_compressed(cache/'1201.npz',version=2,source_sha256=hashlib.sha256(video.read_bytes()).hexdigest(),extractor_sha256='stale')
            cap=Capture()
            with patch('sign_api.comparison_avatar.ROOT',root),patch('sign_api.comparison_avatar.CACHE',cache),patch('sign_api.comparison_avatar.extractor_hash',return_value='new'),patch('cv2.VideoCapture',return_value=cap),patch('sign_api.body_features.Extractor',Extractor):
                h,p,t,aspect=reference_data('1201','REAL01')
                self.assertEqual(Extractor.processed,60)
                self.assertEqual(len(h),48)
                self.assertEqual(h[-1,0,0,0],60)
                self.assertTrue(cap.released)
                reference_data('1201','REAL01')
                self.assertEqual(Extractor.processed,60)
            with np.load(cache/'1201.npz') as saved:self.assertEqual(str(saved['extractor_sha256']),'new')


if __name__=='__main__':unittest.main()
