"""
Quota Enforcement Middleware for Tiannara API.

Tracks and enforces API usage limits based on user subscription tier.
Automatically blocks requests when quota is exceeded.
"""
from fastapi import Request, HTTPException, status
from datetime import datetime, timedelta
from tiannara_api.database import SessionLocal
from tiannara_api.database.models import User
from tiannara_api.payment import PRICING_PLANS


def should_reset_quota(user: User) -> bool:
    """Check if user's quota should be reset (new billing cycle)."""
    if not user.last_quota_reset:
        return True
    
    # Check if current date is past the last reset + 30 days
    next_reset = user.last_quota_reset + timedelta(days=30)
    return datetime.utcnow() >= next_reset


def reset_user_quota(user: User, db):
    """Reset user's monthly request count."""
    user.monthly_request_count = 0
    user.last_quota_reset = datetime.utcnow()
    db.commit()


def increment_user_usage(user: User, db):
    """Increment user's monthly request count."""
    user.monthly_request_count += 1
    user.total_requests += 1
    db.commit()


async def check_and_enforce_quota(request: Request, call_next):
    """
    Middleware to check and enforce API quotas.
    
    This middleware:
    1. Extracts user from JWT token
    2. Checks if quota needs reset (new billing cycle)
    3. Verifies user hasn't exceeded their tier limit
    4. Increments usage counter
    5. Blocks requests if quota exceeded
    """
    # Skip quota check for certain paths
    skip_paths = [
        "/health",
        "/docs",
        "/openapi.json",
        "/metrics",
        "/auth/login",
        "/auth/register",
        "/auth/send-otp",
        "/auth/verify-otp",
    ]
    
    if any(request.url.path.startswith(path) for path in skip_paths):
        return await call_next(request)
    
    # Get user from request state (set by auth middleware)
    user_email = getattr(request.state, "user_email", None)
    
    if not user_email:
        # No authenticated user, let route handle it
        return await call_next(request)
    
    # Get user from database
    db = SessionLocal()
    try:
        user = db.query(User).filter(User.email == user_email).first()
        
        if not user:
            return await call_next(request)
        
        # Check if quota needs reset
        if should_reset_quota(user):
            reset_user_quota(user, db)
        
        # Get user's tier limits
        tier_limits = PRICING_PLANS.get(user.tier, PRICING_PLANS.get("starter"))
        max_requests = tier_limits.get("requests_per_month", 5000)
        
        # Unlimited for enterprise (-1 means unlimited)
        if max_requests == -1:
            # Still track usage for analytics
            increment_user_usage(user, db)
            return await call_next(request)
        
        # Check if quota exceeded
        if user.monthly_request_count >= max_requests:
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail={
                    "error": "quota_exceeded",
                    "message": f"You've reached your {user.tier} tier limit of {max_requests:,} requests/month",
                    "current_usage": user.monthly_request_count,
                    "limit": max_requests,
                    "tier": user.tier,
                    "upgrade_url": "/dashboard/billing/upgrade",
                    "reset_date": (user.last_quota_reset + timedelta(days=30)).isoformat() if user.last_quota_reset else None
                }
            )
        
        # Increment usage counter
        increment_user_usage(user, db)
        
        # Add usage info to response headers
        response = await call_next(request)
        response.headers["X-RateLimit-Limit"] = str(max_requests)
        response.headers["X-RateLimit-Remaining"] = str(max(max_requests - user.monthly_request_count, 0))
        response.headers["X-RateLimit-Reset"] = (user.last_quota_reset + timedelta(days=30)).isoformat() if user.last_quota_reset else ""
        
        return response
        
    finally:
        db.close()


# Export for use in main.py
__all__ = ["check_and_enforce_quota"]
