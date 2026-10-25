import os
import unittest
from unittest.mock import patch
import numpy as np

from fastapi.testclient import TestClient
from sign_api.standalone import app
from sign_api.api import runtime


def frame(t=0):
    return {'timestamp_ms': t, 'hands': [None, None], 'pose': None}


def clip():
    return {'attempt_id':'test-1', 'aspect':16/9, 'target_word_id':'WORD0115',
            'frames':[frame(i*67) for i in range(20)]}


class ApiTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.client = TestClient(app)
        cls.client.__enter__()

    @classmethod
    def tearDownClass(cls):
        cls.client.__exit__(None,None,None)

    def test_health_and_words(self):
        health = self.client.get('/api/v1/signs/health').json()
        self.assertTrue(health['ready'])
        self.assertEqual(health['classes'], 100)
        self.assertEqual(health['references'], 100)
        self.assertEqual(health['input_policy'], 'seated_active_v2')
        self.assertEqual(len(self.client.get('/api/v1/signs').json()['words']), 100)

    def test_chapter_catalog_is_complete(self):
        response=self.client.get('/api/v1/signs/chapters')
        self.assertEqual(response.status_code,200)
        data=response.json(); self.assertEqual(data['total_words'],100)
        self.assertEqual(len(data['chapters']),10)
        words=[]
        for chapter in data['chapters']:
            detail=self.client.get(chapter['detail_url']).json()
            self.assertEqual(chapter['word_count'],10)
            self.assertEqual(len(detail['words']),10)
            self.assertEqual([w['order'] for w in detail['words']],list(range(1,11)))
            self.assertTrue(all(w['feedback_available'] for w in detail['words']))
            words.extend(w['word_id'] for w in detail['words'])
        self.assertEqual(len(set(words)),100)

    def test_word_page_contract_and_unknown_ids(self):
        detail=self.client.get('/api/v1/signs/words/WORD0115').json()
        self.assertEqual(detail['label'],'커피')
        self.assertFalse(detail['capture']['both_hands_required'])
        self.assertTrue(detail['capture']['shoulders_required'])
        self.assertEqual(detail['video_evaluation_url'],'/api/v1/signs/evaluate-video')
        for path in ('chapters/chapter-99','words/WORD9999','reference/WORD9999'):
            self.assertEqual(self.client.get('/api/v1/signs/'+path).status_code,404)

    def test_reference_video_supports_playback_and_seeking(self):
        res=self.client.get('/api/v1/signs/reference/WORD0115',headers={'Range':'bytes=0-127'})
        self.assertEqual(res.status_code,206)
        self.assertEqual(res.headers['content-type'],'video/mp4')
        self.assertEqual(len(res.content),128)

    def test_video_upload_rejects_unknown_word_and_bad_attempt_id(self):
        res=self.client.post('/api/v1/signs/evaluate-video',data={'target_word_id':'WORD9999'},files={'video':('x.mp4',b'bad','video/mp4')})
        self.assertEqual(res.status_code,422)
        res=self.client.post('/api/v1/signs/evaluate-video',data={'target_word_id':'WORD0115','attempt_id':'../bad'},files={'video':('x.mp4',b'bad','video/mp4')})
        self.assertEqual(res.status_code,422)

    def test_no_hands_not_classified(self):
        res = self.client.post('/api/v1/signs/predict', json=clip())
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.json()['status'], 'retry')
        self.assertIsNone(res.json()['recognition'])

    def test_schema_guards(self):
        for mutate in [lambda d:d.update(mirrored=True),
                       lambda d:d.update(target_word_id='WORD9999'),
                       lambda d:d.update(frames=[frame()]*16),
                       lambda d:d.update(frames=[frame(i) for i in range(301)]),
                       lambda d:d['frames'][0].update(hands=[[[1,2,3]],None]),
                       lambda d:d.update(schema_version='unknown')]:
            data = clip()
            mutate(data)
            self.assertEqual(self.client.post('/api/v1/signs/evaluate',json=data).status_code,422)

    def test_missing_target(self):
        data=clip(); del data['target_word_id']
        self.assertEqual(self.client.post('/api/v1/signs/evaluate',json=data).status_code,422)

    def test_auth(self):
        with patch.dict(os.environ, {'SIGN_API_KEY':'test-service-key'}):
            self.assertEqual(self.client.get('/api/v1/signs/health').status_code,401)
            self.assertEqual(self.client.get('/api/v1/signs/health', headers={'X-Sign-Api-Key':'test-service-key'}).status_code,200)

    def test_ws_tracking_and_finish(self):
        with self.client.websocket_connect('/api/v1/signs/practice') as ws:
            ws.send_text('not json')
            self.assertEqual(ws.receive_json()['code'],422)
            ws.send_json({'type':'start','attempt_id':'ws-1','aspect':16/9,'target_word_id':'WORD0115'})
            self.assertEqual(ws.receive_json()['type'],'started')
            for start in (0,10):
                ws.send_json({'type':'frames','frames':[frame(i*67) for i in range(start,start+10)]})
                self.assertEqual(ws.receive_json()['type'],'tracking')
            ws.send_json({'type':'finish'})
            self.assertEqual(ws.receive_json()['status'],'retry')

    def test_ws_isolation(self):
        with self.client.websocket_connect('/api/v1/signs/practice') as first, self.client.websocket_connect('/api/v1/signs/practice') as second:
            first.send_json({'type':'start','attempt_id':'first','aspect':1.7,'target_word_id':'WORD0115'})
            first.receive_json()
            second.send_json({'type':'frames','frames':[frame()]})
            self.assertEqual(second.receive_json()['code'],422)

    def test_busy(self):
        runtime.gate.acquire()
        try:
            self.assertEqual(self.client.post('/api/v1/signs/predict',json=clip()).status_code,429)
        finally:
            runtime.gate.release()

    def test_seated_policy_keeps_active_hand_and_excludes_resting_hand(self):
        from sign_api.api import Clip
        features=np.ones((30,154),np.float32)
        features[:,127]=-.2; features[:,129]=1.6
        shapes=np.full((30,2,6),np.nan,np.float32)
        captured=[]; original=runtime.model
        def capture(xs,masks):
            captured.append(xs.numpy().copy())
            return original(xs,masks)
        with patch('sign_api.api.encode_frames',return_value=(features,shapes)),patch.object(runtime,'model',capture):
            result=runtime.infer(Clip(**clip()))
        self.assertEqual(result['status'],'ok')
        self.assertEqual(result['quality']['excluded_resting_slots'],[1])
        self.assertTrue(captured[0][0,:,:63].any())
        self.assertFalse(captured[0][0,:,63:126].any())
        self.assertFalse(captured[0][0,:,139:151].any())

    def test_resting_hand_alone_does_not_satisfy_capture_quality(self):
        from sign_api.api import Clip
        features=np.ones((30,154),np.float32)
        features[:,127]=-.2; features[:,129]=1.6
        features[12:,:63]=0; features[12:,126:128]=0; features[12:,151]=0
        shapes=np.full((30,2,6),np.nan,np.float32)
        with patch('sign_api.api.encode_frames',return_value=(features,shapes)):
            result=runtime.infer(Clip(**clip()))
        self.assertEqual(result['status'],'retry')
        self.assertEqual(result['quality']['hand_frames'],30)
        self.assertEqual(result['quality']['active_hand_frames'],12)
        self.assertIsNone(result['recognition'])


if __name__ == '__main__':
    unittest.main()
