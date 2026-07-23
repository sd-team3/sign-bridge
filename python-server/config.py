# -*- coding: utf-8 -*-
"""
전역 설정 파일
- 인식할 지문자(자모) 클래스 목록
- 데이터/모델 저장 경로
"""

import os

# ── 경로 설정 ──────────────────────────────────────────────
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_DIR = os.path.join(BASE_DIR, "data")
MODEL_DIR = os.path.join(BASE_DIR, "model")

# 웹 페이지에서 /collect로 들어온 데이터가 병합 전까지 쌓이는 곳
INCOMING_DIR = os.path.join(DATA_DIR, "incoming")
# /dataset/merge 실행 후 처리된 원본 파일을 옮겨두는 곳 (재병합 방지 + 이력 보존용)
ARCHIVE_DIR = os.path.join(INCOMING_DIR, "archive")
# /model/train 실행 시 덮어써지기 전 이전 모델을 보관하는 곳
MODEL_BACKUP_DIR = os.path.join(MODEL_DIR, "backup")

CSV_PATH = os.path.join(DATA_DIR, "landmarks.csv")
MODEL_PATH = os.path.join(MODEL_DIR, "jamo_mlp.joblib")
LABEL_ENCODER_PATH = os.path.join(MODEL_DIR, "label_encoder.joblib")

for _dir in (DATA_DIR, INCOMING_DIR, ARCHIVE_DIR, MODEL_DIR, MODEL_BACKUP_DIR):
    os.makedirs(_dir, exist_ok=True)

# ── 인식 대상 클래스 ────────────────────────────────────────
# 필요에 따라 자유롭게 추가/삭제하세요.
# 주의: 아래 목록은 대부분 '정지 손모양(static)'으로 표현되는 자모입니다.
#       ㅘ, ㅝ, ㅢ 같은 이중모음 일부는 손의 '움직임'이 포함된 지문자라서
#       이 정지 프레임 기반 분류기로는 정확도가 떨어질 수 있습니다.
#       (움직임이 필요한 자모는 추후 시퀀스 모델로 확장 필요)

CONSONANTS = list("ㄱㄴㄷㄹㅁㅂㅅㅇㅈㅊㅋㅌㅍㅎ")
DOUBLE_CONSONANTS = list("ㄲㄸㅃㅆㅉ")
VOWELS_BASIC = list("ㅏㅑㅓㅕㅗㅛㅜㅠㅡㅣ")

LABELS = CONSONANTS + DOUBLE_CONSONANTS + VOWELS_BASIC

# ── MediaPipe 설정 ─────────────────────────────────────────
MAX_NUM_HANDS = 1
MIN_DETECTION_CONFIDENCE = 0.7
MIN_TRACKING_CONFIDENCE = 0.5
