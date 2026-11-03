from copy import deepcopy
import math


def interpret_feedback(geometry, target, predicted, target_score, recognition=None):
    result = deepcopy(geometry)
    recognition = recognition or {}
    confidence = float(target_score)
    accepted = recognition.get('accepted', math.isfinite(confidence) and confidence >= .7)
    result['policy'] = 'semantic_v1'
    result['similarity']['role'] = 'optional_reference_comparison'
    result['reference_notes'] = []
    measures = {c.get('measure') for c in result.get('observations', {}).get('corrections', [])}
    if '어깨 너비에 대한 손 높이 차이' in measures:
        result['reference_notes'].append('모범 영상과 손의 높이가 다르게 측정됐어요. 이 차이만으로 틀린 동작이라고 판단하지 않아요.')
    if '어깨 너비에 대한 손의 몸 중심 거리 차이' in measures:
        result['reference_notes'].append('모범 영상과 손이 몸에서 떨어진 거리가 다르게 측정됐어요. 편안한 자세와 촬영 위치에 따른 차이일 수 있어요.')
    if '손가락 관절 각도 차이(도)' in measures:
        result['reference_notes'].append('모범 영상과 손가락 각도가 다르게 측정됐어요. 영상 좌표 비교만으로 교정이 필요한지 확정하지 않아요.')
    if accepted and predicted == target:
        result.update(status='recognized', feedback_required=False, reason='recognized_variation',
            message=f'‘{target}’ 동작으로 인식됐어요. 모범 영상과 위치나 동작 크기가 조금 달라도 같은 단어로 인식할 수 있어요.', actions=[])
        if not result['similarity'].get('available'):
            result['reference_notes'].append('단어는 인식됐지만 이번 촬영의 자세 비교는 충분히 확인하지 못했어요.')
    elif accepted:
        result.update(status='advice', feedback_required=True, reason='target_mismatch',
            message=f'이번에는 ‘{predicted}’ 동작으로 인식됐어요. 목표 단어 ‘{target}’의 손 모양과 움직임 순서를 다시 확인해 볼까요?',
            actions=['모범 영상을 천천히 보고, 목표 단어의 동작을 처음부터 끝까지 다시 보여 주세요.'])
    else:
        result.update(status='advice', feedback_required=True, reason='uncertain_recognition',
            message='어떤 단어인지 아직 또렷하게 구별하지 못했어요. 틀렸다고 단정하지 않고 한 번 더 확인할게요.',
            actions=['동작에 사용하는 손이 잘 보이도록, 처음부터 끝까지 끊지 않고 다시 보여 주세요.'])
    return result
