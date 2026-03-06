from datetime import datetime

from PySide6.QtCore import Property, QObject, Signal, Slot

from talya.infrastructure.database import initialize_database
from talya.services.task_service import TaskService


class AppState(QObject):
    currentSectionChanged = Signal()
    tasksChanged = Signal()
    darkModeChanged = Signal()
    sidebarCollapsedChanged = Signal()
    editModeChanged = Signal()
    selectedTaskChanged = Signal()

    def __init__(self) -> None:
        super().__init__()
        initialize_database()
        self._current_section = "Today"
        self._task_service = TaskService()
        self._dark_mode = False
        self._sidebar_collapsed = False
        self._edit_mode = False
        self._selected_task_id: str | None = None

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
                "updatedAt": task.updated_at.isoformat() if task.updated_at else None,
                "notes": task.notes or "",
                "dueDate": task.due_date.isoformat() if task.due_date else None,
                "reminderAt": task.reminder_at.isoformat()
                if task.reminder_at
                else None,
            }
            for task in tasks
        ]

    @Property("QVariantMap", notify=selectedTaskChanged)
    def selectedTask(self) -> dict:
        if not self._selected_task_id:
            return {}

        task = self._task_service.get_task_by_id(self._selected_task_id)
        if task is None:
            return {}

        return {
            "id": task.id,
            "title": task.title,
            "section": task.section,
            "isCompleted": task.is_completed,
            "createdAt": task.created_at.isoformat(),
            "createdLabel": self._format_created_label(task.created_at),
            "updatedAt": task.updated_at.isoformat() if task.updated_at else None,
            "notes": task.notes or "",
            "dueDate": task.due_date.isoformat() if task.due_date else None,
            "reminderAt": task.reminder_at.isoformat() if task.reminder_at else None,
        }

    @Property(bool, notify=selectedTaskChanged)
    def hasSelectedTask(self) -> bool:
        return bool(self.selectedTask)

    @Property(bool, notify=darkModeChanged)
    def darkMode(self) -> bool:
        return self._dark_mode

    @Property(bool, notify=sidebarCollapsedChanged)
    def sidebarCollapsed(self) -> bool:
        return self._sidebar_collapsed

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
        self._selected_task_id = None
        self.currentSectionChanged.emit()
        self.tasksChanged.emit()
        self.selectedTaskChanged.emit()

    @Slot(str)
    def selectTask(self, task_id: str) -> None:
        if task_id == self._selected_task_id:
            return
        self._selected_task_id = task_id
        self.selectedTaskChanged.emit()

    @Slot()
    def clearSelectedTask(self) -> None:
        if self._selected_task_id is None:
            return
        self._selected_task_id = None
        self.selectedTaskChanged.emit()

    @Slot(str)
    def addTask(self, title: str) -> None:
        task = self._task_service.add_task(title, self._current_section)
        if task is None:
            return
        self._selected_task_id = task.id
        self.tasksChanged.emit()
        self.selectedTaskChanged.emit()

    @Slot(str)
    def toggleTaskCompleted(self, task_id: str) -> None:
        changed = self._task_service.toggle_task_completed(task_id)
        if changed:
            self.tasksChanged.emit()
            self.selectedTaskChanged.emit()

    @Slot(str, str)
    def updateTaskTitle(self, task_id: str, title: str) -> None:
        changed = self._task_service.update_task_title(task_id, title)
        if changed:
            self.tasksChanged.emit()
            self.selectedTaskChanged.emit()

    @Slot(str, str)
    def updateTaskNotes(self, task_id: str, notes: str) -> None:
        changed = self._task_service.update_task_notes(task_id, notes)
        if changed:
            self.tasksChanged.emit()
            self.selectedTaskChanged.emit()

    @Slot(str)
    def deleteTask(self, task_id: str) -> None:
        changed = self._task_service.delete_task(task_id)
        if changed:
            if self._selected_task_id == task_id:
                self._selected_task_id = None
            self.tasksChanged.emit()
            self.selectedTaskChanged.emit()

    @Slot()
    def setLightMode(self) -> None:
        if not self._dark_mode:
            return
        self._dark_mode = False
        self.darkModeChanged.emit()

    @Slot()
    def setDarkMode(self) -> None:
        if self._dark_mode:
            return
        self._dark_mode = True
        self.darkModeChanged.emit()

    @Slot()
    def toggleSidebarCollapsed(self) -> None:
        self._sidebar_collapsed = not self._sidebar_collapsed
        self.sidebarCollapsedChanged.emit()

    @Slot()
    def toggleEditMode(self) -> None:
        self._edit_mode = not self._edit_mode
        self.editModeChanged.emit()
        self.tasksChanged.emit()
        self.selectedTaskChanged.emit()
