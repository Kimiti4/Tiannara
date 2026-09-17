"""
Prometheus Metrics for Tiannara API

Provides comprehensive monitoring and observability through Prometheus metrics.

Metrics Collected:
- HTTP request counts (by method, endpoint, status)
- Request latency (histogram)
- Active users gauge
- Error rates
- Database query performance
- Cache hit/miss ratios
- System resources (CPU, memory)

Date: April 30, 2026
Status: 🚀 IMPLEMENTING - Week 24 Day 1
"""

from prometheus_client import Counter, Histogram, Gauge, Summary
from prometheus_client import generate_latest, CONTENT_TYPE_LATEST
from fastapi import FastAPI, Request, Response
from fastapi.responses import PlainTextResponse
import time
import psutil
import os


# ==================== HTTP Metrics ====================

HTTP_REQUEST_COUNT = Counter(
    'http_requests_total',
    'Total HTTP requests received',
    ['method', 'endpoint', 'status']
)

HTTP_REQUEST_LATENCY = Histogram(
    'http_request_duration_seconds',
    'HTTP request latency in seconds',
    ['method', 'endpoint'],
    buckets=[0.001, 0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0, 10.0]
)

HTTP_REQUEST_SIZE = Histogram(
    'http_request_size_bytes',
    'HTTP request size in bytes',
    ['method', 'endpoint'],
    buckets=[100, 1000, 10000, 100000, 1000000]
)

HTTP_RESPONSE_SIZE = Histogram(
    'http_response_size_bytes',
    'HTTP response size in bytes',
    ['method', 'endpoint'],
    buckets=[100, 1000, 10000, 100000, 1000000]
)


# ==================== Authentication Metrics ====================

AUTH_ATTEMPTS = Counter(
    'auth_attempts_total',
    'Total authentication attempts',
    ['type', 'result']  # type: login/signup, result: success/failure
)

ACTIVE_USERS = Gauge(
    'active_users',
    'Number of currently active authenticated users'
)

TOTAL_USERS = Gauge(
    'total_users',
    'Total number of registered users'
)


# ==================== API Usage Metrics ====================

API_CALLS_BY_TIER = Counter(
    'api_calls_by_tier_total',
    'Total API calls grouped by user tier',
    ['tier', 'endpoint']
)

QUOTA_USAGE = Gauge(
    'quota_usage_percentage',
    'User quota usage percentage',
    ['user_id', 'tier']
)


# ==================== Error Metrics ====================

ERROR_COUNT = Counter(
    'errors_total',
    'Total errors encountered',
    ['error_type', 'endpoint']
)

EXCEPTION_COUNT = Counter(
    'exceptions_total',
    'Total exceptions raised',
    ['exception_type']
)


# ==================== Database Metrics ====================

DB_QUERY_LATENCY = Histogram(
    'database_query_duration_seconds',
    'Database query latency in seconds',
    ['operation']  # select, insert, update, delete
)

DB_CONNECTION_POOL_SIZE = Gauge(
    'database_connection_pool_size',
    'Current database connection pool size'
)

DB_ACTIVE_CONNECTIONS = Gauge(
    'database_active_connections',
    'Number of active database connections'
)


# ==================== Cache Metrics ====================

CACHE_HITS = Counter(
    'cache_hits_total',
    'Total cache hits',
    ['cache_name']
)

CACHE_MISSES = Counter(
    'cache_misses_total',
    'Total cache misses',
    ['cache_name']
)

CACHE_HIT_RATIO = Gauge(
    'cache_hit_ratio',
    'Cache hit ratio (hits / total)',
    ['cache_name']
)


# ==================== System Metrics ====================

CPU_USAGE = Gauge(
    'system_cpu_usage_percent',
    'System CPU usage percentage'
)

MEMORY_USAGE = Gauge(
    'system_memory_usage_bytes',
    'System memory usage in bytes',
    ['type']  # used, available, total
)

DISK_USAGE = Gauge(
    'system_disk_usage_bytes',
    'System disk usage in bytes',
    ['type']  # used, free, total
)

PROCESS_UPTIME = Gauge(
    'process_uptime_seconds',
    'Process uptime in seconds'
)


# ==================== Business Metrics ====================

PREDICTIONS_TOTAL = Counter(
    'predictions_total',
    'Total predictions made',
    ['domain', 'success']
)

PREDICTION_CONFIDENCE = Histogram(
    'prediction_confidence',
    'Prediction confidence scores',
    ['domain'],
    buckets=[0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 0.95, 0.99, 1.0]
)

ENGINES_RUNNING = Gauge(
    'engines_running',
    'Number of domain engines currently running',
    ['engine_type']
)


# ==================== Middleware ====================

class MetricsMiddleware:
    """
    FastAPI middleware to automatically collect metrics for all requests.
    
    Usage:
        app.add_middleware(MetricsMiddleware)
    """
    
    def __init__(self, app: FastAPI):
        self.app = app
    
    async def __call__(self, scope, receive, send):
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return
        
        request = Request(scope, receive)
        start_time = time.time()
        
        # Track request
        method = request.method
        path = request.url.path
        
        # Call the actual application
        response_body = []
        async def send_wrapper(message):
            if message["type"] == "http.response.start":
                # Extract status code
                status_code = message.get("status", 500)
                
                # Calculate latency
                duration = time.time() - start_time
                
                # Record metrics
                HTTP_REQUEST_COUNT.labels(
                    method=method,
                    endpoint=path,
                    status=str(status_code)
                ).inc()
                
                HTTP_REQUEST_LATENCY.labels(
                    method=method,
                    endpoint=path
                ).observe(duration)
                
                # Track errors
                if status_code >= 400:
                    error_type = "client_error" if status_code < 500 else "server_error"
                    ERROR_COUNT.labels(
                        error_type=error_type,
                        endpoint=path
                    ).inc()
            
            elif message["type"] == "http.response.body":
                body = message.get("body", b"")
                response_body.append(body)
                
                # Track response size
                HTTP_RESPONSE_SIZE.labels(
                    method=method,
                    endpoint=path
                ).observe(len(body))
            
            await send(message)
        
        try:
            await self.app(scope, receive, send_wrapper)
        except Exception as e:
            # Track unexpected exceptions
            EXCEPTION_COUNT.labels(
                exception_type=type(e).__name__
            ).inc()
            raise


# ==================== Metrics Endpoint ====================

def create_metrics_endpoint(app: FastAPI):
    """
    Create /metrics endpoint for Prometheus scraping.
    
    Args:
        app: FastAPI application instance
    """
    
    @app.get("/metrics")
    async def metrics():
        """
        Prometheus metrics endpoint.
        
        Returns all collected metrics in Prometheus exposition format.
        """
        # Update system metrics
        _update_system_metrics()
        
        # Generate metrics
        metrics_data = generate_latest()
        
        return PlainTextResponse(
            content=metrics_data.decode('utf-8'),
            media_type=CONTENT_TYPE_LATEST
        )


# ==================== Helper Functions ====================

def _update_system_metrics():
    """Update system-level metrics."""
    try:
        # CPU usage
        cpu_percent = psutil.cpu_percent(interval=None)
        CPU_USAGE.set(cpu_percent)
        
        # Memory usage
        memory = psutil.virtual_memory()
        MEMORY_USAGE.labels(type='used').set(memory.used)
        MEMORY_USAGE.labels(type='available').set(memory.available)
        MEMORY_USAGE.labels(type='total').set(memory.total)
        
        # Disk usage
        disk = psutil.disk_usage('/')
        DISK_USAGE.labels(type='used').set(disk.used)
        DISK_USAGE.labels(type='free').set(disk.free)
        DISK_USAGE.labels(type='total').set(disk.total)
        
    except Exception as e:
        # Don't let metric collection failures break the app
        pass


def track_auth_attempt(auth_type: str, success: bool):
    """
    Track authentication attempt.
    
    Args:
        auth_type: Type of auth (login, signup, token_refresh)
        success: Whether authentication succeeded
    """
    result = "success" if success else "failure"
    AUTH_ATTEMPTS.labels(type=auth_type, result=result).inc()


def track_api_call(tier: str, endpoint: str):
    """
    Track API call by user tier.
    
    Args:
        tier: User tier (starter, professional, enterprise)
        endpoint: API endpoint called
    """
    API_CALLS_BY_TIER.labels(tier=tier, endpoint=endpoint).inc()


def track_prediction(domain: str, success: bool, confidence: float):
    """
    Track prediction made by domain engine.
    
    Args:
        domain: Prediction domain (algorithm, logic, causal, etc.)
        success: Whether prediction was successful
        confidence: Confidence score (0.0 - 1.0)
    """
    PREDICTIONS_TOTAL.labels(domain=domain, success=str(success)).inc()
    PREDICTION_CONFIDENCE.labels(domain=domain).observe(confidence)


def track_cache_access(cache_name: str, hit: bool):
    """
    Track cache access.
    
    Args:
        cache_name: Name of cache (user_sessions, api_responses, etc.)
        hit: Whether it was a cache hit or miss
    """
    if hit:
        CACHE_HITS.labels(cache_name=cache_name).inc()
    else:
        CACHE_MISSES.labels(cache_name=cache_name).inc()
    
    # Update hit ratio
    hits = CACHE_HITS.labels(cache_name=cache_name)._value.get()
    misses = CACHE_MISSES.labels(cache_name=cache_name)._value.get()
    total = hits + misses
    if total > 0:
        CACHE_HIT_RATIO.labels(cache_name=cache_name).set(hits / total)


def increment_engine(engine_type: str):
    """Increment running engine counter."""
    ENGINES_RUNNING.labels(engine_type=engine_type).inc()


def decrement_engine(engine_type: str):
    """Decrement running engine counter."""
    ENGINES_RUNNING.labels(engine_type=engine_type).dec()


# ==================== Initialization ====================

def init_metrics(app: FastAPI):
    """
    Initialize metrics collection for FastAPI application.
    
    This should be called during app startup.
    
    Args:
        app: FastAPI application instance
    """
    # Add middleware for automatic request tracking
    app.add_middleware(MetricsMiddleware)
    
    # Create /metrics endpoint
    create_metrics_endpoint(app)
    
    # Set process start time
    PROCESS_UPTIME.set(time.time())
    
    print("✅ Prometheus metrics initialized")
