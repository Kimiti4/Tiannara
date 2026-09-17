"""
Workspace API Key Authentication Middleware for Tiannara SaaS

Authenticates requests using workspace-scoped API keys from X-API-Key header.
Keys are managed by workspace ADMINS/OWNERS via RBAC.
"""

from fastapi import Request, HTTPException, status
from typing import Optional
import hashlib
import logging
from datetime import datetime, timezone

from tiannara_api.database import SessionLocal
from tiannara_api.database.model_classes.workspace_api_key import WorkspaceApiKey

logger = logging.getLogger(__name__)


def hash_api_key(api_key: str) -> str:
    """Hash API key for comparison with stored hash."""
    return hashlib.sha256(api_key.encode()).hexdigest()


async def authenticate_api_key(request: Request) -> dict:
    """
    Authenticate request using workspace API key from X-API-Key header.
    
    Usage:
        @router.get("/protected")
        async def protected_endpoint(
            workspace_key: dict = Depends(authenticate_api_key),
        ):
            # workspace_key contains:
            # - workspace_id: The workspace this key belongs to
            # - key_id: The API key ID
            # - key_name: Human-readable name
            
    Returns:
        dict: Workspace authentication context
        
    Raises:
        HTTPException: 401 if invalid key, 403 if revoked
    """
    api_key = request.headers.get("X-API-Key")
    
    if not api_key:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="API key required. Provide it in the X-API-Key header.",
            headers={"WWW-Authenticate": "ApiKey"},
        )
    
    # Hash the provided key
    hashed_key = hash_api_key(api_key)
    
    # Look up the key in database
    db = SessionLocal()
    try:
        key_record = db.query(WorkspaceApiKey).filter(
            WorkspaceApiKey.hashed_key == hashed_key
        ).first()
        
        if not key_record:
            logger.warning(f"Invalid API key attempt: {api_key[:12]}...")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid API key",
                headers={"WWW-Authenticate": "ApiKey"},
            )
        
        if key_record.status != "active":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="API key has been revoked",
                headers={"WWW-Authenticate": "ApiKey"},
            )
        
        # Update key usage stats
        key_record.last_used = datetime.now(timezone.utc)
        key_record.request_count = (key_record.request_count or 0) + 1
        
        db.commit()
        
        logger.info(f"API key authenticated for workspace: {key_record.workspace_id}")
        
        return {
            "workspace_id": key_record.workspace_id,
            "key_id": key_record.id,
            "key_name": key_record.name,
            "request_count": key_record.request_count
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error authenticating API key: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Authentication service error"
        )
    finally:
        db.close()
