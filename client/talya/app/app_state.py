from datetime import date, datetime, timedelta
import hashlib
import json
from pathlib import Path
import threading

from PySide6.QtCore import Property, QObject, Signal, Slot, QTimer
from PySide6.QtGui import QFontDatabase

from talya.services.auth_service import AuthService

from talya.infrastructure.database import initialize_database, set_database_path
from talya.infrastructure.settings_repository import SettingsRepository
from talya.infrastructure.macos_notifications import send_notification
from talya.infrastructure.macos_launch_agent import (
    install_launch_agent,
    uninstall_launch_agent,
)
from talya.infrastructure.macos_emoji_picker import show_emoji_picker
from talya.services.list_service import ListService
from talya.services.task_service import TaskService
from talya.services.sync_service import SyncService
from talya.services.calendar_service import CalendarService


class AppState(QObject):
    currentSectionChanged = Signal()
    sidebarListsChanged = Signal()
    currentListTypeChanged = Signal()
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
    appIconChoiceChanged = Signal()
    reminderSettingsChanged = Signal()
    bannerChanged = Signal()
    sidebarBlurEnabledChanged = Signal()
    syncLogsChanged = Signal()
    calendarVisibilityChanged = Signal()
    calendarColorChanged = Signal()
    calendarEventsChanged = Signal()
    calendarSourcesChanged = Signal()
    fontFamilyChanged = Signal()
    calendarViewChanged = Signal()
    calendarDateChanged = Signal()

    def __init__(self) -> None:
        super().__init__()
        self._current_section = "Today"
        self._account_key = ""
        self._settings_repository = SettingsRepository()
        self._task_service: TaskService | None = None
        self._list_service: ListService | None = None
        self._sync_service = SyncService()
        self._auth_service = AuthService()
        self._calendar_service = CalendarService()
        self._dark_mode = False
        self._sidebar_collapsed = False
        self._edit_mode = False
        self._selected_task_id: str | None = None
        self._current_list_id: str | None = None
        self._current_list_type = "inbox"
        self._is_authenticated = False
        self._user_name = ""
        self._user_email = ""
        self._auth_error = ""
        self._auth_status = ""
        self._sidebar_blur_opacity = 0.7
        self._sidebar_blur_enabled = True
        self._app_icon_choice = "dark"
        self._reminder_notify_app = True
        self._reminder_notify_system = True
        self._reminder_notify_background = True
        self._banner_message = ""
        self._banner_visible = False
        self._sync_logs: list[dict] = []
        self._sync_timer: QTimer | None = None
        self._last_sync_at = ""
        self._calendar_visible = True
        self._calendar_color = "#9aa1ad"
        self._calendar_view = "month"
        self._calendar_date = date.today()
        self._calendar_events: list[dict] = []
        self._apple_calendars: list[dict] = []
        self._google_calendars: list[dict] = []
        self._selected_apple_calendar_ids: set[str] = set()
        self._selected_google_calendar_ids: set[str] = set()
        self._system_font_family = QFontDatabase.systemFont(
            QFontDatabase.GeneralFont
        ).family()
        self._available_fonts = self._load_fonts()
        self._font_family = ""
        self.authResult.connect(self._handle_auth_result)
        self.authStatusMessage.connect(self._handle_auth_status)
        cached_profile = self._auth_service.load_cached_profile()
        self._switch_account("local")
        if cached_profile:
            self._set_authenticated(
                cached_profile.get("name", ""),
                cached_profile.get("email", ""),
            )
        self._start_reminder_timer()

    @Property(str, notify=currentSectionChanged)
    def currentSection(self) -> str:
        return self._current_section

    @Property(str, notify=currentListTypeChanged)
    def currentListType(self) -> str:
        return self._current_list_type

    @Property("QVariantList", notify=sidebarListsChanged)
    def sidebarLists(self) -> list[dict]:
        if self._list_service is None:
            return []
        items = list(self._list_service.list_lists())
        items.sort(key=lambda item: (not item.is_pinned, item.position))
        return [
            {
                "id": item.id,
                "name": item.name,
                "icon": item.icon,
                "color": item.color,
                "listType": item.list_type,
                "isSystem": item.is_system,
                "isPinned": item.is_pinned,
            }
            for item in items
        ]

    @Property("QVariantList", notify=tasksChanged)
    def tasks(self) -> list[dict]:
        if self._task_service is None:
            return []
        if self._list_service is None or self._current_list_id is None:
            return []
        current_list = self._list_service.get_by_id(self._current_list_id)
        if current_list is None:
            return []
        if current_list.list_type in {"settings", "profile"}:
            return []
        tasks = self._task_service.list_tasks_for_list(current_list)
        return [
            {
                "id": task.id,
                "title": task.title,
                "listId": task.list_id,
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
            "listId": task.list_id,
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

    @Property(bool, notify=sidebarBlurEnabledChanged)
    def sidebarBlurEnabled(self) -> bool:
        return self._sidebar_blur_enabled

    @Property(str, notify=appIconChoiceChanged)
    def appIconChoice(self) -> str:
        return self._app_icon_choice

    @Property(bool, notify=reminderSettingsChanged)
    def reminderNotifyApp(self) -> bool:
        return self._reminder_notify_app

    @Property(bool, notify=reminderSettingsChanged)
    def reminderNotifySystem(self) -> bool:
        return self._reminder_notify_system

    @Property(bool, notify=reminderSettingsChanged)
    def reminderNotifyBackground(self) -> bool:
        return self._reminder_notify_background

    @Property(str, notify=bannerChanged)
    def bannerMessage(self) -> str:
        return self._banner_message

    @Property(bool, notify=bannerChanged)
    def bannerVisible(self) -> bool:
        return self._banner_visible

    @Property("QVariantList", notify=syncLogsChanged)
    def syncLogs(self) -> list[dict]:
        return list(self._sync_logs)

    @Property(str, notify=syncLogsChanged)
    def lastSyncAt(self) -> str:
        return self._last_sync_at

    @Property(bool, notify=calendarVisibilityChanged)
    def calendarVisible(self) -> bool:
        return self._calendar_visible

    @Property(str, notify=calendarColorChanged)
    def calendarColor(self) -> str:
        return self._calendar_color

    @Property("QVariantList", notify=calendarEventsChanged)
    def calendarEvents(self) -> list[dict]:
        return list(self._calendar_events)

    @Property(str, notify=calendarViewChanged)
    def calendarView(self) -> str:
        return self._calendar_view

    @Property(str, notify=calendarDateChanged)
    def calendarDate(self) -> str:
        return self._calendar_date.isoformat()

    @Property("QVariantList", notify=calendarSourcesChanged)
    def appleCalendars(self) -> list[dict]:
        return [
            {**item, "selected": item["id"] in self._selected_apple_calendar_ids}
            for item in self._apple_calendars
        ]

    @Property("QVariantList", notify=calendarSourcesChanged)
    def googleCalendars(self) -> list[dict]:
        return [
            {**item, "selected": item["id"] in self._selected_google_calendar_ids}
            for item in self._google_calendars
        ]

    @Property("QVariantList", notify=calendarSourcesChanged)
    def calendarAvailableCalendars(self) -> list[dict]:
        return [
            item
            for item in self.appleCalendars + self.googleCalendars
            if item.get("selected")
        ]

    @Property("QVariantList", notify=fontFamilyChanged)
    def availableFonts(self) -> list[str]:
        return self._available_fonts

    @Property(str, notify=fontFamilyChanged)
    def fontFamily(self) -> str:
        return self._font_family or "System"

    @Property(str, notify=fontFamilyChanged)
    def fontFamilyResolved(self) -> str:
        return self._font_family or self._system_font_family

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
        self._list_service = ListService()
        self._ensure_current_list()
        self._selected_task_id = None
        self._load_settings()
        self.tasksChanged.emit()
        self.selectedTaskChanged.emit()
        self.currentSectionChanged.emit()
        self.sidebarListsChanged.emit()

    def _ensure_current_list(self) -> None:
        if self._list_service is None:
            return
        lists = self._list_service.list_lists()
        if not lists:
            return
        if self._current_list_id is None:
            self._current_list_id = lists[0].id
        current = self._list_service.get_by_id(self._current_list_id)
        if current is None:
            self._current_list_id = lists[0].id
            current = lists[0]
        self._current_section = current.name
        self._current_list_type = current.list_type

    def _load_fonts(self) -> list[str]:
        families = sorted({family for family in QFontDatabase.families() if family})
        return ["System"] + families

    def _load_settings(self) -> None:
        dark_mode = self._settings_repository.get("dark_mode")
        sidebar_collapsed = self._settings_repository.get("sidebar_collapsed")
        sidebar_blur_opacity = self._settings_repository.get("sidebar_blur_opacity")
        sidebar_blur_enabled = self._settings_repository.get("sidebar_blur_enabled")
        app_icon_choice = self._settings_repository.get("app_icon_choice")
        reminder_notify_app = self._settings_repository.get("reminder_notify_app")
        reminder_notify_system = self._settings_repository.get("reminder_notify_system")
        reminder_notify_background = self._settings_repository.get(
            "reminder_notify_background"
        )
        calendar_visible = self._settings_repository.get("calendar_visible")
        calendar_color = self._settings_repository.get("calendar_color")
        calendar_apple_selected = self._settings_repository.get("calendar_apple_selected")
        calendar_google_selected = self._settings_repository.get("calendar_google_selected")
        font_family = self._settings_repository.get("font_family")
        self._dark_mode = dark_mode == "1"
        self._sidebar_collapsed = sidebar_collapsed == "1"
        if sidebar_blur_opacity is not None:
            try:
                self._sidebar_blur_opacity = float(sidebar_blur_opacity)
            except ValueError:
                self._sidebar_blur_opacity = 0.7
        if sidebar_blur_enabled is not None:
            self._sidebar_blur_enabled = sidebar_blur_enabled == "1"
        if app_icon_choice in {"dark", "light"}:
            self._app_icon_choice = app_icon_choice
        if reminder_notify_app is not None:
            self._reminder_notify_app = reminder_notify_app == "1"
        if reminder_notify_system is not None:
            self._reminder_notify_system = reminder_notify_system == "1"
        if reminder_notify_background is not None:
            self._reminder_notify_background = reminder_notify_background == "1"
        if calendar_visible is not None:
            self._calendar_visible = calendar_visible == "1"
        if calendar_color:
            self._calendar_color = calendar_color
        if calendar_apple_selected:
            try:
                self._selected_apple_calendar_ids = set(
                    json.loads(calendar_apple_selected)
                )
            except json.JSONDecodeError:
                self._selected_apple_calendar_ids = set()
        if calendar_google_selected:
            try:
                self._selected_google_calendar_ids = set(
                    json.loads(calendar_google_selected)
                )
            except json.JSONDecodeError:
                self._selected_google_calendar_ids = set()
        if font_family is not None:
            if font_family == "System":
                self._font_family = ""
            else:
                self._font_family = font_family
        self.darkModeChanged.emit()
        self.sidebarCollapsedChanged.emit()
        self.sidebarBlurOpacityChanged.emit()
        self.sidebarBlurEnabledChanged.emit()
        self.appIconChoiceChanged.emit()
        self.reminderSettingsChanged.emit()
        self.calendarVisibilityChanged.emit()
        self.calendarColorChanged.emit()
        self.calendarSourcesChanged.emit()
        self.fontFamilyChanged.emit()
        if self._reminder_notify_background:
            project_root = Path(__file__).resolve().parents[2]
            install_launch_agent(project_root)

    def _save_setting(self, key: str, value: str) -> None:
        self._settings_repository.set(key, value)
        self._schedule_sync()

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
        if self._list_service is None:
            return
        for item in self._list_service.list_lists():
            if item.name == section:
                self._current_list_id = item.id
                self._current_section = item.name
                self._current_list_type = item.list_type
                break
        self._selected_task_id = None
        self.currentSectionChanged.emit()
        self.currentListTypeChanged.emit()
        self.tasksChanged.emit()
        self.selectedTaskChanged.emit()
        self.sidebarListsChanged.emit()

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
        if self._task_service is None or self._current_list_id is None:
            return
        if self._current_list_type in {"settings", "profile"}:
            return
        task = self._task_service.add_task(title, self._current_list_id)
        if task is None:
            return
        self._selected_task_id = task.id
        self.tasksChanged.emit()
        self.selectedTaskChanged.emit()
        self._schedule_sync()

    @Slot(str)
    def toggleTaskCompleted(self, task_id: str) -> None:
        if self._task_service is None:
            return
        changed = self._task_service.toggle_task_completed(task_id)
        if changed:
            self.tasksChanged.emit()
            self.selectedTaskChanged.emit()
            self._schedule_sync()

    @Slot(str, str)
    def updateTaskTitle(self, task_id: str, title: str) -> None:
        if self._task_service is None:
            return
        changed = self._task_service.update_task_title(task_id, title)
        if changed:
            self.tasksChanged.emit()
            self.selectedTaskChanged.emit()
            self._schedule_sync()

    @Slot(str, str)
    def updateTaskNotes(self, task_id: str, notes: str) -> None:
        if self._task_service is None:
            return
        changed = self._task_service.update_task_notes(task_id, notes)
        if changed:
            self.tasksChanged.emit()
            self.selectedTaskChanged.emit()
            self._schedule_sync()

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
            self._schedule_sync()

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
            self._schedule_sync()

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
            self._schedule_sync()

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

    @Slot(bool)
    def setSidebarBlurEnabled(self, value: bool) -> None:
        if self._sidebar_blur_enabled == value:
            return
        self._sidebar_blur_enabled = value
        self._save_setting("sidebar_blur_enabled", "1" if value else "0")
        self.sidebarBlurEnabledChanged.emit()

    @Slot(str)
    def setAppIconChoice(self, value: str) -> None:
        if value not in {"dark", "light"}:
            return
        if value == self._app_icon_choice:
            return
        self._app_icon_choice = value
        self._save_setting("app_icon_choice", value)
        self.appIconChoiceChanged.emit()

    @Slot(str)
    def setFontFamily(self, value: str) -> None:
        cleaned = value.strip()
        if cleaned == "System":
            cleaned = ""
        if cleaned == self._font_family:
            return
        self._font_family = cleaned
        self._save_setting("font_family", value or "System")
        self.fontFamilyChanged.emit()

    @Slot(str)
    def selectList(self, list_id: str) -> None:
        if self._list_service is None:
            return
        current = self._list_service.get_by_id(list_id)
        if current is None:
            return
        if list_id == self._current_list_id:
            return
        self._current_list_id = list_id
        self._current_section = current.name
        self._current_list_type = current.list_type
        self._selected_task_id = None
        self.currentSectionChanged.emit()
        self.currentListTypeChanged.emit()
        self.tasksChanged.emit()
        self.selectedTaskChanged.emit()

    @Slot()
    def selectCalendar(self) -> None:
        self._current_list_id = None
        self._current_section = "Calendar"
        self._current_list_type = "calendar"
        self._selected_task_id = None
        self.currentSectionChanged.emit()
        self.currentListTypeChanged.emit()
        self.tasksChanged.emit()
        self.selectedTaskChanged.emit()
        self.refreshCalendarEvents()

    @Slot(bool)
    def setCalendarVisible(self, value: bool) -> None:
        if self._calendar_visible == value:
            return
        self._calendar_visible = value
        self._save_setting("calendar_visible", "1" if value else "0")
        if not value and self._current_list_type == "calendar":
            self._ensure_current_list()
            self.currentSectionChanged.emit()
            self.currentListTypeChanged.emit()
            self.tasksChanged.emit()
        self.calendarVisibilityChanged.emit()

    @Slot(str)
    def setCalendarColor(self, value: str) -> None:
        cleaned = value.strip()
        if not cleaned:
            return
        if cleaned == self._calendar_color:
            return
        self._calendar_color = cleaned
        self._save_setting("calendar_color", cleaned)
        self.calendarColorChanged.emit()

    @Slot()
    def refreshCalendars(self) -> None:
        thread = threading.Thread(target=self._run_refresh_calendars, daemon=True)
        thread.start()

    def _run_refresh_calendars(self) -> None:
        apple = self._calendar_service.list_apple_calendars()
        google_token = (
            self._auth_service.load_google_calendar_tokens()
            or self._auth_service.load_cached_provider_tokens("google")
            or {}
        )
        google = self._calendar_service.list_google_calendars(
            google_token.get("access_token", "")
        )
        self._apple_calendars = apple
        self._google_calendars = google
        self.calendarSourcesChanged.emit()

    @Slot()
    def connectGoogleCalendar(self) -> None:
        thread = threading.Thread(target=self._run_google_calendar_auth, daemon=True)
        thread.start()

    def _run_google_calendar_auth(self) -> None:
        result = self._auth_service.authenticate_google_calendar()
        if "error" in result:
            self.authStatusMessage.emit(result["error"])
            return
        self.refreshCalendars()

    @Slot(str, bool)
    def toggleAppleCalendar(self, calendar_id: str, enabled: bool) -> None:
        if enabled:
            self._selected_apple_calendar_ids.add(calendar_id)
        else:
            self._selected_apple_calendar_ids.discard(calendar_id)
        self._save_setting(
            "calendar_apple_selected",
            json.dumps(sorted(self._selected_apple_calendar_ids)),
        )
        self.calendarSourcesChanged.emit()
        self.refreshCalendarEvents()

    @Slot(str, bool)
    def toggleGoogleCalendar(self, calendar_id: str, enabled: bool) -> None:
        if enabled:
            self._selected_google_calendar_ids.add(calendar_id)
        else:
            self._selected_google_calendar_ids.discard(calendar_id)
        self._save_setting(
            "calendar_google_selected",
            json.dumps(sorted(self._selected_google_calendar_ids)),
        )
        self.calendarSourcesChanged.emit()
        self.refreshCalendarEvents()

    @Slot(str)
    def setCalendarView(self, view: str) -> None:
        if view not in {"day", "month", "year"}:
            return
        if view == self._calendar_view:
            return
        self._calendar_view = view
        self.calendarViewChanged.emit()
        self.refreshCalendarEvents()

    @Slot(str)
    def setCalendarDate(self, value: str) -> None:
        try:
            self._calendar_date = date.fromisoformat(value)
        except ValueError:
            return
        self.calendarDateChanged.emit()
        self.refreshCalendarEvents()

    @Slot()
    def refreshCalendarEvents(self) -> None:
        thread = threading.Thread(target=self._run_refresh_events, daemon=True)
        thread.start()

    def _run_refresh_events(self) -> None:
        start, end = self._calendar_range()
        google_token = (
            self._auth_service.load_google_calendar_tokens()
            or self._auth_service.load_cached_provider_tokens("google")
            or {}
        )
        events = self._calendar_service.list_events(
            sorted(self._selected_apple_calendar_ids),
            sorted(self._selected_google_calendar_ids),
            start,
            end,
            google_token.get("access_token", ""),
        )
        self._calendar_events = events
        self.calendarEventsChanged.emit()

    def _calendar_range(self) -> tuple[datetime, datetime]:
        if self._calendar_view == "day":
            start_date = self._calendar_date
            end_date = self._calendar_date + timedelta(days=1)
        elif self._calendar_view == "year":
            start_date = date(self._calendar_date.year, 1, 1)
            end_date = date(self._calendar_date.year + 1, 1, 1)
        else:
            start_date = date(self._calendar_date.year, self._calendar_date.month, 1)
            if self._calendar_date.month == 12:
                end_date = date(self._calendar_date.year + 1, 1, 1)
            else:
                end_date = date(self._calendar_date.year, self._calendar_date.month + 1, 1)
        return (
            datetime.combine(start_date, datetime.min.time()),
            datetime.combine(end_date, datetime.min.time()),
        )

    @Slot(str, str, str, str, str, str, bool)
    def createCalendarEvent(
        self,
        provider: str,
        calendar_id: str,
        title: str,
        start_iso: str,
        end_iso: str,
        notes: str,
        all_day: bool,
    ) -> None:
        if not title.strip():
            return
        try:
            start_dt = datetime.fromisoformat(start_iso)
            end_dt = datetime.fromisoformat(end_iso)
        except ValueError:
            return
        if all_day:
            start_dt = datetime.combine(start_dt.date(), datetime.min.time())
            end_dt = datetime.combine(end_dt.date(), datetime.min.time()) + timedelta(days=1)
        google_token = (
            self._auth_service.load_google_calendar_tokens()
            or self._auth_service.load_cached_provider_tokens("google")
            or {}
        )
        self._calendar_service.create_event(
            provider,
            calendar_id,
            title.strip(),
            start_dt,
            end_dt,
            notes.strip(),
            "",
            google_token.get("access_token", ""),
            all_day,
        )
        self.refreshCalendarEvents()

    @Slot(str, str, str, str, str, str, str, bool)
    def updateCalendarEvent(
        self,
        provider: str,
        event_id: str,
        calendar_id: str,
        title: str,
        start_iso: str,
        end_iso: str,
        notes: str,
        all_day: bool,
    ) -> None:
        if not title.strip():
            return
        try:
            start_dt = datetime.fromisoformat(start_iso)
            end_dt = datetime.fromisoformat(end_iso)
        except ValueError:
            return
        if all_day:
            start_dt = datetime.combine(start_dt.date(), datetime.min.time())
            end_dt = datetime.combine(end_dt.date(), datetime.min.time()) + timedelta(days=1)
        google_token = (
            self._auth_service.load_google_calendar_tokens()
            or self._auth_service.load_cached_provider_tokens("google")
            or {}
        )
        self._calendar_service.update_event(
            provider,
            event_id,
            calendar_id,
            title.strip(),
            start_dt,
            end_dt,
            notes.strip(),
            "",
            google_token.get("access_token", ""),
            all_day,
        )
        self.refreshCalendarEvents()

    @Slot(str, str, str)
    def addSidebarList(self, name: str, icon: str, color: str) -> None:
        if self._list_service is None:
            return
        cleaned = name.strip()
        if not cleaned:
            return
        new_list = self._list_service.add_list(cleaned, icon or "•", color or "#9aa1ad")
        self._current_list_id = new_list.id
        self._current_section = new_list.name
        self.sidebarListsChanged.emit()
        self.currentSectionChanged.emit()
        self.tasksChanged.emit()
        self._schedule_sync()

    @Slot(str, str, str, str)
    def updateSidebarList(self, list_id: str, name: str, icon: str, color: str) -> None:
        if self._list_service is None:
            return
        cleaned = name.strip()
        if not cleaned:
            return
        changed = self._list_service.update_list(list_id, cleaned, icon or "•", color or "#9aa1ad")
        if changed:
            if list_id == self._current_list_id:
                self._current_section = cleaned
                self.currentSectionChanged.emit()
            self.sidebarListsChanged.emit()
            self._schedule_sync()

    @Slot(str)
    def updateCurrentListName(self, name: str) -> None:
        if self._list_service is None or self._current_list_id is None:
            return
        cleaned = name.strip()
        if not cleaned:
            return
        current = self._list_service.get_by_id(self._current_list_id)
        if current is None or current.list_type in {"settings", "profile", "calendar"}:
            return
        changed = self._list_service.update_list(
            self._current_list_id,
            cleaned,
            current.icon,
            current.color,
        )
        if changed:
            self._current_section = cleaned
            self.currentSectionChanged.emit()
            self.sidebarListsChanged.emit()
            self._schedule_sync()

    @Slot(str)
    def deleteSidebarList(self, list_id: str) -> None:
        if self._list_service is None:
            return
        fallback = next(
            (
                item
                for item in self._list_service.list_lists()
                if item.list_type not in {"settings", "profile"} and item.id != list_id
            ),
            None,
        )
        if fallback is None:
            return
        deleted = self._list_service.delete_list(list_id, fallback.id)
        if deleted:
            if self._current_list_id == list_id:
                self._current_list_id = fallback.id
                self._current_section = fallback.name
                self._current_list_type = fallback.list_type
            self.sidebarListsChanged.emit()
            self.currentSectionChanged.emit()
            self.currentListTypeChanged.emit()
            self.tasksChanged.emit()
            self._schedule_sync()

    @Slot(str)
    def toggleListPinned(self, list_id: str) -> None:
        if self._list_service is None:
            return
        changed = self._list_service.toggle_pinned(list_id)
        if changed:
            self.sidebarListsChanged.emit()
            self._schedule_sync()

    @Slot("QVariantList")
    def reorderSidebarLists(self, ordered_ids: list[str]) -> None:
        if self._list_service is None:
            return
        cleaned = [value for value in ordered_ids if isinstance(value, str)]
        if not cleaned:
            return
        self._list_service.reorder_lists(cleaned)
        self.sidebarListsChanged.emit()
        self._schedule_sync()

    @Slot(bool)
    def setReminderNotifyApp(self, value: bool) -> None:
        if self._reminder_notify_app == value:
            return
        self._reminder_notify_app = value
        self._save_setting("reminder_notify_app", "1" if value else "0")
        self.reminderSettingsChanged.emit()

    @Slot(bool)
    def setReminderNotifySystem(self, value: bool) -> None:
        if self._reminder_notify_system == value:
            return
        self._reminder_notify_system = value
        self._save_setting("reminder_notify_system", "1" if value else "0")
        self.reminderSettingsChanged.emit()

    @Slot(bool)
    def setReminderNotifyBackground(self, value: bool) -> None:
        if self._reminder_notify_background == value:
            return
        self._reminder_notify_background = value
        self._save_setting("reminder_notify_background", "1" if value else "0")
        project_root = Path(__file__).resolve().parents[2]
        if value:
            install_launch_agent(project_root)
        else:
            uninstall_launch_agent()
        self.reminderSettingsChanged.emit()

    @Slot()
    def toggleEditMode(self) -> None:
        self._edit_mode = not self._edit_mode
        self.editModeChanged.emit()
        self.tasksChanged.emit()
        self.selectedTaskChanged.emit()

    @Slot()
    def showEmojiPicker(self) -> None:
        show_emoji_picker()

    def _start_reminder_timer(self) -> None:
        self._reminder_timer = QTimer(self)
        self._reminder_timer.setInterval(30000)
        self._reminder_timer.timeout.connect(self._check_due_reminders)
        self._reminder_timer.start()

    def _check_due_reminders(self) -> None:
        if self._task_service is None:
            return
        now = datetime.now()
        tasks = self._task_service.list_tasks()
        for task in tasks:
            if task.is_completed:
                continue
            if task.reminder_at is None:
                continue
            if task.reminder_at > now:
                continue
            if task.reminder_fired_at is not None:
                continue

            title = task.title
            body = "Reminder"

            if self._reminder_notify_app:
                self._banner_message = f"{title}"
                self._banner_visible = True
                self.bannerChanged.emit()

            if self._reminder_notify_system:
                send_notification(title, body)

            self._task_service.mark_reminder_fired(task.id, now)

        if self._banner_visible:
            QTimer.singleShot(5000, self._hide_banner)

    def _hide_banner(self) -> None:
        if not self._banner_visible:
            return
        self._banner_visible = False
        self.bannerChanged.emit()

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
            self._start_sync()
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

    def _start_sync(self) -> None:
        identity = self._auth_service.load_cached_identity() or {}
        provider = identity.get("provider")
        provider_user_id = identity.get("provider_user_id")
        if not provider or not provider_user_id:
            return
        tokens = self._auth_service.load_cached_provider_tokens(provider) or {}
        access_token = tokens.get("access_token", "")
        thread = threading.Thread(
            target=self._run_sync,
            args=(provider, provider_user_id, access_token),
            daemon=True,
        )
        thread.start()

    def _run_sync(self, provider: str, provider_user_id: str, access_token: str) -> None:
        try:
            self.authStatusMessage.emit("Syncing with server...")
            conflicts = self._sync_service.sync(
                provider,
                provider_user_id,
                self._user_email,
                self._user_name,
                access_token,
            )
            if conflicts:
                for item in conflicts:
                    self._add_sync_log(
                        f"Server overwrote {item['entity']} {item['entity_id']}",
                        item,
                    )
            if self._list_service is not None:
                self._list_service.refresh()
                self.sidebarListsChanged.emit()
            if self._task_service is not None:
                self._task_service.refresh()
                self.tasksChanged.emit()
            self._last_sync_at = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            self.syncLogsChanged.emit()
            self.authStatusMessage.emit("Sync complete.")
        except Exception as exc:
            self.authStatusMessage.emit(f"Sync failed: {exc}")
            self._add_sync_log(f"Sync failed: {exc}", {})

    def _schedule_sync(self) -> None:
        if not self._is_authenticated:
            return
        identity = self._auth_service.load_cached_identity() or {}
        if not identity.get("provider") or not identity.get("provider_user_id"):
            return
        if self._sync_timer is None:
            self._sync_timer = QTimer(self)
            self._sync_timer.setSingleShot(True)
            self._sync_timer.timeout.connect(self._start_sync)
        self._sync_timer.start(1200)

    def _add_sync_log(self, message: str, details: dict) -> None:
        entry = {
            "timestamp": datetime.now().isoformat(timespec="seconds"),
            "message": message,
            "details": details,
        }
        self._sync_logs.insert(0, entry)
        self._sync_logs = self._sync_logs[:50]
        self.syncLogsChanged.emit()

    @Slot()
    def clearSyncLogs(self) -> None:
        self._sync_logs = []
        self.syncLogsChanged.emit()
