from __future__ import annotations

import time
from datetime import datetime
from pathlib import Path

from talya.infrastructure.database import initialize_database, set_database_path
from talya.infrastructure.macos_notifications import send_notification
from talya.infrastructure.settings_repository import SettingsRepository
from talya.infrastructure.task_repository import TaskRepository


def _account_db_paths(project_root: Path) -> list[Path]:
    paths = [project_root / "data" / "talya.db"]
    accounts_root = project_root / "data" / "accounts"
    if accounts_root.exists():
        for entry in accounts_root.iterdir():
            if entry.is_dir():
                candidate = entry / "talya.db"
                if candidate.exists():
                    paths.append(candidate)
    return paths


def _process_account(db_path: Path) -> None:
    set_database_path(db_path)
    initialize_database()
    settings = SettingsRepository()
    if settings.get("reminder_notify_background") != "1":
        return
    if settings.get("reminder_notify_system") != "1":
        return

    repository = TaskRepository()
    now = datetime.now()
    for task in repository.list_tasks():
        if task.is_completed:
            continue
        if task.reminder_at is None or task.reminder_at > now:
            continue
        if task.reminder_fired_at is not None:
            continue

        send_notification(task.title, "Reminder")
        repository.update_task_reminder_fired_at(task.id, now)


def main() -> None:
    project_root = Path(__file__).resolve().parents[2]
    while True:
        for db_path in _account_db_paths(project_root):
            _process_account(db_path)
        time.sleep(60)


if __name__ == "__main__":
    main()
