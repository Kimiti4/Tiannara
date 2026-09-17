"""WebSocket authentication via HttpOnly session cookie or API key."""

from __future__ import annotations

from typing import Any, Dict, Optional

from fastapi import WebSocket

from tiannara_api.gateway.auth import verify_jwt_token
from tiannara_api.middleware.api_key_auth import lookup_user_by_api_key
from tiannara_api.security.cookies import AUTH_COOKIE_NAME


async def authenticate_websocket(websocket: WebSocket) -> Optional[Dict[str, Any]]:
    """
    Validate credentials before accepting the connection.

    Browser clients: HttpOnly ``tiannara_token`` cookie (same-origin /ws proxy).
    Programmatic clients: ``api_key`` query param or ``X-API-Key`` header.
    """
    token = websocket.cookies.get(AUTH_COOKIE_NAME)
    if token:
        try:
            payload = verify_jwt_token(token)
            if payload.get("user_id") or payload.get("email"):
                return {
                    "user_id": payload.get("user_id"),
                    "email": payload.get("email"),
                    "tier": payload.get("tier", "starter"),
                }
        except Exception:
            return None

    api_key = (
        websocket.query_params.get("api_key")
        or websocket.headers.get("x-api-key")
    )
    if api_key:
        return lookup_user_by_api_key(api_key)

    return None


async def require_websocket_auth(websocket: WebSocket) -> Optional[Dict[str, Any]]:
    """Authenticate; close with 1008 if invalid. Call before websocket.accept()."""
    user = await authenticate_websocket(websocket)
    if user is None:
        await websocket.close(code=1008, reason="Authentication required")
        return None
    return user
