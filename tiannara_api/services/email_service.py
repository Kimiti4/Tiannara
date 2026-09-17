"""
Email Service for Tiannara API

Sends transactional emails using Resend API.
Supports workspace invitations, password resets, and notifications.

Date: May 1, 2026
Status: Week 27 Day 3 - Email Integration
"""

import os
import logging
from typing import Optional
from dataclasses import dataclass

logger = logging.getLogger(__name__)


@dataclass
class EmailMessage:
    """Email message structure."""
    to: str
    subject: str
    html: str
    text: Optional[str] = None
    from_name: str = "Tiannara"


class EmailService:
    """
    Email service using Resend API.
    
    Features:
    - Send transactional emails
    - HTML and text support
    - Error handling and logging
    - Fallback to console logging in development
    """
    
    def __init__(self, api_key: Optional[str] = None):
        """
        Initialize email service.
        
        Args:
            api_key: Resend API key. If not provided, uses RESEND_API_KEY env var.
        """
        self.api_key = api_key or os.getenv("RESEND_API_KEY")
        self.from_email = os.getenv("EMAIL_FROM", "noreply@tiannara.com")
        self.is_configured = bool(self.api_key)
        
        if not self.is_configured:
            logger.warning("⚠️  Resend API key not configured. Emails will be logged to console.")
    
    async def send_email(self, message: EmailMessage) -> bool:
        """
        Send an email message.
        
        Args:
            message: EmailMessage object with recipient, subject, and content
            
        Returns:
            True if email sent successfully, False otherwise
        """
        if not self.is_configured:
            # Development mode - log to console
            logger.info(f"📧 [DEV MODE] Email would be sent to: {message.to}")
            logger.info(f"   Subject: {message.subject}")
            logger.info(f"   Preview: {message.html[:200]}...")
            return True
        
        try:
            import aiohttp
            
            url = "https://api.resend.com/emails"
            headers = {
                "Authorization": f"Bearer {self.api_key}",
                "Content-Type": "application/json",
            }
            
            payload = {
                "from": f"{message.from_name} <{self.from_email}>",
                "to": [message.to],
                "subject": message.subject,
                "html": message.html,
            }
            
            if message.text:
                payload["text"] = message.text
            
            async with aiohttp.ClientSession() as session:
                async with session.post(url, json=payload, headers=headers) as response:
                    if response.status == 200:
                        result = await response.json()
                        logger.info(f"✅ Email sent successfully to {message.to}")
                        logger.debug(f"   Resend ID: {result.get('id')}")
                        return True
                    else:
                        error_text = await response.text()
                        logger.error(f"❌ Failed to send email: {response.status} - {error_text}")
                        return False
                        
        except ImportError:
            logger.error("❌ aiohttp not installed. Install with: pip install aiohttp")
            return False
        except Exception as e:
            logger.error(f"❌ Error sending email: {str(e)}")
            import traceback
            logger.debug(traceback.format_exc())
            return False
    
    async def send_workspace_invitation(
        self,
        to_email: str,
        workspace_name: str,
        inviter_name: str,
        invite_url: str,
        role: str = "member"
    ) -> bool:
        """
        Send workspace invitation email.
        
        Args:
            to_email: Recipient email address
            workspace_name: Name of the workspace
            inviter_name: Name of person sending invitation
            invite_url: Full URL to accept invitation
            role: Role being assigned (member, admin, viewer)
            
        Returns:
            True if email sent successfully
        """
        subject = f"You're invited to join {workspace_name} on Tiannara"
        
        html_content = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
                .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                .header {{ background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
                          color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }}
                .content {{ background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }}
                .button {{ display: inline-block; padding: 12px 30px; background: #667eea; 
                          color: white; text-decoration: none; border-radius: 5px; margin: 20px 0; }}
                .footer {{ text-align: center; margin-top: 30px; color: #666; font-size: 12px; }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>🎉 You're Invited!</h1>
                </div>
                <div class="content">
                    <p><strong>{inviter_name}</strong> has invited you to join their workspace on Tiannara.</p>
                    
                    <h2 style="color: #667eea;">{workspace_name}</h2>
                    
                    <p>You've been invited as a <strong>{role}</strong>.</p>
                    
                    <div style="text-align: center;">
                        <a href="{invite_url}" class="button">Accept Invitation</a>
                    </div>
                    
                    <p style="margin-top: 30px;">Or copy and paste this link into your browser:</p>
                    <p style="word-break: break-all; color: #667eea;">{invite_url}</p>
                    
                    <div class="footer">
                        <p>This invitation will expire in 7 days.</p>
                        <p>If you didn't expect this invitation, you can safely ignore this email.</p>
                    </div>
                </div>
            </div>
        </body>
        </html>
        """
        
        text_content = f"""
        You're invited to join {workspace_name} on Tiannara!
        
        {inviter_name} has invited you to join their workspace as a {role}.
        
        Accept the invitation here:
        {invite_url}
        
        This invitation will expire in 7 days.
        
        If you didn't expect this invitation, you can safely ignore this email.
        """
        
        message = EmailMessage(
            to=to_email,
            subject=subject,
            html=html_content,
            text=text_content,
        )
        
        return await self.send_email(message)

    async def send_otp_email(
        self,
        to_email: str,
        otp_code: str,
        purpose: str = "verification",
        expiry_minutes: int = 10
    ) -> bool:
        """
        Send OTP verification email.
        
        Args:
            to_email: Recipient email address
            otp_code: The OTP code to send
            purpose: Purpose of the OTP (e.g., "registration", "email change")
            expiry_minutes: How long the OTP is valid
            
        Returns:
            True if email sent successfully
        """
        subject = f"Your Tiannara Verification Code"
        
        html_content = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
                .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                .header {{ background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
                          color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }}
                .content {{ background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }}
                .otp-code {{ font-size: 36px; font-weight: bold; color: #667eea; 
                            letter-spacing: 8px; text-align: center; margin: 30px 0; 
                            padding: 20px; background: white; border-radius: 10px; }}
                .footer {{ text-align: center; margin-top: 30px; color: #666; font-size: 12px; }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>🔐 Verification Code</h1>
                </div>
                <div class="content">
                    <p>Your verification code for {purpose} is:</p>
                    
                    <div class="otp-code">{otp_code}</div>
                    
                    <p>This code will expire in <strong>{expiry_minutes} minutes</strong>.</p>
                    
                    <p style="margin-top: 30px;"><strong>Security Notice:</strong></p>
                    <p>If you didn't request this code, please ignore this email or contact support if you're concerned about your account security.</p>
                    
                    <div class="footer">
                        <p>For security reasons, never share this code with anyone.</p>
                        <p>Tiannara Team</p>
                    </div>
                </div>
            </div>
        </body>
        </html>
        """
        
        text_content = f"""
        Your Tiannara Verification Code
        
        Your verification code for {purpose} is: {otp_code}
        
        This code will expire in {expiry_minutes} minutes.
        
        Security Notice:
        If you didn't request this code, please ignore this email or contact support if you're concerned about your account security.
        
        For security reasons, never share this code with anyone.
        
        Tiannara Team
        """
        
        message = EmailMessage(
            to=to_email,
            subject=subject,
            html=html_content,
            text=text_content,
        )
        
        return await self.send_email(message)


# Global email service instance
email_service = EmailService()

# Convenience functions
async def send_email(to_email: str, subject: str, body: str) -> bool:
    """Send a simple email."""
    message = EmailMessage(
        to=to_email,
        subject=subject,
        html=f"<html><body>{body}</body></html>",
        text=body,
    )
    return await email_service.send_email(message)

async def send_otp_email(to_email: str, otp_code: str, purpose: str = "verification", expiry_minutes: int = 10) -> bool:
    """Send OTP verification email."""
    return await email_service.send_otp_email(to_email, otp_code, purpose, expiry_minutes)
