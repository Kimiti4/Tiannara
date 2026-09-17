"""
OTP (One-Time Password) Service for Tiannara SaaS

Features:
- Generate cryptographically secure 6-digit OTP codes
- Send OTP via email using Resend API
- Verify OTP codes with expiration (10 minutes)
- Rate limiting to prevent abuse
- Secure storage with hashing
"""

import logging
import os
import secrets
import hashlib
import time
from typing import Optional, Dict, Any
from datetime import datetime, timedelta
from dataclasses import dataclass, field
import httpx

logger = logging.getLogger(__name__)


@dataclass
class OTPRecord:
    """Stores OTP verification data."""
    code_hash: str
    email: str
    created_at: float
    expires_at: float
    attempts: int = 0
    max_attempts: int = 5
    is_verified: bool = False


class OTPService:
    """
    One-Time Password service for email verification.
    
    Features:
    - Cryptographically secure OTP generation
    - Email delivery via Resend/SendGrid
    - Automatic expiration (10 minutes default)
    - Brute force protection (max 5 attempts)
    - Rate limiting per email address
    """
    
    def __init__(
        self,
        otp_length: int = 6,
        expiry_minutes: int = 10,
        resend_api_key: Optional[str] = None,
        from_email: str = "noreply@tiannara.ai"
    ):
        self.otp_length = otp_length
        self.expiry_seconds = expiry_minutes * 60
        self.from_email = from_email
        
        # Initialize Resend client if API key provided
        self.resend_api_key = resend_api_key or self._get_resend_key()
        self.resend_base_url = "https://api.resend.com/emails"
        
        # In-memory OTP store (use Redis in production)
        self.otp_store: Dict[str, OTPRecord] = {}
        
        # Rate limiting: track OTP requests per email
        self.rate_limit_store: Dict[str, list] = {}
        self.rate_limit_window = 300  # 5 minutes
        self.rate_limit_max = 3  # Max 3 OTPs per 5 minutes
    
    def _get_resend_key(self) -> Optional[str]:
        """Get Resend API key from environment."""
        import os
        return os.getenv("RESEND_API_KEY")
    
    def generate_otp(self) -> str:
        """
        Generate a cryptographically secure OTP code.
        
        Returns:
            String of digits (default 6 digits)
        """
        # Use secrets module for cryptographic randomness
        otp = ''.join([str(secrets.randbelow(10)) for _ in range(self.otp_length)])
        return otp
    
    def _hash_code(self, code: str) -> str:
        """Hash OTP code for secure storage."""
        return hashlib.sha256(code.encode()).hexdigest()
    
    def request_otp(self, email: str) -> Dict[str, Any]:
        """
        Request OTP for email verification.
        
        Args:
            email: User's email address
            
        Returns:
            Dictionary with success status and message
        """
        # Check rate limiting
        if not self._check_rate_limit(email):
            logger.warning(f"Rate limit exceeded for OTP request: {email}")
            return {
                "success": False,
                "error": "Too many OTP requests. Please wait 5 minutes before trying again."
            }
        
        # Generate OTP
        otp_code = self.generate_otp()
        code_hash = self._hash_code(otp_code)
        
        # Store OTP record
        now = time.time()
        otp_record = OTPRecord(
            code_hash=code_hash,
            email=email.lower(),
            created_at=now,
            expires_at=now + self.expiry_seconds
        )
        
        self.otp_store[email.lower()] = otp_record
        
        # Send OTP via email
        send_result = self._send_otp_email(email, otp_code)
        
        if not send_result["success"]:
            # Remove OTP if email failed
            self.otp_store.pop(email.lower(), None)
            return send_result
        
        logger.info(f"OTP sent successfully to {email}")
        return {
            "success": True,
            "message": f"Verification code sent to {email}",
            "expires_in_minutes": self.expiry_seconds // 60
        }
    
    def verify_otp(self, email: str, code: str) -> Dict[str, Any]:
        """
        Verify OTP code for email.
        
        Args:
            email: User's email address
            code: OTP code to verify
            
        Returns:
            Dictionary with verification result
        """
        email_lower = email.lower()
        
        # Check if OTP exists
        if email_lower not in self.otp_store:
            return {
                "success": False,
                "error": "No verification code found. Please request a new one."
            }
        
        otp_record = self.otp_store[email_lower]
        
        # Check if expired
        if time.time() > otp_record.expires_at:
            self.otp_store.pop(email_lower)
            return {
                "success": False,
                "error": "Verification code has expired. Please request a new one."
            }
        
        # Check attempt limit
        if otp_record.attempts >= otp_record.max_attempts:
            self.otp_store.pop(email_lower)
            return {
                "success": False,
                "error": "Too many failed attempts. Please request a new verification code."
            }
        
        # Increment attempts
        otp_record.attempts += 1
        
        # Verify code
        code_hash = self._hash_code(code)
        if code_hash != otp_record.code_hash:
            remaining = otp_record.max_attempts - otp_record.attempts
            return {
                "success": False,
                "error": f"Invalid verification code. {remaining} attempts remaining."
            }
        
        # Mark as verified
        otp_record.is_verified = True
        
        # Clean up after successful verification
        self.otp_store.pop(email_lower)
        
        logger.info(f"OTP verified successfully for {email}")
        return {
            "success": True,
            "message": "Email verified successfully"
        }
    
    def _check_rate_limit(self, email: str) -> bool:
        """Check if email has exceeded OTP request rate limit."""
        email_lower = email.lower()
        now = time.time()
        
        if email_lower not in self.rate_limit_store:
            self.rate_limit_store[email_lower] = []
        
        # Remove old entries outside window
        self.rate_limit_store[email_lower] = [
            timestamp for timestamp in self.rate_limit_store[email_lower]
            if now - timestamp < self.rate_limit_window
        ]
        
        # Check if limit exceeded
        if len(self.rate_limit_store[email_lower]) >= self.rate_limit_max:
            return False
        
        # Record this request
        self.rate_limit_store[email_lower].append(now)
        return True
    
    def _send_otp_email(self, email: str, otp_code: str) -> Dict[str, Any]:
        """
        Send OTP code via email using Resend API.
        
        Args:
            email: Recipient email
            otp_code: OTP code to send
            
        Returns:
            Dictionary with send result
        """
        if not self.resend_api_key:
            logger.warning(
                "RESEND_API_KEY not configured; OTP logged server-side only for %s",
                email,
            )
            result = {
                "success": True,
                "message": "OTP generated (development mode - check server logs)",
                "dev_mode": True,
            }
            if os.getenv("EXPOSE_OTP_IN_RESPONSE", "").lower() == "true":
                result["otp_code"] = otp_code
            return result
        
        try:
            # Prepare email content
            subject = "Tiannara Verification Code"
            html_content = self._generate_otp_email_html(otp_code)
            text_content = f"Your Tiannara verification code is: {otp_code}\n\nThis code will expire in 10 minutes.\n\nIf you didn't request this code, please ignore this email."
            
            # Send via Resend API
            response = httpx.post(
                self.resend_base_url,
                headers={
                    "Authorization": f"Bearer {self.resend_api_key}",
                    "Content-Type": "application/json"
                },
                json={
                    "from": f"Tiannara <{self.from_email}>",
                    "to": [email],
                    "subject": subject,
                    "html": html_content,
                    "text": text_content
                },
                timeout=10.0
            )
            
            if response.status_code == 200:
                logger.info(f"OTP email sent successfully to {email}")
                return {"success": True, "message": "Verification code sent"}
            else:
                error_detail = response.json().get("error", {}).get("message", "Unknown error")
                logger.error(f"Resend API error: {error_detail}")
                return {
                    "success": False,
                    "error": f"Failed to send verification email: {error_detail}"
                }
        
        except httpx.RequestError as e:
            logger.error(f"HTTP request failed: {str(e)}")
            return {
                "success": False,
                "error": "Failed to send verification email. Please try again."
            }
        except Exception as e:
            logger.error(f"Unexpected error sending OTP: {str(e)}", exc_info=True)
            return {
                "success": False,
                "error": "An unexpected error occurred. Please try again."
            }
    
    def _generate_otp_email_html(self, otp_code: str) -> str:
        """Generate HTML email template for OTP."""
        return f"""
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <style>
                body {{ font-family: Arial, sans-serif; background-color: #f4f4f4; margin: 0; padding: 0; }}
                .container {{ max-width: 600px; margin: 40px auto; background: white; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }}
                .header {{ background: linear-gradient(135deg, #9333ea 0%, #ec4899 100%); padding: 40px 20px; text-align: center; }}
                .header h1 {{ color: white; margin: 0; font-size: 28px; }}
                .content {{ padding: 40px 30px; }}
                .otp-code {{ background: #f3f4f6; border: 2px solid #e5e7eb; border-radius: 8px; padding: 20px; text-align: center; margin: 30px 0; }}
                .otp-code span {{ font-size: 36px; font-weight: bold; color: #9333ea; letter-spacing: 8px; }}
                .footer {{ background: #f9fafb; padding: 20px 30px; text-align: center; color: #6b7280; font-size: 14px; }}
                .warning {{ background: #fef3c7; border-left: 4px solid #f59e0b; padding: 15px; margin: 20px 0; border-radius: 4px; }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>🧠 Tiannara</h1>
                </div>
                <div class="content">
                    <h2 style="color: #1f2937; margin-top: 0;">Verify Your Email</h2>
                    <p style="color: #4b5563; line-height: 1.6;">
                        Thank you for signing up for Tiannara! To complete your registration, please use the verification code below:
                    </p>
                    <div class="otp-code">
                        <span>{otp_code}</span>
                    </div>
                    <p style="color: #6b7280; font-size: 14px;">
                        This code will expire in <strong>10 minutes</strong>.
                    </p>
                    <div class="warning">
                        <p style="margin: 0; color: #92400e; font-size: 14px;">
                            ⚠️ If you didn't request this code, please ignore this email. Your account is safe.
                        </p>
                    </div>
                </div>
                <div class="footer">
                    <p>© 2026 Tiannara AI. All rights reserved.</p>
                    <p style="font-size: 12px; margin-top: 10px;">
                        This is an automated message. Please do not reply to this email.
                    </p>
                </div>
            </div>
        </body>
        </html>
        """
    
    def cleanup_expired_otps(self):
        """Remove expired OTP records (call periodically)."""
        now = time.time()
        expired_emails = [
            email for email, record in self.otp_store.items()
            if now > record.expires_at
        ]
        
        for email in expired_emails:
            self.otp_store.pop(email)
        
        if expired_emails:
            logger.info(f"Cleaned up {len(expired_emails)} expired OTP records")


# Singleton instance
_otp_service = None


def get_otp_service() -> OTPService:
    """Get or create OTP service singleton."""
    global _otp_service
    if _otp_service is None:
        _otp_service = OTPService()
    return _otp_service
