from __future__ import annotations

from datetime import datetime

from talya.domain.task import Task
from talya.infrastructure.database import create_connection


class TaskRepository:
    def list_tasks(self) -> list[Task]:
        connection = create_connection()
        try:
            rows = connection.execute(
                """
                SELECT id, title, section, is_completed, created_at
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
                INSERT INTO tasks (id, title, section, is_completed, created_at)
                VALUES (?, ?, ?, ?, ?)
                """,
                (
                    task.id,
                    task.title,
                    task.section,
                    int(task.is_completed),
                    task.created_at.isoformat(),
                ),
            )
            connection.commit()
        finally:
            connection.close()

    def update_task_completion(self, task_id: str, is_completed: bool) -> None:
        connection = create_connection()
        try:
            connection.execute(
                """
                UPDATE tasks
                SET is_completed = ?
                WHERE id = ?
                """,
                (int(is_completed), task_id),
            )
            connection.commit()
        finally:
            connection.close()
