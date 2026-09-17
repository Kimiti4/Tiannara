"""
Email Change Verification Routes
Secure email change with OTP verification
"""

from datetime import datetime, timezone, timedelta
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel

from tiannara_api.database import get_db
from tiannara_api.database.models import User
from tiannara_api.routes.auth import get_current_user
from tiannara_api.services.email_service import send_otp_email

import logging

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/auth/email-change", tags=["email-verification"])

# In-memory OTP storage (use Redis in production)
email_change_otps = {}  # user_id -> {email, otp, expires_at}

class SendOTPRequest(BaseModel):
    email: str

class VerifyOTPRequest(BaseModel):
    email: str
    otp_code: str

def generate_otp() -> str:
    """Generate 6-digit OTP."""
    import secrets
    return f"{secrets.randbelow(1000000):06d}"


@router.post("/send-otp")
async def send_email_change_otp(
    request: SendOTPRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Send OTP to new email address for verification."""
    # Check if email is already in use
    existing_user = db.query(User).filter(User.email == request.email).first()
    if existing_user and existing_user.id != current_user.id:
        raise HTTPException(status_code=400, detail="Email already in use by another account")
    
    # Generate OTP
    otp = generate_otp()
    expires_at = datetime.now(timezone.utc) + timedelta(minutes=10)
    
    # Store OTP
    email_change_otps[current_user.id] = {
        'email': request.email,
        'otp': otp,
        'expires_at': expires_at,
        'created_at': datetime.now(timezone.utc)
    }
    
    # Send OTP email
    await send_otp_email(
        to_email=request.email,
        otp_code=otp,
        purpose="email change verification",
        expiry_minutes=10
    )
    
    return {
        "success": True,
        "message": f"Verification code sent to {request.email}",
        "expires_in": 600  # 10 minutes in seconds
    }


@router.post("/verify")
async def verify_email_change(
    request: VerifyOTPRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Verify OTP and complete email change."""
    # Check if OTP exists
    otp_data = email_change_otps.get(current_user.id)
    if not otp_data:
        raise HTTPException(status_code=400, detail="No pending email change. Please request a new code.")
    
    # Check if expired
    if datetime.now(timezone.utc) > otp_data['expires_at']:
        del email_change_otps[current_user.id]
        raise HTTPException(status_code=400, detail="Verification code expired. Please request a new code.")
    
    # Verify OTP
    if otp_data['otp'] != request.otp_code:
        raise HTTPException(status_code=401, detail="Invalid verification code")
    
    # Verify email matches
    if otp_data['email'] != request.email:
        raise HTTPException(status_code=400, detail="Email mismatch")
    
    # Update email
    old_email = current_user.email
    current_user.email = request.email
    current_user.updated_at = datetime.now(timezone.utc)
    
    db.commit()
    db.refresh(current_user)
    
    # Clean up OTP
    del email_change_otps[current_user.id]
    
    # Send notification to old email
    try:
        from tiannara_api.services.email_service import send_email
        await send_email(
            to_email=old_email,
            subject="Your Email Address Has Been Changed",
            body=f"""
            Hi {current_user.name},
            
            Your email address for Tiannara has been changed from {old_email} to {request.email}.
            
            If you did not make this change, please contact support immediately.
            
            Best regards,
            Tiannara Team
            """
        )
    except Exception as e:
        logger.error(f"Warning: Failed to send notification email: {e}")
    
    return {
        "success": True,
        "message": "Email updated successfully",
        "email": request.email
    }
