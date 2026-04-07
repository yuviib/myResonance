import torch
import torch.nn as nn
import numpy as np
import os
import logging

logger = logging.getLogger(__name__)


class SASRec(nn.Module):
    def __init__(self, item_num, embed_dim=64, max_len=15, num_blocks=2, num_heads=1, dropout_rate=0.2):
        super(SASRec, self).__init__()
        self.item_num = item_num
        self.embed_dim = embed_dim
        self.max_len = max_len

        self.item_emb = nn.Embedding(item_num + 1, embed_dim, padding_idx=0)
        self.pos_emb = nn.Embedding(max_len, embed_dim)
        self.emb_dropout = nn.Dropout(p=dropout_rate)

        self.attention_layers = nn.ModuleList()
        self.forward_layers = nn.ModuleList()
        self.layer_norms = nn.ModuleList()

        for _ in range(num_blocks):
            new_attn_layer = nn.MultiheadAttention(embed_dim, num_heads, dropout=dropout_rate, batch_first=True)
            self.attention_layers.append(new_attn_layer)

            new_ff_layer = nn.Sequential(
                nn.Linear(embed_dim, embed_dim),
                nn.ReLU(),
                nn.Dropout(p=dropout_rate),
                nn.Linear(embed_dim, embed_dim)
            )
            self.forward_layers.append(new_ff_layer)

            self.layer_norms.append(nn.LayerNorm(embed_dim))

    def forward(self, log_seqs):
        seqs = self.item_emb(log_seqs)

        positions = torch.arange(log_seqs.shape[1], device=log_seqs.device).unsqueeze(0).repeat(log_seqs.shape[0], 1)
        seqs += self.pos_emb(positions)
        seqs = self.emb_dropout(seqs)

        timeline_mask = (log_seqs == 0).to(log_seqs.device)  # (batch, seq_len), True = padding

        seq_len = log_seqs.shape[1]
        attn_mask = torch.triu(torch.ones((seq_len, seq_len), device=log_seqs.device), diagonal=1).bool()

        for i in range(len(self.attention_layers)):
            # Zero padding positions before layer norm to prevent contaminating normalization statistics
            seqs = seqs * (~timeline_mask).unsqueeze(-1).float()
            seqs_norm = self.layer_norms[i](seqs)

            # key_padding_mask omitted intentionally: combining it with a causal attn_mask on
            # left-padded sequences causes softmax(0/0) -> NaN gradients. Padding is suppressed
            # by zeroing seqs directly before and after each block instead.
            mha_outputs, _ = self.attention_layers[i](
                seqs_norm, seqs_norm, seqs_norm,
                attn_mask=attn_mask
            )
            seqs = seqs + mha_outputs

            # Re-zero after MHA residual so the feed-forward doesn't process dirty padding slots
            # (MHA can write into padding positions since key_padding_mask is removed)
            seqs = seqs * (~timeline_mask).unsqueeze(-1).float()

            seqs_norm = self.layer_norms[i](seqs)
            ff_outputs = self.forward_layers[i](seqs_norm)
            seqs = seqs + ff_outputs

        # Final zero to guarantee the returned last-position vector is never a padding slot
        seqs = seqs * (~timeline_mask).unsqueeze(-1).float()

        logger.debug(f"[SASRec] Forward complete. Output shape: {seqs[:, -1, :].shape}")
        return seqs[:, -1, :]


def load_sasrec_model(item_num, path=None, device='cpu'):
    model = SASRec(item_num)
    if path and os.path.exists(path):
        model.load_state_dict(torch.load(path, map_location=device))
    model.to(device)
    model.eval()
    return model


from sentence_transformers import SentenceTransformer


class TrackEmbedder:
    def __init__(self, model_name='all-MiniLM-L6-v2', target_dim=64):
        logger.info("Initializing TrackEmbedder. Downloading sentence-transformer model if not cached...")
        self.encoder = SentenceTransformer(model_name)
        self.target_dim = target_dim
        self.source_dim = self.encoder.get_sentence_embedding_dimension()  # 384

        # Deterministic projection matrix (fixed seed, not learned)
        # QR decomposition gives an orthonormal basis that preserves maximum variance
        # across all 384 dimensions — far superior to naive slicing
        rng = np.random.RandomState(42)
        raw = rng.randn(self.source_dim, self.target_dim).astype('float32')
        q, _ = np.linalg.qr(raw)
        self.projection = q[:, :self.target_dim]  # (384, 64)

    def embed_tracks(self, tracks_metadata):
        """
        tracks_metadata: list of strings like "Title - Artist - Genre"
        Returns normalized (n, 64) float32 array.
        """
        raw_embeddings = self.encoder.encode(tracks_metadata, convert_to_numpy=True)  # (n, 384)

        # Project 384D -> 64D using full orthonormal projection
        projected = raw_embeddings @ self.projection  # (n, 64)

        # Normalize to unit sphere for cosine similarity / dot-product compatibility
        norms = np.linalg.norm(projected, axis=1, keepdims=True)
        norms[norms == 0] = 1.0
        normalized = projected / norms

        return normalized.astype('float32')

    def embed_single_track(self, title, artist, genre):
        text = f"{title} by {artist} in the style of {genre}"
        return self.embed_tracks([text])[0]


# Singleton instance
track_embedder = TrackEmbedder()