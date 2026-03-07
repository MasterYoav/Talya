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

    def _clear_token(self) -> None:
        self._token_store.clear("server_token")

    def sync(
        self,
        provider: str,
        provider_user_id: str,
        email: str,
        name: str,
        access_token: str,
    ) -> list[dict]:
        token = self._load_token()
        if not token:
            if not access_token:
                raise RuntimeError("Missing provider access token for server login.")
            token = self.login(provider, provider_user_id, email, name, access_token)

        now = datetime.utcnow().isoformat()
        local_list_updated = {}
        local_task_updated = {}
        local_setting_updated = {}
        lists = []
        for row in self._list_repository.list_all_lists():
            updated_at = row["updated_at"] or now
            local_list_updated[row["id"]] = updated_at
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
                    "updated_at": updated_at,
                }
            )

        tasks = []
        for row in self._task_repository.list_all_tasks():
            updated_at = row["updated_at"] or now
            local_task_updated[row["id"]] = updated_at
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
                    "updated_at": updated_at,
                }
            )

        settings = []
        for setting in self._settings_repository.list_settings():
            updated_at = setting["updated_at"] or now
            local_setting_updated[setting["key"]] = updated_at
            settings.append(
                {
                    "key": setting["key"],
                    "value": setting["value"],
                    "updated_at": updated_at,
                }
            )

        payload = self._post_merge(token, lists, tasks, settings, provider, provider_user_id, email, name, access_token)
        conflicts = []

        for item in payload.get("lists", []):
            self._list_repository.upsert_list(item)
            conflict = self._detect_conflict("list", item["id"], local_list_updated.get(item["id"]), item["updated_at"])
            if conflict:
                conflicts.append(conflict)

        for item in payload.get("tasks", []):
            self._task_repository.upsert_task(item)
            conflict = self._detect_conflict("task", item["id"], local_task_updated.get(item["id"]), item["updated_at"])
            if conflict:
                conflicts.append(conflict)

        for item in payload.get("settings", []):
            self._settings_repository.upsert_setting(
                item["key"], item["value"], item["updated_at"]
            )
            conflict = self._detect_conflict("setting", item["key"], local_setting_updated.get(item["key"]), item["updated_at"])
            if conflict:
                conflicts.append(conflict)

        return conflicts

    def _post_merge(
        self,
        token: str,
        lists: list[dict],
        tasks: list[dict],
        settings: list[dict],
        provider: str,
        provider_user_id: str,
        email: str,
        name: str,
        access_token: str,
    ) -> dict:
        response = requests.post(
            f"{self._base_url}/sync/merge",
            json={"lists": lists, "tasks": tasks, "settings": settings},
            headers={"Authorization": f"Bearer {token}"},
            timeout=30,
        )
        if response.status_code == 401:
            self._clear_token()
            token = self.login(provider, provider_user_id, email, name, access_token)
            response = requests.post(
                f"{self._base_url}/sync/merge",
                json={"lists": lists, "tasks": tasks, "settings": settings},
                headers={"Authorization": f"Bearer {token}"},
                timeout=30,
            )
        response.raise_for_status()
        return response.json()

    @staticmethod
    def _parse_dt(value: str | None) -> datetime | None:
        if not value:
            return None
        return datetime.fromisoformat(value)

    def _detect_conflict(
        self,
        entity: str,
        entity_id: str,
        local_updated_at: str | None,
        server_updated_at: str | None,
    ) -> dict | None:
        local_dt = self._parse_dt(local_updated_at)
        server_dt = self._parse_dt(server_updated_at)
        if local_dt and server_dt and server_dt > local_dt:
            return {
                "entity": entity,
                "entity_id": entity_id,
                "server_updated_at": server_updated_at,
                "local_updated_at": local_updated_at,
            }
        return None
