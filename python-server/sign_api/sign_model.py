from __future__ import annotations

import numpy as np
import torch
from torch import nn

HAND_POINTS = 21
FEATURE_SIZE = HAND_POINTS * 3 * 2

def normalize_hands(frame: np.ndarray) -> np.ndarray:

    hands = frame.reshape(2, HAND_POINTS, 3).astype(np.float32, copy=True)
    for hand in hands:
        if not np.any(hand):
            continue
        wrist = hand[0].copy()
        hand -= wrist

        scale = np.linalg.norm(hand[9, :2])
        if scale > 1e-5:
            hand /= scale
    return hands.reshape(-1)

def resample_sequence(frames: np.ndarray, length: int) -> tuple[np.ndarray, np.ndarray]:

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


def inference_logits(model, x, mask, checkpoint):
    result = model(x, mask)
    if checkpoint.get('mirror_ensemble'):
        from .body_features import mirror
        flipped = torch.from_numpy(np.array([mirror(a) for a in x.detach().cpu().numpy()])).to(device=x.device,dtype=x.dtype)
        result = (result + model(flipped, mask)) * .5
    temperature = float(checkpoint.get('temperature', 1.0))
    if not np.isfinite(temperature) or temperature <= 0: raise ValueError('Invalid temperature')
    return result / temperature
