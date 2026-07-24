# -*- coding: utf-8 -*-
"""
Jamo KSL API 서버

엔드포인트 개요
  GET  /               - 데이터 수집/병합/학습/실시간 인식을 한 페이지에서 다루는 대시보드
  GET  /health          - 헬스체크 (모델 로딩 여부 포함)
  GET  /labels          - 인식 대상 라벨 목록
  POST /predict         - 랜드마크 21개를 받아 지문자 예측 (top3 포함)
  POST /collect          - 웹 페이지에서 캡처한 랜드마크 배치를 data/temp/landmark_{일시}_{입력한 이름}.csv 로 누적 저장
  GET  /dataset/stats    - 병합된(landmarks.csv) 샘플 수 + 아직 병합 안 된(temp) 샘플 수
  POST /dataset/merge    - data/temp/*.csv를 landmarks.csv에 병합하고 처리된 파일은 data/temp/archive로 이동
  POST /model/train      - landmarks.csv 전체로 모델을 재학습하고, 이전 모델은 model/old/{학습시각}/에 백업 후
                            학습된 모델을 메모리에 즉시 반영(핫 리로드)
"""

import glob
import os
import re
import time
from typing import List

import numpy as np
import pandas as pd
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
from joblib import load
from pydantic import BaseModel

import training
from config import (
    ARCHIVE_DIR,
    CSV_PATH,
    LABEL_ENCODER_PATH,
    LABEL_IMAGE_CODES,
    LABELS,
    MODEL_PATH,
    TEMP_DIR,
)
from utils import csv_header, extract_feature_vector_from_points

app = FastAPI(title="Jamo KSL API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

STATIC_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "static")
app.mount("/static", StaticFiles(directory=STATIC_DIR), name="static")


# ─────────────────────────────────────────────────────────
# 모델 로딩 (서버 시작 시 1회, /model/train 성공 시 재로딩)
# 모델이 아직 없는 초기 상태에서도 서버 자체는 뜨도록 예외를 던지지 않는다.
# ─────────────────────────────────────────────────────────
_state = {"model": None, "encoder": None}


def _load_model():
    if os.path.exists(MODEL_PATH) and os.path.exists(LABEL_ENCODER_PATH):
        _state["model"] = load(MODEL_PATH)
        _state["encoder"] = load(LABEL_ENCODER_PATH)
    else:
        _state["model"] = None
        _state["encoder"] = None


_load_model()


@app.get("/")
def index():
    return FileResponse(os.path.join(STATIC_DIR, "index.html"))


@app.get("/health")
def health():
    return {
        "status": "ok",
        "model_loaded": _state["model"] is not None,
        "num_classes": len(_state["encoder"].classes_) if _state["encoder"] is not None else 0,
    }


@app.get("/labels")
def get_labels():
    return {"labels": LABELS, "label_images": LABEL_IMAGE_CODES}


# ─────────────────────────────────────────────────────────
# 예측 (서비스)
# ─────────────────────────────────────────────────────────
class Landmark(BaseModel):
    x: float
    y: float
    z: float


class PredictRequest(BaseModel):
    landmarks: List[Landmark]
    mirror: bool = False


class TopPrediction(BaseModel):
    label: str
    confidence: float


class PredictResponse(BaseModel):
    label: str
    confidence: float
    top3: List[TopPrediction]


@app.post("/predict", response_model=PredictResponse)
def predict(req: PredictRequest):
    if _state["model"] is None:
        raise HTTPException(
            status_code=503,
            detail="아직 학습된 모델이 없습니다. 데이터를 모으고 병합 후 학습을 먼저 실행하세요.",
        )
    if len(req.landmarks) != 21:
        raise HTTPException(status_code=400, detail="landmark는 21개여야 합니다.")

    points = [lm.model_dump() for lm in req.landmarks]
    feature_vector = extract_feature_vector_from_points(points, mirror=req.mirror).reshape(1, -1)

    model = _state["model"]
    encoder = _state["encoder"]

    probs = model.predict_proba(feature_vector)[0]
    best_idx = int(np.argmax(probs))

    top3_idx = np.argsort(probs)[::-1][:3]
    top3 = [
        TopPrediction(label=str(encoder.classes_[i]), confidence=float(probs[i]))
        for i in top3_idx
    ]

    return PredictResponse(
        label=str(encoder.classes_[best_idx]),
        confidence=float(probs[best_idx]),
        top3=top3,
    )


# ─────────────────────────────────────────────────────────
# 데이터 수집 (요구사항 1)
# 브라우저에서 캡처한 landmark 배치를 JSON으로 받아
# data/temp/landmark_{일시}_{입력한 이름}.csv 로 누적 저장한다.
# 팀원 각자 이 파일들을 깃허브에 그대로 커밋/머지하면 data/temp/ 아래에
# 사람별/시각별 파일이 나란히 쌓이고, 팀장이 /dataset/merge 를 눌러 하나로 합친다.
# 정규화(feature 추출)는 서버에서 수행 -> 학습/추론과 동일한 로직을 항상 보장.
# ─────────────────────────────────────────────────────────
_SAFE_NAME_RE = re.compile(r"[^0-9A-Za-z가-힣_-]+")


def _sanitize_collector_name(name: str) -> str:
    """파일명에 그대로 들어가는 값이라 경로 탈출/특수문자를 막기 위해 정리한다."""
    name = (name or "").strip()
    name = _SAFE_NAME_RE.sub("_", name)
    name = name.strip("_")
    return name[:40] if name else "unknown"


class CollectFrame(BaseModel):
    landmarks: List[Landmark]


class CollectRequest(BaseModel):
    label: str
    mirror: bool = False
    frames: List[CollectFrame]
    # 데이터를 넣은 사람 이름 (웹 페이지에서 입력). 기존 클라이언트와의 호환을 위해
    # 값이 없으면 "unknown"으로 저장된다 (스프링 서버 등 다른 API 호출부에 영향 없음).
    collector: str = "unknown"


@app.post("/collect")
def collect(req: CollectRequest):
    if req.label not in LABELS:
        raise HTTPException(status_code=400, detail=f"알 수 없는 라벨입니다: {req.label}")
    if not req.frames:
        raise HTTPException(status_code=400, detail="frames가 비어 있습니다.")

    rows = []
    for frame in req.frames:
        if len(frame.landmarks) != 21:
            raise HTTPException(status_code=400, detail="landmark는 21개여야 합니다.")
        points = [lm.model_dump() for lm in frame.landmarks]
        feature_vector = extract_feature_vector_from_points(points, mirror=req.mirror)
        rows.append([req.label] + list(feature_vector))

    collector = _sanitize_collector_name(req.collector)
    # 마이크로초까지 포함해 같은 사람이 짧은 간격으로 여러 번 저장해도 파일명이 겹치지 않게 한다.
    ts = time.strftime("%Y%m%d_%H%M%S_") + f"{time.time_ns() % 1_000_000:06d}"
    filename = f"landmark_{ts}_{collector}.csv"
    filepath = os.path.join(TEMP_DIR, filename)

    df = pd.DataFrame(rows, columns=csv_header())
    df.to_csv(filepath, index=False, encoding="utf-8")

    return {
        "saved_file": filename,
        "saved_rows": len(rows),
        "label": req.label,
        "collector": collector,
    }


def _pending_files():
    # TEMP_DIR 바로 아래 csv만 대상으로 함 (archive 하위 폴더는 이미 병합된 것이므로 제외)
    return sorted(glob.glob(os.path.join(TEMP_DIR, "*.csv")))


# ─────────────────────────────────────────────────────────
# 현재 데이터 현황 (병합된 것 / 병합 대기 중인 것)
# ─────────────────────────────────────────────────────────
@app.get("/dataset/stats")
def dataset_stats():
    merged_counts = {label: 0 for label in LABELS}
    if os.path.exists(CSV_PATH):
        df = pd.read_csv(CSV_PATH)
        for label, count in df["label"].value_counts().items():
            if label in merged_counts:
                merged_counts[label] = int(count)

    pending_counts = {label: 0 for label in LABELS}
    pending_files = _pending_files()
    for f in pending_files:
        df = pd.read_csv(f)
        for label, count in df["label"].value_counts().items():
            if label in pending_counts:
                pending_counts[label] += int(count)

    return {
        "merged_counts": merged_counts,
        "pending_counts": pending_counts,
        "pending_files": len(pending_files),
        "total_merged": int(sum(merged_counts.values())),
        "total_pending": int(sum(pending_counts.values())),
    }


# ─────────────────────────────────────────────────────────
# 병합 (요구사항 1) - data/temp/*.csv -> landmarks.csv
# ─────────────────────────────────────────────────────────
@app.post("/dataset/merge")
def merge_dataset():
    pending_files = _pending_files()
    if not pending_files:
        return {"merged_files": 0, "merged_rows": 0, "message": "병합할 대기 데이터가 없습니다."}

    if not os.path.exists(CSV_PATH):
        pd.DataFrame(columns=csv_header()).to_csv(CSV_PATH, index=False, encoding="utf-8")

    frames = [pd.read_csv(f) for f in pending_files]
    new_df = pd.concat(frames, ignore_index=True)
    new_df.to_csv(CSV_PATH, mode="a", header=False, index=False, encoding="utf-8")

    for f in pending_files:
        dest = os.path.join(ARCHIVE_DIR, os.path.basename(f))
        os.replace(f, dest)

    return {"merged_files": len(pending_files), "merged_rows": len(new_df)}


# ─────────────────────────────────────────────────────────
# 학습 (요구사항 1) - landmarks.csv 전체로 재학습 후 모델에 반영
# ─────────────────────────────────────────────────────────
@app.post("/model/train")
def train_model_endpoint():
    try:
        report = training.train()
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

    _load_model()  # 서버 재시작 없이 방금 학습된 모델을 즉시 반영

    return report
