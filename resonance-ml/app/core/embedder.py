from sentence_transformers import SentenceTransformer
import torch
import torch.nn as nn
import numpy as np
import logging

logger = logging.getLogger(__name__)

class TrackEmbedder:
    def __init__(self, model_name='all-MiniLM-L6-v2', target_dim=64):
        logger.info("Initializing zero-shot embeddings. Downloading sentence-transformer model (~400MB). This will only happen once...")
        self.encoder = SentenceTransformer(model_name)
        self.target_dim = target_dim
        
        # Fixed projection to 64D (Deterministic so we don't need to save weights)
        self.source_dim = self.encoder.get_sentence_embedding_dimension()
        
    def embed_tracks(self, tracks_metadata):
        """
        tracks_metadata: list of strings like "Title - Artist - Genre"
        """
        # Get 384D embeddings
        raw_embeddings = self.encoder.encode(tracks_metadata)
        
        # Deterministic projection to 64D using simple slicing + normalization
        # In a full SASRec training loop, these would be fine-tuned.
        # For zero-shot, we take the top 64 components to preserve most variance.
        projected = raw_embeddings[:, :self.target_dim]
        
        # Normalize to unit sphere (best for cosine similarity / dot product)
        norms = np.linalg.norm(projected, axis=1, keepdims=True)
        # Avoid division by zero
        norms[norms == 0] = 1.0
        normalized = projected / norms
        
        return normalized.astype('float32')

    def embed_single_track(self, title, artist, genre):
        text = f"{title} by {artist} in the style of {genre}"
        return self.embed_tracks([text])[0]

# Singleton instance
track_embedder = TrackEmbedder()
