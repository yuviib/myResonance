# 💎 Resonance Web Application (Rails)

This repository contains the core Ruby on Rails backend and frontend for the **Resonance Music Platform**. It is responsible for user management, library state, interaction telemetry, and serving the modern web interface.

## 🏗️ Architecture & Engineering Highlights

This application is designed to demonstrate modern, full-stack Ruby on Rails practices without relying on a heavy JavaScript framework (like React or Vue).

### 1. Persistent Audio Engine (Hotwire & Stimulus)
Traditional Rails apps suffer from full-page reloads, which would interrupt audio playback. By deeply integrating **Turbo Drive** and a 400+ line **Stimulus.js** player controller (`player_controller.js`), this application maintains persistent audio state while the user navigates seamlessly across different routes (playlists, artist pages, discovery feeds).

### 2. Telemetry & Neural Session Tracking
The frontend meticulously tracks user engagement (e.g., skips, completion percentages, playback durations). It batches and sends this telemetry to the `InteractionsController`, which groups them into "Neural Sessions" (30-minute idle heuristic). This high-quality data is the lifeblood of the `resonance-ml` microservice.

### 3. Service-Oriented Architecture
Instead of bloating the monolith with heavy data science libraries, the Rails app communicates with the Python ML microservice via clean REST API boundaries (e.g., `RecommendationsController` and `MlClient`). It features robust fallback mechanisms in case the AI engine is unreachable or lacks enough confidence.

## 🛠️ Technology Stack
* **Framework:** Ruby on Rails (MVC)
* **Frontend:** Hotwire (Turbo + Stimulus), TailwindCSS
* **Database:** PostgreSQL (ActiveRecord ORM)
* **API Integration:** HTTParty / Net::HTTP for microservice communication

## 🚀 Local Development

1. **Install Dependencies:**
   ```bash
   bundle install
   yarn install # or npm install if applicable
   ```

2. **Database Setup:**
   Ensure PostgreSQL is running, then execute:
   ```bash
   rails db:create
   rails db:migrate
   rails db:seed
   ```

3. **Start the Server:**
   ```bash
   bin/dev
   ```
   The application will be available at `http://localhost:3000`.

---
*This service is designed to run in parallel with the `resonance-ml` Python engine. See the root repository documentation for docker-compose instructions.*
