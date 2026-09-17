"""
API Key Authentication Middleware for Tiannara SaaS

This middleware authenticates requests using API keys passed in the X-API-Key header.
It validates the key against the database and tracks usage.
"""

from fastapi import Request, HTTPException, status
from fastapi.responses import JSONResponse
from typing import Optional
import hashlib
import logging
from datetime import datetime, timezone

from tiannara_api.database import SessionLocal
from tiannara_api.database.models import User

logger = logging.getLogger(__name__)


def hash_api_key(api_key: str) -> str:
    """Hash API key for comparison with stored hash."""
    return hashlib.sha256(api_key.encode()).hexdigest()


def lookup_user_by_api_key(api_key: str) -> Optional[dict]:
    """Return user context dict if API key is valid, else None."""
    if not api_key:
        return None
    hashed_key = hash_api_key(api_key)
    db = SessionLocal()
    try:
        for user in db.query(User).all():
            if not user.api_keys:
                continue
            for key_data in user.api_keys:
                if (
                    key_data.get("hashed_key") == hashed_key
                    and key_data.get("status") == "active"
                ):
                    return {
                        "id": user.id,
                        "user_id": user.id,
                        "email": user.email,
                        "name": user.name,
                        "tier": user.tier,
                    }
        return None
    finally:
        db.close()


async def authenticate_api_key(request: Request):
    """
    Authenticate request using API key from X-API-Key header.
    
    This function should be called as a dependency in protected routes.
    
    Usage:
        @router.get("/protected")
        async def protected_endpoint(
            user: dict = Depends(authenticate_api_key)
        ):
            # user contains authenticated user data
            pass
    """
    api_key = request.headers.get("X-API-Key")
    
    if not api_key:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="API key required. Provide it in the X-API-Key header.",
            headers={"WWW-Authenticate": "ApiKey"},
        )
    
    user_ctx = lookup_user_by_api_key(api_key)
    if not user_ctx:
        logger.warning(f"Invalid API key attempt: {api_key[:8]}...")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or revoked API key",
            headers={"WWW-Authenticate": "ApiKey"},
        )

    db = SessionLocal()
    try:
        user = db.query(User).filter(User.id == user_ctx["user_id"]).first()
        matched_key = None
        hashed_key = hash_api_key(api_key)
        if user and user.api_keys:
            for key_data in user.api_keys:
                if key_data.get("hashed_key") == hashed_key:
                    matched_key = key_data
                    break
        if matched_key:
            matched_key["last_used"] = datetime.now(timezone.utc).isoformat()
            matched_key["request_count"] = matched_key.get("request_count", 0) + 1
            db.commit()
        logger.info(f"API key authenticated for user: {user_ctx['email']}")
        return {
            "user_id": user_ctx["user_id"],
            "email": user_ctx["email"],
            "name": user_ctx["name"],
            "tier": user_ctx["tier"],
            "api_key_id": matched_key["id"] if matched_key else None,
            "api_key_name": matched_key.get("name") if matched_key else None,
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error authenticating API key: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Authentication service error",
        )
    finally:
        db.close()


# Alternative: Middleware that runs on every request
class ApiKeyMiddleware:
    """
    ASGI middleware that checks for API key authentication on specific routes.
    
    This is useful for protecting entire route groups.
    """
    
    def __init__(self, app, protected_prefixes: list = ["/api/v1/"]):
        self.app = app
        self.protected_prefixes = protected_prefixes
    
    async def __call__(self, scope, receive, send):
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return
        
        path = scope["path"]
        
        # Check if this path needs API key authentication
        needs_auth = any(path.startswith(prefix) for prefix in self.protected_prefixes)
        
        if needs_auth:
            # Extract API key from headers
            headers = dict(scope["headers"])
            api_key = headers.get(b"x-api-key", b"").decode()
            
            if not api_key:
                response = JSONResponse(
                    status_code=401,
                    content={"detail": "API key required"}
                )
                await response(scope, receive, send)
                return
            
            # Validate API key
            hashed_key = hash_api_key(api_key)
            
            db = SessionLocal()
            try:
                users = db.query(User).all()
                
                authenticated = False
                for user in users:
                    if not user.api_keys:
                        continue
                    
                    for key_data in user.api_keys:
                        if (key_data.get("hashed_key") == hashed_key and 
                            key_data.get("status") == "active"):
                            authenticated = True
                            
                            # Update usage
                            key_data["last_used"] = datetime.now(timezone.utc).isoformat()
                            key_data["request_count"] = key_data.get("request_count", 0) + 1
                            db.commit()
                            break
                    
                    if authenticated:
                        break
                
                if not authenticated:
                    response = JSONResponse(
                        status_code=401,
                        content={"detail": "Invalid or revoked API key"}
                    )
                    await response(scope, receive, send)
                    return
                
            except Exception as e:
                logger.error(f"API key middleware error: {str(e)}")
                response = JSONResponse(
                    status_code=500,
                    content={"detail": "Authentication error"}
                )
                await response(scope, receive, send)
                return
            finally:
                db.close()
        
        # Continue with request
        await self.app(scope, receive, send)
