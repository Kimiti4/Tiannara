"""
Enhanced Rate Limiting Middleware for Tiannara API

Features:
- Per-endpoint rate limits
- User-based throttling (by JWT token)
- IP-based blocking for abuse
- Sliding window algorithm
- Automatic ban for repeated violations

Date: April 30, 2026
Status: Week 24 Day 5 - Security Hardening
"""

import time
from collections import defaultdict
from typing import Dict, Optional, Tuple
from fastapi import Request, HTTPException, status


class RateLimitEntry:
    """Tracks request history for a single client."""
    
    def __init__(self, max_requests: int, window_seconds: int):
        self.max_requests = max_requests
        self.window_seconds = window_seconds
        self.requests: list[float] = []
        self.violations: int = 0
        self.banned_until: float = 0
    
    def is_banned(self) -> bool:
        """Check if client is currently banned."""
        return time.time() < self.banned_until
    
    def add_request(self) -> Tuple[bool, int]:
        """
        Add a request and check if limit exceeded.
        
        Returns:
            Tuple of (is_allowed, remaining_requests)
        """
        now = time.time()
        
        # Remove old requests outside the window
        self.requests = [r for r in self.requests if now - r < self.window_seconds]
        
        # Check if banned
        if self.is_banned():
            return False, 0
        
        # Check if limit exceeded
        if len(self.requests) >= self.max_requests:
            self.violations += 1
            
            # Ban for increasing durations based on violation count
            ban_duration = min(300 * (2 ** self.violations), 86400)  # Max 24 hours
            self.banned_until = now + ban_duration
            
            return False, 0
        
        # Add request
        self.requests.append(now)
        remaining = self.max_requests - len(self.requests)
        
        return True, remaining
    
    def reset_violations(self):
        """Reset violation count after successful period."""
        self.violations = 0
        self.banned_until = 0


# Default rate limits by endpoint pattern
DEFAULT_RATE_LIMITS = {
    # Authentication endpoints (strict limits)
    "/api/v1/auth/login": {"max_requests": 5, "window_seconds": 60},
    "/api/v1/auth/signup": {"max_requests": 3, "window_seconds": 300},
    "/api/v1/auth/verify-otp": {"max_requests": 5, "window_seconds": 60},
    
    # API usage endpoints (moderate limits)
    "/api/v1/usage": {"max_requests": 30, "window_seconds": 60},
    "/api/v1/predict": {"max_requests": 60, "window_seconds": 60},
    
    # Admin endpoints (strict limits)
    "/api/v1/admin": {"max_requests": 20, "window_seconds": 60},
    
    # General API (generous limits)
    "/api/v1": {"max_requests": 100, "window_seconds": 60},
    
    # Health/metrics (very generous)
    "/health": {"max_requests": 300, "window_seconds": 60},
    "/metrics": {"max_requests": 300, "window_seconds": 60},
}


class EnhancedRateLimiter:
    """
    Advanced rate limiter with per-endpoint and per-user tracking.
    
    Features:
    - Sliding window algorithm
    - Per-endpoint rate limits
    - User-based tracking (via JWT)
    - IP-based fallback
    - Automatic banning for abuse
    """
    
    def __init__(self, app, default_limits: Dict = None):
        self.app = app
        self.limits = default_limits or DEFAULT_RATE_LIMITS
        
        # Track rate limits: key -> RateLimitEntry
        # Keys can be: user_id, IP address, or endpoint-specific
        self.clients: Dict[str, RateLimitEntry] = {}
        
        # Cleanup interval (seconds)
        self.cleanup_interval = 3600  # 1 hour
        self.last_cleanup = time.time()
    
    async def __call__(self, scope, receive, send):
        """Process request and enforce rate limits."""
        
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return
        
        request = Request(scope, receive)
        
        # Get client identifier (user ID or IP)
        client_id = self._get_client_id(request)
        
        # Get endpoint-specific limits
        endpoint = request.url.path
        limits = self._get_endpoint_limits(endpoint)
        
        # Create or get rate limit entry
        if client_id not in self.clients:
            self.clients[client_id] = RateLimitEntry(
                max_requests=limits["max_requests"],
                window_seconds=limits["window_seconds"]
            )
        
        client_entry = self.clients[client_id]
        
        # Check rate limit
        allowed, remaining = client_entry.add_request()
        
        if not allowed:
            if client_entry.is_banned():
                raise HTTPException(
                    status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                    detail=f"Too many requests. You are temporarily banned. Try again later."
                )
            else:
                raise HTTPException(
                    status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                    detail=f"Rate limit exceeded. Maximum {limits['max_requests']} requests per {limits['window_seconds']} seconds."
                )
        
        # Periodic cleanup of old entries
        self._cleanup_if_needed()
        
        await self.app(scope, receive, send)
    
    def _get_client_id(self, request: Request) -> str:
        """
        Get unique client identifier.
        
        Priority:
        1. JWT user ID (if authenticated)
        2. API key (if provided)
        3. IP address (fallback)
        """
        
        # Try to get user from authorization header
        auth_header = request.headers.get("authorization", "")
        if auth_header.startswith("Bearer "):
            # Extract token (simplified - in production, decode JWT)
            token = auth_header[7:]
            return f"user:{token[:20]}"  # Use first 20 chars as identifier
        
        # Fallback to IP address
        client_ip = request.client.host if request.client else "unknown"
        return f"ip:{client_ip}"
    
    def _get_endpoint_limits(self, endpoint: str) -> dict:
        """Get rate limits for specific endpoint."""
        
        # Check for exact match first
        if endpoint in self.limits:
            return self.limits[endpoint]
        
        # Check for prefix match
        for path, limits in self.limits.items():
            if endpoint.startswith(path):
                return limits
        
        # Default limits
        return {"max_requests": 100, "window_seconds": 60}
    
    def _cleanup_if_needed(self):
        """Remove old entries to prevent memory leaks."""
        now = time.time()
        
        if now - self.last_cleanup < self.cleanup_interval:
            return
        
        # Remove entries with no recent activity
        active_clients = {}
        for client_id, entry in self.clients.items():
            # Keep if has recent requests or is banned
            if entry.requests or entry.is_banned():
                active_clients[client_id] = entry
        
        self.clients = active_clients
        self.last_cleanup = now
    
    def get_client_status(self, client_id: str) -> Optional[dict]:
        """
        Get rate limit status for a client.
        
        Returns:
            Dictionary with current status or None if not found
        """
        if client_id not in self.clients:
            return None
        
        entry = self.clients[client_id]
        now = time.time()
        
        return {
            "client_id": client_id,
            "requests_in_window": len(entry.requests),
            "max_requests": entry.max_requests,
            "remaining": max(0, entry.max_requests - len(entry.requests)),
            "violations": entry.violations,
            "is_banned": entry.is_banned(),
            "banned_until": entry.banned_until if entry.is_banned() else None,
            "window_seconds": entry.window_seconds,
        }
