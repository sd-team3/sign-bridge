# -*- coding: utf-8 -*-
"""
지문자 데이터 수집 프로그램
웹캠으로 손을 비추면 MediaPipe가 21개 keypoint를 추출하고,
현재 선택된 라벨과 함께 landmarks.csv에 한 줄씩 '적층' 저장한다.

조작법
  A / D       : 이전 / 다음 라벨로 이동
  SPACE       : 현재 프레임 1개 저장
  C           : 연속 저장 모드 ON/OFF (누르는 동안 매 프레임 자동 저장)
  M           : 왼손 모드 ON/OFF (좌우 반전 후 저장 - 왼손으로 찍을 때 사용)
  Q / ESC     : 종료
"""

import csv
import os
import time

import cv2
import mediapipe as mp

from config import (
    CSV_PATH,
    LABELS,
    MAX_NUM_HANDS,
    MIN_DETECTION_CONFIDENCE,
    MIN_TRACKING_CONFIDENCE,
)
from utils import csv_header, extract_feature_vector

mp_hands = mp.solutions.hands
mp_drawing = mp.solutions.drawing_utils


def ensure_csv_header():
    """CSV 파일이 없으면 헤더를 만들어둔다."""
    if not os.path.exists(CSV_PATH):
        header = csv_header()
        with open(CSV_PATH, "w", newline="", encoding="utf-8") as f:
            writer = csv.writer(f)
            writer.writerow(header)


def append_row(label, feature_vector):
    with open(CSV_PATH, "a", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow([label] + list(feature_vector))


def count_samples_per_label():
    """현재까지 라벨별로 몇 개 쌓였는지 세어서 화면에 표시하기 위함"""
    counts = {label: 0 for label in LABELS}
    if os.path.exists(CSV_PATH):
        with open(CSV_PATH, "r", encoding="utf-8") as f:
            reader = csv.reader(f)
            next(reader, None)  # 헤더 skip
            for row in reader:
                if row and row[0] in counts:
                    counts[row[0]] += 1
    return counts


def main():
    ensure_csv_header()
    counts = count_samples_per_label()

    label_idx = 0
    mirror_mode = False
    continuous_mode = False
    last_save_time = 0
    save_interval = 0.08  # 연속 저장 모드일 때 초당 과도하게 쌓이지 않도록 최소 간격(초)

    cap = cv2.VideoCapture(0)
    if not cap.isOpened():
        print("웹캠을 열 수 없습니다. 카메라 연결/권한을 확인하세요.")
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

            frame = cv2.flip(frame, 1)  # 셀피뷰(거울모드)로 보기 편하게
            rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            result = hands.process(rgb)

            feature_vector = None
            if result.multi_hand_landmarks:
                hand_landmarks = result.multi_hand_landmarks[0]
                mp_drawing.draw_landmarks(
                    frame, hand_landmarks, mp_hands.HAND_CONNECTIONS
                )
                feature_vector = extract_feature_vector(
                    hand_landmarks, mirror=mirror_mode
                )

            current_label = LABELS[label_idx]

            # ── 연속 저장 모드 처리 ──
            if continuous_mode and feature_vector is not None:
                now = time.time()
                if now - last_save_time >= save_interval:
                    append_row(current_label, feature_vector)
                    counts[current_label] += 1
                    last_save_time = now

            # ── 화면 표시 ──
            overlay_lines = [
                f"Label: {current_label}  ({counts[current_label]} samples)",
                f"Mirror(left-hand) mode: {'ON' if mirror_mode else 'OFF'}",
                f"Continuous save: {'ON' if continuous_mode else 'OFF'}",
                "A/D: change label | SPACE: save 1 | C: continuous | M: mirror | Q: quit",
            ]
            y = 25
            for line in overlay_lines:
                cv2.putText(
                    frame, line, (10, y), cv2.FONT_HERSHEY_SIMPLEX,
                    0.55, (0, 255, 0), 1, cv2.LINE_AA,
                )
                y += 25

            cv2.imshow("Jamo Data Collector", frame)
            key = cv2.waitKey(1) & 0xFF

            if key in (ord("q"), 27):  # q or ESC
                break
            elif key == ord("a"):
                label_idx = (label_idx - 1) % len(LABELS)
            elif key == ord("d"):
                label_idx = (label_idx + 1) % len(LABELS)
            elif key == ord("m"):
                mirror_mode = not mirror_mode
            elif key == ord("c"):
                continuous_mode = not continuous_mode
            elif key == ord(" "):
                if feature_vector is not None:
                    append_row(current_label, feature_vector)
                    counts[current_label] += 1
                else:
                    print("손이 인식되지 않아 저장하지 않았습니다.")

    cap.release()
    cv2.destroyAllWindows()

    print("\n=== 수집 결과 ===")
    for label, c in counts.items():
        print(f"{label}: {c}개")
    print(f"\n저장 위치: {CSV_PATH}")


if __name__ == "__main__":
    main()
