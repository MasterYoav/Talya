from __future__ import annotations

from talya.infrastructure.database import create_connection


class SettingsRepository:
    def get(self, key: str) -> str | None:
        connection = create_connection()
        try:
            row = connection.execute(
                "SELECT value FROM settings WHERE key = ?",
                (key,),
            ).fetchone()
            if row is None:
                return None
            return row["value"]
        finally:
            connection.close()

    def set(self, key: str, value: str) -> None:
        connection = create_connection()
        try:
            connection.execute(
                """
                INSERT INTO settings (key, value)
                VALUES (?, ?)
                ON CONFLICT(key) DO UPDATE SET value = excluded.value
                """,
                (key, value),
            )
            connection.commit()
        finally:
            connection.close()
