"""
Security Headers Middleware for Tiannara API

Implements OWASP-recommended security headers to protect against common web vulnerabilities.

Headers Implemented:
- Content-Security-Policy (CSP)
- X-Frame-Options (Clickjacking protection)
- X-Content-Type-Options (MIME sniffing prevention)
- Strict-Transport-Security (HSTS)
- Referrer-Policy
- Permissions-Policy
- X-XSS-Protection
- Cache-Control

Date: April 30, 2026
Status: Week 24 Day 5 - Security Hardening
"""

from fastapi import Request, Response
from typing import Callable


class SecurityHeadersMiddleware:
    """
    FastAPI middleware that adds security headers to all responses.
    
    Protects against:
    - Clickjacking (X-Frame-Options)
    - MIME type sniffing (X-Content-Type-Options)
    - XSS attacks (Content-Security-Policy, X-XSS-Protection)
    - Man-in-the-middle (Strict-Transport-Security)
    - Information leakage (Referrer-Policy)
    - Unauthorized feature usage (Permissions-Policy)
    """
    
    def __init__(
        self,
        app,
        hsts_max_age: int = 31536000,  # 1 year
        csp_policy: str = None
    ):
        self.app = app
        self.hsts_max_age = hsts_max_age
        
        # Default CSP policy - restrictive but functional
        self.csp_policy = csp_policy or (
            "default-src 'self'; "
            "script-src 'self' 'unsafe-inline' 'unsafe-eval'; "
            "style-src 'self' 'unsafe-inline'; "
            "img-src 'self' data: https:; "
            "font-src 'self'; "
            "connect-src 'self' http://localhost:* ws://localhost:*; "
            "frame-ancestors 'none'; "
            "base-uri 'self'; "
            "form-action 'self'"
        )
    
    async def __call__(self, scope, receive, send):
        """Process request and add security headers to response."""
        
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return
        
        async def send_wrapper(message):
            """Intercept response and add security headers."""
            if message["type"] == "http.response.start":
                # Add security headers
                headers = dict(message.get("headers", []))
                
                # Prevent clickjacking
                headers[b"x-frame-options"] = b"DENY"
                
                # Prevent MIME type sniffing
                headers[b"x-content-type-options"] = b"nosniff"
                
                # Content Security Policy
                headers[b"content-security-policy"] = self.csp_policy.encode()
                
                # HTTP Strict Transport Security (HSTS)
                headers[b"strict-transport-security"] = (
                    f"max-age={self.hsts_max_age}; includeSubDomains".encode()
                )
                
                # Referrer Policy
                headers[b"referrer-policy"] = b"strict-origin-when-cross-origin"
                
                # Permissions Policy (formerly Feature-Policy)
                headers[b"permissions-policy"] = (
                    b"geolocation=(), microphone=(), camera=(), payment=(), usb=()"
                )
                
                # XSS Protection (legacy but still useful)
                headers[b"x-xss-protection"] = b"1; mode=block"
                
                # Cache Control for API responses
                headers[b"cache-control"] = b"no-store, no-cache, must-revalidate"
                headers[b"pragma"] = b"no-cache"
                
                # Remove server header (information disclosure)
                headers.pop(b"server", None)
                
                message["headers"] = list(headers.items())
            
            await send(message)
        
        await self.app(scope, receive, send_wrapper)
