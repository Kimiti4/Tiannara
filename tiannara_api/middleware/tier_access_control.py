"""
Tier-Based Access Control Decorators for Tiannara API.

Provides decorators to protect routes based on user subscription tier.
Ensures users can only access features included in their plan.
"""
from functools import wraps
from fastapi import HTTPException, status, Request
from tiannara_api.database import SessionLocal
from tiannara_api.database.models import User


# Tier hierarchy (higher number = more access)
TIER_LEVELS = {
    "free": 0,
    "starter": 1,
    "pro": 2,
    "professional": 2,
    "enterprise": 3,
}


def get_user_tier_level(tier: str) -> int:
    """Get numeric level for a tier."""
    return TIER_LEVELS.get(tier.lower(), 0)


def require_tier(minimum_tier: str):
    """
    Decorator to require minimum subscription tier for route access.
    
    Usage:
        @router.get("/advanced-feature")
        @require_tier("professional")
        def advanced_feature():
            ...
    
    Args:
        minimum_tier: Minimum tier required ("starter", "professional", "enterprise")
    
    Returns:
        Decorated function that checks user's tier before execution
    """
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            # Extract request from args or kwargs
            request = None
            for arg in args:
                if isinstance(arg, Request):
                    request = arg
                    break
            
            if not request:
                request = kwargs.get('request')
            
            if not request:
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="Request object not found"
                )
            
            # Get user ID from request state (set by auth middleware)
            user_id = getattr(request.state, 'user_id', None)
            
            if not user_id:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Authentication required"
                )
            
            # Check user's tier
            db = SessionLocal()
            try:
                user = db.query(User).filter(User.id == user_id).first()
                
                if not user:
                    raise HTTPException(
                        status_code=status.HTTP_404_NOT_FOUND,
                        detail="User not found"
                    )
                
                user_level = get_user_tier_level(user.tier)
                required_level = get_user_tier_level(minimum_tier)
                
                if user_level < required_level:
                    raise HTTPException(
                        status_code=status.HTTP_403_FORBIDDEN,
                        detail=f"This feature requires {minimum_tier.capitalize()} tier or higher. Your current tier: {user.tier.capitalize()}. Upgrade at /billing"
                    )
                
                # Store user object in request state for route handler
                request.state.user = user
                
            finally:
                db.close()
            
            # Call the actual route handler
            return await func(*args, **kwargs)
        
        return wrapper
    return decorator


def require_active_subscription():
    """
    Decorator to require an active subscription (not free tier).
    
    Usage:
        @router.get("/premium-feature")
        @require_active_subscription()
        def premium_feature():
            ...
    """
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            # Extract request
            request = None
            for arg in args:
                if isinstance(arg, Request):
                    request = arg
                    break
            
            if not request:
                request = kwargs.get('request')
            
            if not request:
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="Request object not found"
                )
            
            # Get user ID
            user_id = getattr(request.state, 'user_id', None)
            
            if not user_id:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Authentication required"
                )
            
            # Check subscription status
            db = SessionLocal()
            try:
                user = db.query(User).filter(User.id == user_id).first()
                
                if not user:
                    raise HTTPException(
                        status_code=status.HTTP_404_NOT_FOUND,
                        detail="User not found"
                    )
                
                # Check if user has active subscription
                if user.tier == "free" or user.subscription_status in ["cancelled", "past_due", "inactive"]:
                    raise HTTPException(
                        status_code=status.HTTP_403_FORBIDDEN,
                        detail="Active subscription required. Please subscribe at /billing"
                    )
                
                request.state.user = user
                
            finally:
                db.close()
            
            return await func(*args, **kwargs)
        
        return wrapper
    return decorator


def check_feature_access(feature: str):
    """
    Decorator to check if user has access to specific feature.
    
    Feature mapping should be defined based on architecture.md specifications.
    
    Usage:
        @router.get("/team-collaboration")
        @check_feature_access("team_collaboration")
        def team_collaboration():
            ...
    
    Args:
        feature: Feature name to check access for
    """
    # Define which tiers have access to which features
    FEATURE_ACCESS = {
        "team_collaboration": ["professional", "enterprise"],
        "priority_processing": ["professional", "enterprise"],
        "advanced_monitoring": ["professional", "enterprise"],
        "webhooks_integrations": ["professional", "enterprise"],
        "sla_guarantee": ["professional", "enterprise"],
        "explainability_reports": ["starter", "professional", "enterprise"],
        "compliance_tooling": ["enterprise"],
        "private_deployment": ["enterprise"],
        "dedicated_support": ["enterprise"],
        "custom_integrations": ["enterprise"],
    }
    
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            # Extract request
            request = None
            for arg in args:
                if isinstance(arg, Request):
                    request = arg
                    break
            
            if not request:
                request = kwargs.get('request')
            
            if not request:
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="Request object not found"
                )
            
            # Get user ID
            user_id = getattr(request.state, 'user_id', None)
            
            if not user_id:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Authentication required"
                )
            
            # Check feature access
            db = SessionLocal()
            try:
                user = db.query(User).filter(User.id == user_id).first()
                
                if not user:
                    raise HTTPException(
                        status_code=status.HTTP_404_NOT_FOUND,
                        detail="User not found"
                    )
                
                allowed_tiers = FEATURE_ACCESS.get(feature, [])
                
                if user.tier not in allowed_tiers:
                    required_tier = allowed_tiers[0] if allowed_tiers else "unknown"
                    raise HTTPException(
                        status_code=status.HTTP_403_FORBIDDEN,
                        detail=f"Feature '{feature}' requires {required_tier.capitalize()} tier. Your current tier: {user.tier.capitalize()}"
                    )
                
                request.state.user = user
                
            finally:
                db.close()
            
            return await func(*args, **kwargs)
        
        return wrapper
    return decorator


# Convenience decorators for common tier requirements
require_starter = require_tier("starter")
require_professional = require_tier("professional")
require_enterprise = require_tier("enterprise")
