# Architecture Overview

Resonance utilizes a microservices architecture pattern, splitting the platform into two distinct but collaborative services: a monolithic Rails backend and an optimized Machine Learning inference service.

## Core Components

### 1. Resonance Rails (The Core Platform)
- **Framework**: Ruby on Rails 8
- **Role**: Serves as the primary source of truth for the application state. It handles:
  - User authentication and authorization (via Devise).
  - Library management (Tracks, Albums, Artists, Playlists).
  - User interactions (Likes, Listens, Queue management).
  - Web interface rendering (utilizing Hotwire/Turbo for SPA-like responsiveness without complex JS frameworks).

### 2. Resonance ML (The Intelligence Engine)
- **Framework**: FastAPI (Python 3.12+)
- **Role**: A dedicated microservice responsible for generating contextual recommendations.
  - Generates vector embeddings for tracks using `sentence-transformers`.
  - Performs high-speed similarity searches utilizing `Qdrant` and `FAISS`.
  - Exposes RESTful endpoints (`/api/v1/...`) that the Rails application consumes.

### 3. PostgreSQL Database
- **Role**: Both services connect to a shared PostgreSQL database. Rails manages the schema and migrations for core business logic, while the ML service reads track metadata and user interactions to feed its recommendation algorithms.

## Inter-Service Communication

The communication between the two services is strictly unidirectional for business logic:
1. **Rails -> ML**: When a user requests a recommendation (e.g., "songs similar to X"), the Rails app makes an HTTP GET request to the ML engine's FastAPI endpoint.
2. **ML -> DB**: The ML engine reads the necessary metadata directly from the shared database, computes the similarity using its vector store, and returns the Track IDs to Rails.
3. **Rails -> Client**: Rails hydrates those Track IDs into full Active Record models and renders them to the user.

## Why this Architecture?

- **Separation of Concerns**: Web development and ML development have vastly different ecosystems. Forcing ML into Ruby or forcing a complex web app into Python can lead to compromises. This architecture allows each language to do what it does best.
- **Scalability**: Vector similarity search is computationally expensive. By isolating it in a microservice, the ML engine can be scaled vertically (more CPU/RAM for FAISS) or horizontally independently of the web frontend, preventing heavy ML queries from blocking web requests.
