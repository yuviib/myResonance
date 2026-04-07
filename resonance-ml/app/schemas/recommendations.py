from pydantic import BaseModel
from typing import List, Optional

class Interaction(BaseModel):
    track_id: int
    genre: Optional[str] = "pop"
    action: str  # 'play', 'skip', 'like'

class RecommendationRequest(BaseModel):
    user_id: Optional[int] = None
    history: List[Interaction]
    limit: int = 10

class RecommendationResponse(BaseModel):
    recommended_track_ids: List[int]
    vibe_vector: List[float]
    vibe_shift_detected: bool
    context_message: str
