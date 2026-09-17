"""
Input Validation Middleware for Tiannara API

Protects against:
- SQL Injection
- Cross-Site Scripting (XSS)
- Path Traversal
- Command Injection
- Malformed requests

Date: April 30, 2026
Status: Week 24 Day 5 - Security Hardening
"""

import re
from fastapi import Request, HTTPException, status
from typing import Callable
import json


# Dangerous patterns that indicate attacks
SQL_INJECTION_PATTERNS = [
    r"(\b(SELECT|INSERT|UPDATE|DELETE|DROP|UNION|ALTER)\b.*\b(FROM|INTO|TABLE|WHERE)\b)",
    r"(--|#|/\*|\*/|;)",  # SQL comments and statement terminators
    r"(\b(OR|AND)\b\s+\d+\s*=\s*\d+)",  # OR 1=1, AND 1=1 patterns
    r"('|\")\s*(OR|AND)\s*('|\"|\d)",  # Quote-based injection
]

XSS_PATTERNS = [
    r"<script[^>]*>",  # Script tags
    r"javascript:",  # JavaScript protocol
    r"on(load|error|click|mouseover|submit)\s*=",  # Event handlers
    r"<iframe[^>]*>",  # iframe injection
    r"<img[^>]*onerror",  # Image error handlers
]

PATH_TRAVERSAL_PATTERNS = [
    r"\.\./",  # Directory traversal
    r"\.\.\\",  # Windows directory traversal
    r"%2e%2e",  # URL-encoded traversal
    r"/etc/passwd",  # Unix system files
    r"C:\\Windows",  # Windows system paths
]

COMMAND_INJECTION_PATTERNS = [
    r"[;&|`$]",  # Shell metacharacters
    r"\$\(",  # Command substitution
    r"`[^`]+`",  # Backtick execution
]


class InputValidationMiddleware:
    """
    Validates incoming requests for malicious patterns.
    
    Blocks:
    - SQL injection attempts
    - XSS attacks
    - Path traversal
    - Command injection
    """
    
    def __init__(self, app):
        self.app = app
        
        # Compile regex patterns for performance
        self.sql_patterns = [re.compile(p, re.IGNORECASE) for p in SQL_INJECTION_PATTERNS]
        self.xss_patterns = [re.compile(p, re.IGNORECASE) for p in XSS_PATTERNS]
        self.path_patterns = [re.compile(p, re.IGNORECASE) for p in PATH_TRAVERSAL_PATTERNS]
        self.cmd_patterns = [re.compile(p, re.IGNORECASE) for p in COMMAND_INJECTION_PATTERNS]
    
    async def __call__(self, scope, receive, send):
        """Process request and validate inputs."""
        
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return
        
        request = Request(scope, receive)
        
        # Validate URL path
        self._validate_path(request.url.path)
        
        # Validate query parameters
        self._validate_query_params(dict(request.query_params))
        
        # For POST/PUT/PATCH, validate body (will be done in route handlers)
        # This middleware focuses on URL-level validation
        
        await self.app(scope, receive, send)
    
    def _validate_path(self, path: str):
        """Validate URL path for dangerous patterns."""
        
        # Check for path traversal
        for pattern in self.path_patterns:
            if pattern.search(path):
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Invalid path: Path traversal detected"
                )
    
    def _validate_query_params(self, params: dict):
        """Validate query parameters for injection attempts."""
        
        for key, value in params.items():
            # Validate key
            self._check_value(key, "query parameter key")
            
            # Validate value
            self._check_value(value, f"query parameter '{key}'")
    
    def _check_value(self, value: str, context: str):
        """Check a string value for dangerous patterns."""
        
        # Check SQL injection
        for pattern in self.sql_patterns:
            if pattern.search(value):
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Invalid input in {context}: Potential SQL injection detected"
                )
        
        # Check XSS
        for pattern in self.xss_patterns:
            if pattern.search(value):
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Invalid input in {context}: Potential XSS attack detected"
                )
        
        # Check command injection
        for pattern in self.cmd_patterns:
            if pattern.search(value):
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Invalid input in {context}: Potential command injection detected"
                )
    
    @staticmethod
    def sanitize_string(value: str, max_length: int = 1000) -> str:
        """
        Sanitize a string by removing dangerous characters.
        
        Args:
            value: Input string to sanitize
            max_length: Maximum allowed length
            
        Returns:
            Sanitized string
        """
        if not value:
            return value
        
        # Truncate if too long
        if len(value) > max_length:
            value = value[:max_length]
        
        # Remove null bytes
        value = value.replace('\x00', '')
        
        # Strip leading/trailing whitespace
        value = value.strip()
        
        return value
    
    @staticmethod
    def validate_email(email: str) -> bool:
        """
        Validate email format.
        
        Args:
            email: Email address to validate
            
        Returns:
            True if valid, False otherwise
        """
        if not email or len(email) > 254:
            return False
        
        # Basic email regex
        pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        return bool(re.match(pattern, email))
    
    @staticmethod
    def validate_password_strength(password: str) -> tuple[bool, str]:
        """
        Validate password meets security requirements.
        
        Requirements:
        - Minimum 8 characters
        - At least one uppercase letter
        - At least one lowercase letter
        - At least one digit
        - At least one special character
        
        Args:
            password: Password to validate
            
        Returns:
            Tuple of (is_valid, error_message)
        """
        if len(password) < 8:
            return False, "Password must be at least 8 characters long"
        
        if not re.search(r'[A-Z]', password):
            return False, "Password must contain at least one uppercase letter"
        
        if not re.search(r'[a-z]', password):
            return False, "Password must contain at least one lowercase letter"
        
        if not re.search(r'\d', password):
            return False, "Password must contain at least one digit"
        
        if not re.search(r'[!@#$%^&*(),.?":{}|<>]', password):
            return False, "Password must contain at least one special character"
        
        return True, ""
