from __future__ import annotations

from datetime import datetime
import os

import requests

from talya.infrastructure.list_repository import ListRepository
from talya.infrastructure.settings_repository import SettingsRepository
from talya.infrastructure.task_repository import TaskRepository
from talya.infrastructure.token_store import TokenStore


class SyncService:
    def __init__(self) -> None:
        self._base_url = os.getenv("TALYA_API_BASE_URL", "http://127.0.0.1:8000")
        self._token_store = TokenStore()
        self._list_repository = ListRepository()
        self._task_repository = TaskRepository()
        self._settings_repository = SettingsRepository()

    def login(
        self,
        provider: str,
        provider_user_id: str,
        email: str,
        name: str,
        access_token: str,
    ) -> str:
        response = requests.post(
            f"{self._base_url}/auth/oauth/login",
            json={
                "provider": provider,
                "provider_user_id": provider_user_id,
                "access_token": access_token,
                "email": email,
                "name": name,
            },
            timeout=20,
        )
        response.raise_for_status()
        token = response.json().get("access_token")
        if not token:
            raise RuntimeError("Missing access token from server.")
        self._token_store.save("server_token", {"token": token})
        return token

    def _load_token(self) -> str | None:
        stored = self._token_store.load("server_token")
        if not stored:
            return None
        return stored.get("token")

    def sync(
        self,
        provider: str,
        provider_user_id: str,
        email: str,
        name: str,
        access_token: str,
    ) -> None:
        token = self._load_token()
        if not token:
            if not access_token:
                raise RuntimeError("Missing provider access token for server login.")
            token = self.login(provider, provider_user_id, email, name, access_token)

        now = datetime.utcnow().isoformat()
        lists = []
        for row in self._list_repository.list_all_lists():
            lists.append(
                {
                    "id": row["id"],
                    "name": row["name"],
                    "icon": row["icon"],
                    "color": row["color"],
                    "list_type": row["list_type"],
                    "is_system": bool(row["is_system"]),
                    "is_pinned": bool(row["is_pinned"]),
                    "position": int(row["position"]),
                    "is_deleted": bool(row["is_deleted"]),
                    "deleted_at": row["deleted_at"],
                    "created_at": row["created_at"],
                    "updated_at": row["updated_at"] or now,
                }
            )

        tasks = []
        for row in self._task_repository.list_all_tasks():
            tasks.append(
                {
                    "id": row["id"],
                    "list_id": row["list_id"] or row["section"],
                    "title": row["title"],
                    "notes": row["notes"] or "",
                    "is_completed": bool(row["is_completed"]),
                    "due_date": row["due_date"],
                    "reminder_at": row["reminder_at"],
                    "reminder_fired_at": row["reminder_fired_at"],
                    "is_deleted": bool(row["is_deleted"]),
                    "deleted_at": row["deleted_at"],
                    "created_at": row["created_at"],
                    "updated_at": row["updated_at"] or now,
                }
            )

        settings = []
        for setting in self._settings_repository.list_settings():
            settings.append(
                {
                    "key": setting["key"],
                    "value": setting["value"],
                    "updated_at": setting["updated_at"] or now,
                }
            )

        response = requests.post(
            f"{self._base_url}/sync/merge",
            json={"lists": lists, "tasks": tasks, "settings": settings},
            headers={"Authorization": f"Bearer {token}"},
            timeout=30,
        )
        response.raise_for_status()
        payload = response.json()

        for item in payload.get("lists", []):
            self._list_repository.upsert_list(item)

        for item in payload.get("tasks", []):
            self._task_repository.upsert_task(item)

        for item in payload.get("settings", []):
            self._settings_repository.upsert_setting(
                item["key"], item["value"], item["updated_at"]
            )
