"""
Rate Limiting Middleware for Tiannara API

Protects against abuse by limiting request frequency per IP/user.
Uses sliding window algorithm for accurate rate tracking.
"""

import time
import logging
from typing import Dict, List, Optional
from fastapi import Request, HTTPException
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import JSONResponse

logger = logging.getLogger(__name__)


class RateLimiter:
    """
    In-memory rate limiter using sliding window algorithm.
    
    For production, replace with Redis-based implementation.
    """
    
    def __init__(self):
        # Store: {identifier: [(timestamp, count), ...]}
        self.request_log: Dict[str, List[float]] = {}
        
        # Default limits
        self.default_limit = 100  # requests
        self.default_window = 60  # seconds
        
        # Endpoint-specific limits
        self.endpoint_limits = {
            "/auth/request-otp": {"limit": 3, "window": 300},  # 3 per 5 min
            "/auth/verify-otp": {"limit": 10, "window": 300},  # 10 per 5 min
            "/auth/signup": {"limit": 5, "window": 3600},  # 5 per hour
            "/auth/login": {"limit": 10, "window": 300},  # 10 per 5 min
        }
    
    def is_rate_limited(self, identifier: str, endpoint: str) -> bool:
        """
        Check if request should be rate limited.
        
        Args:
            identifier: Client identifier (IP or user ID)
            endpoint: API endpoint path
            
        Returns:
            True if rate limit exceeded, False otherwise
        """
        now = time.time()
        
        # Get endpoint-specific limits
        limits = self.endpoint_limits.get(endpoint, {
            "limit": self.default_limit,
            "window": self.default_window
        })
        
        limit = limits["limit"]
        window = limits["window"]
        
        # Initialize log if not exists
        if identifier not in self.request_log:
            self.request_log[identifier] = []
        
        # Remove old entries outside window
        self.request_log[identifier] = [
            timestamp for timestamp in self.request_log[identifier]
            if now - timestamp < window
        ]
        
        # Check if limit exceeded
        if len(self.request_log[identifier]) >= limit:
            return True
        
        # Record this request
        self.request_log[identifier].append(now)
        return False
    
    def get_remaining_requests(self, identifier: str, endpoint: str) -> int:
        """Get remaining requests in current window."""
        now = time.time()
        
        limits = self.endpoint_limits.get(endpoint, {
            "limit": self.default_limit,
            "window": self.default_window
        })
        
        limit = limits["limit"]
        window = limits["window"]
        
        if identifier not in self.request_log:
            return limit
        
        # Count recent requests
        recent_count = len([
            timestamp for timestamp in self.request_log[identifier]
            if now - timestamp < window
        ])
        
        return max(0, limit - recent_count)
    
    def cleanup_old_entries(self):
        """Remove expired entries to prevent memory leaks."""
        now = time.time()
        max_age = 3600  # Keep entries for 1 hour max
        
        expired_keys = []
        for identifier, timestamps in self.request_log.items():
            self.request_log[identifier] = [
                ts for ts in timestamps if now - ts < max_age
            ]
            if not self.request_log[identifier]:
                expired_keys.append(identifier)
        
        for key in expired_keys:
            del self.request_log[key]
        
        if expired_keys:
            logger.debug(f"Cleaned up {len(expired_keys)} expired rate limit entries")


# Global rate limiter instance
rate_limiter = RateLimiter()


class RateLimitMiddleware(BaseHTTPMiddleware):
    """
    FastAPI middleware for rate limiting.
    
    Applies rate limits based on client IP address.
    Returns 429 Too Many Requests when limit exceeded.
    """
    
    async def dispatch(self, request: Request, call_next):
        # Get client identifier (IP address)
        client_ip = request.client.host if request.client else "unknown"
        
        # Get endpoint path
        endpoint = request.url.path
        
        # Skip rate limiting for certain paths
        skip_paths = ["/docs", "/openapi.json", "/health"]
        if any(endpoint.startswith(path) for path in skip_paths):
            return await call_next(request)
        
        # Check rate limit
        if rate_limiter.is_rate_limited(client_ip, endpoint):
            remaining = rate_limiter.get_remaining_requests(client_ip, endpoint)
            
            logger.warning(f"Rate limit exceeded for {client_ip} on {endpoint}")
            
            return JSONResponse(
                status_code=429,
                content={
                    "success": False,
                    "error": "Too many requests. Please try again later.",
                    "detail": f"Rate limit exceeded. Try again in a few minutes."
                },
                headers={
                    "X-RateLimit-Limit": str(rate_limiter.endpoint_limits.get(endpoint, {}).get("limit", rate_limiter.default_limit)),
                    "X-RateLimit-Remaining": str(remaining),
                    "Retry-After": "60"
                }
            )
        
        # Process request
        response = await call_next(request)
        
        # Add rate limit headers to response
        remaining = rate_limiter.get_remaining_requests(client_ip, endpoint)
        response.headers["X-RateLimit-Remaining"] = str(remaining)
        
        return response


def get_rate_limiter() -> RateLimiter:
    """Get global rate limiter instance."""
    return rate_limiter
