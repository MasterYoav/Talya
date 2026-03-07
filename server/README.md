# Talya Server

Backend API built with FastAPI and PostgreSQL.

## Quick start (dev)

Use Python 3.12 (recommended). Python 3.14 is not supported by SQLAlchemy yet.

1. Create a PostgreSQL database named `talya`.
2. Set env vars (or use a `.env` file):

```bash
export TALYA_DATABASE_URL="postgresql+psycopg://talya:talya@localhost:5432/talya"
export TALYA_JWT_SECRET="change-me"
```

To generate a strong JWT secret:

```bash
python -c "import secrets; print(secrets.token_urlsafe(48))"
```

3. Install dependencies:

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

4. Run:

```bash
uvicorn app.main:app --reload
```

## OAuth note

OAuth tokens are expected to be validated by the client today. The server
accepts provider identity payloads and issues a JWT. Add token verification
against Google/GitHub before production.

## Sync API

`POST /sync/merge` accepts lists, tasks, and settings using last-write-wins and
returns the merged server state.
