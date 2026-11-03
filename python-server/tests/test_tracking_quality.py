import unittest
import json
from types import SimpleNamespace as NS
import numpy as np
from sign_api.tracking_quality import summarize


class QualityTests(unittest.TestCase):
    def frames(self, resting=False, missing=False):
        pose=np.zeros((33,3),np.float32)
        pose[11]=[.7,.3,1];pose[12]=[.3,.3,1]
        pose[15]=[.7,.95 if resting else .45,1];pose[16]=[.3,.45,1]
        hand=np.ones((21,3),np.float32)*.3
        return [NS(timestamp_ms=i*100,hands=[hand,None if missing and 3<=i<8 else hand],pose=pose) for i in range(12)]

    def test_raised_hand_missing_interior_is_reported(self):
        result=summarize(self.frames(missing=True),1)
        self.assertEqual(result['expected_missing_frames'],5)
        self.assertEqual(result['longest_expected_gap_ms'],500)
        self.assertTrue(result['needs_tracking_review'])

    def test_tracking_gap_is_json_serializable(self):
        result=summarize(self.frames(missing=True),1)
        self.assertIs(type(result['needs_tracking_review']),bool)
        self.assertEqual(json.loads(json.dumps(result))['longest_expected_gap_ms'],500)

    def test_resting_hand_not_flagged_as_required(self):
        result=summarize(self.frames(resting=True,missing=True),1)
        self.assertEqual(result['expected_missing_frames'],0)
        self.assertFalse(result['needs_tracking_review'])

    def test_irregular_timestamps_use_elapsed_time(self):
        frames=self.frames(missing=True)
        for i,f in enumerate(frames):f.timestamp_ms=i*40
        result=summarize(frames,1)
        self.assertEqual(result['longest_expected_gap_ms'],200)
        self.assertFalse(result['needs_tracking_review'])


if __name__=='__main__':unittest.main()
