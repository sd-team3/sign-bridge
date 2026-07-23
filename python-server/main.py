# -*- coding: utf-8 -*-
"""
Jamo KSL API 서버

엔드포인트 개요
  GET  /               - 데이터 수집/병합/학습/실시간 인식을 한 페이지에서 다루는 대시보드
  GET  /health          - 헬스체크 (모델 로딩 여부 포함)
  GET  /labels          - 인식 대상 라벨 목록
  POST /predict         - 랜드마크 21개를 받아 지문자 예측 (top3 포함)
  POST /collect          - 웹 페이지에서 캡처한 랜드마크 배치를 landmark_YYYYMMDD_HHMMSS_xxxxxx.csv로 누적 저장
  GET  /dataset/stats    - 병합된(landmarks.csv) 샘플 수 + 아직 병합 안 된(incoming) 샘플 수
  POST /dataset/merge    - incoming/*.csv를 landmarks.csv에 병합하고 처리된 파일은 archive로 이동
  POST /model/train      - landmarks.csv 전체로 모델을 재학습하고, 학습된 모델을 메모리에 즉시 반영(핫 리로드)
"""

import glob
import os
import time
import uuid
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
    INCOMING_DIR,
    LABEL_ENCODER_PATH,
    LABELS,
    MODEL_PATH,
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
    return {"labels": LABELS}


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
# data/incoming/landmark_YYYYMMDD_HHMMSS_xxxxxx.csv 로 누적 저장한다.
# 정규화(feature 추출)는 서버에서 수행 -> 학습/추론과 동일한 로직을 항상 보장.
# ─────────────────────────────────────────────────────────
class CollectFrame(BaseModel):
    landmarks: List[Landmark]


class CollectRequest(BaseModel):
    label: str
    mirror: bool = False
    frames: List[CollectFrame]


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

    ts = time.strftime("%Y%m%d_%H%M%S")
    filename = f"landmark_{ts}_{uuid.uuid4().hex[:6]}.csv"
    filepath = os.path.join(INCOMING_DIR, filename)

    df = pd.DataFrame(rows, columns=csv_header())
    df.to_csv(filepath, index=False, encoding="utf-8")

    return {"saved_file": filename, "saved_rows": len(rows), "label": req.label}


def _pending_files():
    return sorted(glob.glob(os.path.join(INCOMING_DIR, "*.csv")))


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
# 병합 (요구사항 1) - incoming/*.csv -> landmarks.csv
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
