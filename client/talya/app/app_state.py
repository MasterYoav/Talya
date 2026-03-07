from datetime import datetime
import hashlib
from pathlib import Path
import threading

from PySide6.QtCore import Property, QObject, Signal, Slot

from talya.services.auth_service import AuthService

from talya.infrastructure.database import initialize_database, set_database_path
from talya.infrastructure.settings_repository import SettingsRepository
from talya.services.task_service import TaskService


class AppState(QObject):
    currentSectionChanged = Signal()
    tasksChanged = Signal()
    darkModeChanged = Signal()
    sidebarCollapsedChanged = Signal()
    editModeChanged = Signal()
    selectedTaskChanged = Signal()
    authChanged = Signal()
    authErrorChanged = Signal()
    authResult = Signal(bool, str, str, str, str)
    authStatusChanged = Signal()
    authStatusMessage = Signal(str)
    sidebarWidthChanged = Signal()
    sidebarBlurOpacityChanged = Signal()

    def __init__(self) -> None:
        super().__init__()
        self._current_section = "Today"
        self._account_key = ""
        self._settings_repository = SettingsRepository()
        self._task_service: TaskService | None = None
        self._auth_service = AuthService()
        self._dark_mode = False
        self._sidebar_collapsed = False
        self._edit_mode = False
        self._selected_task_id: str | None = None
        self._is_authenticated = False
        self._user_name = ""
        self._user_email = ""
        self._auth_error = ""
        self._auth_status = ""
        self._sidebar_blur_opacity = 0.7
        self.authResult.connect(self._handle_auth_result)
        self.authStatusMessage.connect(self._handle_auth_status)
        cached_profile = self._auth_service.load_cached_profile()
        self._switch_account("local")
        if cached_profile:
            self._set_authenticated(
                cached_profile.get("name", ""),
                cached_profile.get("email", ""),
            )

    @Property(str, notify=currentSectionChanged)
    def currentSection(self) -> str:
        return self._current_section

    @Property("QVariantList", notify=tasksChanged)
    def tasks(self) -> list[dict]:
        if self._task_service is None:
            return []
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
        if self._task_service is None:
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

    @Property(int, notify=sidebarWidthChanged)
    def sidebarWidth(self) -> int:
        return 64 if self._sidebar_collapsed else 272

    @Property(float, notify=sidebarBlurOpacityChanged)
    def sidebarBlurOpacity(self) -> float:
        return self._sidebar_blur_opacity

    @Property(bool, notify=editModeChanged)
    def editMode(self) -> bool:
        return self._edit_mode

    @Property(bool, notify=authChanged)
    def isAuthenticated(self) -> bool:
        return self._is_authenticated

    @Property(str, notify=authChanged)
    def userName(self) -> str:
        return self._user_name

    @Property(str, notify=authChanged)
    def userEmail(self) -> str:
        return self._user_email

    @Property(str, notify=authErrorChanged)
    def authError(self) -> str:
        return self._auth_error

    @Property(str, notify=authStatusChanged)
    def authStatus(self) -> str:
        return self._auth_status

    def _format_created_label(self, created_at: datetime) -> str:
        return created_at.strftime("%b %d, %H:%M")

    def _account_database_path(self, account_key: str) -> Path:
        project_root = Path(__file__).resolve().parents[2]
        if account_key == "local":
            return project_root / "data" / "talya.db"
        data_dir = project_root / "data" / "accounts" / account_key
        return data_dir / "talya.db"

    def _normalize_account_key(self, account_id: str) -> str:
        cleaned = account_id.strip()
        if not cleaned:
            return "local"
        if cleaned.lower() == "local":
            return "local"
        return hashlib.sha256(cleaned.lower().encode("utf-8")).hexdigest()[:12]

    def _switch_account(self, account_id: str) -> None:
        account_key = self._normalize_account_key(account_id)
        if account_key == self._account_key:
            return
        self._account_key = account_key
        set_database_path(self._account_database_path(self._account_key))
        initialize_database()
        self._task_service = TaskService()
        self._selected_task_id = None
        self._load_settings()
        self.tasksChanged.emit()
        self.selectedTaskChanged.emit()
        self.currentSectionChanged.emit()

    def _load_settings(self) -> None:
        dark_mode = self._settings_repository.get("dark_mode")
        sidebar_collapsed = self._settings_repository.get("sidebar_collapsed")
        sidebar_blur_opacity = self._settings_repository.get("sidebar_blur_opacity")
        self._dark_mode = dark_mode == "1"
        self._sidebar_collapsed = sidebar_collapsed == "1"
        if sidebar_blur_opacity is not None:
            try:
                self._sidebar_blur_opacity = float(sidebar_blur_opacity)
            except ValueError:
                self._sidebar_blur_opacity = 0.7
        self.darkModeChanged.emit()
        self.sidebarCollapsedChanged.emit()
        self.sidebarBlurOpacityChanged.emit()

    def _save_setting(self, key: str, value: str) -> None:
        self._settings_repository.set(key, value)

    def _parse_optional_datetime_input(
        self, value: str
    ) -> tuple[datetime | None, bool]:
        cleaned = value.strip()
        if not cleaned:
            return None, True
        try:
            return datetime.fromisoformat(cleaned), True
        except ValueError:
            return None, False

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
        if self._task_service is None:
            return
        task = self._task_service.add_task(title, self._current_section)
        if task is None:
            return
        self._selected_task_id = task.id
        self.tasksChanged.emit()
        self.selectedTaskChanged.emit()

    @Slot(str)
    def toggleTaskCompleted(self, task_id: str) -> None:
        if self._task_service is None:
            return
        changed = self._task_service.toggle_task_completed(task_id)
        if changed:
            self.tasksChanged.emit()
            self.selectedTaskChanged.emit()

    @Slot(str, str)
    def updateTaskTitle(self, task_id: str, title: str) -> None:
        if self._task_service is None:
            return
        changed = self._task_service.update_task_title(task_id, title)
        if changed:
            self.tasksChanged.emit()
            self.selectedTaskChanged.emit()

    @Slot(str, str)
    def updateTaskNotes(self, task_id: str, notes: str) -> None:
        if self._task_service is None:
            return
        changed = self._task_service.update_task_notes(task_id, notes)
        if changed:
            self.tasksChanged.emit()
            self.selectedTaskChanged.emit()

    @Slot(str, str)
    def updateTaskDueDate(self, task_id: str, due_date: str) -> None:
        if self._task_service is None:
            return
        parsed, valid = self._parse_optional_datetime_input(due_date)
        if not valid:
            return
        changed = self._task_service.update_task_due_date(task_id, parsed)
        if changed:
            self.tasksChanged.emit()
            self.selectedTaskChanged.emit()

    @Slot(str, str)
    def updateTaskReminderAt(self, task_id: str, reminder_at: str) -> None:
        if self._task_service is None:
            return
        parsed, valid = self._parse_optional_datetime_input(reminder_at)
        if not valid:
            return
        changed = self._task_service.update_task_reminder_at(task_id, parsed)
        if changed:
            self.tasksChanged.emit()
            self.selectedTaskChanged.emit()

    @Slot(str)
    def deleteTask(self, task_id: str) -> None:
        if self._task_service is None:
            return
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
        self._save_setting("dark_mode", "0")
        self.darkModeChanged.emit()

    @Slot()
    def setDarkMode(self) -> None:
        if self._dark_mode:
            return
        self._dark_mode = True
        self._save_setting("dark_mode", "1")
        self.darkModeChanged.emit()

    @Slot()
    def toggleSidebarCollapsed(self) -> None:
        self._sidebar_collapsed = not self._sidebar_collapsed
        self._save_setting("sidebar_collapsed", "1" if self._sidebar_collapsed else "0")
        self.sidebarCollapsedChanged.emit()
        self.sidebarWidthChanged.emit()

    @Slot(float)
    def setSidebarBlurOpacity(self, value: float) -> None:
        clamped = max(0.0, min(1.0, value))
        if abs(clamped - self._sidebar_blur_opacity) < 0.001:
            return
        self._sidebar_blur_opacity = clamped
        self._save_setting("sidebar_blur_opacity", f"{self._sidebar_blur_opacity:.3f}")
        self.sidebarBlurOpacityChanged.emit()

    @Slot()
    def toggleEditMode(self) -> None:
        self._edit_mode = not self._edit_mode
        self.editModeChanged.emit()
        self.tasksChanged.emit()
        self.selectedTaskChanged.emit()

    def _set_auth_error(self, message: str) -> None:
        if self._auth_error == message:
            return
        self._auth_error = message
        self.authErrorChanged.emit()

    def _set_auth_status(self, message: str) -> None:
        if self._auth_status == message:
            return
        self._auth_status = message
        self.authStatusChanged.emit()

    def _set_authenticated(self, name: str, email: str) -> None:
        self._is_authenticated = True
        self._user_name = name
        self._user_email = email
        self._set_auth_error("")
        self._set_auth_status("")
        self._switch_account(email or name)
        self.authChanged.emit()

    def _handle_auth_result(
        self, success: bool, name: str, email: str, error: str, account_id: str
    ) -> None:
        if success:
            self._set_authenticated(name, email or account_id)
        else:
            self._set_auth_error(error)

    def _handle_auth_status(self, message: str) -> None:
        self._set_auth_status(message)

    @Slot(str, str)
    def login(self, email: str, password: str) -> None:
        cleaned_email = email.strip()
        cleaned_password = password.strip()
        if "@" not in cleaned_email or not cleaned_password:
            self._set_auth_error("Enter a valid email and password.")
            return
        name = cleaned_email.split("@", maxsplit=1)[0].replace(".", " ").title()
        self._set_authenticated(name or "User", cleaned_email)

    @Slot(str, str, str)
    def register(self, name: str, email: str, password: str) -> None:
        cleaned_name = name.strip()
        cleaned_email = email.strip()
        cleaned_password = password.strip()
        if not cleaned_name or "@" not in cleaned_email or len(cleaned_password) < 6:
            self._set_auth_error("Use a name, valid email, and 6+ char password.")
            return
        self._set_authenticated(cleaned_name, cleaned_email)

    @Slot()
    def logout(self) -> None:
        if not self._is_authenticated:
            return
        self._is_authenticated = False
        self._user_name = ""
        self._user_email = ""
        self._set_auth_error("")
        self._set_auth_status("")
        self._auth_service.clear_profile()
        self._switch_account("local")
        self.authChanged.emit()

    @Slot(str, str)
    def updateProfile(self, name: str, email: str) -> None:
        cleaned_name = name.strip()
        cleaned_email = email.strip()
        if not cleaned_name or "@" not in cleaned_email:
            self._set_auth_error("Enter a name and valid email.")
            return
        self._user_name = cleaned_name
        self._user_email = cleaned_email
        self._set_auth_error("")
        self._auth_service.save_profile(self._user_name, self._user_email)
        self._switch_account(cleaned_email)
        self.authChanged.emit()

    @Slot()
    def loginWithGoogle(self) -> None:
        self._set_auth_error("")
        self._set_auth_status("")
        thread = threading.Thread(target=self._run_google_auth, daemon=True)
        thread.start()

    def _run_google_auth(self) -> None:
        result = self._auth_service.authenticate_with_google()
        if "error" in result:
            self.authResult.emit(False, "", "", result["error"], "")
        else:
            self.authResult.emit(
                True,
                result.get("name", ""),
                result.get("email", ""),
                "",
                result.get("account_id", ""),
            )

    @Slot()
    def loginWithGithub(self) -> None:
        self._set_auth_error("")
        thread = threading.Thread(target=self._run_github_auth, daemon=True)
        thread.start()

    def _run_github_auth(self) -> None:
        result = self._auth_service.authenticate_with_github()
        if "error" in result:
            self.authResult.emit(False, "", "", result["error"], "")
        else:
            self.authResult.emit(
                True,
                result.get("name", ""),
                result.get("email", ""),
                "",
                result.get("account_id", ""),
            )
