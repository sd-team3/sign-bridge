import os

import cv2
import numpy as np
from PIL import Image, ImageDraw, ImageFont

NUM_LANDMARKS = 21  # MediaPipe Hands 기준 landmark 개수


def csv_header():
    return ["label"] + [f"f{i}" for i in range(63)]

# ── 한글 폰트 로딩 (cv2.putText는 한글을 그리지 못하므로 PIL로 대체) ──
_FONT_CANDIDATES = [
    "C:/Windows/Fonts/malgun.ttf",       # Windows (맑은 고딕)
    "C:/Windows/Fonts/malgunbd.ttf",
    "/usr/share/fonts/truetype/nanum/NanumGothic.ttf",  # Linux
    "/System/Library/Fonts/AppleSDGothicNeo.ttc",       # macOS
]
_font_cache = {}


def _get_korean_font(size):
    if size in _font_cache:
        return _font_cache[size]
    for path in _FONT_CANDIDATES:
        if os.path.exists(path):
            font = ImageFont.truetype(path, size)
            _font_cache[size] = font
            return font
    font = ImageFont.load_default()
    _font_cache[size] = font
    return font


def draw_korean_texts(frame, items):
    img_pil = Image.fromarray(cv2.cvtColor(frame, cv2.COLOR_BGR2RGB))
    draw = ImageDraw.Draw(img_pil)
    for item in items:
        b, g, r = item.get("color", (255, 255, 255))
        font = _get_korean_font(item.get("size", 32))
        draw.text(item["pos"], item["text"], font=font, fill=(r, g, b))
    result = cv2.cvtColor(np.array(img_pil), cv2.COLOR_RGB2BGR)
    frame[:] = result
    return frame


def landmarks_to_array(hand_landmarks):
    coords = np.array(
        [[lm.x, lm.y, lm.z] for lm in hand_landmarks.landmark],
        dtype=np.float32,
    )
    return coords


def mirror_landmarks(coords):
    coords = coords.copy()
    coords[:, 0] = 1.0 - coords[:, 0]
    return coords


def normalize_landmarks(coords):
    coords = coords.copy()
    wrist = coords[0].copy()
    coords -= wrist  # 손목 기준 평행이동

    scale = np.linalg.norm(coords, axis=1).max()
    if scale > 1e-6:
        coords /= scale

    return coords.flatten()  # (21, 3) -> (63,)


def extract_feature_vector(hand_landmarks, mirror=False):
    coords = landmarks_to_array(hand_landmarks)
    if mirror:
        coords = mirror_landmarks(coords)
    return normalize_landmarks(coords)


def raw_points_to_array(points):
    coords = np.array(
        [[p["x"], p["y"], p["z"]] for p in points],
        dtype=np.float32,
    )
    return coords


def extract_feature_vector_from_points(points, mirror=False):
    coords = raw_points_to_array(points)
    if mirror:
        coords = mirror_landmarks(coords)
    return normalize_landmarks(coords)
