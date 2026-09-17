"""
API Gateway Authentication

Handles:
- API key authentication
- JWT token validation
- User tier checking (Starter/Pro/Enterprise)
- Permission-based access control
"""

import logging
import os
import secrets
from typing import Optional, Dict, Any
from datetime import datetime, timedelta, timezone

from fastapi import HTTPException, Security, status
from fastapi.security import APIKeyHeader, HTTPBearer, HTTPAuthorizationCredentials
from jose import JWTError, jwt

from tiannara_api.middleware.api_key_auth import lookup_user_by_api_key
from tiannara_api.security.tiers import normalize_tier

logger = logging.getLogger(__name__)

# Security schemes
API_KEY_HEADER = APIKeyHeader(name="X-API-Key", auto_error=False)
JWT_BEARER = HTTPBearer(auto_error=False)

# JWT Configuration
_env = os.getenv("ENVIRONMENT", "development").lower()
_jwt_from_env = os.getenv("JWT_SECRET_KEY")
if _env == "production" and not _jwt_from_env:
    raise RuntimeError("JWT_SECRET_KEY must be set when ENVIRONMENT=production")
JWT_SECRET = _jwt_from_env or secrets.token_hex(32)
JWT_ALGORITHM = "HS256"
JWT_EXPIRATION_HOURS = int(os.getenv("JWT_EXPIRATION_HOURS", "24"))

# Tier-based quotas (canonical tier names)
TIER_QUOTAS = {
    "starter": 5000,
    "professional": 50000,
    "enterprise": -1,
}

PERMISSIONS = {
    "starter": ["read", "predict", "analyze"],
    "professional": ["read", "predict", "analyze", "reason", "evolve", "causal"],
    "enterprise": ["*"],
}


def create_jwt_token(data: Dict[str, Any], expires_hours: int = JWT_EXPIRATION_HOURS) -> str:
    """Create a JWT token for authenticated users."""
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + timedelta(hours=expires_hours)
    to_encode.update({"exp": expire})
    
    encoded_jwt = jwt.encode(to_encode, JWT_SECRET, algorithm=JWT_ALGORITHM)
    return encoded_jwt


def verify_jwt_token(token: str) -> Dict[str, Any]:
    """Verify and decode a JWT token."""
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
        return payload
    except JWTError as e:
        logger.error(f"JWT verification failed: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
            headers={"WWW-Authenticate": "Bearer"},
        )


def get_api_key(api_key: str = Security(API_KEY_HEADER)):
    """Validate API key against database; returns key string if valid."""
    if not api_key:
        return None
    if not lookup_user_by_api_key(api_key):
        if _env == "production":
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid or revoked API key",
            )
        return None
    return api_key


def get_user_tier_for_api_key(api_key: Optional[str]) -> str:
    """Resolve canonical tier for an API key, or starter if unauthenticated."""
    if not api_key:
        return "starter"
    user = lookup_user_by_api_key(api_key)
    if not user:
        return "starter"
    return normalize_tier(user.get("tier"))


def get_jwt_credentials(credentials: Optional[HTTPAuthorizationCredentials] = Security(JWT_BEARER)):
    """
    Validate JWT credentials from Authorization header.
    """
    if not credentials:
        return None
    
    return verify_jwt_token(credentials.credentials)


def check_tier_quota(tier: str, current_usage: int) -> bool:
    """
    Check if user has remaining quota based on their tier.
    
    Returns:
        True if quota available, False if exceeded
    """
    quota = TIER_QUOTAS.get(normalize_tier(tier), 0)
    
    # Enterprise has unlimited quota
    if quota == -1:
        return True
    
    return current_usage < quota


def check_permission(user_tier: str, required_permission: str) -> bool:
    """
    Check if user tier has required permission.
    
    Args:
        user_tier: User's subscription tier
        required_permission: Permission being requested
        
    Returns:
        True if permission granted, False otherwise
    """
    user_permissions = PERMISSIONS.get(normalize_tier(user_tier), [])
    
    # Enterprise has all permissions
    if "*" in user_permissions:
        return True
    
    return required_permission in user_permissions


class AuthenticationError(Exception):
    """Custom authentication error."""
    pass
