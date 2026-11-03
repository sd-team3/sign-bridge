import base64
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import xml.etree.ElementTree as ET
import numpy as np
from sign_api.api import Frame
from sign_api.comparison_avatar import build_comparison,pack_frames,mirrored
from sign_api.practice_diagnostics import save_diagnostics


def sample():
    pose=np.zeros((30,33,3),np.float32);pose[:,:,2]=1
    for i,xy in {0:[.5,.2],11:[.65,.5],12:[.35,.5],13:[.75,.6],14:[.25,.6],15:[.7,.65],16:[.3,.65]}.items():pose[:,i,:2]=xy
    rng=np.random.default_rng(5);hands=rng.normal(0,.012,(30,2,21,3)).astype(np.float32)
    hands[:,:,:,:2]+=pose[:,[15,16],:2,None].transpose(0,1,3,2)
    hands[:,:,0,:2]=pose[:,[15,16],:2]
    times=np.arange(30,dtype=np.float32)*100
    frames=[Frame(timestamp_ms=float(t),hands=h.tolist(),pose=p.tolist()) for t,h,p in zip(times,hands,pose)]
    return hands,pose,times,frames


class ComparisonTests(unittest.TestCase):
    def test_position_highlight_requires_supported_side_measurement(self):
        h,p,t,f=sample();shifted=h.copy();poses=p.copy();shifted[:,0,:,1]+=.18;poses[:,15,1]+=.18
        actual=[Frame(timestamp_ms=float(tm),hands=hh.tolist(),pose=pp.tolist()) for tm,hh,pp in zip(t,shifted,poses)]
        with patch('sign_api.comparison_avatar.reference_data',return_value=(h,p,t,16/9)):
            plain=build_comparison(actual,16/9,'WORD0115','커피',{'observations':{'corrections':[]}})
            marked=build_comparison(actual,16/9,'WORD0115','커피',{'observations':{'corrections':[{'text':'왼손의 위치 차이','measure':'어깨 너비에 대한 손 높이 차이'}]}})
        self.assertFalse(any(b'#d79a30' in base64.b64decode(frame['image'].split(',')[1]) for frame in plain['frames']))
        self.assertTrue(any(b'#d79a30' in base64.b64decode(frame['image'].split(',')[1]) for frame in marked['frames']))
        for frame in marked['frames']:
            self.assertEqual(frame['comparison_status'],'highlighted')
            self.assertTrue(any('왼손' in note and '낮게' in note for note in frame['highlight_notes']))

    def test_unhighlighted_frames_report_no_major_difference(self):
        h,p,t,f=sample()
        with patch('sign_api.comparison_avatar.reference_data',return_value=(h,p,t,16/9)):
            result=build_comparison(f,16/9,'WORD0115','커피',{})
        for frame in result['frames']:
            self.assertEqual(frame['comparison_status'],'no_major_difference')
            self.assertEqual(frame['highlight_notes'],[])
            self.assertNotIn(b'#d79a30',base64.b64decode(frame['image'].split(',')[1]))

    def test_height_advice_does_not_highlight_only_horizontal_difference(self):
        h,p,t,f=sample();shifted=h.copy();poses=p.copy();shifted[:,0,:,0]+=.2;poses[:,15,0]+=.2
        actual=[Frame(timestamp_ms=float(tm),hands=hh.tolist(),pose=pp.tolist()) for tm,hh,pp in zip(t,shifted,poses)]
        with patch('sign_api.comparison_avatar.reference_data',return_value=(h,p,t,16/9)):
            result=build_comparison(actual,16/9,'WORD0115','커피',{'observations':{'corrections':[{'text':'왼손 높이','measure':'어깨 너비에 대한 손 높이 차이'}]}})
        for frame in result['frames']:
            self.assertEqual(frame['highlight_notes'],[])
            self.assertNotIn(b'#d79a30',base64.b64decode(frame['image'].split(',')[1]))

    def test_hidden_resting_hand_does_not_make_active_hand_comparison_unavailable(self):
        h,p,t,f=sample();p[:,11,0]=.55;p[:,12,0]=.45
        p[:,16,1]=.85;h[:,1,:,1]+=.2;h[:,1]=h[0,1]
        frames=[Frame(timestamp_ms=float(tm),hands=[hh[0].tolist(),None],pose=pp.tolist()) for tm,hh,pp in zip(t,h,p)]
        with patch('sign_api.comparison_avatar.reference_data',return_value=(h,p,t,16/9)):
            result=build_comparison(frames,16/9,'WORD0115','커피',{})
        self.assertTrue(all(frame['comparison_status']=='no_major_difference' for frame in result['frames']))

    def test_finger_description_matches_the_painted_finger(self):
        h,p,t,f=sample()
        h[:,0,5:9]=[[.7,.62,0],[.7,.59,0],[.7,.56,0],[.7,.53,0]]
        actual=h.copy();actual[:,0,7:9]=[[.73,.59,0],[.73,.62,0]]
        frames=[Frame(timestamp_ms=float(tm),hands=hh.tolist(),pose=pp.tolist()) for tm,hh,pp in zip(t,actual,p)]
        with patch('sign_api.comparison_avatar.reference_data',return_value=(h,p,t,16/9)):
            result=build_comparison(frames,16/9,'WORD0115','커피',{'observations':{'corrections':[{'text':'왼손 검지','measure':'손가락 관절 각도 차이(도)'}]}})
        for frame in result['frames']:
            self.assertEqual(frame['comparison_status'],'highlighted')
            self.assertEqual(len(frame['highlight_notes']),1)
            self.assertIn('왼손 검지',frame['highlight_notes'][0])
            self.assertIn('굽혀져',frame['highlight_notes'][0])
            self.assertIn(b'#d79a30',base64.b64decode(frame['image'].split(',')[1]))

    def test_comparison_failure_does_not_erase_recognition(self):
        from test_video_metadata import Capture,Extractor
        from sign_api.video_api import evaluate_file
        from sign_api.api import runtime
        result={'status':'ok','attempt_id':'compare-test','recognition':{'predicted_label':'커피'},'feedback':{'message':'인식됨'}}
        with patch('sign_api.video_api.cv2.VideoCapture',return_value=Capture(30)),patch('sign_api.video_api.Extractor',Extractor),patch('sign_api.video_api.runtime.infer',return_value=result),patch.dict(runtime.words,{'0115':'커피'}),patch('sign_api.comparison_avatar.build_comparison',side_effect=ValueError('missing reference')),patch.dict('os.environ',{'SIGN_SAVE_PRACTICE_COORDS':'false'}):
            response=evaluate_file('unused','WORD0115',False,'compare-test',True)
        self.assertEqual(response['status'],'ok');self.assertEqual(response['recognition']['predicted_label'],'커피');self.assertFalse(response['feedback']['comparison']['available'])

    def test_avatar_has_three_aligned_safe_images(self):
        h,p,t,f=sample()
        with patch('sign_api.comparison_avatar.reference_data',return_value=(h,p,t,16/9)):
            result=build_comparison(f,16/9,'WORD0115','<script>커피</script>',{'reference':{'subject':'REAL01'}})
        self.assertTrue(result['available']);self.assertEqual(result['alignment'],'dtw');self.assertEqual(len(result['frames']),3)
        self.assertLess(len(json.dumps(result)),300000)
        for frame in result['frames']:
            svg=base64.b64decode(frame['image'].split(',')[1]);tree=ET.fromstring(svg)
            self.assertFalse(any(n.tag.endswith('script') for n in tree.iter()))
            self.assertNotIn(b'<script>',svg)

    def test_mirror_round_trip_preserves_missing_hand(self):
        h,p,t,f=sample();h[:,0]=0
        mh,mp=mirrored(h,p);hh,pp=mirrored(mh,mp)
        np.testing.assert_allclose(hh,h,atol=1e-7);np.testing.assert_allclose(pp,p,atol=1e-7)
        self.assertTrue(np.all(mh[:,1]==0))

    def test_missing_tracking_is_not_presented_as_precise_alignment(self):
        h,p,t,f=sample()
        empty=[Frame(timestamp_ms=float(tm),hands=[None,None],pose=None) for tm in t]
        with patch('sign_api.comparison_avatar.reference_data',return_value=(h,p,t,16/9)):
            result=build_comparison(empty,16/9,'WORD0115','커피',{})
        self.assertEqual(result['alignment'],'relative_time')
        self.assertIn('생략',result['notice'])
        self.assertTrue(all(frame['comparison_status']=='unavailable' and not frame['highlight_notes'] for frame in result['frames']))

    def test_trace_is_coordinates_and_unreviewed_not_a_training_label(self):
        h,p,t,f=sample()
        with tempfile.TemporaryDirectory() as folder,patch('sign_api.practice_diagnostics.ROOT',Path(folder)),patch.dict('os.environ',{'SIGN_SAVE_PRACTICE_COORDS':'true'}):
            result={'attempt_id':'test-safe','target_word_id':'WORD0115','model_id':'test-model','recognition':{'top3':[{'label':'커피','score':.8}],'accepted':True},'feedback':{'reason':'recognized_variation'}}
            self.assertTrue(save_diagnostics(f,16/9,result))
            records=list(Path(folder).rglob('*.json'));self.assertEqual(len(records),1)
            record=json.loads(records[0].read_text(encoding='utf-8'));self.assertIsNone(record['verified_label']);self.assertEqual(record['annotation_status'],'unreviewed')
            with np.load(records[0].parent/record['coordinates'],allow_pickle=False) as data:np.testing.assert_allclose(data['hands'],h)
            self.assertEqual(len(list(Path(folder).rglob('*mp4'))),0)
            result['attempt_id']='../bad';self.assertFalse(save_diagnostics(f,16/9,result))


if __name__=='__main__':unittest.main()
