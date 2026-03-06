from PySide6.QtCore import Property, QObject, Signal, Slot

from talya.infrastructure.database import initialize_database
from talya.services.task_service import TaskService


class AppState(QObject):
    currentSectionChanged = Signal()
    tasksChanged = Signal()

    def __init__(self) -> None:
        super().__init__()
        initialize_database()
        self._current_section = "Today"
        self._task_service = TaskService()

    def get_current_section(self) -> str:
        return self._current_section

    def set_current_section(self, section: str) -> None:
        if section == self._current_section:
            return

        self._current_section = section
        self.currentSectionChanged.emit()
        self.tasksChanged.emit()

    @Property(str, notify=currentSectionChanged)
    def currentSection(self) -> str:
        return self.get_current_section()

    @Property("QVariantList", notify=tasksChanged)
    def tasks(self) -> list[dict]:
        tasks = self._task_service.list_tasks_for_section(self._current_section)
        return [
            {
                "id": task.id,
                "title": task.title,
                "section": task.section,
                "isCompleted": task.is_completed,
                "createdAt": task.created_at.isoformat(),
            }
            for task in tasks
        ]

    @Slot(str)
    def selectSection(self, section: str) -> None:
        self.set_current_section(section)

    @Slot(str)
    def addTask(self, title: str) -> None:
        task = self._task_service.add_task(title, self._current_section)
        if task is None:
            return

        self.tasksChanged.emit()

    @Slot(str)
    def toggleTaskCompleted(self, task_id: str) -> None:
        changed = self._task_service.toggle_task_completed(task_id)
        if changed:
            self.tasksChanged.emit()
