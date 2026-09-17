"""
Request/Response Logging Middleware

Logs every API request and response for observability.
Tracks latency, status codes, and errors.
"""

import time
import logging
from typing import Callable
from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware

logger = logging.getLogger(__name__)


class LoggingMiddleware(BaseHTTPMiddleware):
    """Middleware to log all HTTP requests and responses."""
    
    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        """Process request and log details."""
        start_time = time.time()
        
        # Log request
        logger.info(
            f"Request: {request.method} {request.url.path} "
            f"from {request.client.host if request.client else 'unknown'}"
        )
        
        # Process request
        try:
            response = await call_next(request)
            
            # Calculate latency
            latency_ms = (time.time() - start_time) * 1000
            
            # Log response
            logger.info(
                f"Response: {request.method} {request.url.path} "
                f"status={response.status_code} "
                f"latency={latency_ms:.2f}ms"
            )
            
            # Add latency header
            response.headers["X-Response-Time"] = f"{latency_ms:.2f}ms"
            
            return response
        
        except Exception as e:
            latency_ms = (time.time() - start_time) * 1000
            logger.error(
                f"Error: {request.method} {request.url.path} "
                f"error={str(e)} "
                f"latency={latency_ms:.2f}ms"
            )
            raise
