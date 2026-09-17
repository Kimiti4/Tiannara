# Tiannara API Gateway
"""
Internal API Gateway for Tiannara Core.
Routes requests to domain engines, handles authentication, rate limiting, and observability.
"""

from tiannara_api.gateway.main import app

__all__ = ["app"]
