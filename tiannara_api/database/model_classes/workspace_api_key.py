"""
Workspace API Key Database Model for Tiannara SaaS

Stores API keys at the workspace level with RBAC tracking.

Date: May 1, 2026
"""

from sqlalchemy import Column, String, Boolean, DateTime, Integer, Text, JSON
from sqlalchemy.dialects.postgresql import UUID
import uuid
from datetime import datetime, timezone

from tiannara_api.database import Base


class WorkspaceApiKey(Base):
    """
    API Key model scoped to workspaces.
    
    Only workspace OWNERS and ADMINS can create/revoke keys.
    All workspace members can use keys for API authentication.
    """
    __tablename__ = "workspace_api_keys"
    
    id = Column(String, primary_key=True, default=lambda: f"key_{uuid.uuid4().hex[:16]}")
    workspace_id = Column(String, nullable=False, index=True)  # Workspace this key belongs to
    name = Column(String(255), nullable=False)  # Human-readable name
    hashed_key = Column(String(255), unique=True, nullable=False, index=True)  # SHA-256 hash
    created_by = Column(String, nullable=False)  # User ID who created the key
    created_by_name = Column(String(255), nullable=False)  # User name at creation time
    status = Column(String(50), default="active", nullable=False)  # active, revoked
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    revoked_at = Column(DateTime, nullable=True)
    revoked_by = Column(String, nullable=True)  # User ID who revoked the key
    last_used = Column(DateTime, nullable=True)  # Last time this key was used
    request_count = Column(Integer, default=0, nullable=False)  # Total requests made
    
    # Usage tracking (JSON for flexibility)
    usage_log = Column(JSON, default=list, nullable=True)  # Array of usage records
    endpoints_used = Column(JSON, default=list, nullable=True)  # Array of endpoint paths
    
    def to_dict(self):
        """Convert to dictionary (excluding sensitive data)."""
        return {
            "id": self.id,
            "workspace_id": self.workspace_id,
            "name": self.name,
            "created_by": self.created_by,
            "created_by_name": self.created_by_name,
            "status": self.status,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "revoked_at": self.revoked_at.isoformat() if self.revoked_at else None,
            "revoked_by": self.revoked_by,
            "last_used": self.last_used.isoformat() if self.last_used else None,
            "request_count": self.request_count,
            "endpoints_used": self.endpoints_used or []
        }
    
    def to_summary(self):
        """Convert to summary for listing (with masked key)."""
        return {
            **self.to_dict(),
            "key_masked": f"{self.hashed_key[:12]}••••••••••••{self.hashed_key[-4:]}"
        }
