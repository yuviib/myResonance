# Resonance ML Engine Guide

This document outlines the Python-based Machine Learning microservice for Resonance.

## Tech Stack
- **Framework**: FastAPI (for high-performance, asynchronous REST APIs)
- **Package Manager**: `uv` (for lightning-fast dependency resolution)
- **Machine Learning**: `PyTorch`, `scikit-learn`, `pandas`, `numpy`
- **Vector Search**: `Qdrant` (Client) and `FAISS` (CPU)
- **Embeddings**: `sentence-transformers`

## Directory Structure
- `app/api/`: Contains the FastAPI routers and endpoint definitions (e.g., `/recommendations`, `/sync`).
- `app/core/`: Contains core configuration, database connections, and model loading logic.
- `app/schemas/`: Pydantic models for data validation and OpenAPI schema generation.
- `scripts/`: Utility scripts for database seeding, embedding generation, or cron jobs.

## Core Concepts

### Embeddings and Vector Search
The core value proposition of `resonance-ml` is its ability to understand the "context" of music. 
Instead of relying on simple genre tagging, the engine uses `sentence-transformers` to convert track metadata (and potentially audio features) into dense mathematical vectors (embeddings).

These vectors are stored in a Vector Database (like Qdrant or FAISS). When a user requests recommendations based on a specific track, the engine converts the target track into a vector and performs a Nearest Neighbor search to find the mathematically closest tracks in the vector space.

### FastAPI Integration
FastAPI automatically generates interactive API documentation. When the service is running, you can view the available endpoints and test them directly from your browser by navigating to:
`http://localhost:8000/docs`

## Adding New Endpoints
To add a new ML capability:
1. Define the Request/Response schema in `app/schemas/`.
2. Implement the logic in `app/api/` (creating a new router if necessary).
3. Include the router in `app/main.py`.
