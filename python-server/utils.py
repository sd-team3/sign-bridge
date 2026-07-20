# -*- coding: utf-8 -*-
"""
손 landmark 처리 공통 함수 모음
- MediaPipe 결과 → 학습/추론용 feature 벡터 변환
- 손목 기준 정규화 (위치/크기 불변)
- 왼손 모드(좌우 반전) 지원
- 한글 텍스트를 OpenCV 프레임에 그리는 기능 (cv2.putText는 한글 미지원)
"""

import os

import cv2
import numpy as np
from PIL import Image, ImageDraw, ImageFont

NUM_LANDMARKS = 21  # MediaPipe Hands 기준 landmark 개수


def csv_header():
    """landmarks.csv / incoming 배치 파일이 공통으로 쓰는 헤더.
    (label + 정규화된 63차원 feature)"""
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
    # 한글 폰트를 못 찾으면 기본 폰트로 대체 (한글은 깨져 보일 수 있음)
    font = ImageFont.load_default()
    _font_cache[size] = font
    return font


def draw_korean_texts(frame, items):
    """
    frame(BGR numpy array) 위에 한글 텍스트 여러 개를 한 번에 그려서 반환.
    items: [{"text": str, "pos": (x, y), "size": int, "color": (B, G, R)}, ...]
    """
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
    """MediaPipe hand_landmarks 객체 → (21, 3) numpy 배열"""
    coords = np.array(
        [[lm.x, lm.y, lm.z] for lm in hand_landmarks.landmark],
        dtype=np.float32,
    )
    return coords


def mirror_landmarks(coords):
    """
    좌우 반전 (왼손 모드용)
    MediaPipe 좌표는 이미지 기준 x가 0~1로 정규화되어 있으므로
    x축만 뒤집으면 오른손 모델로 왼손을 인식시킬 수 있음
    """
    coords = coords.copy()
    coords[:, 0] = 1.0 - coords[:, 0]
    return coords


def normalize_landmarks(coords):
    """
    손목(landmark 0)을 원점으로 이동 + 손 크기로 스케일 정규화
    → 카메라와의 거리, 화면 내 위치에 관계없이 같은 손모양이면 같은 벡터가 되도록 함
    """
    coords = coords.copy()
    wrist = coords[0].copy()
    coords -= wrist  # 손목 기준 평행이동

    scale = np.linalg.norm(coords, axis=1).max()
    if scale > 1e-6:
        coords /= scale

    return coords.flatten()  # (21, 3) -> (63,)


def extract_feature_vector(hand_landmarks, mirror=False):
    """
    MediaPipe 결과 하나를 학습/추론에 바로 쓸 수 있는 1차원 feature 벡터로 변환
    mirror=True 이면 왼손 입력을 오른손 기준으로 반전시켜 처리
    """
    coords = landmarks_to_array(hand_landmarks)
    if mirror:
        coords = mirror_landmarks(coords)
    return normalize_landmarks(coords)


def raw_points_to_array(points):
    """
    MediaPipe 객체 없이, [{"x":.., "y":.., "z":..}, ...] 형태의
    순수 좌표 리스트(21개)를 (21, 3) numpy 배열로 변환.
    FastAPI 등에서 클라이언트가 보낸 landmark 좌표를 받을 때 사용.
    """
    coords = np.array(
        [[p["x"], p["y"], p["z"]] for p in points],
        dtype=np.float32,
    )
    return coords


def extract_feature_vector_from_points(points, mirror=False):
    """
    raw_points_to_array + mirror + normalize 를 한 번에 처리.
    FastAPI 서버처럼 MediaPipe 객체가 아니라 좌표 리스트를 입력받는 환경에서 사용.
    """
    coords = raw_points_to_array(points)
    if mirror:
        coords = mirror_landmarks(coords)
    return normalize_landmarks(coords)
