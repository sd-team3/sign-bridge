"""Versioned hands + shoulder-relative upper-body features shared by train/inference."""
import numpy as np
from .sign_model import normalize_hands

SCHEMA='hands_body_v1'
SIZE=154
POSE_IDS=[0,11,12,13,14,15,16]

def encode(hands,pose,aspect):
    out=np.zeros(SIZE,np.float32)
    out[:126]=normalize_hands(hands.reshape(126))
    present=np.any(hands!=0,axis=(1,2))
    out[151:153]=present
    if pose is None or min(pose[11,2],pose[12,2])<.5: return out
    xy=pose[:,:2]*np.array([aspect,1],np.float32)
    center=(xy[11]+xy[12])/2
    scale=np.linalg.norm(xy[11]-xy[12])
    if scale<.03: return out
    out[153]=1
    wrists=(hands[:,0,:2]*[aspect,1]-center)/scale
    wrists[~present]=0
    out[126:130]=np.clip(wrists,-5,5).reshape(-1)
    body=np.zeros((7,3),np.float32)
    for i,p in enumerate(POSE_IDS):
        if pose[p,2]>=.5:
            body[i,:2]=np.clip((xy[p]-center)/scale,-5,5)
            body[i,2]=pose[p,2]
    out[130:151]=body.reshape(-1)
    return out

def mirror(seq):
    out=seq.copy()
    hands=seq[:,:126].reshape(-1,2,21,3)[:,::-1].copy(); hands[...,0]*=-1
    out[:,:126]=hands.reshape(-1,126)
    wrists=seq[:,126:130].reshape(-1,2,2)[:,::-1].copy(); wrists[...,0]*=-1
    out[:,126:130]=wrists.reshape(-1,4)
    pose=seq[:,130:151].reshape(-1,7,3)[:,[0,2,1,4,3,6,5]].copy(); pose[...,0]*=-1
    out[:,130:151]=pose.reshape(-1,21)
    out[:,151:153]=seq[:,151:153][:,::-1]
    return out

class Extractor:
    def __init__(self):
        import mediapipe as mp
        self.hands=mp.solutions.hands.Hands(False,2,1,.5,.5)
        self.pose=mp.solutions.pose.Pose(static_image_mode=False,model_complexity=1,
                                       smooth_landmarks=True,enable_segmentation=False,
                                       min_detection_confidence=.5,min_tracking_confidence=.5)
    def reset(self): self.hands.reset(); self.pose.reset()
    def process(self,image):
        import cv2
        if image.shape[1]>640: image=cv2.resize(image,(640,round(image.shape[0]*640/image.shape[1])))
        rgb=cv2.cvtColor(image,cv2.COLOR_BGR2RGB)
        h=self.hands.process(rgb); p=self.pose.process(rgb)
        hands=np.zeros((2,21,3),np.float32)
        if h.multi_hand_landmarks and h.multi_handedness:
            for lm,hd in zip(h.multi_hand_landmarks,h.multi_handedness):
                hands[0 if hd.classification[0].label=='Left' else 1]=[[v.x,v.y,v.z] for v in lm.landmark]
        pose=np.array([[v.x,v.y,v.visibility] for v in p.pose_landmarks.landmark],np.float32) if p.pose_landmarks else None
        self.last_hands=hands
        self.last_pose=pose
        return encode(hands,pose,image.shape[1]/image.shape[0])
    def close(self): self.hands.close(); self.pose.close()
    def __enter__(self): return self
    def __exit__(self,*args): self.close()
