from datetime import datetime, timezone
import json
import os
from pathlib import Path
import re
import numpy as np
from .comparison_avatar import pack_frames

ROOT = Path(__file__).resolve().parent.parent/'data/practice_diagnostics'


def save_diagnostics(frames,aspect,result,corrected_frames=None):
    if os.environ.get('SIGN_SAVE_PRACTICE_COORDS','true').lower() in ('0','false','off'):
        return False
    attempt=result.get('attempt_id','')
    if not re.fullmatch(r'[A-Za-z0-9_-]{1,80}',attempt):return False
    date=datetime.now(timezone.utc)
    folder=ROOT/date.strftime('%Y-%m-%d');folder.mkdir(parents=True,exist_ok=True)
    stem=date.strftime('%H%M%S_%f')+'_'+attempt
    h,p,t=pack_frames(frames)
    extra={}
    if corrected_frames is not None:extra['corrected_hands']=pack_frames(corrected_frames)[0]
    numeric=folder/(stem+'.npz');temporary=numeric.with_suffix('.npz.partial')
    try:
        with temporary.open('xb') as stream:
            np.savez_compressed(stream,hands=h,pose=p,timestamps_ms=t,aspect=aspect,schema='raw_mp_legacy_v1',**extra)
        temporary.rename(numeric)
    finally:temporary.unlink(missing_ok=True)
    record=dict(recorded_at=date.isoformat(),attempt_id=attempt,target_word_id=result.get('target_word_id'),
        model_id=result.get('model_id'),quality=result.get('quality'),recognition=result.get('recognition'),
        feedback_reason=(result.get('feedback') or {}).get('reason'),status=result.get('status'),
        coordinates=numeric.name,verified_label=None,annotation_status='unreviewed',
        preprocessing=result.get('preprocessing'),
        comparison_alignment=((result.get('feedback') or {}).get('comparison') or {}).get('alignment'))
    (folder/(stem+'.json')).write_text(json.dumps(record,ensure_ascii=False,indent=2,allow_nan=False),encoding='utf-8')
    return True
