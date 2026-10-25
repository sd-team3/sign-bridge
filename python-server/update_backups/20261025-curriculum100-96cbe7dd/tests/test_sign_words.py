import os
import unittest
from unittest.mock import patch

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
        self.assertEqual(health['classes'], 50)
        self.assertEqual(len(self.client.get('/api/v1/signs').json()['words']), 50)

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


if __name__ == '__main__':
    unittest.main()
