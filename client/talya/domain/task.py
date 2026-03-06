from dataclasses import dataclass
from datetime import datetime
from uuid import uuid4


@dataclass
class Task:
    id: str
    title: str
    section: str
    is_completed: bool
    created_at: datetime
    updated_at: datetime | None = None
    notes: str | None = None
    due_date: datetime | None = None
    reminder_at: datetime | None = None

    @staticmethod
    def create(title: str, section: str) -> "Task":
        now = datetime.now()
        return Task(
            id=str(uuid4()),
            title=title.strip(),
            section=section,
            is_completed=False,
            created_at=now,
            updated_at=now,
            notes=None,
            due_date=None,
            reminder_at=None,
        )
