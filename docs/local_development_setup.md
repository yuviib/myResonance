# Local Development Setup

Follow these instructions to spin up the Resonance platform on your local machine for development.

## Prerequisites
Ensure you have the following installed on your system:
- **Docker** and **Docker Compose**
- **Ruby** 3.x (We recommend using `rbenv` or `rvm`)
- **Python** 3.12+
- **uv** (Python package installer: `pip install uv`)

---

## 1. Database Infrastructure

Both the Rails app and the ML service rely on PostgreSQL. We use Docker Compose to manage this dependency.

1. From the root of the project (`myResonance/`), run:
   ```bash
   docker-compose up -d
   ```
2. This will start a PostgreSQL instance on port `5432`. Ensure no local Postgres instance is already occupying this port.

---

## 2. Rails Application Setup

Open a new terminal window and navigate to the Rails directory.

```bash
cd resonance-rails
```

1. **Install Dependencies**:
   ```bash
   bundle install
   ```
2. **Database Creation & Migrations**:
   ```bash
   rails db:setup
   ```
   *(Note: `db:setup` creates the database, loads the schema, and runs the seed data).*
3. **Start the Server**:
   ```bash
   bin/dev
   ```
   This command starts Puma (the web server) alongside Tailwind's file watcher. The application will be available at `http://localhost:3000`.

---

## 3. ML Engine Setup

Open a separate terminal window and navigate to the ML directory.

```bash
cd resonance-ml
```

1. **Install Dependencies via `uv`**:
   `uv` is extremely fast and manages the virtual environment for you.
   ```bash
   uv sync
   ```
2. **Start the FastAPI Server**:
   ```bash
   uv run uvicorn app.main:app --reload --port 8000
   ```
   The `--reload` flag ensures the server restarts automatically when you make code changes. 
3. **Verify**:
   Navigate to `http://localhost:8000/docs` in your browser. You should see the Swagger UI detailing the Resonance ML endpoints.

---

## Troubleshooting

- **Database Connection Issues**: Ensure your `.env` files (if present) or local environment variables correctly specify `postgres` as the user and match the password defined in `docker-compose.yml`.
- **Port Conflicts**: If port 3000 or 8000 are in use, you can specify different ports:
  - Rails: `bin/dev -p 3001`
  - FastAPI: `uv run uvicorn app.main:app --reload --port 8001` (Remember to update the Rails configuration to point to the new ML port).
