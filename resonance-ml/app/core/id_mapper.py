import json
import os
import asyncio
import logging

logger = logging.getLogger(__name__)

# Service responsible for maintaining the strictly coupled mapping between 
# Rails database IDs and FAISS vector indices.
# Rationale: FAISS requires 0-based integer indexing, whereas Rails IDs 
# are non-sequential primary keys. A bi-directional mapping is required 
# to translate inference results back into application entities.
class IDMapper:
    def __init__(self, storage_path="data/id_mappings.json"):
        self.storage_path = storage_path
        self._lock = asyncio.Lock()
        self._faiss_to_rails = {}
        self._rails_to_faiss = {}
        self._next_id = 0
        self._load_from_disk()

    def _load_from_disk(self):
        """Rationale: Atomic load at startup ensures the microservice state is synchronized with the Rails DB."""
        if not os.path.exists(self.storage_path):
            return

        try:
            with open(self.storage_path, 'r') as f:
                data = json.load(f)
                self._faiss_to_rails = {int(k): v for k, v in data.get("faiss_to_rails", {}).items()}
                self._rails_to_faiss = {int(k): v for k, v in data.get("rails_to_faiss", {}).items()}
                
                # Pre-calculate next ID to ensure O(1) allocation during ingestion
                if self._faiss_to_rails:
                    self._next_id = max(self._faiss_to_rails.keys()) + 1
            
            logger.info(f"Synchronized {len(self._faiss_to_rails)} ID mappings.")
        except (json.JSONDecodeError, OSError) as e:
            logger.error(f"Critical failure loading ID mappings: {e}")

    async def add_mapping(self, faiss_id: int, rails_id: int):
        """Atomic update to ensure bi-directional consistency under concurrent ingestion."""
        async with self._lock:
            self._faiss_to_rails[faiss_id] = rails_id
            self._rails_to_faiss[rails_id] = faiss_id
            self._next_id = max(self._next_id, faiss_id + 1)
            
            # TODO: Consider debouncing saves if ingestion frequency increases
            self._save_to_disk()

    def get_rails_id(self, faiss_id: int):
        return self._faiss_to_rails.get(faiss_id)

    def get_faiss_id(self, rails_id: int):
        return self._rails_to_faiss.get(rails_id)

    def next_faiss_id(self):
        return self._next_id

    def _save_to_disk(self):
        """Rationale: Synchronous write is acceptable for this low-volume metadata to guarantee durability."""
        try:
            with open(self.storage_path + ".tmp", 'w') as f:
                json.dump({
                    "faiss_to_rails": self._faiss_to_rails,
                    "rails_to_faiss": self._rails_to_faiss
                }, f)
            os.replace(self.storage_path + ".tmp", self.storage_path)
        except OSError as e:
            logger.error(f"Persistence failure for ID mappings: {e}")

id_mapper = IDMapper()
