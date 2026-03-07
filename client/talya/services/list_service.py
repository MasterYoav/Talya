from __future__ import annotations

from talya.domain.sidebar_list import SidebarList
from talya.infrastructure.list_repository import ListRepository


class ListService:
    def __init__(self) -> None:
        self._repository = ListRepository()
        self._lists: list[SidebarList] = self._repository.list_lists()

    def list_lists(self) -> list[SidebarList]:
        return list(self._lists)

    def refresh(self) -> None:
        self._lists = self._repository.list_lists()

    def get_by_id(self, list_id: str) -> SidebarList | None:
        for item in self._lists:
            if item.id == list_id:
                return item
        return None

    def add_list(self, name: str, icon: str, color: str) -> SidebarList:
        new_list = self._repository.add_list(
            name=name,
            icon=icon,
            color=color,
            list_type="user",
            is_system=False,
        )
        self.refresh()
        return new_list

    def update_list(self, list_id: str, name: str, icon: str, color: str) -> bool:
        for item in self._lists:
            if item.id == list_id:
                item.name = name
                item.icon = icon
                item.color = color
                self._repository.update_list(list_id, name, icon, color)
                self.refresh()
                return True
        self._repository.update_list(list_id, name, icon, color)
        self.refresh()
        return True

    def toggle_pinned(self, list_id: str) -> bool:
        for item in self._lists:
            if item.id == list_id:
                item.is_pinned = not item.is_pinned
                self._repository.set_pinned(item.id, item.is_pinned)
                self.refresh()
                return True
        return False

    def delete_list(self, list_id: str, fallback_list_id: str) -> bool:
        for index, item in enumerate(self._lists):
            if item.id == list_id:
                del self._lists[index]
                self._repository.update_task_list(list_id, fallback_list_id)
                self._repository.delete_list(list_id)
                self.refresh()
                return True
        return False

    def reorder_lists(self, ordered_ids: list[str]) -> None:
        self._repository.update_positions(ordered_ids)
        self.refresh()
