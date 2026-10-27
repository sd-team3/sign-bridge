import numpy as np
from .pose_feedback import compare


def mirrored(rows):
    result=rows[:,::-1].copy()
    result[:,:,0]*=-1
    return result


def choose(references,actual,ignore_resting,threshold):
    if not isinstance(references,list): return references,None
    best=None; best_cost=float('inf'); fallback=None
    sample=actual[np.linspace(0,len(actual)-1,min(48,len(actual))).round().astype(int)] if len(actual) else actual
    for entry in references:
        original=entry['geometry']
        if fallback is None: fallback=(original,dict(subject=entry['subject'],video_url=entry['video_url'],mirrored=False))
        for flip in (False,True):
            rows=mirrored(original) if flip else original
            subset=rows[np.linspace(0,len(rows)-1,min(48,len(rows))).round().astype(int)]
            result=compare(subset,sample,ignore_resting=ignore_resting,similarity_threshold=threshold)
            cost=result.get('alignment_cost')
            if result['similarity_available'] and cost is not None and cost<best_cost-1e-6:
                best_cost=cost
                best=(rows,dict(subject=entry['subject'],video_url=entry['video_url'],mirrored=flip))
    return best or fallback or (None,None)
