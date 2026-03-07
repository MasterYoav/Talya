from __future__ import annotations

from fastapi import FastAPI

from .models import Base
from .database import engine
from .routes.auth import router as auth_router
from .routes.sync import router as sync_router


def create_app() -> FastAPI:
    app = FastAPI(title="Talya API", version="0.1.0")
    Base.metadata.create_all(bind=engine)
    app.include_router(auth_router)
    app.include_router(sync_router)
    return app


app = create_app()
