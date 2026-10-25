"""손 랜드마크 시퀀스를 위한 모델과 공통 전처리."""
from __future__ import annotations

import numpy as np
import torch
from torch import nn

HAND_POINTS = 21
FEATURE_SIZE = HAND_POINTS * 3 * 2


def normalize_hands(frame: np.ndarray) -> np.ndarray:
    """각 손을 손목 원점/손 크기 기준으로 정규화한다. 미검출 손은 0으로 유지한다."""
    hands = frame.reshape(2, HAND_POINTS, 3).astype(np.float32, copy=True)
    for hand in hands:
        if not np.any(hand):
            continue
        wrist = hand[0].copy()
        hand -= wrist
        # 손목-중지 MCP 거리는 카메라와 피사체 거리 변화에 비교적 안정적이다.
        scale = np.linalg.norm(hand[9, :2])
        if scale > 1e-5:
            hand /= scale
    return hands.reshape(-1)


def resample_sequence(frames: np.ndarray, length: int) -> tuple[np.ndarray, np.ndarray]:
    """가변 길이 영상을 고정 길이로 보간한다. mask는 실제 손이 잡힌 프레임이다."""
    if len(frames) == 0:
        size=frames.shape[1] if frames.ndim==2 else FEATURE_SIZE
        return np.zeros((length, size), np.float32), np.zeros(length, np.bool_)
    indices = np.linspace(0, len(frames) - 1, length).round().astype(int)
    seq = frames[indices].astype(np.float32)
    return seq, np.any(seq[:, :FEATURE_SIZE] != 0, axis=1)


class SignLSTM(nn.Module):
    def __init__(self, classes: int, hidden_size: int = 192, num_layers: int = 2, dropout: float = 0.3, input_size: int = FEATURE_SIZE):
        super().__init__()
        self.input_norm = nn.LayerNorm(input_size)
        self.lstm = nn.LSTM(input_size, hidden_size, num_layers=num_layers,
                            batch_first=True, bidirectional=True,
                            dropout=dropout if num_layers > 1 else 0.0)
        self.attention = nn.Sequential(nn.Linear(hidden_size * 2, hidden_size), nn.Tanh(), nn.Linear(hidden_size, 1))
        self.head = nn.Sequential(nn.Dropout(dropout), nn.Linear(hidden_size * 2, classes))

    def forward(self, x: torch.Tensor, mask: torch.Tensor | None = None) -> torch.Tensor:
        output, _ = self.lstm(self.input_norm(x))
        scores = self.attention(output).squeeze(-1)
        if mask is not None:
            scores = scores.masked_fill(~mask.bool(), -1e4)
        weights = torch.softmax(scores, dim=1).unsqueeze(-1)
        return self.head((output * weights).sum(dim=1))
