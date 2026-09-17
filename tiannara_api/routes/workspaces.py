"""
Workspace Management Routes for Tiannara API

Endpoints for creating, managing, and collaborating in team workspaces.

Features:
- Create and manage workspaces
- Invite members via email
- Role-based access control
- Workspace settings and billing

Date: May 1, 2026
Status: Week 27 Day 3 - Team Workspaces Implementation
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from pydantic import BaseModel, EmailStr, Field
import uuid
import os

from tiannara_api.database import get_db
from tiannara_api.database.model_classes.workspace import (
    Workspace,
    WorkspaceMember,
    Invitation,
    WorkspaceRole,
    create_workspace,
    invite_user_to_workspace,
    accept_invitation,
)
from tiannara_api.database.model_classes.audit_log import (
    AuditAction,
    create_audit_log,
)
from tiannara_api.routes.auth import get_current_user
from tiannara_api.services.email_service import email_service

# Import User model - use lazy import to avoid circular dependencies
def get_user_model():
    """Get User model class (lazy import)."""
    from tiannara_api.database.models import User
    return User

router = APIRouter(prefix="/workspaces", tags=["Workspaces"])


# ==================== Request/Response Models ====================

class CreateWorkspaceRequest(BaseModel):
    """Request to create a new workspace."""
    name: str = Field(..., min_length=1, max_length=255, description="Workspace name")
    description: Optional[str] = Field(None, max_length=1000, description="Optional description")
    tier: str = Field(default="team", description="Workspace tier (team, business, enterprise)")


class WorkspaceResponse(BaseModel):
    """Workspace information response."""
    id: str
    name: str
    description: Optional[str]
    owner_id: str
    tier: str
    is_active: bool
    created_at: str
    
    class Config:
        from_attributes = True


class WorkspaceMemberResponse(BaseModel):
    """Workspace member information."""
    id: str
    user_id: str
    user_email: str
    user_name: str
    role: str
    joined_at: str
    
    class Config:
        from_attributes = True


class InviteMemberRequest(BaseModel):
    """Request to invite a member to workspace."""
    email: EmailStr
    role: WorkspaceRole = WorkspaceRole.MEMBER


class InvitationResponse(BaseModel):
    """Invitation information."""
    id: str
    email: str
    role: str
    invited_by: str
    expires_at: str
    is_pending: bool
    
    class Config:
        from_attributes = True


class AcceptInvitationRequest(BaseModel):
    """Request to accept an invitation."""
    token: str


# ==================== Routes ====================

@router.post("", response_model=WorkspaceResponse, status_code=status.HTTP_201_CREATED)
async def create_new_workspace(
    request: CreateWorkspaceRequest,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Create a new workspace.
    
    The authenticated user becomes the OWNER of the workspace.
    
    Args:
        request: Workspace creation details
        current_user: Authenticated user
        db: Database session
        
    Returns:
        Created workspace information
    """
    try:
        user_id = current_user.get("user", {}).get("id")
        
        if not user_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User ID not found in token"
            )
        
        # Create workspace
        workspace = create_workspace(
            db_session=db,
            name=request.name,
            owner_id=user_id,
            description=request.description,
            tier=request.tier,
        )
        
        # Log the action
        create_audit_log(
            db_session=db,
            action=AuditAction.WORKSPACE_CREATE,
            resource_type="workspace",
            resource_id=str(workspace.id),
            user_id=user_id,
            user_email=current_user.get("user", {}).get("email"),
            success=True,
            metadata={"workspace_name": request.name, "tier": request.tier},
        )
        
        # Convert to response model
        return WorkspaceResponse(
            id=str(workspace.id),
            name=workspace.name,
            description=workspace.description,
            owner_id=str(workspace.owner_id),
            tier=workspace.tier,
            is_active=workspace.is_active,
            created_at=workspace.created_at.isoformat() if workspace.created_at else None,
            updated_at=workspace.updated_at.isoformat() if workspace.updated_at else None,
            member_count=1,  # Owner is the first member
        )
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create workspace: {str(e)}"
        )


@router.get("", response_model=List[WorkspaceResponse])
async def list_user_workspaces(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    List all workspaces the current user is a member of.
    
    Args:
        current_user: Authenticated user
        db: Database session
        
    Returns:
        List of workspaces
    """
    try:
        user_id = current_user.get("user", {}).get("id")
        
        if not user_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User ID not found in token"
            )
        
        # Get all memberships for this user
        memberships = db.query(WorkspaceMember).filter(
            WorkspaceMember.user_id == user_id
        ).all()
        
        # Get workspace details
        workspace_ids = [m.workspace_id for m in memberships]
        workspaces = db.query(Workspace).filter(
            Workspace.id.in_(workspace_ids),
            Workspace.is_active == True
        ).all()
        
        # Convert to response models with member counts
        result = []
        for ws in workspaces:
            member_count = db.query(WorkspaceMember).filter(
                WorkspaceMember.workspace_id == ws.id
            ).count()
            
            result.append(WorkspaceResponse(
                id=str(ws.id),
                name=ws.name,
                description=ws.description,
                owner_id=str(ws.owner_id),
                tier=ws.tier,
                is_active=ws.is_active,
                created_at=ws.created_at.isoformat() if ws.created_at else None,
                updated_at=ws.updated_at.isoformat() if ws.updated_at else None,
                member_count=member_count,
            ))
        
        return result
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to list workspaces: {str(e)}"
        )


@router.get("/{workspace_id}", response_model=WorkspaceResponse)
async def get_workspace_details(
    workspace_id: str,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get detailed information about a specific workspace.
    
    Args:
        workspace_id: Workspace ID
        current_user: Authenticated user
        db: Database session
        
    Returns:
        Workspace details
    """
    try:
        # Check membership
        user_id = current_user.get("user", {}).get("id")
        
        membership = db.query(WorkspaceMember).filter(
            WorkspaceMember.workspace_id == workspace_id,
            WorkspaceMember.user_id == user_id
        ).first()
        
        if not membership:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Workspace not found or access denied"
            )
        
        # Get workspace
        workspace = db.query(Workspace).filter(Workspace.id == workspace_id).first()
        
        if not workspace:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Workspace not found"
            )
        
        return workspace
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get workspace: {str(e)}"
        )


@router.get("/{workspace_id}/members", response_model=List[WorkspaceMemberResponse])
async def list_workspace_members(
    workspace_id: str,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    List all members of a workspace.
    
    Requires MEMBER role or higher.
    
    Args:
        workspace_id: Workspace ID
        current_user: Authenticated user
        db: Database session
        
    Returns:
        List of workspace members
    """
    try:
        user_id = current_user.get("user", {}).get("id")
        
        # Check membership
        membership = db.query(WorkspaceMember).filter(
            WorkspaceMember.workspace_id == workspace_id,
            WorkspaceMember.user_id == user_id
        ).first()
        
        if not membership:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Workspace not found or access denied"
            )
        
        # Check permission
        if not membership.has_permission("resource.read"):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Insufficient permissions to view members"
            )
        
        # Get all members
        members = db.query(WorkspaceMember).filter(
            WorkspaceMember.workspace_id == workspace_id
        ).all()
        
        # Build response with user details
        result = []
        for member in members:
            User = get_user_model()
            user = db.query(User).filter(User.id == member.user_id).first()
            result.append({
                "id": str(member.id),
                "user_id": str(member.user_id),
                "user_email": user.email if user else "Unknown",
                "user_name": user.name if user else "Unknown",
                "role": member.role.value,
                "joined_at": member.joined_at.isoformat(),
            })
        
        return result
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to list members: {str(e)}"
        )


@router.post("/{workspace_id}/invite", response_model=InvitationResponse, status_code=status.HTTP_201_CREATED)
async def invite_member(
    workspace_id: str,
    request: InviteMemberRequest,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Invite a user to join the workspace.
    
    Requires ADMIN role or higher.
    
    Args:
        workspace_id: Workspace ID
        request: Invitation details
        current_user: Authenticated user
        db: Database session
        
    Returns:
        Created invitation
    """
    try:
        user_id = current_user.get("user", {}).get("id")
        
        # Check membership and permissions
        membership = db.query(WorkspaceMember).filter(
            WorkspaceMember.workspace_id == workspace_id,
            WorkspaceMember.user_id == user_id
        ).first()
        
        if not membership:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Workspace not found or access denied"
            )
        
        if not membership.has_permission("member.invite"):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Insufficient permissions to invite members"
            )
        
        # Check if user is already a member (by email)
        User = get_user_model()
        existing_user = db.query(User).filter(
            User.email == request.email.lower()
        ).first()
        
        if existing_user:
            # Check if this user is already a member
            existing_member = db.query(WorkspaceMember).filter(
                WorkspaceMember.workspace_id == workspace_id,
                WorkspaceMember.user_id == existing_user.id
            ).first()
            
            if existing_member:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="User is already a member of this workspace"
                )
        
        # Create invitation
        invitation = invite_user_to_workspace(
            db_session=db,
            workspace_id=workspace_id,
            email=request.email,
            role=request.role,
            invited_by=user_id,
        )
        
        # Log the invitation
        create_audit_log(
            db_session=db,
            action=AuditAction.MEMBER_INVITE,
            resource_type="workspace",
            resource_id=workspace_id,
            user_id=user_id,
            user_email=current_user.get("user", {}).get("email"),
            success=True,
            metadata={"invited_email": request.email, "role": request.role.value},
        )
        
        # Get workspace name for email
        workspace = db.query(Workspace).filter(Workspace.id == workspace_id).first()
        workspace_name = workspace.name if workspace else "Unknown Workspace"
        
        # Send invitation email
        base_url = os.getenv("API_BASE_URL", "http://localhost:8004")
        invite_url = f"{base_url}/api/v1/workspaces/accept-invitation?token={invitation.token}"
        
        # Get inviter name from user object
        inviter_name = current_user.get("user", {}).get("name", "Someone")
        
        await email_service.send_workspace_invitation(
            to_email=request.email,
            workspace_name=workspace_name,
            inviter_name=inviter_name,
            invite_url=invite_url,
            role=request.role.value,
        )
        
        return invitation
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create invitation: {str(e)}"
        )


@router.post("/accept-invitation", response_model=WorkspaceMemberResponse)
async def accept_workspace_invitation(
    request: AcceptInvitationRequest,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Accept a workspace invitation.
    
    Args:
        request: Invitation token
        current_user: Authenticated user
        db: Database session
        
    Returns:
        Created workspace membership
    """
    try:
        user_id = current_user.get("user", {}).get("id")
        
        if not user_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User ID not found in token"
            )
        
        # Accept invitation
        member = accept_invitation(
            db_session=db,
            token=request.token,
            user_id=user_id,
        )
        
        return member
    
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to accept invitation: {str(e)}"
        )


@router.delete("/{workspace_id}/members/{user_id}")
async def remove_member(
    workspace_id: str,
    user_id: str,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Remove a member from the workspace.
    
    Requires ADMIN role or higher. Cannot remove the last OWNER.
    
    Args:
        workspace_id: Workspace ID
        user_id: User ID to remove
        current_user: Authenticated user
        db: Database session
    """
    try:
        remover_id = current_user.get("user", {}).get("id")
        
        # Check remover's membership and permissions
        remover_membership = db.query(WorkspaceMember).filter(
            WorkspaceMember.workspace_id == workspace_id,
            WorkspaceMember.user_id == remover_id
        ).first()
        
        if not remover_membership:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Workspace not found or access denied"
            )
        
        if not remover_membership.has_permission("member.remove"):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Insufficient permissions to remove members"
            )
        
        # Get target member
        target_member = db.query(WorkspaceMember).filter(
            WorkspaceMember.workspace_id == workspace_id,
            WorkspaceMember.user_id == user_id
        ).first()
        
        if not target_member:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Member not found in workspace"
            )
        
        # Prevent removing the last owner
        if target_member.role == WorkspaceRole.OWNER:
            owners_count = db.query(WorkspaceMember).filter(
                WorkspaceMember.workspace_id == workspace_id,
                WorkspaceMember.role == WorkspaceRole.OWNER
            ).count()
            
            if owners_count <= 1:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Cannot remove the last owner. Transfer ownership first."
                )
        
        # Remove member
        db.delete(target_member)
        db.commit()
        
        return {"success": True, "message": "Member removed successfully"}
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to remove member: {str(e)}"
        )
