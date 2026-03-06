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

    @staticmethod
    def create(title: str, section: str) -> "Task":
        return Task(
            id=str(uuid4()),
            title=title.strip(),
            section=section,
            is_completed=False,
            created_at=datetime.now(),
        )
