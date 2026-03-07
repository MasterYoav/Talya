from __future__ import annotations

from datetime import datetime
import sqlite3

from talya.domain.task import Task
from talya.infrastructure.database import create_connection


def parse_optional_datetime(value: str | None) -> datetime | None:
    if value is None:
        return None
    return datetime.fromisoformat(value)


class TaskRepository:
    def list_tasks(self) -> list[Task]:
        connection = create_connection()
        try:
            rows = connection.execute(
                """
                SELECT
                    id,
                    title,
                    list_id,
                    section,
                    is_completed,
                    created_at,
                    updated_at,
                    notes,
                    due_date,
                    reminder_at,
                    reminder_fired_at,
                    is_deleted
                FROM tasks
                WHERE is_deleted = 0
                ORDER BY created_at DESC
                """
            ).fetchall()

            return [
                Task(
                    id=row["id"],
                    title=row["title"],
                    list_id=row["list_id"] or row["section"],
                    is_completed=bool(row["is_completed"]),
                    created_at=datetime.fromisoformat(row["created_at"]),
                    updated_at=parse_optional_datetime(row["updated_at"]),
                    notes=row["notes"],
                    due_date=parse_optional_datetime(row["due_date"]),
                    reminder_at=parse_optional_datetime(row["reminder_at"]),
                    reminder_fired_at=parse_optional_datetime(row["reminder_fired_at"]),
                )
                for row in rows
            ]
        finally:
            connection.close()

    def add_task(self, task: Task) -> None:
        connection = create_connection()
        try:
            connection.execute(
                """
                INSERT INTO tasks (
                    id,
                    title,
                    section,
                    list_id,
                    is_completed,
                    created_at,
                    updated_at,
                    notes,
                    due_date,
                    reminder_at,
                    reminder_fired_at,
                    is_deleted
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    task.id,
                    task.title,
                    task.list_id,
                    task.list_id,
                    int(task.is_completed),
                    task.created_at.isoformat(),
                    task.updated_at.isoformat() if task.updated_at else None,
                    task.notes,
                    task.due_date.isoformat() if task.due_date else None,
                    task.reminder_at.isoformat() if task.reminder_at else None,
                    task.reminder_fired_at.isoformat()
                    if task.reminder_fired_at
                    else None,
                    0,
                ),
            )
            connection.commit()
        finally:
            connection.close()

    def update_task_completion(
        self, task_id: str, is_completed: bool, updated_at: datetime
    ) -> None:
        connection = create_connection()
        try:
            connection.execute(
                """
                UPDATE tasks
                SET is_completed = ?, updated_at = ?
                WHERE id = ?
                """,
                (int(is_completed), updated_at.isoformat(), task_id),
            )
            connection.commit()
        finally:
            connection.close()

    def update_task_title(self, task_id: str, title: str, updated_at: datetime) -> None:
        connection = create_connection()
        try:
            connection.execute(
                """
                UPDATE tasks
                SET title = ?, updated_at = ?
                WHERE id = ?
                """,
                (title, updated_at.isoformat(), task_id),
            )
            connection.commit()
        finally:
            connection.close()

    def update_task_notes(self, task_id: str, notes: str, updated_at: datetime) -> None:
        connection = create_connection()
        try:
            connection.execute(
                """
                UPDATE tasks
                SET notes = ?, updated_at = ?
                WHERE id = ?
                """,
                (notes, updated_at.isoformat(), task_id),
            )
            connection.commit()
        finally:
            connection.close()

    def update_task_due_date(
        self, task_id: str, due_date: datetime | None, updated_at: datetime
    ) -> None:
        connection = create_connection()
        try:
            connection.execute(
                """
                UPDATE tasks
                SET due_date = ?, updated_at = ?
                WHERE id = ?
                """,
                (
                    due_date.isoformat() if due_date else None,
                    updated_at.isoformat(),
                    task_id,
                ),
            )
            connection.commit()
        finally:
            connection.close()

    def update_task_reminder_at(
        self, task_id: str, reminder_at: datetime | None, updated_at: datetime
    ) -> None:
        connection = create_connection()
        try:
            connection.execute(
                """
                UPDATE tasks
                SET reminder_at = ?, reminder_fired_at = NULL, updated_at = ?
                WHERE id = ?
                """,
                (
                    reminder_at.isoformat() if reminder_at else None,
                    updated_at.isoformat(),
                    task_id,
                ),
            )
            connection.commit()
        finally:
            connection.close()

    def update_task_reminder_fired_at(
        self, task_id: str, fired_at: datetime
    ) -> None:
        connection = create_connection()
        try:
            connection.execute(
                """
                UPDATE tasks
                SET reminder_fired_at = ?, updated_at = ?
                WHERE id = ?
                """,
                (
                    fired_at.isoformat(),
                    fired_at.isoformat(),
                    task_id,
                ),
            )
            connection.commit()
        finally:
            connection.close()

    def delete_task(self, task_id: str) -> None:
        connection = create_connection()
        try:
            connection.execute(
                """
                UPDATE tasks
                SET is_deleted = 1, deleted_at = ?, updated_at = ?
                WHERE id = ?
                """,
                (datetime.now().isoformat(), datetime.now().isoformat(), task_id),
            )
            connection.commit()
        finally:
            connection.close()

    def list_all_tasks(self) -> list[sqlite3.Row]:
        connection = create_connection()
        try:
            return connection.execute(
                """
                SELECT
                    id,
                    title,
                    list_id,
                    section,
                    is_completed,
                    created_at,
                    updated_at,
                    notes,
                    due_date,
                    reminder_at,
                    reminder_fired_at,
                    is_deleted,
                    deleted_at
                FROM tasks
                ORDER BY updated_at ASC, created_at ASC
                """
            ).fetchall()
        finally:
            connection.close()

    def upsert_task(self, payload: dict) -> None:
        connection = create_connection()
        try:
            connection.execute(
                """
                INSERT INTO tasks (
                    id,
                    title,
                    section,
                    list_id,
                    is_completed,
                    created_at,
                    updated_at,
                    notes,
                    due_date,
                    reminder_at,
                    reminder_fired_at,
                    is_deleted,
                    deleted_at
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(id) DO UPDATE SET
                    title = excluded.title,
                    section = excluded.section,
                    list_id = excluded.list_id,
                    is_completed = excluded.is_completed,
                    notes = excluded.notes,
                    due_date = excluded.due_date,
                    reminder_at = excluded.reminder_at,
                    reminder_fired_at = excluded.reminder_fired_at,
                    updated_at = excluded.updated_at,
                    is_deleted = excluded.is_deleted,
                    deleted_at = excluded.deleted_at
                """,
                (
                    payload["id"],
                    payload["title"],
                    payload["list_id"],
                    payload["list_id"],
                    1 if payload["is_completed"] else 0,
                    payload.get("created_at"),
                    payload["updated_at"],
                    payload.get("notes", ""),
                    payload.get("due_date"),
                    payload.get("reminder_at"),
                    payload.get("reminder_fired_at"),
                    1 if payload.get("is_deleted") else 0,
                    payload.get("deleted_at"),
                ),
            )
            connection.commit()
        finally:
            connection.close()
