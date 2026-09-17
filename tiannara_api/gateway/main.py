"""
Tiannara Core API Gateway

Main entry point for the API Gateway.
Handles routing, authentication, rate limiting, and observability.
"""

from __future__ import annotations

import logging
import time
from contextlib import asynccontextmanager

import os

from fastapi import FastAPI, Request, Response, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware

from tiannara_api.gateway.auth import get_api_key, get_jwt_credentials, check_permission, verify_jwt_token
from tiannara_api.middleware.api_key_auth import lookup_user_by_api_key
from tiannara_api.security.cookies import get_token_from_request
from tiannara_api.gateway.routing import register_engine, get_engine, get_all_engines, ROUTE_MAP
from tiannara_api.gateway.rate_limit import RateLimiter
from tiannara_api.gateway.usage_tracker import UsageTracker
from tiannara_api.gateway.orchestrator import GatewayOrchestrator

# Import engines
from tiannara_api.engines.algorithm import AlgorithmEngine
from tiannara_api.engines.logic import LogicEngine
from tiannara_api.engines.nlp import NLPEngine
from tiannara_api.engines.causal import CausalEngine
from tiannara_api.engines.prediction import PredictionEngine

# Import existing routes for backward compatibility
from tiannara_api.routes.autonomous import router as autonomous_router
from tiannara_api.routes.discovery import router as discovery_router
from tiannara_api.routes.evolution import router as evolution_router
from tiannara_api.routes.memory import router as memory_router
from tiannara_api.routes.modules import router as modules_router
from tiannara_api.routes.status import router as status_router
from tiannara_api.routes.autonomy import router as autonomy_router

# Import gateway routes (commented out to avoid circular import - routes are registered in tiannara_api/main.py)
# from tiannara_api.routes.gateway_routes import router as gateway_router
from tiannara_api.routes.unified_endpoints import router as unified_router

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Global instances
rate_limiter = RateLimiter()
usage_tracker = UsageTracker()
orchestrator = GatewayOrchestrator()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup and shutdown events."""
    # Startup: Register all engines
    logger.info("Starting Tiannara Core API Gateway...")
    
    # Initialize and register engines
    algorithm_engine = AlgorithmEngine()
    logic_engine = LogicEngine()
    nlp_engine = NLPEngine()
    causal_engine = CausalEngine()
    prediction_engine = PredictionEngine()
    
    register_engine("algorithm_engine", algorithm_engine)
    register_engine("logic_engine", logic_engine)
    register_engine("nlp_engine", nlp_engine)
    register_engine("causal_engine", causal_engine)
    register_engine("prediction_engine", prediction_engine)
    
    logger.info("All domain engines registered")
    logger.info("Tiannara Core API Gateway ready")
    
    yield
    
    # Shutdown
    logger.info("Shutting down Tiannara Core API Gateway...")


# Create FastAPI app
app = FastAPI(
    title="Tiannara Core API Gateway",
    description="Internal API Gateway for Tiannara Core - AI Infrastructure",
    version="2.0.0-gateway",
    lifespan=lifespan,
)

_gateway_origins = os.getenv(
    "ALLOWED_ORIGINS", "http://localhost:3000,http://127.0.0.1:3000"
).split(",")
app.add_middleware(
    CORSMiddleware,
    allow_origins=[o.strip() for o in _gateway_origins if o.strip()],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type", "X-API-Key"],
)

_GATEWAY_PUBLIC_PREFIXES = (
    "/docs",
    "/openapi.json",
    "/redoc",
    "/status",
    "/health",
    "/api/v1/gateway",
)


def _gateway_is_public(path: str) -> bool:
    if path == "/":
        return True
    return any(path.startswith(prefix) for prefix in _GATEWAY_PUBLIC_PREFIXES)


def _gateway_authenticated(request: Request) -> bool:
    token = get_token_from_request(request)
    if token:
        try:
            verify_jwt_token(token)
            return True
        except Exception:
            pass
    api_key = request.headers.get("X-API-Key")
    return bool(api_key and lookup_user_by_api_key(api_key))


# Request processing middleware
@app.middleware("http")
async def process_request(request: Request, call_next):
    """Middleware to handle authentication, rate limiting, and logging."""
    start_time = time.time()

    if request.method == "OPTIONS":
        return await call_next(request)

    path = request.url.path
    if _gateway_is_public(path):
        return await call_next(request)

    env = os.getenv("ENVIRONMENT", "development").lower()
    api_key = request.headers.get("X-API-Key")

    if env == "production" and not _gateway_authenticated(request):
        raise HTTPException(
            status_code=401,
            detail="Authentication required. Provide Bearer token, session cookie, or X-API-Key.",
        )

    if api_key:
        user = lookup_user_by_api_key(api_key)
        tier = (user or {}).get("tier", "starter")
        allowed, rate_info = rate_limiter.check_rate_limit(api_key, tier=tier)
        if not allowed:
            raise HTTPException(
                status_code=429,
                detail="Rate limit exceeded",
                headers={
                    "X-RateLimit-Limit": str(rate_info["limit"]),
                    "X-RateLimit-Remaining": str(rate_info["remaining"]),
                    "X-RateLimit-Reset": str(rate_info["reset"]),
                },
            )
    
    # Process request
    try:
        response = await call_next(request)
        
        # Log request
        latency_ms = (time.time() - start_time) * 1000
        
        if api_key:
            usage_tracker.log_request(
                api_key=api_key,
                endpoint=request.url.path,
                method=request.method,
                status_code=response.status_code,
                latency_ms=latency_ms,
            )
        
        # Add headers
        response.headers["X-Response-Time"] = f"{latency_ms:.2f}ms"
        
        return response
    
    except Exception as e:
        latency_ms = (time.time() - start_time) * 1000
        logger.error(f"Request failed: {str(e)}")
        raise


# Include gateway routes (commented out to avoid circular import - routes are registered in tiannara_api/main.py)
# app.include_router(gateway_router, prefix="/api/v1")
app.include_router(unified_router, prefix="/api/v1")  # Unified domain endpoints

# Include existing routes for backward compatibility
app.include_router(status_router)
app.include_router(modules_router)
app.include_router(discovery_router)
app.include_router(evolution_router)
app.include_router(autonomous_router)
app.include_router(memory_router)
app.include_router(autonomy_router)


@app.get("/")
async def root():
    """Root endpoint - API information."""
    return {
        "name": "Tiannara Core API Gateway",
        "version": "2.0.0-gateway",
        "status": "operational",
        "documentation": "/docs",
    }


@app.get("/api/v1/gateway/engines/{engine_name}")
async def get_engine_info(engine_name: str):
    """Get information about a specific engine."""
    engines = get_all_engines()
    
    if engine_name not in engines:
        raise HTTPException(status_code=404, detail=f"Engine not found: {engine_name}")
    
    engine = engines[engine_name]
    return {
        "name": engine.name,
        "version": engine.version,
        "health": engine.get_health(),
        "metrics": engine.get_metrics(),
    }
