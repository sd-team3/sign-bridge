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
    if (result.get('reference') or {}).get('tracking_review'):
        result['reference_notes'].append('모범 영상의 손을 충분히 확인하지 못한 구간이 있어 세부 자세 비교는 생략했어요.')
    if accepted and predicted == target:
        corrections = result.get('observations', {}).get('corrections', [])
        actions = [correction['text'] for correction in corrections[:2]]
        message = f'‘{target}’ 동작으로 인식됐어요.'
        if actions:
            message += ' 모범 동작에 더 가깝게 연습하려면 아래 부분을 맞춰 보세요.'
        elif not result['similarity'].get('available') and not (result.get('reference') or {}).get('tracking_review'):
            result['reference_notes'].append('동작에 사용하는 손과 손가락이 보이도록 다시 촬영하면 자세를 비교할 수 있어요.')
        result.update(status='recognized', feedback_required=False, reason='recognized_variation',
                      message=message, actions=actions)
    elif accepted:
        result.update(status='advice', feedback_required=True, reason='target_mismatch',
            message=f'이번에는 ‘{predicted}’ 동작으로 인식됐어요. 목표 단어 ‘{target}’의 손 모양과 움직임 순서를 다시 확인해 볼까요?',
            actions=['모범 영상을 천천히 보고, 목표 단어의 동작을 처음부터 끝까지 다시 보여 주세요.'])
    else:
        result.update(status='advice', feedback_required=True, reason='uncertain_recognition',
            message='어떤 단어인지 아직 또렷하게 구별하지 못했어요. 틀렸다고 단정하지 않고 한 번 더 확인할게요.',
            actions=['동작에 사용하는 손이 잘 보이도록, 처음부터 끝까지 끊지 않고 다시 보여 주세요.'])
    return result
