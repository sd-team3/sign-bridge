from .pose_feedback import compare
from .reference_selection import choose


def evaluate_feedback(reference, actual, target, predicted, target_score, ignore_resting=False, threshold=70.0):
    reference,selected=choose(reference,actual,ignore_resting,threshold)
    if reference is None:
        return {'status':'reference_unavailable','feedback_required':True,'reason':'reference_unavailable',
                'message':'이 단어의 모범 동작을 불러오지 못했어요. 잠시 후 다시 시도해 주세요.',
                'actions':['모범 영상이 재생되는지 확인한 뒤 다시 시도해 주세요.'],
                'similarity':{'available':False,'score':None,'threshold':threshold,'below_threshold':None,
                              'method':'dtw_geometry_v1'},'source':'rules'}
    observation=compare(reference,actual,ignore_resting=ignore_resting,similarity_threshold=threshold)
    required=observation['feedback_required']
    reason=observation['reason']; message=observation['summary']
    corrections=observation['corrections']
    actions=[c['text'] for c in corrections]
    if predicted != target:
        required=True
        if reason == 'no_clear_difference':
            message='손의 시작 위치와 이동 순서가 모범 동작과 같은지 확인하고, 처음부터 끝까지 다시 촬영해 주세요.'
        message=f'이번에는 ‘{predicted}’ 동작으로 인식됐어요. 연습 중인 ‘{target}’의 모범 동작을 다시 확인해 주세요. '+message
        if reason == 'no_clear_difference': reason='target_mismatch'
        if not actions: actions=['모범 영상을 느리게 보며 동작의 시작부터 끝까지 다시 따라 해 주세요.']
    elif target_score < .7:
        required=True
        if reason == 'no_clear_difference':
            reason='uncertain_recognition'
            message=f'‘{target}’으로 인식됐지만 결과가 아직 뚜렷하지 않아요. 모범 영상을 느리게 재생한 뒤, 동작을 끊지 않고 처음부터 끝까지 다시 보여 주세요.'
    if required and not actions:
        actions=([observation['summary']] if reason=='insufficient_tracking' else
                 ['모범 영상을 느리게 재생해 손의 시작 위치와 이동 경로를 확인해 주세요.',
                  '동작에 사용하는 손이 보이도록 처음부터 끝까지 다시 촬영해 주세요.'])
    score=observation['similarity_score']
    return {'status':'advice' if required else 'no_reliable_correction', 'reference':selected,
            'feedback_required':bool(required),'reason':reason,'message':message,'actions':actions,
            'similarity':{'available':observation['similarity_available'],'score':score,
                          'threshold':float(threshold),'below_threshold':score <= threshold if score is not None else None,
                          'method':'dtw_geometry_v1'},'observations':observation,'source':'rules'}
