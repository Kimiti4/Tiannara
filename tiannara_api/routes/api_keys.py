"""
Workspace API Key Management Routes for Tiannara SaaS

Architecture:
- API keys are WORKSPACE-scoped, not user-scoped
- Only workspace ADMIN and OWNER can manage keys (RBAC)
- Keys authenticate requests on behalf of the workspace
- MEMBERs and VIEWERs can use keys but NOT manage them

RBAC Permissions:
- OWNER: Full control (create, list, revoke, use keys)
- ADMIN: Full control (create, list, revoke, use keys)  
- MEMBER: Can use keys but CANNOT create/revoke
- VIEWER: Can use keys but CANNOT create/revoke

Date: May 1, 2026
"""

from fastapi import APIRouter, HTTPException, Depends, Header, status, Request
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime, timezone
import hashlib
import secrets
import logging

from tiannara_api.database import get_db
from tiannara_api.database.models import User
from tiannara_api.database.model_classes.workspace import WorkspaceMember, WorkspaceRole
from tiannara_api.gateway.auth import verify_jwt_token
from sqlalchemy.orm import Session
from sqlalchemy import Column, String, Boolean, DateTime, ForeignKey, Integer, JSON
from sqlalchemy.dialects.postgresql import UUID

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/api-keys",
    tags=["api-keys"],
    responses={404: {"description": "Not found"}},
)


# ==================== Models ====================

class CreateApiKeyRequest(BaseModel):
    """Request to create a new API key."""
    name: str = Field(..., min_length=1, max_length=100, description="Descriptive name for the key")
    workspace_id: str = Field(..., description="Workspace to create key for")


class ApiKeyResponse(BaseModel):
    """API key response (includes the actual key ONCE at creation)."""
    id: str
    name: str
    key: str  # Only returned once at creation
    workspace_id: str
    created_by: str
    created_at: str
    last_used: Optional[str] = None
    request_count: int = 0
    status: str = "active"


class ApiKeySummary(BaseModel):
    """API key summary (masked key for security)."""
    id: str
    name: str
    key_masked: str
    workspace_id: str
    created_by: str
    created_at: str
    last_used: Optional[str] = None
    request_count: int = 0
    status: str


class ApiKeyUsageResponse(BaseModel):
    """API key usage statistics."""
    total_requests: int
    requests_today: int
    requests_this_week: int
    requests_this_month: int
    last_request_at: Optional[str] = None
    endpoints_used: List[str] = []


# ==================== In-Memory Store ====================
# (Replace with database model in production)
workspace_api_keys_db = {}  # workspace_id -> [key_records]
api_key_lookup_db = {}  # hashed_key -> key_record (for fast lookup during auth)


# ==================== Helper Functions ====================

def generate_api_key() -> str:
    """Generate a secure API key."""
    return f"tk_live_{secrets.token_urlsafe(32)}"


def hash_api_key(api_key: str) -> str:
    """Hash API key for secure storage."""
    return hashlib.sha256(api_key.encode()).hexdigest()


def mask_api_key(hashed_key: str) -> str:
    """Mask API key hash for display."""
    return f"{hashed_key[:12]}••••••••••••{hashed_key[-4:]}"


def get_current_user_from_token(authorization: str, db: Session) -> User:
    """Extract user from JWT token."""
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials"
        )
    
    token = authorization.replace("Bearer ", "")
    payload = verify_jwt_token(token)
    
    if not payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token"
        )
    
    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token payload"
        )
    
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    return user


def verify_workspace_admin_access(user_id: str, workspace_id: str, db: Session) -> dict:
    """
    Verify that user has ADMIN or OWNER role in the workspace.
    
    RBAC Check:
    - OWNER: ✅ Can manage API keys
    - ADMIN: ✅ Can manage API keys
    - MEMBER: ❌ Cannot manage API keys
    - VIEWER: ❌ Cannot manage API keys
    
    Args:
        user_id: User's ID
        workspace_id: Workspace ID
        db: Database session
        
    Returns:
        dict: User's workspace membership info
        
    Raises:
        HTTPException: 403 if user lacks admin access, 404 if not a member
    """
    membership = db.query(WorkspaceMember).filter(
        WorkspaceMember.workspace_id == workspace_id,
        WorkspaceMember.user_id == user_id
    ).first()
    
    if not membership:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="You are not a member of this workspace"
        )
    
    # RBAC: Only OWNER and ADMIN can manage API keys
    if membership.role not in [WorkspaceRole.OWNER, WorkspaceRole.ADMIN]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Insufficient permissions. Only workspace OWNERS and ADMINS can manage API keys. Your role: {membership.role.value}"
        )
    
    return {
        "user_id": user_id,
        "workspace_id": workspace_id,
        "role": membership.role.value,
        "membership_id": membership.id
    }


def verify_workspace_member_access(user_id: str, workspace_id: str, db: Session) -> dict:
    """
    Verify that user is at least a MEMBER of the workspace.
    
    Used for endpoints that allow members to view (but not manage) keys.
    
    Args:
        user_id: User's ID
        workspace_id: Workspace ID
        db: Database session
        
    Returns:
        dict: User's workspace membership info
        
    Raises:
        HTTPException: 404 if not a member
    """
    membership = db.query(WorkspaceMember).filter(
        WorkspaceMember.workspace_id == workspace_id,
        WorkspaceMember.user_id == user_id
    ).first()
    
    if not membership:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="You are not a member of this workspace"
        )
    
    return {
        "user_id": user_id,
        "workspace_id": workspace_id,
        "role": membership.role.value,
        "membership_id": membership.id
    }


# ==================== Routes ====================

@router.post("", response_model=ApiKeyResponse)
async def create_api_key(
    request: CreateApiKeyRequest,
    authorization: str = Header(...),
    db: Session = Depends(get_db)
):
    """
    Generate a new API key for a workspace.
    
    RBAC: Requires OWNER or ADMIN role in the workspace.
    
    The API key is returned ONLY ONCE at creation time.
    Store it securely - it cannot be retrieved again.
    """
    try:
        # Authenticate user
        user = get_current_user_from_token(authorization, db)
        
        # RBAC Check: Verify user is workspace admin
        access = verify_workspace_admin_access(user.id, request.workspace_id, db)
        
        # Generate new API key
        api_key = generate_api_key()
        hashed_key = hash_api_key(api_key)
        
        # Create API key record
        api_key_record = {
            "id": f"key_{secrets.token_hex(8)}",
            "name": request.name,
            "hashed_key": hashed_key,
            "workspace_id": request.workspace_id,
            "created_by": user.id,
            "created_by_name": user.name,
            "created_at": datetime.now(timezone.utc).isoformat(),
            "last_used": None,
            "request_count": 0,
            "status": "active",
            "usage_log": []  # For detailed tracking
        }
        
        # Store in workspace-scoped database
        if request.workspace_id not in workspace_api_keys_db:
            workspace_api_keys_db[request.workspace_id] = []
        
        workspace_api_keys_db[request.workspace_id].append(api_key_record)
        
        # Store hashed key for fast lookup during auth
        api_key_lookup_db[hashed_key] = api_key_record
        
        logger.info(f"API key created for workspace {request.workspace_id} by {user.email}: {api_key_record['id']}")
        
        return ApiKeyResponse(
            id=api_key_record["id"],
            name=request.name,
            key=api_key,  # Return plain key ONCE
            workspace_id=request.workspace_id,
            created_by=user.id,
            created_at=api_key_record["created_at"],
            last_used=api_key_record["last_used"],
            request_count=api_key_record["request_count"],
            status=api_key_record["status"]
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error creating API key: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create API key"
        )


@router.get("", response_model=List[ApiKeySummary])
async def list_api_keys(
    workspace_id: str,
    authorization: str = Header(...),
    db: Session = Depends(get_db)
):
    """
    List all API keys for a workspace.
    
    RBAC: Any workspace member can view keys (masked).
    """
    try:
        # Authenticate user
        user = get_current_user_from_token(authorization, db)
        
        # RBAC Check: Verify user is workspace member
        access = verify_workspace_member_access(user.id, workspace_id, db)
        
        # Get workspace's API keys
        api_keys = workspace_api_keys_db.get(workspace_id, [])
        
        # Return masked summaries
        return [
            ApiKeySummary(
                id=key["id"],
                name=key["name"],
                key_masked=mask_api_key(key["hashed_key"]),
                workspace_id=key["workspace_id"],
                created_by=key["created_by"],
                created_at=key["created_at"],
                last_used=key.get("last_used"),
                request_count=key.get("request_count", 0),
                status=key.get("status", "active")
            )
            for key in api_keys if key.get("status") != "revoked"
        ]
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error listing API keys: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to list API keys"
        )


@router.delete("/{key_id}")
async def revoke_api_key(
    key_id: str,
    workspace_id: str,
    authorization: str = Header(...),
    db: Session = Depends(get_db)
):
    """
    Revoke an API key.
    
    RBAC: Requires OWNER or ADMIN role in the workspace.
    
    Once revoked, the key cannot be used for authentication.
    """
    try:
        # Authenticate user
        user = get_current_user_from_token(authorization, db)
        
        # RBAC Check: Verify user is workspace admin
        access = verify_workspace_admin_access(user.id, workspace_id, db)
        
        # Find and revoke the key
        api_keys = workspace_api_keys_db.get(workspace_id, [])
        key_found = False
        
        for key in api_keys:
            if key["id"] == key_id:
                key["status"] = "revoked"
                key["revoked_at"] = datetime.now(timezone.utc).isoformat()
                key["revoked_by"] = user.id
                
                # Remove from lookup db to prevent further auth
                if key["hashed_key"] in api_key_lookup_db:
                    del api_key_lookup_db[key["hashed_key"]]
                
                key_found = True
                break
        
        if not key_found:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="API key not found"
            )
        
        logger.info(f"API key revoked: {key_id} for workspace {workspace_id} by {user.email}")
        
        return {
            "success": True,
            "message": "API key revoked successfully"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error revoking API key: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to revoke API key"
        )


@router.get("/{key_id}/usage", response_model=ApiKeyUsageResponse)
async def get_api_key_usage(
    key_id: str,
    workspace_id: str,
    authorization: str = Header(...),
    db: Session = Depends(get_db)
):
    """
    Get usage statistics for a specific API key.
    
    RBAC: Requires OWNER or ADMIN role in the workspace.
    """
    try:
        # Authenticate user
        user = get_current_user_from_token(authorization, db)
        
        # RBAC Check: Verify user is workspace admin
        access = verify_workspace_admin_access(user.id, workspace_id, db)
        
        # Find the key
        api_keys = workspace_api_keys_db.get(workspace_id, [])
        key_data = None
        
        for key in api_keys:
            if key["id"] == key_id:
                key_data = key
                break
        
        if not key_data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="API key not found"
            )
        
        # TODO: Implement detailed usage tracking
        # For now, return basic stats from the key record
        return ApiKeyUsageResponse(
            total_requests=key_data.get("request_count", 0),
            requests_today=0,  # TODO: Calculate from logs
            requests_this_week=0,  # TODO: Calculate from logs
            requests_this_month=0,  # TODO: Calculate from logs
            last_request_at=key_data.get("last_used"),
            endpoints_used=[]  # TODO: Track endpoint usage
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting API key usage: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get API key usage"
        )
