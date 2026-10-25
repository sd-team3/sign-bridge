import numpy as np
from .seated_features import prepare as prepare_v1, augment as augment_v1

POLICY = 'seated_active_v2'

def suppress_resting(frames):
    a = np.asarray(frames, dtype=np.float32).copy()
    if len(a) == 0:
        return a

    a[:, 139:151] = 0
    idle = []
    raised = []
    for slot in (0, 1):
        valid = (a[:, 153] > .5) & (a[:, 151+slot] > .5)
        wrist = a[valid, 126+slot*2:128+slot*2]
        shape = a[valid, slot*63:(slot+1)*63]
        enough = valid.sum() >= max(8, len(a)*.35)
        if enough:
            span = np.linalg.norm(np.quantile(wrist, .95, axis=0)-np.quantile(wrist, .05, axis=0))
            shape_change = np.quantile(np.sqrt(np.mean((shape-np.median(shape, axis=0))**2, axis=1)), .9)
            idle.append(bool(np.mean(wrist[:, 1] > 1.1) >= .9 and span < .3 and shape_change < .18))
            raised.append(bool(np.mean(wrist[:, 1] < .9) >= .3))
        else:
            idle.append(False)
            raised.append(False)
    for slot in (0, 1):
        if idle[slot] and raised[1-slot]:
            a[:, slot*63:(slot+1)*63] = 0
            a[:, 126+slot*2:128+slot*2] = 0
            a[:, 151+slot] = 0
    return a

def prepare(frames, length=64):
    return prepare_v1(suppress_resting(frames), length)

def augment(frames, rng):
    return augment_v1(frames, rng)
