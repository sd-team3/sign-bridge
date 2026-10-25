"""Conservative, body-relative reference comparison; no word-specific guesses."""
import numpy as np

FINGERS = [('검지', (5, 6, 7, 8)), ('중지', (9, 10, 11, 12)),
           ('약지', (13, 14, 15, 16)), ('새끼손가락', (17, 18, 19, 20))]


def geometry(hands, pose, aspect):
    # Anatomical sides come from Pose wrists, not Hands' selfie handedness.
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
        # Close/crossed wrists and unreliable pose wrists are left unassigned.
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
    # Remove standing/resting lead-in and tail when hands hang below the torso.
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
    """Ignore only low, stationary hands while the other hand is raised."""
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


def compare(reference, actual, ignore_resting=False):
    result = {'corrections': [], 'basis': '모범 영상과 어깨 너비 기준 손 위치·손가락 관절 각도 비교'}
    if len(reference)<12 or len(actual)<12:
        result['summary']='비교할 동작 프레임이 부족합니다. 전체 동작을 녹화해 주세요.'
        return result
    if ignore_resting:
        reference, actual = exclude_resting_geometry(reference), exclude_resting_geometry(actual)
    reference, actual = trim(reference), trim(actual)
    pairs, cost = alignment(reference, actual)
    result['alignment_cost'] = cost if np.isfinite(cost) else None
    if not pairs or cost > .85:
        result['summary']='동작 시점이나 손 위치를 안정적으로 맞추지 못해 자세 교정을 보류했습니다. 모범 동작을 처음부터 끝까지 따라 해 주세요.'
        return result
    # Each actual frame counts once even when DTW repeats it.
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
        for column in (1,2,3,4,5):
            valid = np.isfinite(refs[:,side,column]) & np.isfinite(users[:,side,column])
            if valid.sum()<8 or valid.mean()<.55: continue
            delta = users[valid,side,column]-refs[valid,side,column]
            threshold = .22 if column==1 else 25
            median=float(np.median(delta)); support=float((delta*np.sign(median)>threshold).mean())
            if abs(median)<threshold or support<.65: continue
            if column==1:
                text=f'{name}을 모범 동작보다 조금 더 {"올리세요" if median>0 else "내리세요"}.'
                measure='어깨 너비에 대한 손 높이 차이'
            else:
                finger=FINGERS[column-2][0]
                text=f'{name} {finger}를 모범 동작보다 조금 더 {"펴세요" if median<0 else "굽히세요"}.'
                measure='손가락 관절 각도 차이(도)'
            candidates.append({'text':text,'measure':measure,'difference':round(median,2),
                               'support':round(support,2),'valid_frames':int(valid.sum()),
                               'priority':abs(median)/threshold})
    result['corrections']=sorted(candidates,key=lambda c:c['priority'],reverse=True)[:3]
    result['summary']=' '.join(c['text'] for c in result['corrections'])
    if not result['summary']:
        coverage=(np.isfinite(users[:,:,1]).any(axis=1).mean() if ignore_resting
                  else np.isfinite(users[:,:,1]).mean())
        result['summary']=('손 가림이나 좌우 구분 불확실로 교정 근거가 부족합니다. 손이 보이도록 다시 녹화해 주세요.'
                           if coverage<.55 else '비교 가능한 구간에서 일관된 손 높이·손가락 각도 차이를 찾지 못했습니다. 다른 자세 요소의 정확성을 뜻하지는 않습니다.')
    return result
