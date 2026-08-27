import os

import pandas as pd
import requests

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


def fallback_tip(deviation) -> str:
    key = (deviation["name"], deviation["direction"])
    if key in ADVICE_TEMPLATES:
        return ADVICE_TEMPLATES[key]
    return "손모양을 기준 동작과 조금 더 비교해보세요."


def _call_groq(label, deviation, fallback) -> str:
    if not config.GROQ_API_KEY:
        return fallback

    direction_text = "많이 넓거나 큽니다"
    if deviation["direction"] == "-":
        direction_text = "많이 좁거나 작습니다"

    system_prompt = (
        "당신은 한국 수어(한국어 지문자) 초보자를 돕는 다정한 코치입니다. "
        "입력으로는 이미 정답으로 인식된 손모양이 기준 동작과 어떻게 다른지에 대한 "
        "관찰 정보가 주어집니다. 이를 바탕으로 30자 이내의 짧고 친절한 한국어 조언을 "
        "한 문장으로만 답하세요. 인사말, 따옴표, 부연설명은 넣지 마세요."
    )
    user_prompt = (
        f"목표 자모: '{label}'. "
        f"관찰된 편차: '{deviation['desc']}'이(가) 기준보다 {direction_text} "
        f"(기준 대비 약 {round(deviation['pct_diff'])}% 차이). "
        f"참고용 기본 조언: '{fallback}'"
    )

    try:
        res = requests.post(
            config.GROQ_API_URL,
            headers={
                "Authorization": f"Bearer {config.GROQ_API_KEY}",
                "Content-Type": "application/json",
            },
            json={
                "model": config.GROQ_MODEL,
                "messages": [
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt},
                ],
                "temperature": 0.5,
                "max_tokens": 60,
            },
            timeout=config.GROQ_TIMEOUT_SEC,
        )
        res.raise_for_status()
        content = res.json()["choices"][0]["message"]["content"].strip()
        return content if content else fallback
    except Exception:
        return fallback


def _call_groq_mismatch(target_label, predicted_label, fallback) -> str:
    if not config.GROQ_API_KEY:
        return fallback

    system_prompt = (
        "당신은 한국 수어(한국어 지문자) 초보자를 돕는 다정한 코치입니다. "
        "사용자가 목표로 하는 자모와 지금 카메라에 인식되는 자모가 서로 다릅니다. "
        "두 자모의 관계만 짧게 짚어서, 지금 손모양이 목표와 얼마나 다른지를 "
        "20자 이내의 짧고 친절한 한국어 한 문장으로 알려주세요. "
        "인사말, 따옴표, 부연설명은 넣지 마세요."
    )
    user_prompt = (
        f"목표 자모: '{target_label}'. "
        f"지금 인식되는 자모: '{predicted_label}'. "
        f"참고용 기본 문구: '{fallback}'"
    )

    try:
        res = requests.post(
            config.GROQ_API_URL,
            headers={
                "Authorization": f"Bearer {config.GROQ_API_KEY}",
                "Content-Type": "application/json",
            },
            json={
                "model": config.GROQ_MODEL,
                "messages": [
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt},
                ],
                "temperature": 0.5,
                "max_tokens": 40,
            },
            timeout=config.GROQ_TIMEOUT_SEC,
        )
        res.raise_for_status()
        content = res.json()["choices"][0]["message"]["content"].strip()
        return content if content else fallback
    except Exception:
        return fallback


def generate_feedback(target_label, predicted_label, predicted_confidence, feat_vec):
    if predicted_label != target_label:
        fallback = f"지금은 '{predicted_label}'에 가까운 손모양이에요. '{target_label}'과는 많이 달라요."
        tip = _call_groq_mismatch(target_label, predicted_label, fallback)
        return {"tip": tip, "kind": "mismatch", "predicted_label": predicted_label}

    reference_df = load_reference()
    deviation = detect_deviation(target_label, feat_vec, reference_df)
    if deviation is None:
        return {"tip": "완벽합니다!", "kind": "perfect", "predicted_label": predicted_label}

    fallback = fallback_tip(deviation)
    tip = _call_groq(target_label, deviation, fallback)
    return {"tip": tip, "kind": "advice", "predicted_label": predicted_label}
