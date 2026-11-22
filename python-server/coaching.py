import math
import os

import pandas as pd

import config

COACH_FEATURES = {
    "thumb_index_gap": (4, 8, "엄지와 검지 끝 사이 간격"),
    "thumb_middle_gap": (4, 12, "엄지와 중지 끝 사이 간격"),
    "index_extension": (0, 8, "검지가 펴진 정도"),
    "middle_extension": (0, 12, "중지가 펴진 정도"),
    "ring_extension": (0, 16, "약지가 펴진 정도"),
    "pinky_extension": (0, 20, "새끼손가락이 펴진 정도"),
    "thumb_extension": (0, 4, "엄지가 펴진 정도"),
}

ADVICE_TEMPLATES = {
    ("thumb_index_gap", "+"): "엄지와 검지를 조금 더 모아보세요.",
    ("thumb_index_gap", "-"): "엄지와 검지를 조금 더 벌려보세요.",
    ("thumb_middle_gap", "+"): "엄지와 중지를 조금 더 모아보세요.",
    ("thumb_middle_gap", "-"): "엄지와 중지를 조금 더 벌려보세요.",
    ("index_extension", "+"): "검지를 살짝 더 구부려보세요.",
    ("index_extension", "-"): "검지를 살짝 더 펴보세요.",
    ("middle_extension", "+"): "중지를 살짝 더 구부려보세요.",
    ("middle_extension", "-"): "중지를 살짝 더 펴보세요.",
    ("ring_extension", "+"): "약지를 살짝 더 구부려보세요.",
    ("ring_extension", "-"): "약지를 살짝 더 펴보세요.",
    ("pinky_extension", "+"): "새끼손가락을 살짝 더 구부려보세요.",
    ("pinky_extension", "-"): "새끼손가락을 살짝 더 펴보세요.",
    ("thumb_extension", "+"): "엄지를 살짝 더 구부려보세요.",
    ("thumb_extension", "-"): "엄지를 살짝 더 펴보세요.",
}


def _distance(feat: list, i: int, j: int) -> float:
    dx = feat[3 * i] - feat[3 * j]
    dy = feat[3 * i + 1] - feat[3 * j + 1]
    dz = feat[3 * i + 2] - feat[3 * j + 2]
    return (dx ** 2 + dy ** 2 + dz ** 2) ** 0.5


def compute_features(feat_vec) -> dict:
    feat = list(feat_vec)
    result = {}
    for name, (i, j, desc) in COACH_FEATURES.items():
        result[name] = _distance(feat, i, j)
    return result


def _mean(values: list) -> float:
    return sum(values) / len(values)


def _std(values: list) -> float:
    avg = _mean(values)
    total = 0.0
    for v in values:
        total += (v - avg) ** 2
    return (total / len(values)) ** 0.5


def build_reference(csv_path=config.CSV_PATH, save_path=config.COACH_REFERENCE_PATH):
    if not os.path.exists(csv_path):
        return None

    df = pd.read_csv(csv_path)
    if df.empty:
        return None

    labels = []
    for lbl in df["label"]:
        if lbl not in labels:
            labels.append(lbl)

    rows = []
    for label in labels:
        subset = df[df["label"] == label]

        feature_values = {}
        for name in COACH_FEATURES:
            feature_values[name] = []

        for _, row in subset.iterrows():
            feat = list(row.drop("label"))
            features = compute_features(feat)
            for name, value in features.items():
                feature_values[name].append(value)

        for name, values in feature_values.items():
            rows.append({
                "label": label,
                "feature": name,
                "mean": _mean(values),
                "std": _std(values),
            })

    reference_df = pd.DataFrame(rows)
    reference_df.to_csv(save_path, index=False, encoding="utf-8")
    return reference_df


def load_reference(save_path=config.COACH_REFERENCE_PATH):
    if not os.path.exists(save_path):
        return None
    return pd.read_csv(save_path)


def detect_deviation(label, feat_vec, reference_df, z_threshold=config.COACH_Z_THRESHOLD):
    if reference_df is None:
        return None

    label_rows = reference_df[reference_df["label"] == label]
    if label_rows.empty:
        return None

    feat = list(feat_vec)
    best = None

    for _, ref_row in label_rows.iterrows():
        name = ref_row["feature"]
        mean = ref_row["mean"]
        std = ref_row["std"]
        if name not in COACH_FEATURES or std < 1e-6:
            continue

        i, j, desc = COACH_FEATURES[name]
        value = _distance(feat, i, j)
        z = (value - mean) / std

        if abs(z) >= z_threshold:
            if best is None or abs(z) > abs(best["z"]):
                pct_diff = 0.0
                if mean > 1e-6:
                    pct_diff = abs(value - mean) / mean * 100
                best = {
                    "name": name,
                    "desc": desc,
                    "z": z,
                    "value": value,
                    "mean": mean,
                    "direction": "+" if z > 0 else "-",
                    "pct_diff": pct_diff,
                }
    return best


def feedback_tip(deviation) -> str:
    key = (deviation["name"], deviation["direction"])
    if key in ADVICE_TEMPLATES:
        return ADVICE_TEMPLATES[key]
    return "손모양을 기준 동작과 조금 더 비교해보세요."


def generate_feedback(target_label, predicted_label, predicted_confidence, feat_vec):
    if not all(math.isfinite(value) for value in feat_vec) or not any(feat_vec):
        return {"tip": "손가락이 화면에 잘 보이도록 다시 보여 주세요.", "kind": "advice", "predicted_label": predicted_label}

    if predicted_label != target_label:
        tip = f"지금은 ‘{predicted_label}’에 가까운 손 모양이에요. ‘{target_label}’의 시범을 다시 확인해 주세요."
        return {"tip": tip, "kind": "mismatch", "predicted_label": predicted_label}

    reference_df = load_reference()
    if reference_df is None or target_label not in reference_df["label"].values:
        return {"tip": "이 지문자의 기준 손 모양을 아직 불러오지 못했어요.", "kind": "advice", "predicted_label": predicted_label}

    deviation = detect_deviation(target_label, feat_vec, reference_df)
    if deviation is None:
        return {"tip": "기준 손 모양과 뚜렷한 차이가 보이지 않아요.", "kind": "perfect", "predicted_label": predicted_label}

    tip = feedback_tip(deviation)
    return {"tip": tip, "kind": "advice", "predicted_label": predicted_label}
