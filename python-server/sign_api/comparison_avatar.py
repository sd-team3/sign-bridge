import base64
from functools import lru_cache
import hashlib
from html import escape
import os
from pathlib import Path
import threading
import numpy as np
from .pose_feedback import geometry, alignment, exclude_resting_geometry

ROOT = Path(__file__).resolve().parent
CACHE = ROOT.parent/'data/comparison_cache'
VERSION = 2
LOCK = threading.Lock()
HAND_EDGES = [(0,1),(1,2),(2,3),(3,4),(0,5),(5,6),(6,7),(7,8),(5,9),(9,10),(10,11),(11,12),(9,13),(13,14),(14,15),(15,16),(13,17),(0,17),(17,18),(18,19),(19,20)]


@lru_cache(maxsize=1)
def extractor_hash():
    return hashlib.sha256(b''.join((ROOT/name).read_bytes() for name in ('body_features.py','hand_tracking.py'))).hexdigest()


def pack_frames(frames):
    hands = np.zeros((len(frames),2,21,3),np.float32)
    pose = np.zeros((len(frames),33,3),np.float32)
    for i,f in enumerate(frames):
        for side,hand in enumerate(f.hands):
            if hand is not None: hands[i,side] = hand
        if f.pose is not None: pose[i] = f.pose
    return hands,pose,np.array([f.timestamp_ms for f in frames],np.float32)


@lru_cache(maxsize=256)
def source_hash(path, size, modified):
    digest = hashlib.sha256()
    with open(path,'rb') as stream:
        for block in iter(lambda:stream.read(1024*1024),b''):digest.update(block)
    return digest.hexdigest()


def reference_data(code, subject):
    if not code.isdigit() or len(code)!=4 or subject not in ('REAL01','REAL02','REAL03'):
        raise ValueError('Invalid reference identity')
    name = code if subject=='REAL01' else code+'_'+subject
    source = ROOT/'assets/videos'/(name+'.mp4')
    stat = source.stat();digest=source_hash(str(source),stat.st_size,stat.st_mtime_ns)
    cache = CACHE/(name+'.npz')
    with LOCK:
        if cache.is_file():
            with np.load(cache,allow_pickle=False) as saved:
                if int(saved['version'])==VERSION and str(saved['source_sha256'])==digest and 'extractor_sha256' in saved and str(saved['extractor_sha256'])==extractor_hash():
                    return saved['hands'].copy(),saved['pose'].copy(),saved['timestamps'].copy(),float(saved['aspect'])
        import cv2
        from .body_features import Extractor
        cap=cv2.VideoCapture(str(source))
        count=int(cap.get(cv2.CAP_PROP_FRAME_COUNT));fps=cap.get(cv2.CAP_PROP_FPS)
        if not cap.isOpened() or not 16<=count<=2400 or not 1<=fps<=120:
            cap.release();raise ValueError('Reference video metadata unavailable')
        selected=set(np.linspace(0,count-1,min(48,count)).round().astype(int))
        hands=[];poses=[];timestamps=[];aspect=None
        try:
            with Extractor() as extractor:
                for index in range(count):
                    if not cap.grab():raise ValueError('Incomplete reference video')
                    ok,image=cap.retrieve()
                    if not ok:raise ValueError('Reference decoding failed')
                    aspect=image.shape[1]/image.shape[0];extractor.process(image)
                    if index not in selected:continue
                    hands.append(extractor.last_hands.copy())
                    poses.append(extractor.last_pose.copy() if extractor.last_pose is not None else np.zeros((33,3),np.float32))
                    timestamps.append(index*1000/fps)
        finally:cap.release()
        h,p,t=np.asarray(hands,np.float32),np.asarray(poses,np.float32),np.asarray(timestamps,np.float32)
        CACHE.mkdir(parents=True,exist_ok=True)
        temporary=cache.with_suffix('.'+str(os.getpid())+'.tmp')
        try:
            with temporary.open('wb') as stream:np.savez_compressed(stream,hands=h,pose=p,timestamps=t,aspect=aspect,version=VERSION,source_sha256=digest,extractor_sha256=extractor_hash())
            temporary.replace(cache)
        finally:temporary.unlink(missing_ok=True)
        return h,p,t,aspect


def mirrored(hands,pose):
    h=hands[:,::-1].copy();p=pose.copy()
    for hand in h.reshape(-1,21,3):
        if np.any(hand):hand[:,0]=1-hand[:,0]
    p[:,:,0]=1-p[:,:,0]
    for a,b in [(1,4),(2,5),(3,6),(7,8),(9,10),(11,12),(13,14),(15,16),(17,18),(19,20),(21,22),(23,24),(25,26),(27,28),(29,30),(31,32)]:
        p[:,[a,b]]=p[:,[b,a]]
    return h,p


def active_indices(rows):
    active=np.flatnonzero(np.any(np.isfinite(rows[:,:,1])&(rows[:,:,1]<.9),axis=1))
    return np.arange(max(0,active[0]-2),min(len(rows),active[-1]+3)) if len(active) else np.arange(len(rows))


def normalized(hands,pose,aspect):
    if min(pose[11,2],pose[12,2])<.7:return None
    xy=pose[:,:2]*[aspect,1];center=(xy[11]+xy[12])/2;scale=np.linalg.norm(xy[11]-xy[12])
    if scale<.06:return None
    body=(xy-center)/scale
    hand=[]
    for h in hands:
        hand.append((h[:,:2]*[aspect,1]-center)/scale if np.any(h) else None)
    return body,pose[:,2],hand


def render_svg(reference,actual,phase,highlight,label):
    chunks=['<svg xmlns="http://www.w3.org/2000/svg" width="900" height="510" viewBox="0 0 900 510" role="img">',
        '<rect width="900" height="510" rx="18" fill="#f6faf8"/>',
        '<style>text{font-family:Arial,sans-serif;fill:#233d32;font-size:15px}.small{font-size:12px;fill:#526b60}</style>']
    chunks.append(f'<text x="450" y="28" text-anchor="middle">{escape(label)} · {escape(phase)}</text>')
    chunks.append('<line x1="450" y1="43" x2="450" y2="475" stroke="#d6e3dc"/>')
    def line(a,b,width,color):
        chunks.append(f'<line x1="{a[0]:.2f}" y1="{a[1]:.2f}" x2="{b[0]:.2f}" y2="{b[1]:.2f}" stroke="{color}" stroke-width="{width}" stroke-linecap="round"/>')
    def circle(point,r,color,stroke=None):
        chunks.append(f'<circle cx="{point[0]:.2f}" cy="{point[1]:.2f}" r="{r}" fill="{color}"'+(f' stroke="{stroke}" stroke-width="3"' if stroke else '')+'/>')
    points=[]
    for data in (reference,actual):
        if data is not None:
            body,visibility,hands=data
            points.extend(body[[i for i in (0,11,12,13,14,15,16) if visibility[i]>=.7]])
            for hand in hands:
                if hand is not None:points.extend(hand)
    extent=np.max(np.abs(points),axis=0) if len(points) else np.array([2,2])
    scale=min(90,190/max(float(extent[0]),1),140/max(float(extent[1]),1))
    for column,(data,title,color) in enumerate([(reference,'모범 동작','#4f9c78'),(actual,'내 동작','#568fc2')]):
        offset=column*450;chunks.append(f'<text x="{offset+225}" y="58" text-anchor="middle">{title}</text>')
        if data is None:
            chunks.append(f'<text x="{offset+225}" y="190" text-anchor="middle" class="small">어깨 위치를 확인하지 못했어요</text>');continue
        body,visibility,hands=data
        def project(v):return np.array([offset+225,170])+v*scale
        left,right=project(body[11]),project(body[12])
        center=(left+right)/2
        chunks.append(f'<path d="M {left[0]:.2f} {left[1]:.2f} Q {center[0]:.2f} {center[1]-10:.2f} {right[0]:.2f} {right[1]:.2f} L {right[0]+8:.2f} 300 L {left[0]-8:.2f} 300 Z" fill="{color}" opacity=".30"/>')
        head=project(body[0]) if visibility[0]>=.7 else center+[0,-65]
        line(head+[0,16],center+[0,-4],13,'#c7cec9')
        circle(head,24,'#c7cec9');line(left,right,14,color)
        for side,(shoulder,elbow,wrist) in enumerate([(11,13,15),(12,14,16)]):
            if min(visibility[shoulder],visibility[elbow])>=.7:line(project(body[shoulder]),project(body[elbow]),17,'#bbc6c0')
            if min(visibility[elbow],visibility[wrist])>=.7:line(project(body[elbow]),project(body[wrist]),13,'#cbd4ce')
        for slot,hand in enumerate(hands):
            if hand is None:continue
            palm=np.array([project(v) for v in hand[[0,5,9,13,17]]])
            chunks.append('<polygon points="'+' '.join(f'{x:.2f},{y:.2f}' for x,y in palm)+'" fill="#c4b097"/>')
            selected=highlight['fingers'][column].get(slot,set())
            for a,b in HAND_EDGES:line(project(hand[a]),project(hand[b]),3.8,'#d79a30' if a in selected and b in selected else '#c4b097')
        for side,point in highlight['wrists'][column]:circle(project(point),13,'none','#d79a30')
        chunks.append(f'<text x="{offset+225}" y="355" text-anchor="middle" class="small">손 모양 확대 · 같은 화면 방향</text>')
        for slot,hand in enumerate(hands):
            cx=offset+115+slot*220
            if hand is None:
                chunks.append(f'<text x="{cx}" y="420" text-anchor="middle" class="small">검출되지 않음</text>');continue
            low=hand.min(0);high=hand.max(0);middle=(low+high)/2;size=max(float(np.max(high-low)),.05)
            points=(hand-middle)/size*90+[cx,418]
            palm=points[[0,5,9,13,17]]
            chunks.append('<polygon points="'+' '.join(f'{x:.2f},{y:.2f}' for x,y in palm)+'" fill="#d5c5b1"/>')
            selected=highlight['fingers'][column].get(slot,set())
            for a,b in HAND_EDGES:line(points[a],points[b],6.5,'#d79a30' if a in selected and b in selected else '#c4b097')
    chunks.append('<text x="450" y="493" text-anchor="middle" class="small">측정 좌표로 그린 아바타예요. 노란 표시는 관측된 차이이며 오답 판정이 아니에요.</text></svg>')
    return 'data:image/svg+xml;base64,'+base64.b64encode(''.join(chunks).encode('utf-8')).decode('ascii')


def build_comparison(frames,aspect,word_id,label,feedback):
    chosen=feedback.get('reference') or {};subject=chosen.get('subject','REAL01');flip=chosen.get('mirrored',False)
    rh,rp,rt,ra=reference_data(word_id[4:],subject)
    if flip:rh,rp=mirrored(rh,rp)
    ah,ap,at=pack_frames(frames)
    rg=np.array([geometry(h,p,ra) for h,p in zip(rh,rp)])
    ag=np.array([geometry(h,p,aspect) for h,p in zip(ah,ap)])
    ri,ai=active_indices(rg),active_indices(ag)
    pairs,cost=alignment(rg[ri],ag[ai])
    useful=[(int(ri[i]),int(ai[j])) for i,j in pairs if np.any(np.isfinite(rg[ri[i],:,:2]).all(1)&np.isfinite(ag[ai[j],:,:2]).all(1))]
    reference_review=bool(chosen.get('tracking_review',False))
    reliable=len(useful)>=8 and np.isfinite(cost) and cost<=.85 and not reference_review
    if not reliable:
        useful=[(int(ri[i]),int(ai[j])) for i,j in zip(np.linspace(0,len(ri)-1,12).round().astype(int),np.linspace(0,len(ai)-1,12).round().astype(int))]
    images=[]
    corrections=feedback.get('observations',{}).get('corrections',[])
    expected_geometry=exclude_resting_geometry(rg)
    stable=bool(corrections)
    for fraction,phase in [(.2,'초반'),(.5,'중간'),(.8,'후반')]:
        i,j=useful[round((len(useful)-1)*fraction)]
        ref=normalized(rh[i],rp[i],ra);actual=normalized(ah[j],ap[j],aspect)
        highlights={'wrists':[[],[]],'fingers':[{},{}]}
        expected=np.isfinite(expected_geometry[i,:,:2]).all(1)
        seen=np.isfinite(ag[j,:,:2]).all(1)
        comparable=bool(reliable and ref is not None and actual is not None and expected.any() and seen[expected].all())
        notes=[];marked_wrists=set()
        if comparable and stable:
            for correction in corrections:
                text=correction.get('text','')
                side=0 if text.startswith('왼손') else 1 if text.startswith('오른손') else None
                if side is None:continue
                name=('왼손','오른손')[side];measure=correction.get('measure')
                if measure in ('어깨 너비에 대한 손 높이 차이','어깨 너비에 대한 손의 몸 중심 거리 차이'):
                    if not np.isfinite(rg[i,side,:2]).all() or not np.isfinite(ag[j,side,:2]).all():continue
                    if np.linalg.norm(rg[i,side,:2]-ag[j,side,:2])<=.25:continue
                    if measure=='어깨 너비에 대한 손 높이 차이':
                        delta=float(ag[j,side,1]-rg[i,side,1])
                        if abs(delta)<=.22:continue
                        note=f'{name}이 모범 동작보다 {"낮게" if delta>0 else "높게"} 보여요. 노란 표시를 보며 손을 조금 {"올려" if delta>0 else "내려"} 주세요.'
                    else:
                        if rg[i,side,0]*ag[j,side,0]<=0 or abs(rg[i,side,0])<=.05:continue
                        delta=float(abs(ag[j,side,0])-abs(rg[i,side,0]))
                        if abs(delta)<=.22:continue
                        note=f'{name}이 모범 동작보다 몸 {"바깥쪽" if delta>0 else "안쪽"}에 있어요. 손을 조금 {"몸 쪽으로 모아" if delta>0 else "몸 바깥쪽으로 옮겨"} 주세요.'
                    if side not in marked_wrists:
                        highlights['wrists'][0].append((side,rg[i,side,:2]));highlights['wrists'][1].append((side,ag[j,side,:2]));marked_wrists.add(side)
                    notes.append(note)
                    continue
                if measure!='손가락 관절 각도 차이(도)':continue
                for column,(finger,ids) in enumerate([('검지',(5,6,7,8)),('중지',(9,10,11,12)),('약지',(13,14,15,16)),('새끼손가락',(17,18,19,20))],2):
                    if finger not in text or not np.isfinite([rg[i,side,column],ag[j,side,column]]).all():continue
                    delta=float(ag[j,side,column]-rg[i,side,column])
                    if abs(delta)<25:continue
                    slots=[]
                    for panel,data in enumerate([ref,actual]):
                        body,visibility,hands=data
                        if visibility[15+side]<.7:continue
                        distances=[np.linalg.norm(h[0]-body[15+side]) if h is not None else np.inf for h in hands]
                        slot=int(np.argmin(distances))
                        if distances[slot]<.35 and abs(distances[0]-distances[1])>=.15:
                            slots.append((panel,slot))
                    if len(slots)==2:
                        for panel,slot in slots:highlights['fingers'][panel].setdefault(slot,set()).update(ids)
                        particle='이' if finger=='새끼손가락' else '가'
                        notes.append(f'{name} {finger}{particle} 모범 동작보다 {"굽혀져" if delta<0 else "펴져"} 보여요. 노란 표시를 보며 손가락을 조금 더 {"펴" if delta<0 else "굽혀"} 주세요.')
        notes=list(dict.fromkeys(notes))
        status='highlighted' if notes else 'no_major_difference' if comparable else 'unavailable'
        images.append(dict(phase=phase,reference_timestamp_ms=round(float(rt[i])),user_timestamp_ms=round(float(at[j])),
            highlight_notes=notes,comparison_status=status,
            image=render_svg(ref,actual,phase,highlights,label)))
    return dict(available=True,kind='coordinate_avatar_v1',reference_subject=subject,mirrored_reference=bool(flip),
        alignment='dtw' if reliable else 'relative_time',frames=images,
        notice=('모범 영상의 손을 충분히 확인하지 못한 구간이 있어 비슷한 진행 시점을 보여드려요. 세부 차이 표시는 생략했어요.' if reference_review else
            '비교 가능한 동작 구간을 맞췄어요. 관측된 차이는 참고해 주세요.' if reliable else '동작 구간을 정확히 맞추기 어려워 비슷한 진행 시점을 보여드려요. 차이 표시는 생략했어요.'))
