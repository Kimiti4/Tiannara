"""
Audit Log Models for Tiannara API

Tracks all workspace actions, permission changes, and security events.
Provides complete audit trail for compliance and debugging.

Date: May 1, 2026
Status: Week 27 Day 5 - Audit Logging Implementation
"""

from sqlalchemy import Column, String, Boolean, DateTime, ForeignKey, Text, Enum as SQLEnum
from sqlalchemy.orm import relationship
import uuid
from datetime import datetime, timezone
from enum import Enum

from tiannara_api.database import Base


class AuditAction(str, Enum):
    """Types of auditable actions."""
    # Workspace Actions
    WORKSPACE_CREATE = "workspace.create"
    WORKSPACE_UPDATE = "workspace.update"
    WORKSPACE_DELETE = "workspace.delete"
    
    # Member Actions
    MEMBER_INVITE = "member.invite"
    MEMBER_ACCEPT = "member.accept"
    MEMBER_REMOVE = "member.remove"
    MEMBER_ROLE_CHANGE = "member.role_change"
    
    # Authentication Actions
    AUTH_LOGIN = "auth.login"
    AUTH_LOGOUT = "auth.logout"
    AUTH_FAILED = "auth.failed"
    AUTH_SSO = "auth.sso"
    
    # Security Actions
    PERMISSION_DENIED = "security.permission_denied"
    RATE_LIMIT_EXCEEDED = "security.rate_limit"
    SUSPICIOUS_ACTIVITY = "security.suspicious"
    
    # API Actions
    API_KEY_CREATE = "api_key.create"
    API_KEY_REVOKE = "api_key.revoke"
    TIER_CHANGE = "billing.tier_change"


class AuditLog(Base):
    """
    Audit log entry for tracking all system actions.
    
    Provides complete audit trail for:
    - Compliance requirements
    - Security monitoring
    - Debugging and troubleshooting
    - Activity history
    """
    __tablename__ = "audit_logs"
    
    id = Column(String, primary_key=True, default=lambda: f"audit_{uuid.uuid4().hex[:16]}")
    
    # Action details
    action = Column(SQLEnum(AuditAction), nullable=False, index=True)
    resource_type = Column(String(50), nullable=True)  # workspace, user, api_key, etc.
    resource_id = Column(String, nullable=True, index=True)
    
    # User information
    user_id = Column(String, ForeignKey("users.id"), nullable=True, index=True)
    user_email = Column(String(255), nullable=True, index=True)
    ip_address = Column(String(45), nullable=True)  # IPv6 max length
    
    # Request context
    request_method = Column(String(10), nullable=True)  # GET, POST, etc.
    request_path = Column(String(500), nullable=True)
    user_agent = Column(Text, nullable=True)
    
    # Outcome
    status_code = Column(String(3), nullable=True)  # HTTP status code
    success = Column(Boolean, default=True)
    error_message = Column(Text, nullable=True)
    
    # Additional data (JSON stored as text)
    action_metadata = Column("metadata", Text, nullable=True)  # JSON string with extra details
    
    # Timestamps
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False, index=True)
    
    # Relationships
    user = relationship("User", backref="audit_logs")
    
    def __repr__(self):
        return f"<AuditLog(id={self.id}, action={self.action.value}, user={self.user_email})>"
    
    def to_dict(self):
        """Convert audit log to dictionary."""
        return {
            "id": self.id,
            "action": self.action.value,
            "resource_type": self.resource_type,
            "resource_id": self.resource_id,
            "user_id": self.user_id,
            "user_email": self.user_email,
            "ip_address": self.ip_address,
            "request_method": self.request_method,
            "request_path": self.request_path,
            "status_code": self.status_code,
            "success": self.success,
            "error_message": self.error_message,
            "metadata": self.action_metadata,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }


def create_audit_log(
    db_session,
    action: AuditAction,
    user_id: str = None,
    user_email: str = None,
    resource_type: str = None,
    resource_id: str = None,
    ip_address: str = None,
    request_method: str = None,
    request_path: str = None,
    user_agent: str = None,
    status_code: str = None,
    success: bool = True,
    error_message: str = None,
    metadata: dict = None
) -> AuditLog:
    """
    Create a new audit log entry.
    
    Args:
        db_session: Database session
        action: Type of action being logged
        user_id: ID of user performing action
        user_email: Email of user performing action
        resource_type: Type of resource affected
        resource_id: ID of resource affected
        ip_address: Client IP address
        request_method: HTTP method
        request_path: Request path
        user_agent: Client user agent string
        status_code: HTTP response status code
        success: Whether action succeeded
        error_message: Error message if failed
        metadata: Additional context as dictionary
        
    Returns:
        Created AuditLog object
    """
    import json
    
    log_entry = AuditLog(
        action=action,
        resource_type=resource_type,
        resource_id=resource_id,
        user_id=user_id,
        user_email=user_email,
        ip_address=ip_address,
        request_method=request_method,
        request_path=request_path,
        user_agent=user_agent,
        status_code=status_code,
        success=success,
        error_message=error_message,
        action_metadata=json.dumps(metadata) if metadata else None,
    )
    
    db_session.add(log_entry)
    db_session.commit()
    db_session.refresh(log_entry)
    
    return log_entry
