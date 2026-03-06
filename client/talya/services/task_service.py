from __future__ import annotations

from talya.domain.task import Task


class TaskService:
    def __init__(self) -> None:
        self._tasks: list[Task] = []

    def add_task(self, title: str, section: str) -> Task | None:
        cleaned = title.strip()
        if not cleaned:
            return None

        task = Task.create(cleaned, section)
        self._tasks.append(task)
        return task

    def list_tasks(self) -> list[Task]:
        return list(self._tasks)

    def list_tasks_for_section(self, section: str) -> list[Task]:
        return [task for task in self._tasks if task.section == section]

    def toggle_task_completed(self, task_id: str) -> bool:
        for task in self._tasks:
            if task.id == task_id:
                task.is_completed = not task.is_completed
                return True
        return False
