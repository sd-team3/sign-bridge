from pathlib import Path
from types import SimpleNamespace as NS
import tempfile
import unittest
from unittest.mock import patch
import numpy as np
from sign_api.legacy_capture import configure,model_hands
from sign_api.api import Frame
from sign_api.practice_diagnostics import save_diagnostics


def result():
    hands=[]
    for x in [.3,.7]:
        hands.append(NS(landmark=[NS(x=x,y=.5,z=0.) for _ in range(21)]))
    return NS(multi_hand_landmarks=hands,multi_handedness=[NS(classification=[NS(label='Left')]) for _ in hands])


class CompatibilityTests(unittest.TestCase):
    def test_legacy_checkpoint_retains_native_input_without_mutating_detector_result(self):
        native=result();detector=NS(process=lambda image:native)
        extractor=NS(hands=detector,last_hands=np.ones((2,21,3),np.float32))
        self.assertTrue(configure(extractor,{}))
        self.assertIs(detector.process(None),native)
        hands=model_hands(extractor)
        self.assertTrue(np.all(hands[1]==0));self.assertAlmostEqual(float(hands[0,0,0]),.7)
        self.assertEqual(native.multi_hand_landmarks[0].landmark[0].x,.3)
        self.assertTrue(extractor.last_hands[1].any())

    def test_new_checkpoint_uses_corrected_hands(self):
        extractor=NS(hands=NS(process=lambda image:result()),last_hands=np.ones((2,21,3),np.float32))
        self.assertFalse(configure(extractor,{'preprocessing_version':'hands_tracking_v2'}))
        self.assertIs(model_hands(extractor),extractor.last_hands)

    def test_trace_preserves_model_input_separately_from_corrected_display(self):
        primary=[Frame(timestamp_ms=i*100,hands=[None,None]) for i in range(20)]
        corrected=[Frame(timestamp_ms=i*100,hands=[np.ones((21,3)).tolist(),None]) for i in range(20)]
        with tempfile.TemporaryDirectory() as directory,patch('sign_api.practice_diagnostics.ROOT',Path(directory)),patch.dict('os.environ',{'SIGN_SAVE_PRACTICE_COORDS':'true'}):
            save_diagnostics(primary,1,{'attempt_id':'compat-test'},corrected)
            with np.load(next(Path(directory).rglob('*.npz'))) as z:
                self.assertFalse(z['hands'].any());self.assertTrue(z['corrected_hands'][:,0].all())


if __name__=='__main__':unittest.main()
