from fastapi import FastAPI
import logging
from app.api import recommendations, sync

# Configure logging to show training metrics in the console
logging.basicConfig(level=logging.INFO)

app = FastAPI(
    title="Resonance ML Engine",
    description="Contextual Recommendation Engine for Resonance Music Platform",
    version="1.0.0"
)

# Include Routers
app.include_router(recommendations.router, prefix="/api/v1", tags=["recommendations"])
app.include_router(sync.router, prefix="/api/v1", tags=["sync"])

@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "resonance-ml"}

@app.get("/")
async def root():
    return {"message": "Welcome to the Resonance ML Engine. Use /api/v1 for endpoints."}
