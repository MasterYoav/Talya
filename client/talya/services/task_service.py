from __future__ import annotations

from talya.domain.task import Task
from talya.infrastructure.task_repository import TaskRepository


class TaskService:
    def __init__(self) -> None:
        self._repository = TaskRepository()
        self._tasks: list[Task] = self._repository.list_tasks()

    def add_task(self, title: str, section: str) -> Task | None:
        cleaned = title.strip()
        if not cleaned:
            return None

        task = Task.create(cleaned, section)
        self._repository.add_task(task)
        self._tasks.insert(0, task)
        return task

    def list_tasks(self) -> list[Task]:
        return list(self._tasks)

    def list_tasks_for_section(self, section: str) -> list[Task]:
        return [task for task in self._tasks if task.section == section]

    def toggle_task_completed(self, task_id: str) -> bool:
        for task in self._tasks:
            if task.id == task_id:
                task.is_completed = not task.is_completed
                self._repository.update_task_completion(task.id, task.is_completed)
                return True
        return False

    def update_task_title(self, task_id: str, title: str) -> bool:
        cleaned = title.strip()
        if not cleaned:
            return False

        for task in self._tasks:
            if task.id == task_id:
                task.title = cleaned
                self._repository.update_task_title(task.id, cleaned)
                return True
        return False

    def delete_task(self, task_id: str) -> bool:
        for index, task in enumerate(self._tasks):
            if task.id == task_id:
                del self._tasks[index]
                self._repository.delete_task(task.id)
                return True
        return False
