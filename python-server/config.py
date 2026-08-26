import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_DIR = os.path.join(BASE_DIR, "data")
MODEL_DIR = os.path.join(BASE_DIR, "model")
TEMP_DIR = os.path.join(DATA_DIR, "temp")
ARCHIVE_DIR = os.path.join(TEMP_DIR, "archive")
MODEL_OLD_DIR = os.path.join(MODEL_DIR, "old")

CSV_PATH = os.path.join(DATA_DIR, "landmarks.csv")
MODEL_PATH = os.path.join(MODEL_DIR, "jamo_mlp.joblib")
LABEL_ENCODER_PATH = os.path.join(MODEL_DIR, "label_encoder.joblib")

for _dir in (DATA_DIR, TEMP_DIR, ARCHIVE_DIR, MODEL_DIR, MODEL_OLD_DIR):
    os.makedirs(_dir, exist_ok=True)

CONSONANTS = list("ㄱㄴㄷㄹㅁㅂㅅㅇㅈㅊㅋㅌㅍㅎ")
VOWELS_BASIC = list("ㅏㅑㅓㅕㅗㅛㅜㅠㅡㅣㅐㅒㅖ")
LABELS = CONSONANTS + VOWELS_BASIC

LABEL_IMAGE_CODES = {
    "ㄱ": "g", "ㄴ": "n", "ㄷ": "d", "ㄹ": "r", "ㅁ": "m",
    "ㅂ": "b", "ㅅ": "s", "ㅇ": "ng", "ㅈ": "j", "ㅊ": "ch",
    "ㅋ": "k", "ㅌ": "t", "ㅍ": "p", "ㅎ": "h",
    "ㅏ": "a", "ㅑ": "ya", "ㅓ": "eo", "ㅕ": "yeo", "ㅗ": "o",
    "ㅛ": "yo", "ㅜ": "u", "ㅠ": "yu", "ㅡ": "eu", "ㅣ": "i",
    "ㅐ": "ae", "ㅒ": "yae", "ㅖ": "ye",
}

MAX_NUM_HANDS = 1
MIN_DETECTION_CONFIDENCE = 0.7
MIN_TRACKING_CONFIDENCE = 0.5

COACH_REFERENCE_PATH = os.path.join(MODEL_DIR, "coach_reference.csv")
COACH_Z_THRESHOLD = 1.3

GROQ_API_KEY = os.environ.get("GROQ_API_KEY", "")
GROQ_API_URL = "https://api.groq.com/openai/v1/chat/completions"
GROQ_MODEL = os.environ.get("GROQ_MODEL", "llama-3.3-70b-versatile")
GROQ_TIMEOUT_SEC = 4
