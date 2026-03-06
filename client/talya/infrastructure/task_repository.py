from __future__ import annotations

from datetime import datetime

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
                    section,
                    is_completed,
                    created_at,
                    updated_at,
                    notes,
                    due_date,
                    reminder_at
                FROM tasks
                ORDER BY created_at DESC
                """
            ).fetchall()

            return [
                Task(
                    id=row["id"],
                    title=row["title"],
                    section=row["section"],
                    is_completed=bool(row["is_completed"]),
                    created_at=datetime.fromisoformat(row["created_at"]),
                    updated_at=parse_optional_datetime(row["updated_at"]),
                    notes=row["notes"],
                    due_date=parse_optional_datetime(row["due_date"]),
                    reminder_at=parse_optional_datetime(row["reminder_at"]),
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
                    is_completed,
                    created_at,
                    updated_at,
                    notes,
                    due_date,
                    reminder_at
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    task.id,
                    task.title,
                    task.section,
                    int(task.is_completed),
                    task.created_at.isoformat(),
                    task.updated_at.isoformat() if task.updated_at else None,
                    task.notes,
                    task.due_date.isoformat() if task.due_date else None,
                    task.reminder_at.isoformat() if task.reminder_at else None,
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

    def delete_task(self, task_id: str) -> None:
        connection = create_connection()
        try:
            connection.execute(
                """
                DELETE FROM tasks
                WHERE id = ?
                """,
                (task_id,),
            )
            connection.commit()
        finally:
            connection.close()
