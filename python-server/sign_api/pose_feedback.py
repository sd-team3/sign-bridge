import numpy as np

FINGERS = [('검지', (5, 6, 7, 8)), ('중지', (9, 10, 11, 12)),
           ('약지', (13, 14, 15, 16)), ('새끼손가락', (17, 18, 19, 20))]

def geometry(hands, pose, aspect):

    row = np.full((2, 6), np.nan, dtype=np.float32)
    if pose is None or min(pose[11, 2], pose[12, 2]) < .7:
        return row
    xy = pose[:, :2] * [aspect, 1]
    center = (xy[11] + xy[12]) / 2
    width = np.linalg.norm(xy[11] - xy[12])
    if width < .06:
        return row
    candidates = [h for h in hands if np.any(h)]
    assigned = {}
    for hand in candidates:
        wrist = hand[0, :2] * [aspect, 1]
        distances = [np.linalg.norm(wrist - xy[p]) / width
                     if pose[p, 2] >= .7 else np.inf for p in (15, 16)]
        side = int(np.argmin(distances))

        if distances[side] > .35 or abs(distances[0] - distances[1]) < .15:
            continue
        if side in assigned:
            assigned[side] = None
        else:
            assigned[side] = hand
    for side, hand in assigned.items():
        if hand is None:
            continue
        row[side, :2] = (hand[0, :2] * [aspect, 1] - center) / width
        points = hand * [aspect, 1, aspect]
        for f, (_, ids) in enumerate(FINGERS):
            angles = []
            for a, b, c in (ids[:3], ids[1:]):
                u, v = points[a] - points[b], points[c] - points[b]
                den = np.linalg.norm(u) * np.linalg.norm(v)
                if den < 1e-6:
                    break
                angles.append(np.degrees(np.arccos(np.clip(np.dot(u, v) / den, -1, 1))))
            if len(angles) == 2:
                row[side, 2 + f] = min(angles)
    return row

def extract_geometry(images):
    from .body_features import Extractor
    rows = []
    if not images:
        return np.empty((0, 2, 6), np.float32)
    indices = np.linspace(0, len(images) - 1, min(80, len(images))).round().astype(int)
    with Extractor() as extractor:
        for i in indices:
            image = images[i]
            extractor.process(image)
            rows.append(geometry(extractor.last_hands, extractor.last_pose,
                                 image.shape[1] / image.shape[0]))
    return np.asarray(rows)

def trim(rows):

    active = np.flatnonzero(np.any(np.isfinite(rows[:, :, 1]) & (rows[:, :, 1] < .9), axis=1))
    return rows[max(0, active[0]-2):active[-1]+3] if len(active) else rows

def alignment(reference, actual):
    n, m = len(reference), len(actual)
    costs = np.full((n+1, m+1), np.inf); costs[0, 0] = 0
    parents = {}
    for i in range(1, n+1):
        for j in range(1, m+1):
            if abs((i-1)/max(1,n-1) - (j-1)/max(1,m-1)) > .25:
                continue
            a, b = reference[i-1], actual[j-1]
            valid = np.isfinite(a[:, :2]).all(1) & np.isfinite(b[:, :2]).all(1)
            if valid.any():
                cost = float(np.linalg.norm(a[valid, :2]-b[valid, :2], axis=1).mean())
                mask = np.isfinite(a[:, 2:]) & np.isfinite(b[:, 2:])
                if mask.any(): cost += float(np.abs(a[:, 2:][mask]-b[:, 2:][mask]).mean()) / 180
            else:
                cost = 2.
            options = [(costs[i-1,j-1], (i-1,j-1)),
                       (costs[i-1,j]+.08, (i-1,j)), (costs[i,j-1]+.08, (i,j-1))]
            previous, parent = min(options, key=lambda x: x[0])
            costs[i,j] = previous + cost; parents[i,j] = parent
    if not np.isfinite(costs[n,m]): return [], float('inf')
    pairs=[]; i,j=n,m
    while i and j:
        pairs.append((i-1,j-1)); i,j=parents[i,j]
    return pairs[::-1], float(costs[n,m]/max(1,len(pairs)))

def exclude_resting_geometry(rows):

    rows = rows.copy()
    for side in (0, 1):
        valid = np.isfinite(rows[:, side]).all(axis=1)
        other = rows[:, 1-side, 1]
        if valid.sum() < max(8, len(rows)*.35): continue
        values = rows[valid, side]
        span = np.linalg.norm(np.quantile(values[:, :2], .95, axis=0)-np.quantile(values[:, :2], .05, axis=0))
        angle_change = np.quantile(np.abs(values[:, 2:]-np.median(values[:, 2:], axis=0)), .9)
        if np.mean(values[:, 1] > 1.1) >= .9 and span < .3 and angle_change < 15 and np.mean(other < .9) >= .3:
            rows[:, side] = np.nan
    return rows

def compare(reference, actual, ignore_resting=False, similarity_threshold=70.0):
    if not np.isfinite(similarity_threshold) or not 0 <= similarity_threshold <= 100:
        raise ValueError('Similarity threshold must be between 0 and 100')
    result = {'corrections': [], 'basis': '모범 영상과 어깨 너비 기준 손 위치·손가락 관절 각도 비교',
              'similarity_score': None, 'similarity_threshold': float(similarity_threshold),
              'similarity_available': False, 'feedback_required': True,
              'reason': 'insufficient_comparison', 'comparison_coverage': 0.0}
    if len(reference)<12 or len(actual)<12:
        result['summary']='동작을 비교하기에는 촬영 구간이 짧아요. 준비 자세에서 시작해 동작이 끝날 때까지 2~10초 정도 다시 촬영해 주세요.'
        return result
    if ignore_resting:
        reference, actual = exclude_resting_geometry(reference), exclude_resting_geometry(actual)
    reference, actual = trim(reference), trim(actual)
    pairs, cost = alignment(reference, actual)
    result['alignment_cost'] = cost if np.isfinite(cost) else None
    if pairs:
        expected = np.array([np.isfinite(reference[i,:,:2]).all(axis=1) for i,j in pairs])
        seen = np.array([np.isfinite(actual[j,:,:2]).all(axis=1) for i,j in pairs])
        count = int((expected & seen).sum())
        coverage = float(count/max(1,int(expected.sum())))
        result['comparison_coverage'] = round(coverage,3)
        if coverage >= .55 and count >= 8 and np.isfinite(cost):
            result['similarity_available'] = True
            result['similarity_score'] = round(float(100*np.exp(-max(0,cost))),1)
    if not result['similarity_available']:
        result['reason']='insufficient_tracking'
        result['summary']='동작에 사용하는 손의 위치를 충분히 확인하지 못했어요. 양쪽 어깨와 움직이는 손이 화면 안에 보이도록 다시 촬영해 주세요. 쉬는 손은 내려놓아도 괜찮아요.'
        return result
    if not pairs or cost > .85:
        result['reason']='low_similarity' if result['similarity_score'] <= similarity_threshold else 'alignment_difference'
        result['summary']='모범 동작과 손의 위치·움직임 차이가 커서 세부 교정 위치를 짚기 어려워요. 모범 영상을 느리게 재생하고, 손의 시작 위치와 이동 경로를 살펴본 뒤 처음부터 끝까지 다시 따라 해 주세요.'
        return result

    grouped = {}
    for i,j in pairs: grouped.setdefault(j,[]).append(reference[i])
    refs=[]; users=[]
    import warnings
    with warnings.catch_warnings():
        warnings.simplefilter('ignore', RuntimeWarning)
        for j, rows in grouped.items():
            refs.append(np.nanmedian(rows,axis=0)); users.append(actual[j])
    refs, users = np.asarray(refs), np.asarray(users)
    candidates=[]
    for side, name in enumerate(('왼손','오른손')):
        for column in (0,1,2,3,4,5):
            valid = np.isfinite(refs[:,side,column]) & np.isfinite(users[:,side,column])
            if valid.sum()<8 or valid.mean()<.55: continue
            if column==0:
                stable=(users[valid,side,0]*refs[valid,side,0]>0)&(np.abs(refs[valid,side,0])>.05)
                if stable.sum()<8 or stable.mean()<.65: continue
                delta=np.abs(users[valid,side,0][stable])-np.abs(refs[valid,side,0][stable])
            else:
                delta = users[valid,side,column]-refs[valid,side,column]
            threshold = .22 if column in (0,1) else 25
            median=float(np.median(delta)); support=float((delta*np.sign(median)>threshold).mean())
            if abs(median)<threshold or support<.65: continue
            if column==0:
                text=f'{name}이 모범 동작보다 몸 {"바깥쪽" if median>0 else "안쪽"}에 있어요. 손을 조금 {"몸 쪽으로 모아" if median>0 else "몸 바깥쪽으로 옮겨"} 주세요.'
                measure='어깨 너비에 대한 손의 몸 중심 거리 차이'
            elif column==1:
                text=f'{name}의 위치가 모범 동작보다 {"낮게" if median>0 else "높게"} 보여요. 모범 영상과 비교하며 손을 조금 {"올려" if median>0 else "내려"} 주세요.'
                measure='어깨 너비에 대한 손 높이 차이'
            else:
                finger=FINGERS[column-2][0]
                text=f'{name} {finger}가 모범 동작보다 {"굽혀져" if median<0 else "펴져"} 보여요. 손가락을 조금 더 {"펴서" if median<0 else "굽혀서"} 따라 해 주세요.'
                measure='손가락 관절 각도 차이(도)'
            candidates.append({'text':text,'measure':measure,'difference':round(median,2),
                               'support':round(support,2),'valid_frames':int(valid.sum()),
                               'priority':abs(median)/threshold})
    result['corrections']=sorted(candidates,key=lambda c:c['priority'],reverse=True)[:3]
    result['summary']=' '.join(c['text'] for c in result['corrections'])
    low = result['similarity_score'] <= similarity_threshold
    result['reason']='low_similarity' if low else 'correction' if result['corrections'] else 'no_clear_difference'
    result['feedback_required']=bool(low or result['corrections'])
    if not result['summary']:
        result['summary']=('모범 동작과 아직 차이가 있어요. 영상을 느리게 재생하면서 손의 시작 위치, 이동 경로, 끝나는 위치를 순서대로 확인하고 다시 따라 해 주세요.'
                           if low else '이번 영상에서는 손 높이와 손가락 모양의 뚜렷한 차이가 보이지 않았어요. 모범 영상과 손의 이동 경로도 함께 확인해 주세요.')
    return result
