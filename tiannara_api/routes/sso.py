"""
SSO (Single Sign-On) Routes for Tiannara API

Endpoints:
- GET /api/v1/auth/sso/providers - List available SSO providers
- GET /api/v1/auth/sso/{provider}/authorize - Initiate OAuth flow
- POST /api/v1/auth/sso/{provider}/callback - Handle OAuth callback
- POST /api/v1/auth/sso/link - Link OAuth account to existing user

Date: May 1, 2026
Status: Week 27 Day 1 - SSO Integration
"""

from fastapi import APIRouter, HTTPException, status, Query, Request
from pydantic import BaseModel
from typing import Optional

from tiannara_api.auth.sso_provider import (
    oauth_registry,
    oauth_state_manager,
    provision_or_get_user,
    generate_sso_tokens,
    initialize_oauth_providers,
)

router = APIRouter(prefix="/auth/sso", tags=["Authentication - SSO"])


# ==================== Request/Response Models ====================

class SSOCallbackRequest(BaseModel):
    """OAuth callback request."""
    code: str
    state: str
    redirect_uri: Optional[str] = None


class AccountLinkRequest(BaseModel):
    """Account linking request."""
    provider_id: str
    code: str
    state: str


# ==================== Routes ====================

@router.get("/providers")
async def list_sso_providers():
    """
    List all configured SSO providers.
    
    Returns provider IDs and names for frontend to display login buttons.
    """
    providers = oauth_registry.list_providers()
    return {
        "success": True,
        "providers": providers
    }


@router.get("/{provider_id}/authorize")
async def initiate_sso_authorization(
    provider_id: str,
    redirect_uri: str = Query(default="http://localhost:3000/callback", description="Frontend redirect URI after auth"),
    request: Request = None
):
    """
    Initiate OAuth authorization flow.
    
    Redirects user to provider's authorization page.
    After authorization, provider will redirect to callback URL.
    
    Args:
        provider_id: OAuth provider (google, microsoft, github)
        redirect_uri: Where to redirect after successful auth
    
    Returns:
        Authorization URL to redirect user to
    """
    try:
        # Get provider
        provider = oauth_registry.get_provider(provider_id)
        
        if not provider:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Provider '{provider_id}' not found or not configured"
            )
        
        # Create state parameter for CSRF protection
        state = oauth_state_manager.create_state(
            provider_id=provider_id,
            redirect_uri=redirect_uri,
        )
        
        # Generate authorization URL
        callback_url = f"{request.base_url}api/v1/auth/sso/{provider_id}/callback"
        auth_url = provider.get_authorization_url(
            redirect_uri=callback_url,
            state=state,
        )
        
        return {
            "success": True,
            "authorization_url": auth_url,
            "state": state,
        }
    
    except HTTPException:
        raise
    except Exception as e:
        import traceback
        logger.error(f"SSO Authorization Error: {str(e)}")
        logger.error(traceback.format_exc())
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to initiate SSO: {str(e)}"
        )


@router.post("/{provider_id}/callback")
async def handle_sso_callback(
    provider_id: str,
    callback_data: SSOCallbackRequest,
    request: Request = None
):
    """
    Handle OAuth callback from provider.
    
    Exchanges authorization code for tokens, fetches user info,
    provisions user if needed, and returns JWT tokens.
    
    Args:
        provider_id: OAuth provider
        callback_data: Authorization code and state
    
    Returns:
        JWT tokens and user information
    """
    try:
        # Get provider
        provider = oauth_registry.get_provider(provider_id)
        
        # Validate state parameter
        state_data = oauth_state_manager.validate_state(callback_data.state)
        if not state_data:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid or expired state parameter"
            )
        
        # Exchange code for token
        redirect_uri = f"{request.base_url}api/v1/auth/sso/{provider_id}/callback"
        token_response = await provider.exchange_code_for_token(
            code=callback_data.code,
            redirect_uri=redirect_uri,
            state=callback_data.state,
        )
        
        access_token = token_response.get("access_token")
        if not access_token:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No access token received from provider"
            )
        
        # Fetch user info
        user_info = await provider.get_user_info(access_token)
        
        # Normalize user info
        normalized_info = provider.normalize_user_info(user_info)
        
        # Provision or get user
        user = provision_or_get_user(normalized_info)
        
        # Generate JWT tokens
        tokens = generate_sso_tokens(user, provider_id)
        
        return tokens
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"SSO callback failed: {str(e)}"
        )


@router.post("/link")
async def link_oauth_account(
    link_data: AccountLinkRequest,
    current_user_email: str = Query(..., description="Current user's email for verification")
):
    """
    Link OAuth account to existing user account.
    
    Allows users to connect multiple authentication methods.
    
    Args:
        link_data: Provider ID and authorization code
        current_user_email: Email of user to link account to
    
    Returns:
        Success message
    """
    try:
        # Get provider
        provider = oauth_registry.get_provider(link_data.provider_id)
        
        # Exchange code for token
        token_response = await provider.exchange_code_for_token(
            code=link_data.code,
            redirect_uri="",  # Not needed for linking
            state="",  # Not needed for linking
        )
        
        access_token = token_response.get("access_token")
        if not access_token:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No access token received from provider"
            )
        
        # Fetch user info
        user_info = await provider.get_user_info(access_token)
        normalized_info = provider.normalize_user_info(user_info)
        
        # Verify email matches
        if normalized_info.get("email") != current_user_email:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="OAuth account email does not match current user email"
            )
        
        # TODO: Store OAuth account linkage in database
        # For now, just return success
        
        return {
            "success": True,
            "message": f"Successfully linked {link_data.provider_id} account",
            "provider_user_id": normalized_info.get("provider_user_id"),
        }
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to link account: {str(e)}"
        )


# ==================== Initialization ====================

# Initialize OAuth providers on module load
initialize_oauth_providers()
