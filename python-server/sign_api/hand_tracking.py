from itertools import permutations
import numpy as np

VERSION = 'hands_tracking_v2'


def candidates(result):
    points = result.multi_hand_landmarks or []
    labels = result.multi_handedness or []
    output = []
    for index, landmark in enumerate(points):
        hand = np.asarray([[p.x, p.y, p.z] for p in landmark.landmark], np.float32)
        if hand.shape != (21, 3) or not np.isfinite(hand).all():
            raise ValueError('Invalid detector landmarks')
        label, confidence = None, .5
        if index < len(labels) and labels[index].classification:
            item = labels[index].classification[0]
            label, confidence = item.label, float(item.score)
        output.append((hand, label, confidence))
    distinct = []
    for item in sorted(output, key=lambda x: -x[2]):
        h = item[0]
        duplicate = False
        for other, _, _ in distinct:
            palm = max(np.linalg.norm(h[9,:2]-h[0,:2]), np.linalg.norm(other[9,:2]-other[0,:2]))
            if np.linalg.norm(h[0,:2]-other[0,:2]) < palm*.35 and np.linalg.norm(h[:,:2]-other[:,:2],axis=1).mean() < palm*.5:
                duplicate = True
        if not duplicate:distinct.append(item)
    return distinct


class HandTracker:
    def __init__(self):
        self.reset()

    def reset(self):
        self.previous = np.zeros((2, 21, 3), np.float32)
        self.age = np.full(2, 100, int)

    def assign(self, detected, pose, aspect):
        hands = np.zeros((2, 21, 3), np.float32)
        cost = np.zeros((len(detected), 2), np.float64)
        scale = None
        if pose is not None and min(pose[11, 2], pose[12, 2]) >= .7:
            scale = np.linalg.norm((pose[11, :2]-pose[12, :2])*[aspect, 1])
        for index, (hand, label, confidence) in enumerate(detected):
            for slot in (0, 1):
                if label in ('Left', 'Right'):
                    cost[index, slot] += .3*confidence*(slot != (0 if label == 'Left' else 1))
                # Preserve the existing unmirrored MediaPipe slot convention.
                pose_id = (16, 15)[slot]
                if scale is not None and scale > .06 and pose[pose_id, 2] >= .7:
                    distance = np.linalg.norm((hand[0, :2]-pose[pose_id, :2])*[aspect, 1])/scale
                    cost[index, slot] += min(distance, 2.)
                if self.age[slot] <= 2:
                    distance = np.linalg.norm((hand[0, :2]-self.previous[slot, 0, :2])*[aspect, 1])
                    cost[index, slot] += .2*min(distance/.2, 2.)
        if detected:
            count = min(2, len(detected))
            choices = [(items, slots) for items in permutations(range(len(detected)),count) for slots in permutations(range(2),count)]
            items, slots = min(choices, key=lambda choice: sum(cost[i,s] for i,s in zip(*choice)))
            for i, slot in zip(items, slots):
                hands[slot] = detected[i][0]
        self.age += 1
        for slot in (0, 1):
            if np.any(hands[slot]):
                self.previous[slot] = hands[slot]
                self.age[slot] = 0
        return hands


def recover_candidates(detected, recovered, pose, aspect):
    if len(detected) >= 2 or pose is None or min(pose[11, 2], pose[12, 2]) < .7:
        return detected, 0
    scale = np.linalg.norm((pose[11, :2]-pose[12, :2])*[aspect, 1])
    if scale < .06:
        return detected, 0
    merged = list(detected)
    for candidate in recovered:
        hand = candidate[0]
        distances = [np.linalg.norm((hand[0, :2]-pose[p, :2])*[aspect, 1])/scale
                     if pose[p, 2] >= .7 else np.inf for p in (15, 16)]
        side = int(np.argmin(distances))
        if distances[side] > .35 or abs(distances[0]-distances[1]) < .15:
            continue
        duplicate = False
        for other, _, _ in merged:
            distance = np.linalg.norm((hand[0, :2]-other[0, :2])*[aspect, 1])
            palm = max(np.linalg.norm((hand[9, :2]-hand[0, :2])*[aspect, 1]),
                       np.linalg.norm((other[9, :2]-other[0, :2])*[aspect, 1]))
            if distance < max(.025, palm*.65):
                duplicate = True
        if not duplicate and len(merged) < 2:
            merged.append(candidate)
    return merged, len(merged)-len(detected)


def expected_missing(hands, pose, aspect):
    if pose is None or min(pose[11, 2], pose[12, 2]) < .7:
        return False
    scale = np.linalg.norm((pose[11, :2]-pose[12, :2])*[aspect, 1])
    if scale < .06:
        return False
    center = (pose[11, :2]+pose[12, :2])/2
    for slot, p in enumerate((16, 15)):
        if not np.any(hands[slot]) and pose[p, 2] >= .7 and 0 < pose[p, 0] < 1 and 0 < pose[p, 1] < 1:
            if (pose[p, 1]-center[1])/scale < .9:
                return True
    return False
