"""
White-label Configuration Models for Tiannara API

Supports enterprise customers customizing the platform with their own:
- Custom domains
- Branding (logos, colors, fonts)
- Company information
- Email templates

Date: May 1, 2026
Status: Week 28 Day 8-9 - White-label Implementation
"""

from sqlalchemy import Column, String, Boolean, DateTime, Integer, Text, ForeignKey
from sqlalchemy.orm import relationship
import uuid
from datetime import datetime, timezone

from tiannara_api.database import Base


class WhiteLabelConfig(Base):
    """
    White-label configuration for enterprise customers.
    
    Allows customization of branding, domains, and appearance.
    """
    __tablename__ = "white_label_configs"
    
    id = Column(String, primary_key=True, default=lambda: f"wl_{uuid.uuid4().hex[:16]}")
    
    # Organization linkage
    workspace_id = Column(String, ForeignKey("workspaces.id"), nullable=False, unique=True, index=True)
    
    # Company Information
    company_name = Column(String(255), nullable=False)
    company_description = Column(Text, nullable=True)
    support_email = Column(String(255), nullable=True)
    support_phone = Column(String(50), nullable=True)
    website_url = Column(String(500), nullable=True)
    
    # Branding - Logos
    logo_url = Column(String(500), nullable=True)  # Main logo
    logo_dark_url = Column(String(500), nullable=True)  # Logo for dark mode
    favicon_url = Column(String(500), nullable=True)  # Browser tab icon
    
    # Branding - Colors (hex codes)
    primary_color = Column(String(7), default="#667eea")  # Primary brand color
    secondary_color = Column(String(7), default="#764ba2")  # Secondary brand color
    accent_color = Column(String(7), default="#f093fb")  # Accent/highlight color
    background_color = Column(String(7), default="#ffffff")  # Background color
    text_color = Column(String(7), default="#1a202c")  # Primary text color
    
    # Typography
    font_family = Column(String(100), default="Inter, sans-serif")  # Primary font
    heading_font = Column(String(100), nullable=True)  # Heading font (optional)
    
    # Custom Domain
    custom_domain = Column(String(255), nullable=True, unique=True, index=True)
    domain_verified = Column(Boolean, default=False)
    domain_verification_token = Column(String(255), nullable=True)
    ssl_enabled = Column(Boolean, default=False)
    
    # Email Customization
    email_from_name = Column(String(255), nullable=True)  # Sender name for emails
    email_from_address = Column(String(255), nullable=True)  # Sender email
    email_footer_text = Column(Text, nullable=True)  # Custom footer for emails
    
    # UI Customization
    hide_tiannara_branding = Column(Boolean, default=False)  # Hide "Powered by Tiannara"
    custom_css = Column(Text, nullable=True)  # Custom CSS overrides
    custom_javascript = Column(Text, nullable=True)  # Custom JS (limited use cases)
    
    # Feature Toggles
    enable_custom_login_page = Column(Boolean, default=False)
    enable_custom_dashboard = Column(Boolean, default=False)
    enable_api_white_label = Column(Boolean, default=False)  # White-label API responses
    
    # Status
    is_active = Column(Boolean, default=True)
    
    # Timestamps
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
    
    # Relationships
    workspace = relationship("Workspace", backref="white_label_config")
    
    def __repr__(self):
        return f"<WhiteLabelConfig(company='{self.company_name}', domain='{self.custom_domain}')>"
    
    def to_dict(self):
        """Convert config to dictionary."""
        return {
            "id": self.id,
            "workspace_id": self.workspace_id,
            "company_name": self.company_name,
            "company_description": self.company_description,
            "support_email": self.support_email,
            "support_phone": self.support_phone,
            "website_url": self.website_url,
            "logo_url": self.logo_url,
            "logo_dark_url": self.logo_dark_url,
            "favicon_url": self.favicon_url,
            "primary_color": self.primary_color,
            "secondary_color": self.secondary_color,
            "accent_color": self.accent_color,
            "background_color": self.background_color,
            "text_color": self.text_color,
            "font_family": self.font_family,
            "heading_font": self.heading_font,
            "custom_domain": self.custom_domain,
            "domain_verified": self.domain_verified,
            "ssl_enabled": self.ssl_enabled,
            "email_from_name": self.email_from_name,
            "email_from_address": self.email_from_address,
            "email_footer_text": self.email_footer_text,
            "hide_tiannara_branding": self.hide_tiannara_branding,
            "enable_custom_login_page": self.enable_custom_login_page,
            "enable_custom_dashboard": self.enable_custom_dashboard,
            "is_active": self.is_active,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }


class DomainVerification(Base):
    """
    Tracks custom domain verification attempts and status.
    
    Used for DNS verification process.
    """
    __tablename__ = "domain_verifications"
    
    id = Column(String, primary_key=True, default=lambda: f"dver_{uuid.uuid4().hex[:16]}")
    
    # Linkage
    config_id = Column(String, ForeignKey("white_label_configs.id"), nullable=False, index=True)
    workspace_id = Column(String, ForeignKey("workspaces.id"), nullable=False, index=True)
    
    # Domain details
    domain = Column(String(255), nullable=False)
    verification_method = Column(String(50), default="dns_txt")  # dns_txt, dns_cname, http
    
    # Verification tokens
    verification_token = Column(String(255), nullable=False)  # Random token for verification
    expected_dns_record = Column(String(500), nullable=True)  # Expected DNS record value
    
    # Status
    is_verified = Column(Boolean, default=False)
    verification_attempts = Column(Integer, default=0)
    last_verification_check = Column(DateTime, nullable=True)
    
    # Error tracking
    last_error = Column(Text, nullable=True)
    
    # Timestamps
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    verified_at = Column(DateTime, nullable=True)
    expires_at = Column(DateTime, nullable=True)  # Verification token expiration
    
    # Relationships
    config = relationship("WhiteLabelConfig", backref="domain_verifications")
    
    def __repr__(self):
        return f"<DomainVerification(domain='{self.domain}', verified={self.is_verified})>"
    
    def to_dict(self):
        """Convert to dictionary."""
        return {
            "id": self.id,
            "config_id": self.config_id,
            "workspace_id": self.workspace_id,
            "domain": self.domain,
            "verification_method": self.verification_method,
            "verification_token": self.verification_token,
            "expected_dns_record": self.expected_dns_record,
            "is_verified": self.is_verified,
            "verification_attempts": self.verification_attempts,
            "last_verification_check": self.last_verification_check.isoformat() if self.last_verification_check else None,
            "last_error": self.last_error,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "verified_at": self.verified_at.isoformat() if self.verified_at else None,
            "expires_at": self.expires_at.isoformat() if self.expires_at else None,
        }


def create_white_label_config(
    db_session,
    workspace_id: str,
    company_name: str,
    **kwargs
) -> WhiteLabelConfig:
    """
    Create a new white-label configuration.
    
    Args:
        db_session: Database session
        workspace_id: Associated workspace ID
        company_name: Company name (required)
        **kwargs: Additional configuration fields
        
    Returns:
        Created WhiteLabelConfig object
    """
    config = WhiteLabelConfig(
        workspace_id=workspace_id,
        company_name=company_name,
        **kwargs
    )
    
    db_session.add(config)
    db_session.commit()
    db_session.refresh(config)
    
    return config


def generate_verification_token() -> str:
    """Generate a random verification token for domain verification."""
    import secrets
    return secrets.token_hex(32)  # 64 character hex string
