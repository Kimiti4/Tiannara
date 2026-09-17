"""
Authentication Routes for Tiannara SaaS

Features:
- User registration with OTP email verification
- Login with JWT token generation
- Password hashing with bcrypt
- Session management
- Profile management
"""

from fastapi import APIRouter, HTTPException, Depends, status, Header, Request, Response
from pydantic import BaseModel, EmailStr, Field, validator
from typing import Optional
from datetime import datetime, timedelta
import os
import secrets
import logging
import re

from tiannara_api.auth.otp_service import get_otp_service, OTPService
from tiannara_api.security.password import hash_password, verify_password, needs_rehash
from tiannara_api.security.tiers import normalize_tier, CANONICAL_TIERS
from tiannara_api.security.cookies import (
    set_auth_cookie,
    clear_auth_cookie,
    get_token_from_request,
)
from tiannara_api.gateway.auth import create_jwt_token, verify_jwt_token
from tiannara_api.database import get_db, init_db
from tiannara_api.database.models import User
from sqlalchemy.orm import Session

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/auth",
    tags=["authentication"],
    responses={404: {"description": "Not found"}},
)


# ==================== Request/Response Models ====================

class SignupRequest(BaseModel):
    """User signup request."""
    name: str = Field(..., min_length=2, max_length=100, description="Full name")
    email: EmailStr = Field(..., description="Email address")
    password: str = Field(..., min_length=12, description="Password (min 12 chars with complexity requirements)")
    tier: str = Field(default="starter", description="Subscription tier")
    
    @validator('password')
    def validate_password_strength(cls, v):
        """Enforce strong password requirements."""
        if len(v) < 12:
            raise ValueError('Password must be at least 12 characters long')
        if not re.search(r'[A-Z]', v):
            raise ValueError('Password must contain at least one uppercase letter')
        if not re.search(r'[a-z]', v):
            raise ValueError('Password must contain at least one lowercase letter')
        if not re.search(r'\d', v):
            raise ValueError('Password must contain at least one digit')
        if not re.search(r'[!@#$%^&*()_+\-=\[\]{};\':"\\|,.<>\/?]', v):
            raise ValueError('Password must contain at least one special character')
        return v


class SignupResponse(BaseModel):
    """Signup response."""
    success: bool
    message: str
    user_id: Optional[str] = None
    requires_verification: bool = False
    dev_mode: Optional[bool] = None
    otp_code: Optional[str] = None


class VerifyOTPRequest(BaseModel):
    """OTP verification request."""
    email: EmailStr = Field(..., description="Email address")
    otp_code: str = Field(..., min_length=6, max_length=6, description="6-digit OTP code")


class VerifyOTPResponse(BaseModel):
    """OTP verification response."""
    success: bool
    message: str
    token: Optional[str] = None
    user: Optional[dict] = None


class LoginRequest(BaseModel):
    """Login request."""
    email: EmailStr = Field(..., description="Email address")
    password: str = Field(..., description="Password")


class LoginResponse(BaseModel):
    """Login response."""
    success: bool
    message: str
    data: Optional[dict] = None  # Contains {token: str, user: dict}


class UserProfile(BaseModel):
    """User profile data."""
    id: str
    email: str
    name: str
    tier: str
    created_at: str
    is_verified: bool


# ==================== Database Integration ====================
# Users are now stored in PostgreSQL for persistence across restarts
# In-memory store removed - all operations use database

pending_users = {}  # email -> {password_hash, name, tier, created_at} (temporary until verification)


# ==================== Authentication Endpoints ====================

@router.post("/request-otp", response_model=dict)
async def request_otp(email: EmailStr):
    """
    Request OTP verification code for email.
    
    Used during signup to verify email ownership.
    Rate limited to prevent abuse.
    """
    otp_service = get_otp_service()
    result = otp_service.request_otp(email)
    
    if not result["success"]:
        raise HTTPException(status_code=429, detail=result.get("error", "Rate limit exceeded"))
    
    return result


@router.post("/verify-otp", response_model=VerifyOTPResponse)
async def verify_otp(
    request: VerifyOTPRequest,
    response: Response,
    db: Session = Depends(get_db),
):
    """
    Verify OTP code and complete registration.
    
    After successful verification:
    - Creates user account
    - Generates JWT token
    - Returns user profile
    """
    otp_service = get_otp_service()
    
    # Verify OTP
    verification = otp_service.verify_otp(request.email, request.otp_code)
    
    if not verification["success"]:
        raise HTTPException(status_code=400, detail=verification.get("error", "Invalid OTP"))
    
    # Check if user has pending registration
    email_lower = request.email.lower()
    if email_lower not in pending_users:
        raise HTTPException(
            status_code=400,
            detail="No pending registration found. Please sign up first."
        )
    
    # Get pending user data
    pending_data = pending_users[email_lower]
    
    # Check if user already exists in database
    existing_user = db.query(User).filter(User.email == email_lower).first()
    if existing_user:
        raise HTTPException(
            status_code=409,
            detail="User already exists. Please login instead."
        )
    
    # Create user account in database
    user_id = f"user_{secrets.token_hex(8)}"
    new_user = User(
        id=user_id,
        email=email_lower,
        name=pending_data["name"],
        password_hash=pending_data["password_hash"],
        tier=pending_data["tier"],
        is_verified=True,
        is_admin=False,
        is_active=True,
        created_at=datetime.utcnow(),
        total_requests=0,
        api_keys=[]
    )
    
    # Save to database
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    # Remove from pending
    pending_users.pop(email_lower)
    
    # Generate JWT token
    token_data = {
        "user_id": user_id,
        "email": email_lower,
        "tier": pending_data["tier"],
        "name": pending_data["name"]
    }
    jwt_token = create_jwt_token(token_data)
    
    logger.info(f"User registered successfully: {email_lower}")
    set_auth_cookie(response, jwt_token)

    return VerifyOTPResponse(
        success=True,
        message="Registration completed successfully",
        token=jwt_token,
        user={
            "id": user_id,
            "email": email_lower,
            "name": pending_data["name"],
            "tier": pending_data["tier"],
            "is_verified": True
        }
    )


@router.post("/signup", response_model=SignupResponse)
async def signup(request: SignupRequest, db: Session = Depends(get_db)):
    """
    Initiate user signup process.
    
    Steps:
    1. Validate input
    2. Hash password
    3. Send OTP to email
    4. Store pending registration
    
    User must verify OTP to complete registration.
    """
    email_lower = request.email.lower()
    
    # Check if user already exists in database
    existing_user = db.query(User).filter(User.email == email_lower).first()
    if existing_user:
        raise HTTPException(
            status_code=409,
            detail="User with this email already exists. Please login instead."
        )
    
    # Check if pending registration exists
    if email_lower in pending_users:
        raise HTTPException(
            status_code=409,
            detail="Pending registration exists. Please check your email for verification code."
        )
    
    tier = normalize_tier(request.tier)
    if tier not in CANONICAL_TIERS:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid tier. Must be one of: {', '.join(sorted(CANONICAL_TIERS))}",
        )

    password_hash = hash_password(request.password)

    pending_users[email_lower] = {
        "password_hash": password_hash,
        "name": request.name,
        "tier": tier,
        "created_at": datetime.utcnow().isoformat()
    }
    
    # Request OTP
    otp_service = get_otp_service()
    otp_result = otp_service.request_otp(email_lower)
    
    logger.info(f"OTP result keys: {otp_result.keys()}")
    logger.info(f"OTP dev_mode: {otp_result.get('dev_mode')}")
    
    if not otp_result["success"]:
        # Clean up pending registration
        pending_users.pop(email_lower)
        raise HTTPException(status_code=429, detail=otp_result.get("error", "Failed to send OTP"))
    
    logger.info(f"Signup initiated for: {email_lower}")
    
    # In dev mode, include OTP code in response
    response_data = {
        "success": True,
        "message": "Verification code sent to your email. Please check your inbox.",
        "requires_verification": True
    }
    
    if (
        otp_result.get("dev_mode")
        and os.getenv("ENVIRONMENT", "development") == "development"
        and os.getenv("EXPOSE_OTP_IN_RESPONSE", "").lower() == "true"
    ):
        response_data["dev_mode"] = True
        response_data["otp_code"] = otp_result.get("otp_code")

    return SignupResponse(**response_data)


@router.post("/login", response_model=LoginResponse)
async def login(
    request: LoginRequest,
    response: Response,
    db: Session = Depends(get_db),
):
    """
    Authenticate user and generate JWT token.
    
    Validates credentials and returns access token for API calls.
    Response format: {success: true, message: "...", data: {token: "...", user: {...}}}
    """
    email_lower = request.email.lower()
    
    # Find user in database
    user_record = db.query(User).filter(User.email == email_lower).first()
    
    if not user_record:
        raise HTTPException(
            status_code=401,
            detail="Invalid email or password"
        )
    
    if not verify_password(request.password, user_record.password_hash):
        raise HTTPException(
            status_code=401,
            detail="Invalid email or password",
        )

    if needs_rehash(user_record.password_hash):
        user_record.password_hash = hash_password(request.password)
        db.commit()

    # Generate JWT token
    token_data = {
        "user_id": user_record.id,
        "email": email_lower,
        "tier": user_record.tier,
        "name": user_record.name
    }
    jwt_token = create_jwt_token(token_data)
    
    logger.info(f"User logged in: {email_lower}")
    set_auth_cookie(response, jwt_token)

    return LoginResponse(
        success=True,
        message="Login successful",
        data={
            "token": jwt_token,
            "user": {
                "id": user_record.id,
                "email": email_lower,
                "name": user_record.name,
                "tier": user_record.tier,
                "is_verified": user_record.is_verified
            }
        }
    )


@router.get("/me", response_model=dict)
async def get_current_user(
    request: Request,
    authorization: str = Header(None, alias="Authorization"),
    db: Session = Depends(get_db),
):
    """Get current user profile (Bearer header or HttpOnly cookie)."""
    token = get_token_from_request(request, authorization)
    if not token:
        raise HTTPException(status_code=401, detail="Authentication required")

    try:
        payload = verify_jwt_token(token)
        email = payload.get("email")
        
        if not email:
            raise HTTPException(status_code=401, detail="Invalid token")
        
        # Query user from database
        user_record = db.query(User).filter(User.email == email).first()
        
        if not user_record:
            raise HTTPException(status_code=401, detail="User not found")
        
        return {
            "success": True,
            "user": {
                "id": user_record.id,
                "email": user_record.email,
                "name": user_record.name,
                "tier": user_record.tier,
                "created_at": user_record.created_at.isoformat() if user_record.created_at else None,
                "is_verified": user_record.is_verified,
                "is_admin": user_record.is_admin
            }
        }
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Token verification failed: {str(e)}")
        raise HTTPException(status_code=401, detail="Invalid or expired token")


async def verify_admin_role(
    request: Request,
    authorization: Optional[str] = Header(None),
    db: Session = Depends(get_db),
) -> dict:
    """
    Verify that the user has admin privileges.
    
    This is a dependency function for protecting admin routes.
    Extracts JWT token from Authorization header.
    
    Args:
        authorization: Authorization header value (e.g., "Bearer <token>")
        
    Returns:
        User data dictionary if admin
        
    Raises:
        HTTPException: If not authenticated or not an admin
    """
    token = get_token_from_request(request, authorization)
    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication required",
            headers={"WWW-Authenticate": "Bearer"},
        )

    try:
        payload = verify_jwt_token(token)
        email = payload.get("email")
        
        if not email:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token"
            )
        
        # Query user from database
        user_record = db.query(User).filter(User.email == email).first()
        
        if not user_record:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User not found"
            )
        
        # Check if user is admin
        if not user_record.is_admin:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Admin access required. Contact support to upgrade your account."
            )
        
        return user_record.to_dict()
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Admin verification failed: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token"
        )


@router.put("/profile", response_model=dict)
async def update_profile(
    name: Optional[str] = None,
    company: Optional[str] = None,
    authorization: str = Header(None, alias="Authorization"),
    db: Session = Depends(get_db)
):
    """
    Update user profile information.
    
    Requires valid JWT token in Authorization header.
    """
    if not authorization:
        raise HTTPException(status_code=401, detail="Authentication required")
    
    try:
        # Extract token from Authorization header
        token = authorization
        if token.startswith("Bearer "):
            token = token[7:]
        
        payload = verify_jwt_token(token)
        email = payload.get("email")
        
        if not email:
            raise HTTPException(status_code=401, detail="Invalid token")
        
        # Query user from database
        user_record = db.query(User).filter(User.email == email).first()
        
        if not user_record:
            raise HTTPException(status_code=401, detail="User not found")
        
        # Update fields
        if name:
            user_record.name = name
        if company:
            # Note: company field needs to be added to User model
            pass  # For now, skip company update
        
        db.commit()
        db.refresh(user_record)
        
        logger.info(f"Profile updated for: {email}")
        
        return {
            "success": True,
            "message": "Profile updated successfully",
            "user": {
                "id": user_record.id,
                "email": user_record.email,
                "name": user_record.name,
                "tier": user_record.tier
            }
        }
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Profile update failed: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to update profile")


@router.post("/logout")
async def logout(response: Response):
    """Clear HttpOnly session cookie."""
    clear_auth_cookie(response)
    return {"success": True, "message": "Logged out successfully"}
