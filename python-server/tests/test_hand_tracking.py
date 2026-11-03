import unittest
from types import SimpleNamespace as NS
import numpy as np
from sign_api.hand_tracking import HandTracker, candidates, recover_candidates, expected_missing


def hand(x,y=.45):
    a=np.zeros((21,3),np.float32)
    a[:,0]=x;a[:,1]=y
    a[9,1]+=.05
    return a


def pose():
    p=np.zeros((33,3),np.float32)
    p[11]=[.7,.3,1];p[12]=[.3,.3,1]
    p[15]=[.7,.45,1];p[16]=[.3,.45,1]
    return p


class TrackingTests(unittest.TestCase):
    def test_duplicate_labels_preserve_both_actual_detections(self):
        h=HandTracker().assign([(hand(.3),'Left',.99),(hand(.7),'Left',.99)],pose(),1)
        self.assertEqual(np.any(h!=0,axis=(1,2)).sum(),2)
        np.testing.assert_array_equal(h[0],hand(.3));np.testing.assert_array_equal(h[1],hand(.7))

    def test_crossed_hands_use_pose_not_horizontal_sort(self):
        p=pose();p[15,0]=.25;p[16,0]=.75
        h=HandTracker().assign([(hand(.25),'Right',.9),(hand(.75),'Left',.9)],p,1)
        self.assertAlmostEqual(float(h[0,0,0]),.75)

    def test_no_detection_never_fabricates_previous_hand(self):
        t=HandTracker();t.assign([(hand(.3),'Left',.9)],pose(),1)
        self.assertFalse(t.assign([],pose(),1).any())

    def test_missing_handedness_does_not_discard_landmark(self):
        lm=NS(landmark=[NS(x=float(p[0]),y=float(p[1]),z=0) for p in hand(.3)])
        d=candidates(NS(multi_hand_landmarks=[lm],multi_handedness=None))
        self.assertEqual(len(d),1)
        self.assertTrue(HandTracker().assign(d,pose(),1).any())

    def test_recovery_requires_distinct_hand_and_pose_agreement(self):
        d=[(hand(.3),'Left',.9)]
        result,count=recover_candidates(d,[(hand(.301),'Left',.9),(hand(.7),'Right',.9)],pose(),1)
        self.assertEqual(count,1);self.assertEqual(len(result),2)
        self.assertEqual(recover_candidates(d,[(hand(.9),'Right',.9)],pose(),1)[1],0)
        self.assertEqual(recover_candidates(d,[(hand(.7),'Right',.9)],None,1)[1],0)

    def test_resting_or_out_of_frame_hand_not_required(self):
        h=np.array([hand(.3),np.zeros((21,3))]);p=pose()
        self.assertTrue(expected_missing(h,p,1))
        p[15,1]=.95;self.assertFalse(expected_missing(h,p,1))
        p[15,1]=-.1;self.assertFalse(expected_missing(h,p,1))

    def test_reset_removes_previous_person(self):
        t=HandTracker();t.assign([(hand(.3),'Left',.9)],pose(),1);t.reset()
        self.assertFalse(t.previous.any());self.assertTrue((t.age>2).all())


if __name__=='__main__':unittest.main()
