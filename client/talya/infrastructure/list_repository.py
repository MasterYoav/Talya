from __future__ import annotations

from datetime import datetime
import sqlite3
from uuid import uuid4

from talya.domain.sidebar_list import SidebarList
from talya.infrastructure.database import create_connection


class ListRepository:
    @staticmethod
    def _parse_optional_datetime(value: str | None) -> datetime | None:
        if value is None:
            return None
        return datetime.fromisoformat(value)

    def list_lists(self) -> list[SidebarList]:
        connection = create_connection()
        try:
            rows = connection.execute(
                """
                SELECT
                    id,
                    name,
                    icon,
                    color,
                    position,
                    list_type,
                    is_system,
                    is_pinned,
                    is_deleted,
                    deleted_at,
                    created_at,
                    updated_at
                FROM lists
                WHERE is_deleted = 0
                ORDER BY is_pinned DESC, position ASC, created_at ASC
                """
            ).fetchall()
            return [
                SidebarList(
                    id=row["id"],
                    name=row["name"],
                    icon=row["icon"],
                    color=row["color"],
                    position=int(row["position"]),
                    list_type=row["list_type"],
                    is_system=bool(row["is_system"]),
                    is_pinned=bool(row["is_pinned"]),
                    is_deleted=bool(row["is_deleted"]),
                    deleted_at=self._parse_optional_datetime(row["deleted_at"]),
                    created_at=self._parse_optional_datetime(row["created_at"]),
                    updated_at=self._parse_optional_datetime(row["updated_at"]),
                )
                for row in rows
            ]
        finally:
            connection.close()

    def list_all_lists(self) -> list[sqlite3.Row]:
        connection = create_connection()
        try:
            return connection.execute(
                """
                SELECT
                    id,
                    name,
                    icon,
                    color,
                    position,
                    list_type,
                    is_system,
                    is_pinned,
                    is_deleted,
                    deleted_at,
                    created_at,
                    updated_at
                FROM lists
                ORDER BY updated_at ASC, created_at ASC
                """
            ).fetchall()
        finally:
            connection.close()

    def add_list(
        self,
        name: str,
        icon: str,
        color: str,
        list_type: str,
        is_system: bool,
    ) -> SidebarList:
        connection = create_connection()
        try:
            row = connection.execute("SELECT MAX(position) AS pos FROM lists").fetchone()
            next_position = int(row["pos"] or 0) + 1
            list_id = str(uuid4())
            now = datetime.now().isoformat()
            connection.execute(
                """
                INSERT INTO lists (id, name, icon, color, position, list_type, is_system, is_pinned, is_deleted, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    list_id,
                    name,
                    icon,
                    color,
                    next_position,
                    list_type,
                    int(is_system),
                    0,
                    0,
                    now,
                    now,
                ),
            )
            connection.commit()
            return SidebarList(
                id=list_id,
                name=name,
                icon=icon,
                color=color,
                position=next_position,
                list_type=list_type,
                is_system=is_system,
                is_pinned=False,
                is_deleted=False,
                created_at=now,
                updated_at=now,
            )
        finally:
            connection.close()

    def update_list(
        self,
        list_id: str,
        name: str,
        icon: str,
        color: str,
    ) -> None:
        connection = create_connection()
        try:
            connection.execute(
                """
                UPDATE lists
                SET name = ?, icon = ?, color = ?, updated_at = ?
                WHERE id = ?
                """,
                (name, icon, color, datetime.now().isoformat(), list_id),
            )
            connection.commit()
        finally:
            connection.close()

    def delete_list(self, list_id: str) -> None:
        connection = create_connection()
        try:
            connection.execute(
                """
                UPDATE lists
                SET is_deleted = 1, deleted_at = ?, updated_at = ?
                WHERE id = ?
                """,
                (datetime.now().isoformat(), datetime.now().isoformat(), list_id),
            )
            connection.commit()
        finally:
            connection.close()

    def update_task_list(self, old_list_id: str, new_list_id: str) -> None:
        connection = create_connection()
        try:
            connection.execute(
                "UPDATE tasks SET list_id = ? WHERE list_id = ?",
                (new_list_id, old_list_id),
            )
            connection.commit()
        finally:
            connection.close()

    def set_pinned(self, list_id: str, pinned: bool) -> None:
        connection = create_connection()
        try:
            connection.execute(
                """
                UPDATE lists
                SET is_pinned = ?, updated_at = ?
                WHERE id = ?
                """,
                (1 if pinned else 0, datetime.now().isoformat(), list_id),
            )
            connection.commit()
        finally:
            connection.close()

    def update_positions(self, ordered_ids: list[str]) -> None:
        connection = create_connection()
        try:
            now = datetime.now().isoformat()
            for position, list_id in enumerate(ordered_ids):
                connection.execute(
                    """
                    UPDATE lists
                    SET position = ?, updated_at = ?
                    WHERE id = ?
                    """,
                    (position, now, list_id),
                )
            connection.commit()
        finally:
            connection.close()

    def upsert_list(self, payload: dict) -> None:
        connection = create_connection()
        try:
            connection.execute(
                """
                INSERT INTO lists (
                    id, name, icon, color, position, list_type, is_system, is_pinned,
                    is_deleted, deleted_at, created_at, updated_at
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(id) DO UPDATE SET
                    name = excluded.name,
                    icon = excluded.icon,
                    color = excluded.color,
                    position = excluded.position,
                    list_type = excluded.list_type,
                    is_system = excluded.is_system,
                    is_pinned = excluded.is_pinned,
                    is_deleted = excluded.is_deleted,
                    deleted_at = excluded.deleted_at,
                    created_at = excluded.created_at,
                    updated_at = excluded.updated_at
                """,
                (
                    payload["id"],
                    payload["name"],
                    payload["icon"],
                    payload["color"],
                    payload["position"],
                    payload["list_type"],
                    1 if payload["is_system"] else 0,
                    1 if payload["is_pinned"] else 0,
                    1 if payload.get("is_deleted") else 0,
                    payload.get("deleted_at"),
                    payload.get("created_at"),
                    payload["updated_at"],
                ),
            )
            connection.commit()
        finally:
            connection.close()
