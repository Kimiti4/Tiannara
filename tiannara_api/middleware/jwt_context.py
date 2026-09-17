"""Populate request.state from JWT or API key for tier decorators and logging."""

from __future__ import annotations

import logging
from typing import Optional

from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response

from tiannara_api.gateway.auth import verify_jwt_token
from tiannara_api.middleware.api_key_auth import lookup_user_by_api_key
from tiannara_api.security.cookies import get_token_from_request

logger = logging.getLogger(__name__)


class JWTContextMiddleware(BaseHTTPMiddleware):
    """Set request.state.user_id / email / tier when credentials are present."""

    async def dispatch(self, request: Request, call_next) -> Response:
        request.state.user_id = None
        request.state.user_email = None
        request.state.user_tier = None

        token = get_token_from_request(request)
        if token:
            try:
                payload = verify_jwt_token(token)
                request.state.user_id = payload.get("user_id")
                request.state.user_email = payload.get("email")
                request.state.user_tier = payload.get("tier")
            except Exception:
                pass
        else:
            api_key = request.headers.get("X-API-Key")
            if api_key:
                user = lookup_user_by_api_key(api_key)
                if user:
                    request.state.user_id = user.get("id")
                    request.state.user_email = user.get("email")
                    request.state.user_tier = user.get("tier")

        return await call_next(request)
