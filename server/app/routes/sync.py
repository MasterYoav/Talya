from __future__ import annotations

from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
import jwt
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..auth import decode_access_token
from ..database import get_db
from ..models import List as ListModel
from ..models import Setting as SettingModel
from ..models import Task as TaskModel
from ..models import User
from ..schemas import ListPayload, SettingPayload, SyncRequest, SyncResponse, TaskPayload

router = APIRouter(prefix="/sync", tags=["sync"])
security = HTTPBearer()


def _current_user_id(
    creds: HTTPAuthorizationCredentials = Depends(security),
) -> str:
    token = creds.credentials
    try:
        data = decode_access_token(token)
        return data["sub"]
    except jwt.ExpiredSignatureError as exc:
        raise HTTPException(status_code=401, detail="Token expired.") from exc
    except jwt.InvalidTokenError as exc:
        raise HTTPException(status_code=401, detail="Invalid token.") from exc


@router.post("/merge", response_model=SyncResponse)
def merge(
    payload: SyncRequest,
    user_id: str = Depends(_current_user_id),
    db: Session = Depends(get_db),
):
    user = db.execute(select(User).where(User.id == user_id)).scalar_one_or_none()
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")

    now = datetime.utcnow()

    for item in payload.lists:
        existing = db.execute(
            select(ListModel).where(ListModel.id == item.id, ListModel.user_id == user_id)
        ).scalar_one_or_none()
        if existing is None:
            db.add(
                ListModel(
                    id=item.id,
                    user_id=user_id,
                    name=item.name,
                    icon=item.icon,
                    color=item.color,
                    list_type=item.list_type,
                    is_system=item.is_system,
                    is_pinned=item.is_pinned,
                    position=item.position,
                    is_deleted=item.is_deleted,
                    deleted_at=item.deleted_at,
                    created_at=item.created_at or now,
                    updated_at=item.updated_at,
                )
            )
        else:
            if item.updated_at >= existing.updated_at:
                existing.name = item.name
                existing.icon = item.icon
                existing.color = item.color
                existing.list_type = item.list_type
                existing.is_system = item.is_system
                existing.is_pinned = item.is_pinned
                existing.position = item.position
                existing.is_deleted = item.is_deleted
                existing.deleted_at = item.deleted_at
                existing.updated_at = item.updated_at

    for item in payload.tasks:
        existing = db.execute(
            select(TaskModel).where(TaskModel.id == item.id, TaskModel.user_id == user_id)
        ).scalar_one_or_none()
        if existing is None:
            db.add(
                TaskModel(
                    id=item.id,
                    user_id=user_id,
                    list_id=item.list_id,
                    title=item.title,
                    notes=item.notes,
                    is_completed=item.is_completed,
                    due_date=item.due_date,
                    reminder_at=item.reminder_at,
                    reminder_fired_at=item.reminder_fired_at,
                    is_deleted=item.is_deleted,
                    deleted_at=item.deleted_at,
                    created_at=item.created_at or now,
                    updated_at=item.updated_at,
                )
            )
        else:
            if item.updated_at >= existing.updated_at:
                existing.list_id = item.list_id
                existing.title = item.title
                existing.notes = item.notes
                existing.is_completed = item.is_completed
                existing.due_date = item.due_date
                existing.reminder_at = item.reminder_at
                existing.reminder_fired_at = item.reminder_fired_at
                existing.is_deleted = item.is_deleted
                existing.deleted_at = item.deleted_at
                existing.updated_at = item.updated_at

    for item in payload.settings:
        existing = db.execute(
            select(SettingModel).where(
                SettingModel.user_id == user_id, SettingModel.key == item.key
            )
        ).scalar_one_or_none()
        if existing is None:
            db.add(
                SettingModel(
                    user_id=user_id,
                    key=item.key,
                    value=item.value,
                    updated_at=item.updated_at,
                )
            )
        else:
            if item.updated_at >= existing.updated_at:
                existing.value = item.value
                existing.updated_at = item.updated_at

    db.commit()

    list_rows = db.execute(select(ListModel).where(ListModel.user_id == user_id)).scalars().all()
    task_rows = db.execute(select(TaskModel).where(TaskModel.user_id == user_id)).scalars().all()
    settings_rows = (
        db.execute(select(SettingModel).where(SettingModel.user_id == user_id)).scalars().all()
    )

    return SyncResponse(
        lists=[
            ListPayload(
                id=row.id,
                name=row.name,
                icon=row.icon,
                color=row.color,
                list_type=row.list_type,
                is_system=row.is_system,
                is_pinned=row.is_pinned,
                position=row.position,
                is_deleted=row.is_deleted,
                deleted_at=row.deleted_at,
                created_at=row.created_at,
                updated_at=row.updated_at,
            )
            for row in list_rows
        ],
        tasks=[
            TaskPayload(
                id=row.id,
                list_id=row.list_id,
                title=row.title,
                notes=row.notes,
                is_completed=row.is_completed,
                due_date=row.due_date,
                reminder_at=row.reminder_at,
                reminder_fired_at=row.reminder_fired_at,
                is_deleted=row.is_deleted,
                deleted_at=row.deleted_at,
                created_at=row.created_at,
                updated_at=row.updated_at,
            )
            for row in task_rows
        ],
        settings=[
            SettingPayload(
                key=row.key,
                value=row.value,
                updated_at=row.updated_at,
            )
            for row in settings_rows
        ],
        server_time=now,
    )
