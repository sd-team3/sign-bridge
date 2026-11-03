import unittest
from unittest.mock import patch
import numpy as np
import torch
from fastapi.testclient import TestClient
from sign_api.api import runtime
from sign_api.standalone import app
from sign_api.feedback_policy import evaluate_feedback


class ContextRecognitionTests(unittest.TestCase):
    def request(self):
        return dict(attempt_id='semantic-test',target_word_id='WORD0115',aspect=16/9,
            frames=[dict(timestamp_ms=i*67,hands=[None,None]) for i in range(30)])

    def encoded(self):
        frames=np.ones((30,154),np.float32);frames[:,127]=-.2;frames[:,129]=-.2
        geometry=np.zeros((30,2,6),np.float32);geometry[:,:,0]=[-.4,.4];geometry[:,:,1]=-.2;geometry[:,:,2:]=170
        return frames,geometry

    def test_named_auxiliary_word_is_not_forced_into_supported70(self):
        with TestClient(app) as client:
            outside=next(i for i,label in enumerate(runtime.ckpt['labels']) if label not in runtime.words.values())
            def predict(xs,mask):
                z=torch.zeros(len(xs),100);z[:,outside]=20;return z
            with patch('sign_api.api.encode_frames',return_value=self.encoded()),patch.object(runtime,'model',predict):
                r=client.post('/api/v1/signs/evaluate',json=self.request()).json()
            self.assertEqual(r['status'],'retry');self.assertIsNone(r['recognition'])
            self.assertEqual(r['feedback']['reason'],'outside_curriculum')
            self.assertTrue(r['feedback']['feedback_required'])

    def test_uncertain_top1_is_not_accepted(self):
        with TestClient(app) as client:
            def predict(xs,mask):
                z=torch.zeros(len(xs),100);z[:,runtime.ckpt['labels'].index('커피')]=.2;return z
            with patch('sign_api.api.encode_frames',return_value=self.encoded()),patch.object(runtime,'model',predict):
                r=client.post('/api/v1/signs/evaluate',json=self.request()).json()
            self.assertFalse(r['recognition']['accepted']);self.assertEqual(r['feedback']['reason'],'uncertain_recognition')
            self.assertTrue(r['feedback']['feedback_required'])

    def test_confident_semantic_match_keeps_geometry_optional(self):
        _,geometry=self.encoded();actual=geometry.copy();actual[:,0,1]+=.35
        result=evaluate_feedback(geometry,actual,'커피','커피',.98,policy='semantic_v1',recognition=dict(accepted=True))
        self.assertFalse(result['feedback_required']);self.assertEqual(result['actions'],[])
        self.assertEqual(result['similarity']['role'],'optional_reference_comparison')
        self.assertTrue(result['reference_notes']);self.assertTrue(result['observations']['corrections'])

    def test_recognition_does_not_claim_posture_when_comparison_missing(self):
        _,geometry=self.encoded()
        result=evaluate_feedback(geometry,np.full_like(geometry,np.nan),'커피','커피',.98,policy='semantic_v1',recognition=dict(accepted=True))
        self.assertFalse(result['feedback_required']);self.assertIsNone(result['similarity']['score'])
        self.assertTrue(any('자세 비교' in note for note in result['reference_notes']))


if __name__=='__main__':unittest.main()
