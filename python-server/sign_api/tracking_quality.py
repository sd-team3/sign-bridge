import numpy as np
from .hand_tracking import expected_missing


def summarize(frames, aspect):
    hands=np.asarray([[h if h is not None else np.zeros((21,3)) for h in f.hands] for f in frames],np.float32)
    present=np.any(hands!=0,axis=(2,3))
    stamps=np.asarray([f.timestamp_ms for f in frames],float)
    interval=float(np.median(np.diff(stamps))) if len(stamps)>1 else 0.
    missing=[]
    for h,frame in zip(hands,frames):
        pose=np.asarray(frame.pose,np.float32) if frame.pose is not None else None
        missing.append(expected_missing(h,pose,aspect))
    longest=0.;start=None
    for i,value in enumerate(missing):
        if value and start is None:start=stamps[i]
        if not value and start is not None:
            longest=max(longest,stamps[i]-start);start=None
    if start is not None:longest=max(longest,stamps[-1]+interval-start)
    return dict(hand_slot_frames=present.sum(0).tolist(),
        expected_missing_frames=int(sum(missing)),longest_expected_gap_ms=round(float(longest),1),
        needs_tracking_review=bool(longest>=300))
