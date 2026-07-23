# -*- coding: utf-8 -*-
"""
실시간 지문자 인식 프로그램
학습된 모델(model/jamo_mlp.joblib)을 불러와 웹캠 영상에서
실시간으로 지문자를 예측한다.

조작법
  M       : 왼손 모드 ON/OFF
  Q / ESC : 종료
"""

import collections

import cv2
import mediapipe as mp
import numpy as np
from joblib import load

from config import (
    LABEL_ENCODER_PATH,
    MAX_NUM_HANDS,
    MIN_DETECTION_CONFIDENCE,
    MIN_TRACKING_CONFIDENCE,
    MODEL_PATH,
)
from utils import extract_feature_vector

mp_hands = mp.solutions.hands
mp_drawing = mp.solutions.drawing_utils

CONFIDENCE_THRESHOLD = 0.6  # 이 값보다 확신도가 낮으면 "인식 불가"로 표시
SMOOTHING_WINDOW = 5  # 최근 N프레임 다수결로 결과를 안정화 (떨림 방지)


def main():
    model = load(MODEL_PATH)
    encoder = load(LABEL_ENCODER_PATH)

    mirror_mode = False
    recent_predictions = collections.deque(maxlen=SMOOTHING_WINDOW)

    cap = cv2.VideoCapture(0)
    if not cap.isOpened():
        print("웹캠을 열 수 없습니다.")
        return

    with mp_hands.Hands(
        max_num_hands=MAX_NUM_HANDS,
        min_detection_confidence=MIN_DETECTION_CONFIDENCE,
        min_tracking_confidence=MIN_TRACKING_CONFIDENCE,
    ) as hands:
        while True:
            ok, frame = cap.read()
            if not ok:
                break

            frame = cv2.flip(frame, 1)
            rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            result = hands.process(rgb)

            display_text = "손을 화면에 비춰주세요"

            if result.multi_hand_landmarks:
                hand_landmarks = result.multi_hand_landmarks[0]
                mp_drawing.draw_landmarks(
                    frame, hand_landmarks, mp_hands.HAND_CONNECTIONS
                )

                feature_vector = extract_feature_vector(
                    hand_landmarks, mirror=mirror_mode
                ).reshape(1, -1)

                probs = model.predict_proba(feature_vector)[0]
                best_idx = int(np.argmax(probs))
                confidence = probs[best_idx]
                predicted_label = encoder.classes_[best_idx]

                # 확률 상위 3개 추출 (내림차순)
                top3_idx = np.argsort(probs)[::-1][:3]
                top3 = [
                    (encoder.classes_[i], probs[i]) for i in top3_idx
                ]

                if confidence >= CONFIDENCE_THRESHOLD:
                    recent_predictions.append(predicted_label)
                else:
                    recent_predictions.append(None)

                # 최근 프레임 다수결로 최종 표시값 결정 (떨림 방지)
                valid = [p for p in recent_predictions if p is not None]
                if valid:
                    stable_label = collections.Counter(valid).most_common(1)[0][0]
                    display_text = f"{stable_label}  ({confidence*100:.0f}%)"
                else:
                    display_text = "인식 불가 (자신있는 손모양을 만들어보세요)"
            else:
                top3 = []

            cv2.putText(
                frame, display_text, (10, 40), cv2.FONT_HERSHEY_SIMPLEX,
                1.0, (0, 255, 255), 2, cv2.LINE_AA,
            )

            # ── Top-3 예측 표시 ──
            if top3:
                cv2.putText(
                    frame, "Top 3:", (10, 75), cv2.FONT_HERSHEY_SIMPLEX,
                    0.6, (255, 255, 255), 1, cv2.LINE_AA,
                )
                y = 100
                for rank, (label, prob) in enumerate(top3, start=1):
                    # 1위는 강조색(노란색), 나머지는 흰색
                    color = (0, 255, 255) if rank == 1 else (200, 200, 200)
                    line = f"{rank}. {label}  {prob*100:.1f}%"
                    cv2.putText(
                        frame, line, (10, y), cv2.FONT_HERSHEY_SIMPLEX,
                        0.6, color, 1, cv2.LINE_AA,
                    )
                    # 확률 막대 (시각적 표시)
                    bar_max_width = 150
                    bar_width = int(bar_max_width * prob)
                    cv2.rectangle(
                        frame, (150, y - 15), (150 + bar_width, y - 2),
                        color, -1,
                    )
                    y += 28

            cv2.putText(
                frame,
                f"Mirror(left-hand) mode: {'ON' if mirror_mode else 'OFF'} (M to toggle)",
                (10, 470),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.55,
                (0, 255, 0),
                1,
                cv2.LINE_AA,
            )

            cv2.imshow("Jamo Realtime Recognition", frame)
            key = cv2.waitKey(1) & 0xFF

            if key in (ord("q"), 27):
                break
            elif key == ord("m"):
                mirror_mode = not mirror_mode
                recent_predictions.clear()

    cap.release()
    cv2.destroyAllWindows()


if __name__ == "__main__":
    main()
