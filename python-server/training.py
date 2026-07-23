# -*- coding: utf-8 -*-
"""
모델 학습 로직 (공용 모듈)
- CLI(train_model.py)와 FastAPI 엔드포인트(/model/train)가 동일한 로직을 공유한다.
- 매번 landmarks.csv 전체로 재학습하는 방식 (증분 학습이 아니라 "누적된 데이터로 다시 학습"하는 방식).
  MLPClassifier는 partial_fit도 가능하지만, 클래스 불균형/재현성 관리가 어려워서
  전체 재학습이 데이터셋이 크지 않은 이 프로젝트 규모에서는 더 안전하다.
"""

import os
import shutil
import time

import numpy as np
import pandas as pd
from joblib import dump
from sklearn.metrics import classification_report
from sklearn.model_selection import train_test_split
from sklearn.neural_network import MLPClassifier
from sklearn.preprocessing import LabelEncoder

from config import CSV_PATH, LABEL_ENCODER_PATH, MODEL_BACKUP_DIR, MODEL_PATH


def load_dataset(csv_path=CSV_PATH):
    df = pd.read_csv(csv_path)
    X = df.drop(columns=["label"]).values.astype(np.float32)
    y = df["label"].values
    return X, y


def backup_current_model():
    """덮어쓰기 전에 기존 모델/인코더를 타임스탬프 붙여서 backup 폴더에 보관."""
    ts = time.strftime("%Y%m%d_%H%M%S")
    for path in (MODEL_PATH, LABEL_ENCODER_PATH):
        if os.path.exists(path):
            filename = os.path.basename(path)
            backup_path = os.path.join(MODEL_BACKUP_DIR, f"{ts}_{filename}")
            shutil.copy2(path, backup_path)


def train(csv_path=CSV_PATH):
    """landmarks.csv 전체로 모델을 재학습하고 model/ 폴더에 저장한다.
    반환값은 API 응답 및 로그 출력에 그대로 쓸 수 있는 학습 리포트 dict."""

    if not os.path.exists(csv_path):
        raise ValueError("landmarks.csv가 없습니다. 먼저 데이터를 모으고 병합하세요.")

    X, y = load_dataset(csv_path)
    if len(X) == 0:
        raise ValueError("학습할 데이터가 없습니다.")

    label_counts = pd.Series(y).value_counts().to_dict()
    too_few = {k: v for k, v in label_counts.items() if v < 10}

    num_classes = len(set(y))
    if num_classes < 2:
        raise ValueError("최소 2개 이상의 클래스(라벨)에 대한 데이터가 있어야 학습할 수 있습니다.")

    encoder = LabelEncoder()
    y_encoded = encoder.fit_transform(y)

    # 클래스당 샘플이 극히 적으면 stratify 분할이 실패할 수 있어 방어적으로 처리
    min_class_count = min(label_counts.values())
    stratify = y_encoded if min_class_count >= 2 else None

    X_train, X_test, y_train, y_test = train_test_split(
        X, y_encoded, test_size=0.2, random_state=42, stratify=stratify
    )

    model = MLPClassifier(
        hidden_layer_sizes=(128, 64),
        activation="relu",
        solver="adam",
        max_iter=500,
        early_stopping=False,
        random_state=42,
    )
    model.fit(X_train, y_train)

    y_pred = model.predict(X_test)
    report = classification_report(
        y_test,
        y_pred,
        labels=list(range(len(encoder.classes_))),
        target_names=[str(c) for c in encoder.classes_],
        zero_division=0,
        output_dict=True,
    )

    backup_current_model()
    dump(model, MODEL_PATH)
    dump(encoder, LABEL_ENCODER_PATH)

    return {
        "trained_at": time.strftime("%Y-%m-%d %H:%M:%S"),
        "total_samples": len(X),
        "num_classes": num_classes,
        "test_accuracy": report.get("accuracy"),
        "label_counts": label_counts,
        "low_sample_labels": too_few,
        "report": report,
    }


if __name__ == "__main__":
    result = train()
    print(f"\n총 샘플 수: {result['total_samples']}개, 클래스 수: {result['num_classes']}개")
    print(f"테스트 정확도: {result['test_accuracy']:.4f}")
    if result["low_sample_labels"]:
        print("\n⚠ 샘플이 10개 미만인 라벨:")
        for label, count in result["low_sample_labels"].items():
            print(f"  {label}: {count}개")
    print(f"\n모델 저장 완료: {MODEL_PATH}")
    print(f"라벨 인코더 저장 완료: {LABEL_ENCODER_PATH}")
