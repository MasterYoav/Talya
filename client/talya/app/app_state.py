from PySide6.QtCore import Property, QObject, Signal, Slot

from talya.services.task_service import TaskService


class AppState(QObject):
    currentSectionChanged = Signal()
    tasksChanged = Signal()

    def __init__(self) -> None:
        super().__init__()
        self._current_section = "Today"
        self._task_service = TaskService()

    def get_current_section(self) -> str:
        return self._current_section

    def set_current_section(self, section: str) -> None:
        if section == self._current_section:
            return

        self._current_section = section
        self.currentSectionChanged.emit()

    @Property(str, notify=currentSectionChanged)
    def currentSection(self) -> str:
        return self.get_current_section()

    @Property("QVariantList", notify=tasksChanged)
    def tasks(self) -> list[dict]:
        return [
            {
                "id": task.id,
                "title": task.title,
                "isCompleted": task.is_completed,
                "createdAt": task.created_at.isoformat(),
            }
            for task in self._task_service.list_tasks()
        ]

    @Slot(str)
    def selectSection(self, section: str) -> None:
        self.set_current_section(section)

    @Slot(str)
    def addTask(self, title: str) -> None:
        task = self._task_service.add_task(title)
        if task is None:
            return

        self.tasksChanged.emit()
