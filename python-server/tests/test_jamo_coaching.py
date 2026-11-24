import unittest
from unittest.mock import patch

from fastapi.testclient import TestClient
import main
import config


class JamoCoachingTests(unittest.TestCase):
    def setUp(self):
        self.client = TestClient(main.app)
        self.landmarks = [
            {'x': .1 + i * .005, 'y': .2 + (i % 4) * .02, 'z': 0.}
            for i in range(21)
        ]

    def payload(self, label):
        return dict(label=label, predicted_label=label, predicted_confidence=.99,
                    landmarks=self.landmarks, mirror=False)

    def test_api_labels_match_all_31_model_classes_and_have_images(self):
        result = self.client.get('/labels').json()
        self.assertEqual(len(result['labels']), 31)
        self.assertEqual(set(result['labels']), set(main._state['encoder'].classes_))
        self.assertTrue(set(result['labels']).issubset(result['label_images']))

    def test_every_trained_label_can_receive_coaching(self):
        for label in config.LABELS:
            with self.subTest(label=label):
                response = self.client.post('/coach', json=self.payload(label))
                self.assertEqual(response.status_code, 200, response.text)
                self.assertTrue(response.json()['tip'])
                self.assertIn(response.json()['kind'], ['advice', 'perfect'])

    def test_previously_missing_vowels_are_valid_predictions_for_other_targets(self):
        for label in ['ㅔ', 'ㅚ', 'ㅟ', 'ㅢ']:
            with self.subTest(label=label):
                payload = self.payload('ㅏ')
                payload['predicted_label'] = label
                result = self.client.post('/coach', json=payload)
                self.assertEqual(result.status_code, 200)
                self.assertEqual(result.json()['kind'], 'mismatch')

    def test_perfect_coaching_uses_requested_message(self):
        with patch('coaching.detect_deviation', return_value=None):
            result = self.client.post('/coach', json=self.payload('ㅔ'))
        self.assertEqual(result.status_code, 200)
        self.assertEqual(result.json()['kind'], 'perfect')
        self.assertEqual(result.json()['tip'], '완벽합니다!')


if __name__ == '__main__':
    unittest.main()
