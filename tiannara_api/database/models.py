"""
Database Models for Tiannara

SQLAlchemy ORM models for PostgreSQL database.
"""
from sqlalchemy import Column, String, Boolean, Integer, DateTime, Text, ARRAY
from sqlalchemy.dialects.postgresql import UUID
import uuid
from datetime import datetime

from tiannara_api.database import Base


class User(Base):
    """User model for authentication and management."""
    
    __tablename__ = "users"
    
    id = Column(String, primary_key=True, default=lambda: f"user_{uuid.uuid4().hex[:16]}")
    email = Column(String, unique=True, nullable=False, index=True)
    name = Column(String, nullable=False)
    password_hash = Column(String, nullable=False)
    tier = Column(String, default="starter")  # free, starter, professional, enterprise
    is_verified = Column(Boolean, default=False)
    is_admin = Column(Boolean, default=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    total_requests = Column(Integer, default=0)
    api_keys = Column(ARRAY(String), default=[])
    
    # Subscription tracking fields
    subscription_id = Column(String, nullable=True)  # Stripe/LemonSqueezy subscription ID
    subscription_status = Column(String, default="inactive")  # active, cancelled, past_due, trialing
    current_period_start = Column(DateTime, nullable=True)
    current_period_end = Column(DateTime, nullable=True)
    cancel_at_period_end = Column(Boolean, default=False)
    
    # Usage tracking for quota enforcement
    monthly_request_count = Column(Integer, default=0)
    last_quota_reset = Column(DateTime, nullable=True)
    
    # MFA fields
    mfa_enabled = Column(Boolean, default=False)
    mfa_secret = Column(String, nullable=True)
    mfa_backup_codes = Column(String, nullable=True)  # Comma-separated backup codes
    
    def to_dict(self):
        """Convert user to dictionary (excluding sensitive data)."""
        return {
            "id": self.id,
            "email": self.email,
            "name": self.name,
            "tier": self.tier,
            "is_verified": self.is_verified,
            "is_admin": self.is_admin,
            "is_active": self.is_active,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
            "total_requests": self.total_requests,
            # Subscription info
            "subscription_status": self.subscription_status,
            "current_period_end": self.current_period_end.isoformat() if self.current_period_end else None,
            "cancel_at_period_end": self.cancel_at_period_end,
            # Usage info
            "monthly_request_count": self.monthly_request_count,
            "last_quota_reset": self.last_quota_reset.isoformat() if self.last_quota_reset else None,
            # MFA info
            "mfa_enabled": self.mfa_enabled,
        }
