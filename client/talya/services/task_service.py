from __future__ import annotations

from datetime import date, datetime

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
        if section == "Today":
            today = date.today()
            return [
                task
                for task in self._tasks
                if self._is_due_on(task, today) or task.section == section
            ]
        if section == "Upcoming":
            today = date.today()
            return [
                task
                for task in self._tasks
                if self._is_due_after(task, today) or task.section == section
            ]
        return [task for task in self._tasks if task.section == section]

    def get_task_by_id(self, task_id: str) -> Task | None:
        for task in self._tasks:
            if task.id == task_id:
                return task
        return None

    def toggle_task_completed(self, task_id: str) -> bool:
        for task in self._tasks:
            if task.id == task_id:
                task.is_completed = not task.is_completed
                task.updated_at = datetime.now()
                self._repository.update_task_completion(
                    task.id,
                    task.is_completed,
                    task.updated_at,
                )
                return True
        return False

    def update_task_title(self, task_id: str, title: str) -> bool:
        cleaned = title.strip()
        if not cleaned:
            return False

        for task in self._tasks:
            if task.id == task_id:
                task.title = cleaned
                task.updated_at = datetime.now()
                self._repository.update_task_title(
                    task.id,
                    cleaned,
                    task.updated_at,
                )
                return True
        return False

    def update_task_notes(self, task_id: str, notes: str) -> bool:
        for task in self._tasks:
            if task.id == task_id:
                task.notes = notes.strip()
                task.updated_at = datetime.now()
                self._repository.update_task_notes(
                    task.id,
                    task.notes,
                    task.updated_at,
                )
                return True
        return False

    def update_task_due_date(
        self, task_id: str, due_date: datetime | None
    ) -> bool:
        for task in self._tasks:
            if task.id == task_id:
                task.due_date = due_date
                task.updated_at = datetime.now()
                self._repository.update_task_due_date(
                    task.id,
                    task.due_date,
                    task.updated_at,
                )
                return True
        return False

    def update_task_reminder_at(
        self, task_id: str, reminder_at: datetime | None
    ) -> bool:
        for task in self._tasks:
            if task.id == task_id:
                task.reminder_at = reminder_at
                task.updated_at = datetime.now()
                self._repository.update_task_reminder_at(
                    task.id,
                    task.reminder_at,
                    task.updated_at,
                )
                return True
        return False

    def delete_task(self, task_id: str) -> bool:
        for index, task in enumerate(self._tasks):
            if task.id == task_id:
                del self._tasks[index]
                self._repository.delete_task(task.id)
                return True
        return False

    @staticmethod
    def _is_due_on(task: Task, target_date: date) -> bool:
        if task.due_date is None:
            return False
        return task.due_date.date() == target_date

    @staticmethod
    def _is_due_after(task: Task, target_date: date) -> bool:
        if task.due_date is None:
            return False
        return task.due_date.date() > target_date
