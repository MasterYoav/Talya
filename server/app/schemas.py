from __future__ import annotations

from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field


class OAuthLoginRequest(BaseModel):
    provider: Literal["google", "github"]
    provider_user_id: str
    access_token: str
    email: str
    name: str = ""


class OAuthLoginResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


class ListPayload(BaseModel):
    id: str
    name: str
    icon: str
    color: str
    list_type: str
    is_system: bool = False
    is_pinned: bool = False
    position: int = 0
    is_deleted: bool = False
    deleted_at: datetime | None = None
    created_at: datetime | None = None
    updated_at: datetime


class TaskPayload(BaseModel):
    id: str
    list_id: str
    title: str
    notes: str = ""
    is_completed: bool = False
    due_date: str | None = None
    reminder_at: str | None = None
    reminder_fired_at: str | None = None
    is_deleted: bool = False
    deleted_at: datetime | None = None
    created_at: datetime | None = None
    updated_at: datetime


class SettingPayload(BaseModel):
    key: str
    value: str
    updated_at: datetime


class SyncRequest(BaseModel):
    lists: list[ListPayload] = Field(default_factory=list)
    tasks: list[TaskPayload] = Field(default_factory=list)
    settings: list[SettingPayload] = Field(default_factory=list)
    last_sync_at: datetime | None = None


class SyncResponse(BaseModel):
    lists: list[ListPayload]
    tasks: list[TaskPayload]
    settings: list[SettingPayload]
    server_time: datetime
