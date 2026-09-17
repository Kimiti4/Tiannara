"""Shared FastAPI dependencies for JWT and API-key authentication."""

from __future__ import annotations

import os
from typing import Any, Dict, Optional

from fastapi import Depends, Header, HTTPException, Request, status
from sqlalchemy.orm import Session

from tiannara_api.database import get_db
from tiannara_api.database.models import User
from tiannara_api.gateway.auth import verify_jwt_token
from tiannara_api.middleware.api_key_auth import lookup_user_by_api_key
from tiannara_api.security.cookies import get_token_from_request


def _user_dict(user: User) -> Dict[str, Any]:
    data = user.to_dict() if hasattr(user, "to_dict") else {}
    if not data:
        data = {
            "id": user.id,
            "email": user.email,
            "name": user.name,
            "tier": user.tier,
            "is_admin": user.is_admin,
        }
    return data


async def require_auth(
    request: Request,
    authorization: Optional[str] = Header(None),
    x_api_key: Optional[str] = Header(None, alias="X-API-Key"),
    db: Session = Depends(get_db),
) -> Dict[str, Any]:
    """
    Require valid JWT (Authorization: Bearer) or X-API-Key.

    Sets request.state.user_id for tier decorators.
    In development, unauthenticated requests are allowed (legacy compat).
    """
    user_data: Optional[Dict[str, Any]] = None

    token = get_token_from_request(request, authorization)
    if token:
        try:
            payload = verify_jwt_token(token)
            email = payload.get("email")
            if email:
                record = db.query(User).filter(User.email == email.lower()).first()
                if record:
                    user_data = _user_dict(record)
        except HTTPException:
            pass

    if not user_data and x_api_key:
        ctx = lookup_user_by_api_key(x_api_key)
        if ctx:
            record = db.query(User).filter(User.id == ctx["user_id"]).first()
            if record:
                user_data = _user_dict(record)

    if not user_data:
        if os.getenv("ENVIRONMENT", "development") != "production":
            return {"id": None, "email": None, "tier": "starter", "is_admin": False}
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication required. Provide Bearer token or X-API-Key.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    request.state.user_id = user_data.get("id")
    request.state.user_email = user_data.get("email")
    request.state.user_tier = user_data.get("tier")
    return user_data
