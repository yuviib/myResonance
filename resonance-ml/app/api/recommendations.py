import asyncio
import logging

import faiss
import numpy as np
import torch
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from typing import List, Optional

from app.core.models.sasrec import SASRec
from app.core.faiss_store import faiss_store
from app.core.id_mapper import id_mapper
from app.core.training_service import get_trainer

logger = logging.getLogger(__name__)
router = APIRouter()

# Auto-detect hardware acceleration; fall back to CPU for standard instances
device = torch.device(
    'cuda' if torch.cuda.is_available()
    else 'mps' if torch.backends.mps.is_available()
    else 'cpu'
)
logger.info(f"ML Inference Device: {device}")

# WSL2 environments exhibit high context-switching overhead with shared L3 caches;
# restricting to a single thread per process prevents thread contention during ANN searches.
torch.set_num_threads(1)
faiss.omp_set_num_threads(1)

_model = None
_model_lock = asyncio.Lock()

async def get_model():
    """
    Singleton loader with thread-safe double-checked locking to ensure
    atomic initialization of the SASRec weights and latent space alignment.
    """
    global _model
    if _model is not None:
        return _model

    async with _model_lock:
        if _model is not None:
            return _model

        item_num = id_mapper.next_faiss_id()
        model_dim = 64
        # Slotted at 1000 items minimum to ensure weight matrices are valid before the first import
        model = SASRec(item_num=max(1000, item_num), embed_dim=model_dim).to(device)

        if item_num > 0:
            logger.info("Aligning SASRec latent space with MiniLM embeddings...")
            with torch.no_grad():
                all_vectors = faiss_store.reconstruct_all(item_num)
                all_vectors = np.nan_to_num(all_vectors)

                # SASRec reserves index 0 for padding; items are 1-indexed for compatibility with causal masking.
                vec_tensor = torch.from_numpy(all_vectors).to(device)
                model.item_emb.weight[1:item_num + 1] = vec_tensor

        model.eval()
        _model = model

    return _model

class Interaction(BaseModel):
    track_id: int
    action: str
    completion_percentage: Optional[float] = 1.0

class RecommendationRequest(BaseModel):
    user_id: Optional[int] = None
    history: List[Interaction]
    limit: int = Field(default=10, ge=1, le=100) # Enforce resource bounds

@router.post("/recommendations")
async def get_recommendations(req: RecommendationRequest):
    """
    Translates raw listening history into sequential embeddings to perform 
    Approximate Nearest Neighbor (ANN) search in the track vector space.
    """
    try:
        # Translate Rails IDs to internal 1-based indexing for the transformer encoder
        history_ids = []
        for interact in req.history:
            f_id = id_mapper.get_faiss_id(interact.track_id)
            if f_id is not None:
                history_ids.append(f_id + 1)

        # SASRec requires a fixed-length window; right-aligned and left-padded for causal attention.
        max_len = 15
        history_ids = history_ids[-max_len:]
        padding = [0] * (max_len - len(history_ids))
        seq = torch.LongTensor([padding + history_ids]).to(device)

        model = await get_model()
        with torch.no_grad():
            predicted_vector = model(seq)
            predicted_vector_np = predicted_vector.cpu().numpy().astype('float32')

        # Retrieve more candidates than requested to allow for downstream filtering of recently heard tracks
        indices, distances = faiss_store.search(predicted_vector_np, top_k=req.limit + 10)

        history_track_ids = {h.track_id for h in req.history}
        recommended_rails_ids = []

        for idx in indices:
            if idx == -1: continue # Faiss sentinel for empty results
            
            r_id = id_mapper.get_rails_id(int(idx))
            if r_id is None or r_id in history_track_ids:
                continue

            recommended_rails_ids.append(r_id)
            if len(recommended_rails_ids) >= req.limit:
                break

        return {
            "recommended_track_ids": recommended_rails_ids,
            "context_message": _generate_context_message(req.history),
            "engine": "SASRec-Neural",
        }

    except Exception as e:
        logger.error(f"Inference pipeline failure: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail="Recommendation engine internal failure")

def _generate_context_message(history: List[Interaction]) -> str:
    """Rationale: Providing a feedback loop in the UI reduces perceived latency by the user."""
    if not history:
        return "Picking up the pace..."
    if history[-1].action == 'like':
        return "Evolving from your latest like."
    return "Deep-diving into your sequential rhythm."

@router.post("/train")
async def trigger_training(data_path: str = "data/interactions.csv", epochs: int = 1):
    """
    Explicit trigger for BPR (Bayesian Personalized Ranking) fine-tuning.
    Rationale: Incremental training allows the model to adapt to new tracks without a full retraining cycle.
    """
    if epochs < 1 or epochs > 50:
        raise HTTPException(status_code=400, detail="Epoch range must be 1-50")
        
    model = await get_model()
    trainer = get_trainer(model, device)
    success = trainer.fine_tune(data_path, epochs=epochs)

    return {
        "status": "success" if success else "failed",
        "engine": "SASRec-Incremental",
        "epochs": epochs,
    }
)
    trainer = get_trainer(model, device)
    success = trainer.fine_tune(data_path, epochs=epochs)

    return {
        "status": "success" if success else "failed",
        "engine": "SASRec-Incremental",
        "epochs": epochs,
    }