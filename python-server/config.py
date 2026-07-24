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

# 팀원들이 웹 페이지(/collect)에서 각자 수집한 데이터가
# landmark_{일시}_{입력한 이름}.csv 형태로 쌓이는 곳.
# (팀원마다 로컬에서 수집한 이 폴더를 깃허브에 merge하면 파일들이 그대로 합쳐지고,
#  팀장이 "병합" 버튼을 눌러 data/landmarks.csv 하나로 합친다)
TEMP_DIR = os.path.join(DATA_DIR, "temp")
# /dataset/merge 실행 후 처리된 원본 파일을 옮겨두는 곳 (재병합 방지 + 이력 보존용)
ARCHIVE_DIR = os.path.join(TEMP_DIR, "archive")
# /model/train 으로 모델이 새로 학습될 때, 덮어써지기 전 이전 모델을 통째로 백업하는 곳.
# model/old/{학습시각}/jamo_mlp.joblib, label_encoder.joblib 형태로 보관된다.
MODEL_OLD_DIR = os.path.join(MODEL_DIR, "old")

CSV_PATH = os.path.join(DATA_DIR, "landmarks.csv")
MODEL_PATH = os.path.join(MODEL_DIR, "jamo_mlp.joblib")
LABEL_ENCODER_PATH = os.path.join(MODEL_DIR, "label_encoder.joblib")

for _dir in (DATA_DIR, TEMP_DIR, ARCHIVE_DIR, MODEL_DIR, MODEL_OLD_DIR):
    os.makedirs(_dir, exist_ok=True)

# ── 인식 대상 클래스 ────────────────────────────────────────
# 필요에 따라 자유롭게 추가/삭제하세요.
# 주의: 아래 목록은 대부분 '정지 손모양(static)'으로 표현되는 자모입니다.
#       ㅘ, ㅝ, ㅢ 같은 이중모음 일부는 손의 '움직임'이 포함된 지문자라서
#       이 정지 프레임 기반 분류기로는 정확도가 떨어질 수 있습니다.
#       (움직임이 필요한 자모는 추후 시퀀스 모델로 확장 필요)

CONSONANTS = list("ㄱㄴㄷㄹㅁㅂㅅㅇㅈㅊㅋㅌㅍㅎ")
# ㅐㅒㅖ는 다른 모음의 합성이 아니라 각각 고유한 손모양을 가진 지문자라서 별도로 포함
VOWELS_BASIC = list("ㅏㅑㅓㅕㅗㅛㅜㅠㅡㅣㅐㅒㅖ")

# 쌍자음(ㄲㄸㅃㅆㅉ)은 정지 손모양 인식 대상에서 제외
LABELS = CONSONANTS + VOWELS_BASIC

# ── 라벨 → 모범 답안 이미지 파일명 매핑 ──────────────────────
# static/image/{코드}.jpg 로 저장. 한글 자모를 파일명에 그대로 쓰면
# macOS(NFD)/Windows·Linux(NFC) 유니코드 정규화 방식 차이 때문에
# 깃에서 같은 파일이 다르게 인식되는 문제가 생길 수 있어, 로마자 코드로 통일한다.
LABEL_IMAGE_CODES = {
    "ㄱ": "g", "ㄴ": "n", "ㄷ": "d", "ㄹ": "r", "ㅁ": "m",
    "ㅂ": "b", "ㅅ": "s", "ㅇ": "ng", "ㅈ": "j", "ㅊ": "ch",
    "ㅋ": "k", "ㅌ": "t", "ㅍ": "p", "ㅎ": "h",
    "ㅏ": "a", "ㅑ": "ya", "ㅓ": "eo", "ㅕ": "yeo", "ㅗ": "o",
    "ㅛ": "yo", "ㅜ": "u", "ㅠ": "yu", "ㅡ": "eu", "ㅣ": "i",
    "ㅐ": "ae", "ㅒ": "yae", "ㅖ": "ye",
}

# ── MediaPipe 설정 ─────────────────────────────────────────
MAX_NUM_HANDS = 1
MIN_DETECTION_CONFIDENCE = 0.7
MIN_TRACKING_CONFIDENCE = 0.5
