from datetime import datetime

from PySide6.QtCore import Property, QObject, Signal, Slot

from talya.infrastructure.database import initialize_database
from talya.services.task_service import TaskService


class AppState(QObject):
    currentSectionChanged = Signal()
    tasksChanged = Signal()
    darkModeChanged = Signal()
    sidebarCollapsedChanged = Signal()
    settingsOpenChanged = Signal()
    editModeChanged = Signal()

    def __init__(self) -> None:
        super().__init__()
        initialize_database()
        self._current_section = "Today"
        self._task_service = TaskService()
        self._dark_mode = False
        self._sidebar_collapsed = False
        self._settings_open = False
        self._edit_mode = False

    @Property(str, notify=currentSectionChanged)
    def currentSection(self) -> str:
        return self._current_section

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
                "createdLabel": self._format_created_label(task.created_at),
            }
            for task in tasks
        ]

    @Property(bool, notify=darkModeChanged)
    def darkMode(self) -> bool:
        return self._dark_mode

    @Property(bool, notify=sidebarCollapsedChanged)
    def sidebarCollapsed(self) -> bool:
        return self._sidebar_collapsed

    @Property(bool, notify=settingsOpenChanged)
    def settingsOpen(self) -> bool:
        return self._settings_open

    @Property(bool, notify=editModeChanged)
    def editMode(self) -> bool:
        return self._edit_mode

    def _format_created_label(self, created_at: datetime) -> str:
        return created_at.strftime("%b %d, %H:%M")

    @Slot(str)
    def selectSection(self, section: str) -> None:
        if section == self._current_section:
            return
        self._current_section = section
        self.currentSectionChanged.emit()
        self.tasksChanged.emit()

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

    @Slot(str, str)
    def updateTaskTitle(self, task_id: str, title: str) -> None:
        changed = self._task_service.update_task_title(task_id, title)
        if changed:
            self.tasksChanged.emit()

    @Slot(str)
    def deleteTask(self, task_id: str) -> None:
        changed = self._task_service.delete_task(task_id)
        if changed:
            self.tasksChanged.emit()

    @Slot()
    def toggleDarkMode(self) -> None:
        self._dark_mode = not self._dark_mode
        self.darkModeChanged.emit()

    @Slot()
    def toggleSidebarCollapsed(self) -> None:
        self._sidebar_collapsed = not self._sidebar_collapsed
        self.sidebarCollapsedChanged.emit()

    @Slot()
    def openSettings(self) -> None:
        if self._settings_open:
            return
        self._settings_open = True
        self.settingsOpenChanged.emit()

    @Slot()
    def closeSettings(self) -> None:
        if not self._settings_open:
            return
        self._settings_open = False
        self.settingsOpenChanged.emit()

    @Slot()
    def toggleEditMode(self) -> None:
        self._edit_mode = not self._edit_mode
        self.editModeChanged.emit()
        self.tasksChanged.emit()
