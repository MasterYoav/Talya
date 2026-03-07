from __future__ import annotations

import json

import keyring


class TokenStore:
    def __init__(self, service_name: str = "talya") -> None:
        self._service_name = service_name

    def save(self, key: str, payload: dict) -> None:
        keyring.set_password(self._service_name, key, json.dumps(payload))

    def load(self, key: str) -> dict | None:
        stored = keyring.get_password(self._service_name, key)
        if not stored:
            return None
        try:
            return json.loads(stored)
        except json.JSONDecodeError:
            return None

    def clear(self, key: str) -> None:
        try:
            keyring.delete_password(self._service_name, key)
        except keyring.errors.PasswordDeleteError:
            return
