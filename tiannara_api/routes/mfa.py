"""
Multi-Factor Authentication (MFA) Routes
TOTP-based 2FA with backup codes
"""

import io
import base64
import secrets
import pyotp
import qrcode
from datetime import datetime, timezone
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel

from tiannara_api.database import get_db
from tiannara_api.database.models import User
from tiannara_api.routes.auth import get_current_user, hash_password

router = APIRouter(prefix="/auth/mfa", tags=["mfa"])

# In-memory storage for MFA setup (use Redis in production)
mfa_pending = {}  # user_id -> {secret, backup_codes}

class MFASetupResponse(BaseModel):
    secret: str
    qr_code_url: str
    backup_codes: list[str]

class MFAEnableRequest(BaseModel):
    code: str

class MFAStatusResponse(BaseModel):
    enabled: bool

class BackupCodesResponse(BaseModel):
    backup_codes: list[str]

def generate_backup_codes(count: int = 8) -> list[str]:
    """Generate secure backup codes."""
    return [secrets.token_hex(4) for _ in range(count)]

def generate_qr_code(secret: str, email: str) -> str:
    """Generate QR code for authenticator app."""
    uri = pyotp.totp.TOTP(secret).provisioning_uri(
        name=email,
        issuer_name="Tiannara"
    )
    
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_L,
        box_size=10,
        border=4,
    )
    qr.add_data(uri)
    qr.make(fit=True)
    
    img = qr.make_image(fill_color="black", back_color="white")
    
    buffered = io.BytesIO()
    img.save(buffered, format="PNG")
    img_str = base64.b64encode(buffered.getvalue()).decode()
    
    return f"data:image/png;base64,{img_str}"


@router.get("/status", response_model=MFAStatusResponse)
async def get_mfa_status(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get MFA status for current user."""
    return MFAStatusResponse(enabled=current_user.mfa_enabled)


@router.post("/setup", response_model=MFASetupResponse)
async def setup_mfa(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Setup MFA - generate secret and QR code."""
    if current_user.mfa_enabled:
        raise HTTPException(status_code=400, detail="MFA is already enabled")
    
    # Generate TOTP secret
    secret = pyotp.random_base32()
    
    # Generate backup codes
    backup_codes = generate_backup_codes()
    
    # Store temporarily
    mfa_pending[current_user.id] = {
        'secret': secret,
        'backup_codes': backup_codes
    }
    
    # Generate QR code
    qr_code_url = generate_qr_code(secret, current_user.email)
    
    return MFASetupResponse(
        secret=secret,
        qr_code_url=qr_code_url,
        backup_codes=backup_codes
    )


@router.post("/enable")
async def enable_mfa(
    request: MFAEnableRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Enable MFA with verification code."""
    if current_user.mfa_enabled:
        raise HTTPException(status_code=400, detail="MFA is already enabled")
    
    pending = mfa_pending.get(current_user.id)
    if not pending:
        raise HTTPException(status_code=400, detail="MFA setup not initiated. Please setup first.")
    
    # Verify TOTP code
    totp = pyotp.TOTP(pending['secret'])
    if not totp.verify(request.code, valid_window=1):
        raise HTTPException(status_code=401, detail="Invalid verification code")
    
    # Enable MFA
    current_user.mfa_enabled = True
    current_user.mfa_secret = pending['secret']
    current_user.mfa_backup_codes = ','.join(pending['backup_codes'])
    current_user.updated_at = datetime.now(timezone.utc)
    
    db.commit()
    db.refresh(current_user)
    
    # Clean up pending setup
    del mfa_pending[current_user.id]
    
    return {
        "success": True,
        "message": "MFA enabled successfully",
        "backup_codes": pending['backup_codes']
    }


@router.post("/disable")
async def disable_mfa(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Disable MFA."""
    if not current_user.mfa_enabled:
        raise HTTPException(status_code=400, detail="MFA is not enabled")
    
    current_user.mfa_enabled = False
    current_user.mfa_secret = None
    current_user.mfa_backup_codes = None
    current_user.updated_at = datetime.now(timezone.utc)
    
    db.commit()
    db.refresh(current_user)
    
    return {"success": True, "message": "MFA disabled"}


@router.post("/regenerate-backup-codes", response_model=BackupCodesResponse)
async def regenerate_backup_codes(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Regenerate MFA backup codes."""
    if not current_user.mfa_enabled:
        raise HTTPException(status_code=400, detail="MFA must be enabled first")
    
    new_codes = generate_backup_codes()
    current_user.mfa_backup_codes = ','.join(new_codes)
    current_user.updated_at = datetime.now(timezone.utc)
    
    db.commit()
    db.refresh(current_user)
    
    return BackupCodesResponse(backup_codes=new_codes)


@router.post("/verify")
async def verify_mfa_code(
    request: MFAEnableRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Verify MFA code during login."""
    if not current_user.mfa_enabled:
        raise HTTPException(status_code=400, detail="MFA is not enabled for this user")
    
    # Check if code is a backup code
    if current_user.mfa_backup_codes:
        backup_codes = current_user.mfa_backup_codes.split(',')
        if request.code in backup_codes:
            # Remove used backup code
            backup_codes.remove(request.code)
            current_user.mfa_backup_codes = ','.join(backup_codes)
            current_user.updated_at = datetime.now(timezone.utc)
            db.commit()
            
            return {"success": True, "message": "Backup code accepted"}
    
    # Verify TOTP code
    totp = pyotp.TOTP(current_user.mfa_secret)
    if totp.verify(request.code, valid_window=1):
        return {"success": True, "message": "MFA code verified"}
    
    raise HTTPException(status_code=401, detail="Invalid MFA code")
