from __future__ import annotations

from datetime import datetime

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
            now = datetime.now().isoformat()
            connection.execute(
                """
                INSERT INTO settings (key, value, updated_at)
                VALUES (?, ?, ?)
                ON CONFLICT(key) DO UPDATE SET
                    value = excluded.value,
                    updated_at = excluded.updated_at
                """,
                (key, value, now),
            )
            connection.commit()
        finally:
            connection.close()

    def list_settings(self) -> list[dict]:
        connection = create_connection()
        try:
            rows = connection.execute(
                "SELECT key, value, updated_at FROM settings"
            ).fetchall()
            return [
                {
                    "key": row["key"],
                    "value": row["value"],
                    "updated_at": row["updated_at"],
                }
                for row in rows
            ]
        finally:
            connection.close()

    def upsert_setting(self, key: str, value: str, updated_at: str) -> None:
        connection = create_connection()
        try:
            connection.execute(
                """
                INSERT INTO settings (key, value, updated_at)
                VALUES (?, ?, ?)
                ON CONFLICT(key) DO UPDATE SET
                    value = excluded.value,
                    updated_at = excluded.updated_at
                """,
                (key, value, updated_at),
            )
            connection.commit()
        finally:
            connection.close()
