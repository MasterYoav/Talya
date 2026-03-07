from __future__ import annotations

import sqlite3


def ensure_schema_version_table(connection: sqlite3.Connection) -> None:
    connection.execute(
        """
        CREATE TABLE IF NOT EXISTS schema_version (
            version INTEGER NOT NULL
        )
        """
    )

    row = connection.execute("SELECT version FROM schema_version LIMIT 1").fetchone()
    if row is None:
        connection.execute("INSERT INTO schema_version (version) VALUES (1)")
        connection.commit()


def get_schema_version(connection: sqlite3.Connection) -> int:
    row = connection.execute("SELECT version FROM schema_version LIMIT 1").fetchone()
    if row is None:
        return 1
    return int(row["version"])


def set_schema_version(connection: sqlite3.Connection, version: int) -> None:
    connection.execute("UPDATE schema_version SET version = ?", (version,))
    connection.commit()


def migrate_to_v2(connection: sqlite3.Connection) -> None:
    existing_columns = {
        row["name"] for row in connection.execute("PRAGMA table_info(tasks)").fetchall()
    }

    if "notes" not in existing_columns:
        connection.execute("ALTER TABLE tasks ADD COLUMN notes TEXT")

    if "due_date" not in existing_columns:
        connection.execute("ALTER TABLE tasks ADD COLUMN due_date TEXT")

    if "reminder_at" not in existing_columns:
        connection.execute("ALTER TABLE tasks ADD COLUMN reminder_at TEXT")

    if "updated_at" not in existing_columns:
        connection.execute("ALTER TABLE tasks ADD COLUMN updated_at TEXT")

    connection.commit()
    set_schema_version(connection, 2)


def migrate_to_v3(connection: sqlite3.Connection) -> None:
    existing_columns = {
        row["name"] for row in connection.execute("PRAGMA table_info(tasks)").fetchall()
    }

    if "reminder_fired_at" not in existing_columns:
        connection.execute("ALTER TABLE tasks ADD COLUMN reminder_fired_at TEXT")

    connection.commit()
    set_schema_version(connection, 3)


def run_migrations(connection: sqlite3.Connection) -> None:
    ensure_schema_version_table(connection)
    version = get_schema_version(connection)

    if version < 2:
        migrate_to_v2(connection)
        version = 2

    if version < 3:
        migrate_to_v3(connection)
