"""Desk occlusion augmentation and shared seated-model sequence preprocessing."""
import numpy as np
from .sign_model import resample_sequence

POLICY='seated_v1'

def desk_occlude(frames,cutoff):
    """Hide landmarks below a synthetic horizontal desk edge, in shoulder-width units."""
    a=frames.copy()
    for slot in (0,1):
        hidden=(a[:,153]>.5)&(a[:,151+slot]>.5)&(a[:,127+slot*2]>cutoff)
        a[hidden,slot*63:(slot+1)*63]=0
        a[hidden,126+slot*2:128+slot*2]=0
        a[hidden,151+slot]=0
    pose=a[:,130:151].reshape(-1,7,3)
    for i in (3,4,5,6):
        hidden=(pose[:,i,2]>.5)&(pose[:,i,1]>cutoff)
        pose[hidden,i]=0
    return a

def prepare(frames,length=64):
    # Remove only hand-free leading/trailing padding, not interior gesture gaps.
    seen=np.flatnonzero(np.any(frames[:,:126]!=0,axis=1))
    if len(seen): frames=frames[max(0,seen[0]-2):min(len(frames),seen[-1]+3)]
    seq,_=resample_sequence(frames,length)
    mask=np.any(seq[:,:126]!=0,axis=1)|(seq[:,153]>.5)
    return seq,mask

def augment(frames,rng):
    a=frames.copy()
    if rng.random()<.65:
        cropped=desk_occlude(a,rng.uniform(.65,1.65))
        # Keep a substantial amount of actual hand evidence; never teach all-hidden clips.
        if np.any(cropped[:,:126]!=0,axis=1).sum()>=max(16,len(a)*.4): a=cropped
    # Brief per-hand tracking gaps, rather than erasing an arbitrary hand for a whole sign.
    if rng.random()<.35:
        slot=int(rng.integers(2)); start=int(rng.integers(max(1,len(a)-5)))
        end=min(len(a),start+int(rng.integers(2,9)))
        a[start:end,slot*63:(slot+1)*63]=0; a[start:end,126+slot*2:128+slot*2]=0; a[start:end,151+slot]=0
    if rng.random()<.4 and len(a)>32:
        n=int(rng.integers(28,min(64,len(a))+1))
        a=a[np.linspace(0,len(a)-1,n).round().astype(int)]
    return a
