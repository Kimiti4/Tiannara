"""
Team Workspace Models for Tiannara API

Provides multi-user workspace functionality with role-based access control.

Models:
- Workspace: Team/organization container
- WorkspaceMember: User membership with roles
- Invitation: Pending invitations to join workspaces

Date: May 1, 2026
Status: Week 27 Day 3 - Team Workspaces Implementation
"""

from sqlalchemy import Column, String, Boolean, DateTime, ForeignKey, Enum as SQLEnum
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID
import uuid
from datetime import datetime, timezone
from enum import Enum

from tiannara_api.database import Base


class WorkspaceRole(str, Enum):
    """Workspace member roles with hierarchical permissions."""
    OWNER = "owner"           # Full control, can delete workspace
    ADMIN = "admin"           # Can manage members and settings
    MEMBER = "member"         # Can use workspace resources
    VIEWER = "viewer"         # Read-only access


class Workspace(Base):
    """
    Workspace model representing a team or organization.
    
    Workspaces contain multiple members and shared resources.
    """
    __tablename__ = "workspaces"
    
    id = Column(String, primary_key=True, default=lambda: f"ws_{uuid.uuid4().hex[:16]}")
    name = Column(String(255), nullable=False, index=True)
    description = Column(String(1000), nullable=True)
    owner_id = Column(String, ForeignKey("users.id"), nullable=False)
    tier = Column(String(50), default="team", nullable=False)  # team, business, enterprise
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
    
    # Relationships
    owner = relationship("User", backref="owned_workspaces", foreign_keys=[owner_id])
    members = relationship("WorkspaceMember", back_populates="workspace", cascade="all, delete-orphan")
    invitations = relationship("Invitation", back_populates="workspace", cascade="all, delete-orphan")
    
    def __repr__(self):
        return f"<Workspace(id={self.id}, name='{self.name}', owner={self.owner_id})>"


class WorkspaceMember(Base):
    """
    Workspace member model linking users to workspaces with specific roles.
    
    Implements role-based access control for workspace resources.
    """
    __tablename__ = "workspace_members"
    
    id = Column(String, primary_key=True, default=lambda: f"wsm_{uuid.uuid4().hex[:16]}")
    workspace_id = Column(String, ForeignKey("workspaces.id", ondelete="CASCADE"), nullable=False)
    user_id = Column(String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    role = Column(SQLEnum(WorkspaceRole), nullable=False, default=WorkspaceRole.MEMBER)
    joined_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    
    # Unique constraint: user can only be in a workspace once
    __table_args__ = (
        # This will be added via Alembic migration
    )
    
    # Relationships
    workspace = relationship("Workspace", back_populates="members")
    user = relationship("User", backref="workspace_memberships")
    
    def has_permission(self, permission: str) -> bool:
        """
        Check if member has specific permission based on role.
        
        Permissions hierarchy:
        - OWNER: All permissions
        - ADMIN: Manage members, settings, billing
        - MEMBER: Use resources, invite others
        - VIEWER: Read-only access
        
        Args:
            permission: Permission to check
            
        Returns:
            True if member has permission
        """
        role_permissions = {
            WorkspaceRole.OWNER: [
                "workspace.delete",
                "workspace.update",
                "workspace.manage_billing",
                "member.invite",
                "member.remove",
                "member.change_role",
                "resource.create",
                "resource.read",
                "resource.update",
                "resource.delete",
            ],
            WorkspaceRole.ADMIN: [
                "workspace.update",
                "member.invite",
                "member.remove",
                "member.change_role",
                "resource.create",
                "resource.read",
                "resource.update",
                "resource.delete",
            ],
            WorkspaceRole.MEMBER: [
                "member.invite",
                "resource.create",
                "resource.read",
                "resource.update",
            ],
            WorkspaceRole.VIEWER: [
                "resource.read",
            ],
        }
        
        return permission in role_permissions.get(self.role, [])
    
    def __repr__(self):
        return f"<WorkspaceMember(workspace={self.workspace_id}, user={self.user_id}, role={self.role})>"


class Invitation(Base):
    """
    Invitation model for pending workspace invitations.
    
    Allows workspace admins to invite users via email.
    """
    __tablename__ = "invitations"
    
    id = Column(String, primary_key=True, default=lambda: f"inv_{uuid.uuid4().hex[:16]}")
    workspace_id = Column(String, ForeignKey("workspaces.id", ondelete="CASCADE"), nullable=False)
    email = Column(String(255), nullable=False, index=True)
    role = Column(SQLEnum(WorkspaceRole), nullable=False, default=WorkspaceRole.MEMBER)
    token = Column(String(255), unique=True, nullable=False, index=True)
    invited_by = Column(String, ForeignKey("users.id"), nullable=False)
    expires_at = Column(DateTime, nullable=False)
    accepted_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    
    # Relationships
    workspace = relationship("Workspace", back_populates="invitations")
    inviter = relationship("User", backref="sent_invitations")
    
    def is_expired(self) -> bool:
        """Check if invitation has expired."""
        return datetime.now(timezone.utc) > self.expires_at
    
    def is_pending(self) -> bool:
        """Check if invitation is still pending."""
        return not self.accepted_at and not self.is_expired()
    
    def __repr__(self):
        return f"<Invitation(email='{self.email}', workspace={self.workspace_id}, role={self.role})>"


# ==================== Helper Functions ====================

def create_workspace(db_session, name: str, owner_id: str, description: str = None, tier: str = "team") -> Workspace:
    """
    Create a new workspace with the specified owner.
    
    Args:
        db_session: Database session
        name: Workspace name
        owner_id: Owner's user ID
        description: Optional description
        tier: Workspace tier (team, business, enterprise)
        
    Returns:
        Created Workspace object
    """
    import secrets
    
    workspace = Workspace(
        name=name,
        description=description,
        owner_id=owner_id,
        tier=tier,
    )
    
    db_session.add(workspace)
    db_session.flush()  # Get workspace ID
    
    # Add owner as OWNER role member
    owner_member = WorkspaceMember(
        workspace_id=workspace.id,
        user_id=owner_id,
        role=WorkspaceRole.OWNER,
    )
    
    db_session.add(owner_member)
    db_session.commit()
    db_session.refresh(workspace)
    
    return workspace


def invite_user_to_workspace(db_session, workspace_id: str, email: str, role: WorkspaceRole, invited_by: str, expires_hours: int = 168) -> Invitation:
    """
    Invite a user to join a workspace.
    
    Args:
        db_session: Database session
        workspace_id: Workspace ID
        email: Email to invite
        role: Role to assign
        invited_by: User ID of inviter
        expires_hours: Hours until invitation expires (default: 7 days)
        
    Returns:
        Created Invitation object
    """
    from datetime import timedelta
    
    # Generate secure token
    token = secrets.token_urlsafe(32)
    
    # Calculate expiration
    expires_at = datetime.now(timezone.utc) + timedelta(hours=expires_hours)
    
    invitation = Invitation(
        workspace_id=workspace_id,
        email=email.lower(),
        role=role,
        token=token,
        invited_by=invited_by,
        expires_at=expires_at,
    )
    
    db_session.add(invitation)
    db_session.commit()
    db_session.refresh(invitation)
    
    return invitation


def accept_invitation(db_session, token: str, user_id: str) -> WorkspaceMember:
    """
    Accept a workspace invitation.
    
    Args:
        db_session: Database session
        token: Invitation token
        user_id: User accepting the invitation
        
    Returns:
        Created WorkspaceMember object
        
    Raises:
        ValueError: If invitation is invalid or expired
    """
    invitation = db_session.query(Invitation).filter(Invitation.token == token).first()
    
    if not invitation:
        raise ValueError("Invalid invitation token")
    
    if invitation.is_expired():
        raise ValueError("Invitation has expired")
    
    if invitation.accepted_at:
        raise ValueError("Invitation already accepted")
    
    # Check if user is already a member
    existing_member = db_session.query(WorkspaceMember).filter(
        WorkspaceMember.workspace_id == invitation.workspace_id,
        WorkspaceMember.user_id == user_id
    ).first()
    
    if existing_member:
        raise ValueError("User is already a member of this workspace")
    
    # Create membership
    member = WorkspaceMember(
        workspace_id=invitation.workspace_id,
        user_id=user_id,
        role=invitation.role,
    )
    
    # Mark invitation as accepted
    invitation.accepted_at = datetime.now(timezone.utc)
    
    db_session.add(member)
    db_session.commit()
    db_session.refresh(member)
    
    return member
