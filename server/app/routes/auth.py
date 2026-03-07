from __future__ import annotations

from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..auth import create_access_token
from ..database import get_db
from ..models import Identity, User
from ..schemas import OAuthLoginRequest, OAuthLoginResponse

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/oauth/login", response_model=OAuthLoginResponse)
def oauth_login(payload: OAuthLoginRequest, db: Session = Depends(get_db)):
    identity = db.execute(
        select(Identity).where(
            Identity.provider == payload.provider,
            Identity.provider_user_id == payload.provider_user_id,
        )
    ).scalar_one_or_none()

    if identity is None:
        user = User(
            name=payload.name,
            email=payload.email,
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
        )
        db.add(user)
        db.flush()
        identity = Identity(
            user_id=user.id,
            provider=payload.provider,
            provider_user_id=payload.provider_user_id,
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
        )
        db.add(identity)
        db.commit()
        db.refresh(user)
    else:
        user = db.execute(select(User).where(User.id == identity.user_id)).scalar_one()
        if payload.email and user.email != payload.email:
            user.email = payload.email
            user.updated_at = datetime.utcnow()
        if payload.name and user.name != payload.name:
            user.name = payload.name
            user.updated_at = datetime.utcnow()
        db.commit()

    if user is None:
        raise HTTPException(status_code=400, detail="User not found")

    token = create_access_token(user.id)
    return OAuthLoginResponse(access_token=token)
