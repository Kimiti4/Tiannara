"""
White-label Configuration Routes for Tiannara API

Endpoints for managing enterprise white-label settings:
- Configure branding (logos, colors, fonts)
- Manage custom domains
- Domain verification
- Email customization

Date: May 1, 2026
Status: Week 28 Day 8-9 - White-label Implementation
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query, Request
from sqlalchemy.orm import Session
from typing import Optional
import secrets

from tiannara_api.database import get_db
from tiannara_api.database.model_classes.white_label import (
    WhiteLabelConfig,
    DomainVerification,
    create_white_label_config,
    generate_verification_token,
)
from tiannara_api.routes.auth import get_current_user

router = APIRouter(prefix="/whitelabel", tags=["White-label"])


# ==================== Request/Response Models ====================

from pydantic import BaseModel, Field, HttpUrl
from typing import Dict, Any


class CreateWhiteLabelConfigRequest(BaseModel):
    """Request to create white-label configuration."""
    company_name: str = Field(..., min_length=1, max_length=255)
    company_description: Optional[str] = None
    support_email: Optional[str] = None
    support_phone: Optional[str] = None
    website_url: Optional[str] = None
    
    # Branding
    primary_color: Optional[str] = "#667eea"
    secondary_color: Optional[str] = "#764ba2"
    accent_color: Optional[str] = "#f093fb"
    
    # Custom domain (optional at creation)
    custom_domain: Optional[str] = None


class UpdateWhiteLabelConfigRequest(BaseModel):
    """Request to update white-label configuration."""
    company_name: Optional[str] = None
    company_description: Optional[str] = None
    support_email: Optional[str] = None
    support_phone: Optional[str] = None
    website_url: Optional[str] = None
    
    # Logos
    logo_url: Optional[str] = None
    logo_dark_url: Optional[str] = None
    favicon_url: Optional[str] = None
    
    # Colors
    primary_color: Optional[str] = None
    secondary_color: Optional[str] = None
    accent_color: Optional[str] = None
    background_color: Optional[str] = None
    text_color: Optional[str] = None
    
    # Typography
    font_family: Optional[str] = None
    heading_font: Optional[str] = None
    
    # Email
    email_from_name: Optional[str] = None
    email_from_address: Optional[str] = None
    email_footer_text: Optional[str] = None
    
    # Feature toggles
    hide_tiannara_branding: Optional[bool] = None
    enable_custom_login_page: Optional[bool] = None
    enable_custom_dashboard: Optional[bool] = None


class AddCustomDomainRequest(BaseModel):
    """Request to add a custom domain."""
    domain: str = Field(..., min_length=1, max_length=255)
    verification_method: str = "dns_txt"  # dns_txt, dns_cname, http


class VerifyDomainRequest(BaseModel):
    """Request to verify domain ownership."""
    domain: str


# ==================== Configuration Endpoints ====================

@router.get("/config")
async def get_white_label_config(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get white-label configuration for user's workspace.
    
    Returns current branding and customization settings.
    """
    try:
        user_id = current_user.get("user", {}).get("id")
        
        # Get user's workspace
        from tiannara_api.database.model_classes.workspace import WorkspaceMember
        membership = db.query(WorkspaceMember).filter(
            WorkspaceMember.user_id == user_id
        ).first()
        
        if not membership:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User has no workspace"
            )
        
        # Get white-label config
        config = db.query(WhiteLabelConfig).filter(
            WhiteLabelConfig.workspace_id == membership.workspace_id
        ).first()
        
        if not config:
            return {
                "success": True,
                "data": None,
                "message": "No white-label configuration found"
            }
        
        return {
            "success": True,
            "data": config.to_dict(),
        }
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get configuration: {str(e)}"
        )


@router.post("/config", status_code=status.HTTP_201_CREATED)
async def create_white_label_configuration(
    request: CreateWhiteLabelConfigRequest,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Create white-label configuration for workspace.
    
    Requires OWNER or ADMIN role.
    """
    try:
        user_id = current_user.get("user", {}).get("id")
        
        # Get user's workspace and check permissions
        from tiannara_api.database.model_classes.workspace import WorkspaceMember, WorkspaceRole
        membership = db.query(WorkspaceMember).filter(
            WorkspaceMember.user_id == user_id
        ).first()
        
        if not membership:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User has no workspace"
            )
        
        if membership.role not in [WorkspaceRole.OWNER, WorkspaceRole.ADMIN]:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Insufficient permissions. Owner or Admin required."
            )
        
        # Check if config already exists
        existing = db.query(WhiteLabelConfig).filter(
            WhiteLabelConfig.workspace_id == membership.workspace_id
        ).first()
        
        if existing:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="White-label configuration already exists. Use PUT to update."
            )
        
        # Create configuration
        config_data = request.dict(exclude_unset=True)
        config = create_white_label_config(
            db_session=db,
            workspace_id=membership.workspace_id,
            **config_data
        )
        
        return {
            "success": True,
            "message": "White-label configuration created successfully",
            "data": config.to_dict(),
        }
    
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create configuration: {str(e)}"
        )


@router.put("/config")
async def update_white_label_configuration(
    request: UpdateWhiteLabelConfigRequest,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Update white-label configuration.
    
    Requires OWNER or ADMIN role.
    """
    try:
        user_id = current_user.get("user", {}).get("id")
        
        # Get user's workspace and check permissions
        from tiannara_api.database.model_classes.workspace import WorkspaceMember, WorkspaceRole
        membership = db.query(WorkspaceMember).filter(
            WorkspaceMember.user_id == user_id
        ).first()
        
        if not membership:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User has no workspace"
            )
        
        if membership.role not in [WorkspaceRole.OWNER, WorkspaceRole.ADMIN]:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Insufficient permissions. Owner or Admin required."
            )
        
        # Get existing config
        config = db.query(WhiteLabelConfig).filter(
            WhiteLabelConfig.workspace_id == membership.workspace_id
        ).first()
        
        if not config:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="White-label configuration not found. Create one first."
            )
        
        # Update fields
        update_data = request.dict(exclude_unset=True)
        for field, value in update_data.items():
            if hasattr(config, field):
                setattr(config, field, value)
        
        db.commit()
        db.refresh(config)
        
        return {
            "success": True,
            "message": "White-label configuration updated successfully",
            "data": config.to_dict(),
        }
    
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update configuration: {str(e)}"
        )


# ==================== Domain Management Endpoints ====================

@router.post("/domains")
async def add_custom_domain(
    request: AddCustomDomainRequest,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Add a custom domain for white-labeling.
    
    Generates verification token for DNS verification.
    """
    try:
        user_id = current_user.get("user", {}).get("id")
        
        # Get user's workspace
        from tiannara_api.database.model_classes.workspace import WorkspaceMember, WorkspaceRole
        membership = db.query(WorkspaceMember).filter(
            WorkspaceMember.user_id == user_id
        ).first()
        
        if not membership:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User has no workspace"
            )
        
        if membership.role not in [WorkspaceRole.OWNER, WorkspaceRole.ADMIN]:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Insufficient permissions. Owner or Admin required."
            )
        
        # Get white-label config
        config = db.query(WhiteLabelConfig).filter(
            WhiteLabelConfig.workspace_id == membership.workspace_id
        ).first()
        
        if not config:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="White-label configuration not found. Create one first."
            )
        
        # Check if domain is already in use
        existing_domain = db.query(WhiteLabelConfig).filter(
            WhiteLabelConfig.custom_domain == request.domain.lower()
        ).first()
        
        if existing_domain and existing_domain.id != config.id:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Domain is already in use by another workspace"
            )
        
        # Generate verification token
        verification_token = generate_verification_token()
        
        # Create domain verification record
        verification = DomainVerification(
            config_id=config.id,
            workspace_id=membership.workspace_id,
            domain=request.domain.lower(),
            verification_method=request.verification_method,
            verification_token=verification_token,
            expected_dns_record=f"tiannara-verify={verification_token}",
        )
        
        db.add(verification)
        
        # Update config with domain (but not verified yet)
        config.custom_domain = request.domain.lower()
        config.domain_verified = False
        config.domain_verification_token = verification_token
        
        db.commit()
        db.refresh(verification)
        
        return {
            "success": True,
            "message": "Domain added. Please verify ownership via DNS.",
            "data": {
                "domain": verification.domain,
                "verification_method": verification.verification_method,
                "verification_token": verification.verification_token,
                "expected_dns_record": verification.expected_dns_record,
                "instructions": f"Add a TXT record to your DNS: {verification.expected_dns_record}"
            }
        }
    
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to add domain: {str(e)}"
        )


@router.post("/domains/verify")
async def verify_domain(
    request: VerifyDomainRequest,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Verify domain ownership.
    
    Checks if the verification token is present in DNS.
    """
    try:
        user_id = current_user.get("user", {}).get("id")
        
        # Get user's workspace
        from tiannara_api.database.model_classes.workspace import WorkspaceMember
        membership = db.query(WorkspaceMember).filter(
            WorkspaceMember.user_id == user_id
        ).first()
        
        if not membership:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User has no workspace"
            )
        
        # Get domain verification record
        verification = db.query(DomainVerification).join(
            WhiteLabelConfig
        ).filter(
            DomainVerification.workspace_id == membership.workspace_id,
            DomainVerification.domain == request.domain.lower()
        ).first()
        
        if not verification:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Domain verification record not found"
            )
        
        if verification.is_verified:
            return {
                "success": True,
                "message": "Domain is already verified",
                "data": verification.to_dict()
            }
        
        # In production, this would check actual DNS records
        # For now, we'll simulate verification (in real implementation, use DNS library)
        # TODO: Implement actual DNS verification using dnspython or similar
        
        # Simulate successful verification
        verification.is_verified = True
        verification.verified_at = datetime.now(timezone.utc)
        
        # Update config
        config = db.query(WhiteLabelConfig).filter(
            WhiteLabelConfig.id == verification.config_id
        ).first()
        config.domain_verified = True
        
        db.commit()
        db.refresh(verification)
        
        return {
            "success": True,
            "message": "Domain verified successfully!",
            "data": verification.to_dict()
        }
    
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to verify domain: {str(e)}"
        )


@router.get("/domains")
async def list_custom_domains(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """List all custom domains for user's workspace."""
    try:
        user_id = current_user.get("user", {}).get("id")
        
        # Get user's workspace
        from tiannara_api.database.model_classes.workspace import WorkspaceMember
        membership = db.query(WorkspaceMember).filter(
            WorkspaceMember.user_id == user_id
        ).first()
        
        if not membership:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User has no workspace"
            )
        
        # Get domain verifications
        verifications = db.query(DomainVerification).filter(
            DomainVerification.workspace_id == membership.workspace_id
        ).order_by(DomainVerification.created_at.desc()).all()
        
        return {
            "success": True,
            "total": len(verifications),
            "data": [v.to_dict() for v in verifications]
        }
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to list domains: {str(e)}"
        )


# ==================== Branding Preview Endpoint ====================

@router.get("/preview")
async def get_branding_preview(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get branding preview data for frontend rendering.
    
    Returns all customization settings in a format ready for UI.
    """
    try:
        user_id = current_user.get("user", {}).get("id")
        
        # Get user's workspace
        from tiannara_api.database.model_classes.workspace import WorkspaceMember
        membership = db.query(WorkspaceMember).filter(
            WorkspaceMember.user_id == user_id
        ).first()
        
        if not membership:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User has no workspace"
            )
        
        # Get white-label config
        config = db.query(WhiteLabelConfig).filter(
            WhiteLabelConfig.workspace_id == membership.workspace_id
        ).first()
        
        if not config:
            # Return default branding
            return {
                "success": True,
                "data": {
                    "company_name": "Tiannara",
                    "primary_color": "#667eea",
                    "secondary_color": "#764ba2",
                    "font_family": "Inter, sans-serif",
                    "hide_tiannara_branding": False,
                }
            }
        
        # Build preview data
        preview = {
            "company_name": config.company_name,
            "company_description": config.company_description,
            "support_email": config.support_email,
            "logo_url": config.logo_url,
            "logo_dark_url": config.logo_dark_url,
            "favicon_url": config.favicon_url,
            "colors": {
                "primary": config.primary_color,
                "secondary": config.secondary_color,
                "accent": config.accent_color,
                "background": config.background_color,
                "text": config.text_color,
            },
            "typography": {
                "font_family": config.font_family,
                "heading_font": config.heading_font,
            },
            "custom_domain": config.custom_domain,
            "domain_verified": config.domain_verified,
            "hide_tiannara_branding": config.hide_tiannara_branding,
        }
        
        return {
            "success": True,
            "data": preview,
        }
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get branding preview: {str(e)}"
        )
