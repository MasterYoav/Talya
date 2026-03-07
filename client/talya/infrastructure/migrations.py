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
        version = 3

    if version < 4:
        migrate_to_v4(connection)
        version = 4

    if version < 5:
        migrate_to_v5(connection)
        version = 5

    if version < 6:
        migrate_to_v6(connection)


def migrate_to_v4(connection: sqlite3.Connection) -> None:
    connection.execute(
        """
        CREATE TABLE IF NOT EXISTS lists (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            icon TEXT NOT NULL,
            color TEXT NOT NULL,
            position INTEGER NOT NULL,
            list_type TEXT NOT NULL,
            is_system INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
        )
        """
    )

    existing_columns = {
        row["name"] for row in connection.execute("PRAGMA table_info(tasks)").fetchall()
    }
    if "list_id" not in existing_columns:
        connection.execute("ALTER TABLE tasks ADD COLUMN list_id TEXT")

    rows = connection.execute("SELECT COUNT(1) as count FROM lists").fetchone()
    if rows and rows["count"] == 0:
        from datetime import datetime
        from uuid import uuid4

        now = datetime.now().isoformat()
        defaults = [
            ("Inbox", "⌂", "#9aa1ad", 0, "inbox", 1),
            ("Today", "•", "#9aa1ad", 1, "today", 1),
            ("Upcoming", "◷", "#9aa1ad", 2, "upcoming", 1),
            ("Settings", "⚙", "#9aa1ad", 100, "settings", 1),
            ("Profile", "◉", "#9aa1ad", 101, "profile", 1),
        ]
        for name, icon, color, position, list_type, is_system in defaults:
            list_id = str(uuid4())
            connection.execute(
                """
                INSERT INTO lists (id, name, icon, color, position, list_type, is_system, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    list_id,
                    name,
                    icon,
                    color,
                    position,
                    list_type,
                    is_system,
                    now,
                    now,
                ),
            )

        sections = [
            row["section"]
            for row in connection.execute(
                "SELECT DISTINCT section FROM tasks WHERE section IS NOT NULL"
            ).fetchall()
        ]
        for section in sections:
            row = connection.execute(
                "SELECT id FROM lists WHERE name = ? LIMIT 1", (section,)
            ).fetchone()
            if row is None:
                list_id = str(uuid4())
                connection.execute(
                    """
                    INSERT INTO lists (id, name, icon, color, position, list_type, is_system, created_at, updated_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """,
                    (
                        list_id,
                        section,
                        "•",
                        "#9aa1ad",
                        10,
                        "user",
                        0,
                        now,
                        now,
                    ),
                )

        for row in connection.execute("SELECT id, section FROM tasks").fetchall():
            list_row = connection.execute(
                "SELECT id FROM lists WHERE name = ? LIMIT 1", (row["section"],)
            ).fetchone()
            if list_row:
                connection.execute(
                    "UPDATE tasks SET list_id = ? WHERE id = ?",
                    (list_row["id"], row["id"]),
                )

    connection.commit()
    set_schema_version(connection, 4)


def migrate_to_v5(connection: sqlite3.Connection) -> None:
    existing_columns = {
        row["name"] for row in connection.execute("PRAGMA table_info(lists)").fetchall()
    }
    if "is_pinned" not in existing_columns:
        connection.execute("ALTER TABLE lists ADD COLUMN is_pinned INTEGER NOT NULL DEFAULT 0")
    connection.commit()
    set_schema_version(connection, 5)


def migrate_to_v6(connection: sqlite3.Connection) -> None:
    task_columns = {
        row["name"] for row in connection.execute("PRAGMA table_info(tasks)").fetchall()
    }
    if "is_deleted" not in task_columns:
        connection.execute(
            "ALTER TABLE tasks ADD COLUMN is_deleted INTEGER NOT NULL DEFAULT 0"
        )
    if "deleted_at" not in task_columns:
        connection.execute("ALTER TABLE tasks ADD COLUMN deleted_at TEXT")

    list_columns = {
        row["name"] for row in connection.execute("PRAGMA table_info(lists)").fetchall()
    }
    if "is_deleted" not in list_columns:
        connection.execute(
            "ALTER TABLE lists ADD COLUMN is_deleted INTEGER NOT NULL DEFAULT 0"
        )
    if "deleted_at" not in list_columns:
        connection.execute("ALTER TABLE lists ADD COLUMN deleted_at TEXT")

    settings_columns = {
        row["name"]
        for row in connection.execute("PRAGMA table_info(settings)").fetchall()
    }
    if "updated_at" not in settings_columns:
        connection.execute("ALTER TABLE settings ADD COLUMN updated_at TEXT")

    connection.commit()
    set_schema_version(connection, 6)
