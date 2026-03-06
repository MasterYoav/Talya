from __future__ import annotations

from talya.domain.task import Task


class TaskService:
    def __init__(self) -> None:
        self._tasks: list[Task] = []

    def add_task(self, title: str) -> Task | None:
        cleaned = title.strip()
        if not cleaned:
            return None

        task = Task.create(cleaned)
        self._tasks.append(task)
        return task

    def list_tasks(self) -> list[Task]:
        return list(self._tasks)
