import torch
from torch import nn
import torch.nn.functional as F


class TemporalBlock(nn.Module):
    def __init__(self, width, dilation, dropout):
        super().__init__()
        self.norm = nn.LayerNorm(width)
        self.depth = nn.Conv1d(width, width, 5, padding=2*dilation, dilation=dilation, groups=width)
        self.mix = nn.Sequential(nn.Linear(width, width*2), nn.GELU(), nn.Dropout(dropout), nn.Linear(width*2, width), nn.Dropout(dropout))

    def forward(self, x):
        y = self.depth(self.norm(x).transpose(1, 2)).transpose(1, 2)
        return x + self.mix(y)


class ContextSignModel(nn.Module):
    def __init__(self, classes, width=96, embedding_size=96, dropout=.15, input_size=154):
        super().__init__()
        if input_size != 154:
            raise ValueError('Expected hands_body_v1 features')
        self.hand = nn.Sequential(nn.LayerNorm(63), nn.Linear(63, 64), nn.GELU(), nn.Linear(64, 48))
        self.relation = nn.Sequential(nn.LayerNorm(19), nn.Linear(19, 48), nn.GELU(), nn.Linear(48, 24))
        self.motion = nn.Sequential(nn.LayerNorm(130), nn.Linear(130, 64), nn.GELU(), nn.Linear(64, 32))
        self.input = nn.Linear(152, width)
        self.position = nn.Parameter(torch.randn(1, 64, width)*.01)
        self.temporal = nn.Sequential(*[TemporalBlock(width, d, dropout) for d in (1, 2, 4)])
        layer = nn.TransformerEncoderLayer(width, 4, width*2, dropout, activation='gelu', batch_first=True, norm_first=True)
        self.attention = nn.TransformerEncoder(layer, 1, enable_nested_tensor=False)
        self.pool = nn.Linear(width, 1)
        self.project = nn.Sequential(nn.LayerNorm(width*4), nn.Linear(width*4, 160), nn.GELU(), nn.Dropout(dropout), nn.Linear(160, embedding_size))
        self.prototypes = nn.Parameter(torch.randn(classes, embedding_size)*.05)
        self.log_scale = nn.Parameter(torch.tensor(2.77))

    def forward(self, x, mask=None, return_embedding=False):
        presence = x[:, :, 151:153] > .5
        left = self.hand(x[:, :, :63]) * presence[:, :, :1]
        right = self.hand(x[:, :, 63:126]) * presence[:, :, 1:2]
        wrists = x[:, :, 126:130].reshape(x.shape[0], x.shape[1], 2, 2)
        both = presence.all(-1, keepdim=True)
        delta = (wrists[:, :, 0]-wrists[:, :, 1])*both
        relation = torch.cat([x[:, :, 126:139], delta, delta.norm(dim=-1, keepdim=True), x[:, :, 151:154]], -1)
        motion = torch.zeros_like(x[:, :, :130])
        motion[:, 1:] = x[:, 1:, :130]-x[:, :-1, :130]
        stable = presence[:, 1:] & presence[:, :-1]
        for slot in (0, 1):
            motion[:, 1:, slot*63:(slot+1)*63] *= stable[:, :, slot:slot+1]
            motion[:, 1:, 126+slot*2:128+slot*2] *= stable[:, :, slot:slot+1]
        token = self.input(torch.cat([left, right, self.relation(relation), self.motion(motion)], -1))
        position = self.position if token.shape[1] == 64 else F.interpolate(self.position.transpose(1,2), size=token.shape[1], mode='linear', align_corners=False).transpose(1,2)
        valid = presence.any(-1)
        if mask is not None:
            valid = valid & mask.bool()
        safe = valid.clone()
        safe[~safe.any(1), 0] = True
        token = self.temporal(token + position)
        token = self.attention(token, src_key_padding_mask=~safe)
        weights = self.pool(token).squeeze(-1).masked_fill(~safe, -1e4).softmax(1)
        pieces = [(token*weights.unsqueeze(-1)).sum(1)]
        for indices in torch.tensor_split(torch.arange(token.shape[1], device=token.device), 3):
            values = token[:, indices]
            active = valid[:, indices].unsqueeze(-1)
            pieces.append((values*active).sum(1)/active.sum(1).clamp_min(1))
        embedding = F.normalize(self.project(torch.cat(pieces, -1)), dim=-1)
        logits = embedding @ F.normalize(self.prototypes, dim=-1).T * self.log_scale.exp().clamp(5, 40)
        return (logits, embedding) if return_embedding else logits


def supervised_contrastive(embedding, labels, temperature=.12):
    similarity = embedding @ embedding.T / temperature
    diagonal = torch.eye(len(labels), dtype=torch.bool, device=labels.device)
    positive = (labels[:, None] == labels[None, :]) & ~diagonal
    similarity = similarity.masked_fill(diagonal, -1e4)
    log_probability = similarity - torch.logsumexp(similarity, 1, keepdim=True)
    usable = positive.any(1)
    return -(log_probability*positive).sum(1)[usable].div(positive.sum(1)[usable]).mean()


def fuse_probabilities(context_logits, legacy_logits, supported_indices, weight, legacy_temperature):
    probability = context_logits.softmax(-1)
    indices = torch.as_tensor(supported_indices, device=probability.device)
    supported = probability.index_select(-1, indices)
    legacy = (legacy_logits/legacy_temperature).softmax(-1)
    result = probability.clone()
    result[:, indices] = (1-weight)*supported + weight*legacy*supported.sum(-1, keepdim=True)
    return result.clamp_min(1e-9).log()


class ContextFusion(nn.Module):
    def __init__(self, classes, model_config, legacy_model_config, supported_indices, fusion_weight=0., legacy_temperature=.65):
        super().__init__()
        from .sign_model import SignLSTM
        self.context = ContextSignModel(classes, **model_config)
        self.legacy = SignLSTM(len(supported_indices), **legacy_model_config)
        self.supported_indices = supported_indices
        self.fusion_weight = fusion_weight
        self.legacy_temperature = legacy_temperature

    def forward(self, x, mask=None):
        logits = self.context(x, mask)
        if self.fusion_weight == 0:
            return logits
        return fuse_probabilities(logits, self.legacy(x, mask), self.supported_indices, self.fusion_weight, self.legacy_temperature)
