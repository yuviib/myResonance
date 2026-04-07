from fastapi import APIRouter
from pydantic import BaseModel
from typing import List
from app.core.id_mapper import id_mapper
from app.core.faiss_store import faiss_store
from app.core.embedder import track_embedder
import logging

logger = logging.getLogger(__name__)

router = APIRouter()

class TrackSync(BaseModel):
    id: int
    title: str
    artist: str
    genre: str = "pop"

@router.post("/sync")
async def sync_tracks(tracks: List[TrackSync]):
    """
    Syncs track metadata from Rails to the ML Engine, generates embeddings,
    and indexes them in the neural Faiss HNSW index.
    """
    new_tracks_count = 0
    metadata_to_embed = []
    rails_ids_to_embed = []

    for track in tracks:
        # Check if we need to neural-index this track
        if id_mapper.get_faiss_id(track.id) is None:
            metadata_to_embed.append(f"{track.title} by {track.artist} (Genre: {track.genre})")
            rails_ids_to_embed.append(track.id)
            new_tracks_count += 1

    # 3. Batch process new embeddings
    if metadata_to_embed:
        logger.info(f"Generating content-aware embeddings for {len(metadata_to_embed)} new tracks...")
        embeddings = track_embedder.embed_tracks(metadata_to_embed)
        
        # Get next available Faiss IDs
        start_faiss_id = id_mapper.next_faiss_id()
        faiss_ids = list(range(start_faiss_id, start_faiss_id + len(rails_ids_to_embed)))
        
        # Add to Faiss Index
        faiss_store.add_vectors(embeddings, faiss_ids)
        
        # Save ID Mapping
        for f_id, r_id in zip(faiss_ids, rails_ids_to_embed):
            await id_mapper.add_mapping(f_id, r_id)
            
        logger.info(f"Neural Index updated: {len(metadata_to_embed)} tracks added to HNSW space.")

    return {
        "status": "success", 
        "total_synced": len(tracks), 
        "newly_indexed_count": new_tracks_count
    }
