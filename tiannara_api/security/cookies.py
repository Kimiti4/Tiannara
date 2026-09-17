"""HttpOnly session cookie helpers for browser clients."""

from __future__ import annotations

import os
from typing import Optional

from fastapi import Request, Response

AUTH_COOKIE_NAME = "tiannara_token"
_COOKIE_MAX_AGE = int(os.getenv("JWT_EXPIRATION_HOURS", "24")) * 3600


def _cookie_secure() -> bool:
    return os.getenv("ENVIRONMENT", "development").lower() == "production"


def set_auth_cookie(response: Response, token: str) -> None:
    """Set HttpOnly JWT cookie (not accessible to JavaScript)."""
    response.set_cookie(
        key=AUTH_COOKIE_NAME,
        value=token,
        httponly=True,
        secure=_cookie_secure(),
        samesite="none" if _cookie_secure() else "lax",
        max_age=_COOKIE_MAX_AGE,
        path="/",
    )


def clear_auth_cookie(response: Response) -> None:
    response.delete_cookie(
        key=AUTH_COOKIE_NAME,
        path="/",
        httponly=True,
        secure=_cookie_secure(),
        samesite="none" if _cookie_secure() else "lax",
    )


def get_token_from_request(
    request: Request,
    authorization: Optional[str] = None,
) -> Optional[str]:
    """Resolve JWT from Authorization header or HttpOnly cookie."""
    if authorization:
        if authorization.startswith("Bearer "):
            return authorization[7:].strip()
        return authorization.strip()
    return request.cookies.get(AUTH_COOKIE_NAME)
