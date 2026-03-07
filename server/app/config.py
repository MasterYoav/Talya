from __future__ import annotations

import os

from dotenv import load_dotenv


load_dotenv(override=True)


def getenv(name: str, default: str | None = None) -> str | None:
    value = os.getenv(name)
    if value is None or value.strip() == "":
        return default
    return value


DATABASE_URL = getenv(
    "TALYA_DATABASE_URL",
    "postgresql+psycopg://talya:talya@localhost:5432/talya",
)
if DATABASE_URL:
    DATABASE_URL = "".join(DATABASE_URL.split())
JWT_SECRET = getenv("TALYA_JWT_SECRET", "talya-dev-secret")
JWT_ISSUER = getenv("TALYA_JWT_ISSUER", "talya")
JWT_AUDIENCE = getenv("TALYA_JWT_AUDIENCE", "talya-client")
JWT_EXPIRES_MINUTES = int(getenv("TALYA_JWT_EXPIRES_MINUTES", "60"))
