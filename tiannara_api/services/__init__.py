"""
Services package for Tiannara API.

Contains business logic services like email, notifications, etc.
"""

from tiannara_api.services.email_service import EmailService, email_service

__all__ = ["EmailService", "email_service"]
