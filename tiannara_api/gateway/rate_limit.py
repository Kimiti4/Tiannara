"""
Rate Limiting

Redis-based rate limiting with tier-based quotas.
Implements sliding window algorithm for accurate request counting.
"""

import time
import logging
from typing import Optional

try:
    import redis
    REDIS_AVAILABLE = True
except ImportError:
    REDIS_AVAILABLE = False

logger = logging.getLogger(__name__)

# Tier-based rate limits (requests per hour)
RATE_LIMITS = {
    "starter": 5000,
    "pro": 50000,
    "enterprise": -1,  # Unlimited
}


class RateLimiter:
    """
    Redis-based rate limiter using sliding window algorithm.
    
    Fallback to in-memory limiting if Redis is not available.
    """
    
    def __init__(self, redis_url: Optional[str] = None):
        self.redis_client = None
        self.in_memory_store = {}  # Fallback: {api_key: [(timestamp, count)]}
        
        if redis_url and REDIS_AVAILABLE:
            try:
                self.redis_client = redis.from_url(redis_url, decode_responses=True)
                self.redis_client.ping()
                logger.info("Redis rate limiter initialized")
            except Exception as e:
                logger.warning(f"Redis connection failed, using in-memory rate limiter: {str(e)}")
        else:
            logger.info("Using in-memory rate limiter (Redis not available)")
    
    def check_rate_limit(self, api_key: str, tier: str = "starter") -> tuple[bool, dict]:
        """
        Check if request is within rate limit.
        
        Args:
            api_key: User's API key
            tier: User's subscription tier
            
        Returns:
            (allowed: bool, info: dict with rate limit details)
        """
        limit = RATE_LIMITS.get(tier, RATE_LIMITS["starter"])
        
        # Enterprise has unlimited requests
        if limit == -1:
            return True, {"limit": -1, "remaining": -1, "reset": None}
        
        if self.redis_client:
            return self._check_redis(api_key, limit)
        else:
            return self._check_in_memory(api_key, limit)
    
    def _check_redis(self, api_key: str, limit: int) -> tuple[bool, dict]:
        """Check rate limit using Redis."""
        try:
            current_time = time.time()
            window_size = 3600  # 1 hour in seconds
            window_key = f"rate_limit:{api_key}"
            
            # Remove old entries outside the window
            self.redis_client.zremrangebyscore(window_key, 0, current_time - window_size)
            
            # Count requests in current window
            current_count = self.redis_client.zcard(window_key)
            
            if current_count >= limit:
                # Rate limit exceeded
                oldest_entry = self.redis_client.zrange(window_key, 0, 0, withscores=True)
                reset_time = int(oldest_entry[0][1] + window_size) if oldest_entry else int(current_time + window_size)
                
                return False, {
                    "limit": limit,
                    "remaining": 0,
                    "reset": reset_time,
                    "current": current_count,
                }
            
            # Add current request
            self.redis_client.zadd(window_key, {f"{current_time}": current_time})
            
            return True, {
                "limit": limit,
                "remaining": limit - current_count - 1,
                "reset": int(current_time + window_size),
                "current": current_count + 1,
            }
        
        except Exception as e:
            logger.error(f"Redis rate limit check failed: {str(e)}")
            # Fallback to allow request
            return True, {"limit": limit, "remaining": limit, "reset": None}
    
    def _check_in_memory(self, api_key: str, limit: int) -> tuple[bool, dict]:
        """Check rate limit using in-memory store (fallback)."""
        current_time = time.time()
        window_size = 3600  # 1 hour
        
        # Initialize or clean old entries
        if api_key not in self.in_memory_store:
            self.in_memory_store[api_key] = []
        
        # Remove old entries
        self.in_memory_store[api_key] = [
            ts for ts in self.in_memory_store[api_key]
            if ts > current_time - window_size
        ]
        
        current_count = len(self.in_memory_store[api_key])
        
        if current_count >= limit:
            return False, {
                "limit": limit,
                "remaining": 0,
                "reset": int(current_time + window_size),
                "current": current_count,
            }
        
        # Add current request
        self.in_memory_store[api_key].append(current_time)
        
        return True, {
            "limit": limit,
            "remaining": limit - current_count - 1,
            "reset": int(current_time + window_size),
            "current": current_count + 1,
        }
    
    def reset_limit(self, api_key: str):
        """Reset rate limit for a specific API key."""
        if self.redis_client:
            self.redis_client.delete(f"rate_limit:{api_key}")
        else:
            self.in_memory_store.pop(api_key, None)
        
        logger.info(f"Rate limit reset for: {api_key}")


# Global rate limiter instance
rate_limiter = RateLimiter()
