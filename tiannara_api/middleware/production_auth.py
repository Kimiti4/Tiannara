"""Require authentication on sensitive routes when ENVIRONMENT=production."""

from __future__ import annotations

import os
from typing import FrozenSet, Tuple

from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import JSONResponse, Response

from tiannara_api.gateway.auth import verify_jwt_token
from tiannara_api.middleware.api_key_auth import lookup_user_by_api_key
from tiannara_api.security.cookies import get_token_from_request

PUBLIC_PREFIXES: Tuple[str, ...] = (
    "/health",
    "/status",
    "/metrics",
    "/api/v1/auth",
    "/api/v1/payment",
    "/api/v1/sso",
    "/docs",
    "/openapi.json",
    "/redoc",
)

PROTECTED_PREFIXES: Tuple[str, ...] = (
    "/autonomous",
    "/memory",
    "/modules",
    "/discovery",
    "/evolution",
    "/autonomy",
    "/api/v1/core",
    "/api/v1/cognitive",
    "/api/v1/observatory",
    "/api/v1/analyze",
)


def _is_protected(path: str) -> bool:
    return any(path.startswith(p) for p in PROTECTED_PREFIXES)


def _is_public(path: str) -> bool:
    return any(path.startswith(p) for p in PUBLIC_PREFIXES)


def _credentials_valid(request: Request) -> bool:
    token = get_token_from_request(request)
    if token:
        try:
            verify_jwt_token(token)
            return True
        except Exception:
            return False
    api_key = request.headers.get("X-API-Key")
    if api_key and lookup_user_by_api_key(api_key):
        return True
    return False


class ProductionAuthMiddleware(BaseHTTPMiddleware):
    """Block unauthenticated access to cognitive/core routes in production."""

    async def dispatch(self, request: Request, call_next) -> Response:
        if request.method == "OPTIONS":
            return await call_next(request)

        env = os.getenv("ENVIRONMENT", "development").lower()
        if env != "production":
            return await call_next(request)

        path = request.url.path
        if _is_public(path) or not _is_protected(path):
            return await call_next(request)

        if _credentials_valid(request):
            return await call_next(request)

        return JSONResponse(
            status_code=401,
            content={"detail": "Authentication required. Provide Bearer token or X-API-Key."},
            headers={"WWW-Authenticate": "Bearer"},
        )
