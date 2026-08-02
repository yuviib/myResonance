# 🧠 Resonance ML Engine (FastAPI)

This repository contains the dedicated Machine Learning and Recommendation microservice for the **Resonance Music Platform**. It is built in Python to leverage the industry-standard data science ecosystem while decoupling heavy computational workloads from the main Ruby on Rails web server.

## 🏗️ Architecture & Engineering Highlights

This microservice acts as the "brain" of the platform, transforming raw user telemetry into high-fidelity, contextual music discovery.

### 1. Asynchronous API (FastAPI)
Built on **FastAPI** for maximum throughput. It provides automatic OpenAPI/Swagger documentation and handles concurrent requests efficiently. The Rails app acts as the client, fetching real-time recommendations based on active user sessions.

### 2. Vector Embeddings & Similarity Search
Rather than relying on basic SQL filtering, this engine utilizes dense vector representations of tracks. By integrating with vector databases (like FAISS/Qdrant), it executes nearest-neighbor searches in sub-milliseconds to find acoustically and semantically similar tracks.

### 3. Sequence-Aware Recommendation (SASRec)
The engine doesn't just look at what a user liked; it looks at *what they just played*. By analyzing the localized trajectory of a user's current session (skips vs. full listens), the AI attempts to predict the next best track in the sequence.

### 4. Offline Evaluation Infrastructure
Includes an offline evaluation pipeline (`scripts/evaluate_model.py`) that calculates rigorous ranking metrics (like **Hit Rate / HR@10**) against random baselines, proving the statistical efficacy of the neural network before deployment.

## 🛠️ Technology Stack
* **Web Framework:** FastAPI (Uvicorn)
* **Machine Learning:** PyTorch, Sentence-Transformers
* **Vector Search:** FAISS / Qdrant
* **Package Management:** `uv` (Lightning-fast Python package installer)

## 🚀 Local Development

1. **Environment Setup:**
   It is highly recommended to use `uv` for dependency management.
   ```bash
   pip install uv
   uv sync
   ```

2. **Start the Development Server:**
   ```bash
   uv run uvicorn app.main:app --reload --port 8000
   ```
   The interactive API documentation will be automatically generated and available at `http://localhost:8000/docs`.

3. **Run Model Evaluation:**
   To test the engine's accuracy against existing telemetry:
   ```bash
   uv run python scripts/evaluate_model.py
   ```

---
*This service is designed to run in parallel with the `resonance-rails` web application. See the root repository documentation for docker-compose instructions.*
