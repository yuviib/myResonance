import faiss
import numpy as np
import os
import logging

logger = logging.getLogger(__name__)


class FaissStore:
    def __init__(self, dimension=64, index_path="data/resonance.index"):
        self.dimension = dimension
        self.index_path = index_path
        self.index = None       # IndexIDMap2 wrapping FlatL2 — used for ANN search
        self.flat_index = None  # Raw IndexFlatL2 — used for reconstruct_n
        self._initialize_index()

    def _initialize_index(self):
        if os.path.exists(self.index_path):
            try:
                loaded = faiss.read_index(self.index_path)
                # Unwrap IDMap2 to get the underlying flat index for reconstruction
                self.index = loaded
                self.flat_index = faiss.downcast_index(loaded.index)
                logger.info(f"Loaded existing Faiss index with {self.index.ntotal} vectors")
                return
            except Exception as e:
                logger.error(f"Failed to load Faiss index: {e}. Reinitializing.")

        self._create_new_index()

    def _create_new_index(self):
        raw_index = faiss.IndexFlatL2(self.dimension)
        self.flat_index = raw_index
        self.index = faiss.IndexIDMap2(raw_index)
        logger.info(f"Initialized new Faiss IndexIDMap2 + FlatL2 (dim={self.dimension})")

    def add_vectors(self, vectors, ids):
        """
        vectors: np.array of shape (n, dimension)
        ids: np.array of shape (n,) — these are the Faiss IDs (0-based)
        """
        if not isinstance(vectors, np.ndarray):
            vectors = np.array(vectors, dtype='float32')
        else:
            vectors = vectors.astype('float32')

        if not isinstance(ids, np.ndarray):
            ids = np.array(ids, dtype='int64')
        else:
            ids = ids.astype('int64')

        self.index.add_with_ids(vectors, ids)
        self.save()

    def search(self, query_vector, top_k=10):
        if not isinstance(query_vector, np.ndarray):
            query_vector = np.array([query_vector], dtype='float32')

        if len(query_vector.shape) == 1:
            query_vector = np.expand_dims(query_vector, axis=0)

        query_vector = query_vector.astype('float32')
        distances, indices = self.index.search(query_vector, top_k)
        return indices[0].tolist(), distances[0].tolist()

    def reconstruct_all(self, item_num):
        """
        Reconstruct all vectors for IDs 0..item_num-1 via the underlying flat index.
        IndexIDMap2 does not support reconstruct_n directly; the raw FlatL2 does.
        """
        return self.flat_index.reconstruct_n(0, item_num)

    def save(self):
        try:
            os.makedirs(os.path.dirname(self.index_path), exist_ok=True)
            faiss.write_index(self.index, self.index_path)
            logger.info("Persisted Faiss index to disk")
        except Exception as e:
            logger.error(f"Failed to save Faiss index: {e}")


faiss_store = FaissStore()