from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime


@dataclass
class SidebarList:
    id: str
    name: str
    icon: str
    color: str
    position: int
    list_type: str
    is_system: bool
    is_pinned: bool
    is_deleted: bool = False
    deleted_at: datetime | None = None
    created_at: datetime | None = None
    updated_at: datetime | None = None
