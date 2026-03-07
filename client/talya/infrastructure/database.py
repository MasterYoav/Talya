from __future__ import annotations

import sqlite3
from pathlib import Path

from talya.infrastructure.migrations import run_migrations

_database_path: Path | None = None


def set_database_path(path: Path) -> None:
    global _database_path
    _database_path = path


def get_database_path() -> Path:
    if _database_path is not None:
        _database_path.parent.mkdir(parents=True, exist_ok=True)
        return _database_path
    project_root = Path(__file__).resolve().parents[2]
    data_dir = project_root / "data"
    data_dir.mkdir(exist_ok=True)
    return data_dir / "talya.db"


def create_connection() -> sqlite3.Connection:
    connection = sqlite3.connect(get_database_path())
    connection.row_factory = sqlite3.Row
    return connection


def initialize_database() -> None:
    connection = create_connection()
    try:
        connection.execute(
            """
            CREATE TABLE IF NOT EXISTS tasks (
                id TEXT PRIMARY KEY,
                title TEXT NOT NULL,
                section TEXT NOT NULL,
                is_completed INTEGER NOT NULL DEFAULT 0,
                created_at TEXT NOT NULL
            )
            """
        )
        connection.commit()
        connection.execute(
            """
            CREATE TABLE IF NOT EXISTS settings (
                key TEXT PRIMARY KEY,
                value TEXT NOT NULL
            )
            """
        )
        connection.commit()
        run_migrations(connection)
    finally:
        connection.close()
