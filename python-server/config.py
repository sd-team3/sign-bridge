import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_DIR = os.path.join(BASE_DIR, "data")
MODEL_DIR = os.path.join(BASE_DIR, "model")
TEMP_DIR = os.path.join(DATA_DIR, "temp") # landmark_{일시}_{이름}.csv 형태
ARCHIVE_DIR = os.path.join(TEMP_DIR, "archive") # 기록보존
MODEL_OLD_DIR = os.path.join(MODEL_DIR, "old") # 모델 이전 버전 백업

CSV_PATH = os.path.join(DATA_DIR, "landmarks.csv")
MODEL_PATH = os.path.join(MODEL_DIR, "jamo_mlp.joblib")
LABEL_ENCODER_PATH = os.path.join(MODEL_DIR, "label_encoder.joblib")

for _dir in (DATA_DIR, TEMP_DIR, ARCHIVE_DIR, MODEL_DIR, MODEL_OLD_DIR):
    os.makedirs(_dir, exist_ok=True)

CONSONANTS = list("ㄱㄴㄷㄹㅁㅂㅅㅇㅈㅊㅋㅌㅍㅎ") #쌍자음은 제외
VOWELS_BASIC = list("ㅏㅑㅓㅕㅗㅛㅜㅠㅡㅣㅐㅒㅖ") #ㅚ, ㅙ와 같은 합성 모음은 제외
LABELS = CONSONANTS + VOWELS_BASIC

LABEL_IMAGE_CODES = {
    "ㄱ": "g", "ㄴ": "n", "ㄷ": "d", "ㄹ": "r", "ㅁ": "m",
    "ㅂ": "b", "ㅅ": "s", "ㅇ": "ng", "ㅈ": "j", "ㅊ": "ch",
    "ㅋ": "k", "ㅌ": "t", "ㅍ": "p", "ㅎ": "h",
    "ㅏ": "a", "ㅑ": "ya", "ㅓ": "eo", "ㅕ": "yeo", "ㅗ": "o",
    "ㅛ": "yo", "ㅜ": "u", "ㅠ": "yu", "ㅡ": "eu", "ㅣ": "i",
    "ㅐ": "ae", "ㅒ": "yae", "ㅖ": "ye",
} #파일명 매핑

MAX_NUM_HANDS = 1
MIN_DETECTION_CONFIDENCE = 0.7
MIN_TRACKING_CONFIDENCE = 0.5