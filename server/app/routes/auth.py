from __future__ import annotations

from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
import requests
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..auth import create_access_token
from ..database import get_db
from ..models import Identity, User
from ..schemas import OAuthLoginRequest, OAuthLoginResponse

router = APIRouter(prefix="/auth", tags=["auth"])

GOOGLE_USERINFO_URL = "https://openidconnect.googleapis.com/v1/userinfo"
GITHUB_USER_URL = "https://api.github.com/user"


def _verify_google(access_token: str, provider_user_id: str) -> dict:
    response = requests.get(
        GOOGLE_USERINFO_URL,
        headers={"Authorization": f"Bearer {access_token}"},
        timeout=15,
    )
    if response.status_code != 200:
        raise HTTPException(status_code=401, detail="Google token invalid.")
    profile = response.json()
    if str(profile.get("sub", "")) != provider_user_id:
        raise HTTPException(status_code=401, detail="Google identity mismatch.")
    return profile


def _verify_github(access_token: str, provider_user_id: str) -> dict:
    response = requests.get(
        GITHUB_USER_URL,
        headers={"Authorization": f"Bearer {access_token}"},
        timeout=15,
    )
    if response.status_code != 200:
        raise HTTPException(status_code=401, detail="GitHub token invalid.")
    profile = response.json()
    if str(profile.get("id", "")) != provider_user_id:
        raise HTTPException(status_code=401, detail="GitHub identity mismatch.")
    return profile


@router.post("/oauth/login", response_model=OAuthLoginResponse)
def oauth_login(payload: OAuthLoginRequest, db: Session = Depends(get_db)):
    if payload.provider == "google":
        profile = _verify_google(payload.access_token, payload.provider_user_id)
        email = profile.get("email", "") or payload.email
        name = profile.get("name", "") or payload.name
    elif payload.provider == "github":
        profile = _verify_github(payload.access_token, payload.provider_user_id)
        email = profile.get("email", "") or payload.email
        name = profile.get("name", "") or payload.name
    else:
        raise HTTPException(status_code=400, detail="Unsupported provider.")

    identity = db.execute(
        select(Identity).where(
            Identity.provider == payload.provider,
            Identity.provider_user_id == payload.provider_user_id,
        )
    ).scalar_one_or_none()

    if identity is None:
        user = User(
            name=name,
            email=email,
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
        if email and user.email != email:
            user.email = email
            user.updated_at = datetime.utcnow()
        if name and user.name != name:
            user.name = name
            user.updated_at = datetime.utcnow()
        db.commit()

    if user is None:
        raise HTTPException(status_code=400, detail="User not found")

    token = create_access_token(user.id)
    return OAuthLoginResponse(access_token=token)
