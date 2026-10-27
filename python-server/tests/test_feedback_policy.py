import unittest
from unittest.mock import patch
import numpy as np
from sign_api.pose_feedback import compare
from sign_api.feedback_policy import evaluate_feedback


class FeedbackPolicyTests(unittest.TestCase):
    def sequence(self):
        a=np.zeros((30,2,6),np.float32)
        a[:,:,0]=[-.4,.4]; a[:,:,1]=-.2; a[:,:,2:]=170
        return a

    def test_horizontal_difference_requires_feedback_without_invented_correction(self):
        ref=self.sequence(); actual=ref.copy(); actual[:,:,0]+=np.where(np.arange(30)%2==0,.4,-.4)[:,None]
        result=evaluate_feedback(ref,actual,'커피','커피',.95)
        self.assertLessEqual(result['similarity']['score'],70)
        self.assertTrue(result['feedback_required'])
        self.assertEqual(result['status'],'advice')
        self.assertTrue(result['message']); self.assertTrue(result['actions'])
        self.assertEqual(result['observations']['corrections'],[])
        self.assertNotIn('검지',result['message'])

    def test_equal_threshold_always_requires_feedback(self):
        a=self.sequence()
        result=evaluate_feedback(a,a,'밥','밥',.99,threshold=100)
        self.assertTrue(result['similarity']['below_threshold'])
        self.assertTrue(result['feedback_required'])
        self.assertEqual(result['status'],'advice')

    def test_default_boundary_is_70_and_score_75_does_not_force_guidance(self):
        a=self.sequence()
        for score,required in ((70,True),(75,False)):
            actual=a.copy()
            offset=np.log(100/score)
            actual[:,:,0]+=np.where(np.arange(30)%2==0,offset,-offset)[:,None]
            result=evaluate_feedback(a,actual,'밥','밥',.99)
            self.assertEqual(result['similarity']['threshold'],70)
            self.assertEqual(result['similarity']['score'],score)
            self.assertEqual(result['feedback_required'],required)

    def test_identical_motion_has_score_100_without_forced_correction(self):
        a=self.sequence(); result=evaluate_feedback(a,a,'밥','밥',.99)
        self.assertEqual(result['similarity']['score'],100)
        self.assertFalse(result['feedback_required'])
        self.assertEqual(result['observations']['corrections'],[])

    def test_missing_tracking_returns_guidance_not_zero_score(self):
        a=self.sequence(); result=evaluate_feedback(a,np.full_like(a,np.nan),'밥','밥',.99)
        self.assertTrue(result['feedback_required'])
        self.assertIsNone(result['similarity']['score'])
        self.assertTrue(result['message']); self.assertTrue(result['actions'])
        self.assertEqual(result['observations']['corrections'],[])

    def test_wrong_label_even_when_confident_requires_guidance(self):
        a=self.sequence(); result=evaluate_feedback(a,a,'밥','영화',.001)
        self.assertTrue(result['feedback_required']); self.assertEqual(result['status'],'advice')
        self.assertIn('영화',result['message']); self.assertIn('밥',result['message'])
        self.assertNotIn('뚜렷한 차이가 보이지',result['message'])

    def test_uncertain_correct_label_requires_guidance(self):
        a=self.sequence(); result=evaluate_feedback(a,a,'밥','밥',.4)
        self.assertTrue(result['feedback_required']); self.assertEqual(result['reason'],'uncertain_recognition')

    def test_observed_side_and_direction_preserved(self):
        ref=self.sequence(); user=ref.copy(); user[:,1,1]+=.3; user[:,1,2]-=40
        result=evaluate_feedback(ref,user,'밥','밥',.99)
        self.assertIn('오른손의 위치',result['message']); self.assertIn('올려',result['message'])
        self.assertIn('검지',result['message']); self.assertIn('펴서',result['message'])
        self.assertNotIn('왼손',result['message'])

    def test_missing_reference_and_short_clip_always_have_guidance(self):
        a=self.sequence()
        for result in (evaluate_feedback(None,a,'밥','밥',.99),evaluate_feedback(a,a[:3],'밥','밥',.99)):
            self.assertTrue(result['feedback_required']); self.assertTrue(result['message'])
            self.assertTrue(result['actions']); self.assertIsNone(result['similarity']['score'])

    def test_invalid_threshold_rejected(self):
        a=self.sequence()
        for threshold in (-1,101,float('nan')):
            with self.assertRaises(ValueError): compare(a,a,similarity_threshold=threshold)
