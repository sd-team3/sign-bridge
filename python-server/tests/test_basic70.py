import json
from pathlib import Path
import sys
import unittest
import numpy as np
import torch
from fastapi.testclient import TestClient
from sign_api.api import runtime
from sign_api.standalone import app
from sign_api.feedback_policy import evaluate_feedback
from sign_api.pose_feedback import geometry
from sign_api.reference_selection import mirrored
from sign_api.sign_model import SignLSTM,inference_logits
from sign_api.body_features import encode,mirror


class Basic70Tests(unittest.TestCase):
    def sequence(self):
        a=np.zeros((30,2,6),np.float32)
        a[:,:,0]=[-.4,.4]; a[:,:,1]=-.2; a[:,:,2:]=170
        return a

    def test_training_variants_are_selected_and_exposed(self):
        a=self.sequence(); wrong=a.copy(); wrong[:,:,0]+=.35
        refs=[dict(subject='REAL01',geometry=wrong,video_url='/first'),dict(subject='REAL02',geometry=a,video_url='/second')]
        result=evaluate_feedback(refs,a,'밥','밥',.99)
        self.assertEqual(result['reference']['subject'],'REAL02')
        self.assertEqual(result['reference']['video_url'],'/second')
        self.assertEqual(result['similarity']['score'],100)

    def test_left_dominant_motion_matches_mirrored_reference(self):
        a=self.sequence(); a[:,1]=np.nan
        refs=[dict(subject='REAL01',geometry=a,video_url='/first')]
        result=evaluate_feedback(refs,mirrored(a),'밥','밥',.99)
        self.assertTrue(result['reference']['mirrored'])
        self.assertEqual(result['similarity']['score'],100)

    def test_missing_tracking_cannot_create_a_high_similarity(self):
        a=self.sequence()
        result=evaluate_feedback([dict(subject='REAL01',geometry=a,video_url='/first')],np.full_like(a,np.nan),'밥','밥',.99)
        self.assertIsNone(result['similarity']['score'])
        self.assertTrue(result['feedback_required'])

    def test_lateral_position_gets_measured_guidance(self):
        a=self.sequence(); user=a.copy(); user[:,0,0]-=.3
        result=evaluate_feedback(a,user,'밥','밥',.99)
        self.assertIn('왼손',result['message']); self.assertIn('몸 쪽으로 모아',result['message'])

    def test_mirror_ensemble_and_temperature_match_manual_inference(self):
        torch.manual_seed(3); model=SignLSTM(3,hidden_size=8,num_layers=1,input_size=154); model.eval()
        x=torch.randn(2,8,154); mask=torch.ones(2,8,dtype=torch.bool)
        flipped=torch.tensor(np.array([mirror(row.numpy()) for row in x]))
        with torch.inference_mode():
            expected=(model(x,mask)+model(flipped,mask))*.5/.65
            actual=inference_logits(model,x,mask,dict(mirror_ensemble=True,temperature=.65))
        torch.testing.assert_close(expected,actual)

    def test_feature_cache_geometry_preserves_raw_geometry(self):
        root=Path('D:/sign-lang'); sys.path.append(str(root))
        if not (root/'coaching_geometry.py').is_file(): self.skipTest('Feature-cache builder not installed')
        from coaching_geometry import from_features
        rng=np.random.default_rng(5)
        pose=np.zeros((33,3),np.float32); pose[:,2]=1
        pose[11,:2]=[.7,.4]; pose[12,:2]=[.3,.4]
        pose[15,:2]=[.72,.58]; pose[16,:2]=[.28,.58]
        hands=rng.normal(0,.02,(2,21,3)).astype(np.float32)
        hands[:,:,:2]+=np.array([[.72,.58],[.28,.58]],np.float32)[:,None,:]
        hands[:,0,:2]=pose[[15,16],:2]
        aspect=16/9
        expected=geometry(hands,pose,aspect)
        actual=from_features(np.array([encode(hands,pose,aspect)]),aspect)[0]
        np.testing.assert_allclose(actual,expected,atol=.001,rtol=.0001,equal_nan=True)

    def test_only_basic_chapters_words_and_variants_are_served(self):
        with TestClient(app) as client:
            health=client.get('/api/v1/signs/health').json()
            self.assertEqual(health['classes'],70); self.assertEqual(health['chapters'],7)
            self.assertEqual(health['reference_variants'],210)
            self.assertTrue(health['mirror_ensemble'])
            self.assertEqual(client.get('/api/v1/signs/chapters/chapter-08').status_code,404)
            self.assertEqual(client.get('/api/v1/signs/words/WORD0684').status_code,404)
            for subject in ('REAL02','REAL03'):
                response=client.get('/api/v1/signs/reference/WORD0115/'+subject,headers={'Range':'bytes=0-63'})
                self.assertEqual(response.status_code,206); self.assertEqual(len(response.content),64)
            self.assertEqual(client.get('/api/v1/signs/reference/WORD0115/REAL07').status_code,404)
