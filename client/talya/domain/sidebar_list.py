from __future__ import annotations

from dataclasses import dataclass


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
