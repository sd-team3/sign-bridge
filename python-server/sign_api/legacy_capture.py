import numpy as np
from .hand_tracking import VERSION


def configure(extractor, checkpoint):
    if checkpoint.get('preprocessing_version') == VERSION:
        return False
    detector=getattr(extractor,'hands',None)
    if detector is None:
        return False
    process=detector.process

    def capture(rgb):
        result=process(rgb)
        hands=np.zeros((2,21,3),np.float32)
        # Preserve old checkpoint inputs; corrected hands remain separate.
        for landmark,label in zip(result.multi_hand_landmarks or [],result.multi_handedness or []):
            slot=0 if label.classification[0].label=='Left' else 1
            hands[slot]=[[p.x,p.y,p.z] for p in landmark.landmark]
        extractor.legacy_hands=hands
        return result

    detector.process=capture
    return True


def model_hands(extractor):
    return getattr(extractor,'legacy_hands',extractor.last_hands)
