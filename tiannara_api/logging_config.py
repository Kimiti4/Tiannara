"""
Structured Logging Configuration for Tiannara API

Provides JSON-formatted logs with correlation IDs for distributed tracing.

Features:
- Structured JSON logging
- Request correlation IDs
- Log level configuration
- File rotation
- Console and file handlers
- Performance timing

Date: April 30, 2026
Status: Week 24 Day 4 - Logging Infrastructure
"""

import logging
import sys
import os
import json
import uuid
from datetime import datetime, timezone
from typing import Optional
from logging.handlers import RotatingFileHandler


class JSONFormatter(logging.Formatter):
    """
    Custom JSON formatter for structured logging.
    
    Outputs logs in JSON format for easy parsing by log aggregation tools.
    """
    
    def __init__(self, include_extra_fields: bool = True):
        super().__init__()
        self.include_extra_fields = include_extra_fields
    
    def format(self, record: logging.LogRecord) -> str:
        """Format log record as JSON."""
        
        # Base log structure
        log_data = {
            "timestamp": datetime.fromtimestamp(record.created, tz=timezone.utc).isoformat(),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "module": record.module,
            "function": record.funcName,
            "line": record.lineno,
        }
        
        # Add exception info if present
        if record.exc_info and record.exc_info[1]:
            log_data["exception"] = {
                "type": record.exc_info[0].__name__,
                "message": str(record.exc_info[1]),
                "traceback": self.formatException(record.exc_info) if record.exc_info else None
            }
        
        # Add correlation ID if available
        correlation_id = getattr(record, 'correlation_id', None)
        if correlation_id:
            log_data["correlation_id"] = correlation_id
        
        # Add request info if available
        request_method = getattr(record, 'request_method', None)
        request_path = getattr(record, 'request_path', None)
        if request_method and request_path:
            log_data["request"] = {
                "method": request_method,
                "path": request_path
            }
        
        # Add performance timing if available
        duration = getattr(record, 'duration', None)
        if duration is not None:
            log_data["duration_ms"] = duration
        
        # Add any extra fields
        if self.include_extra_fields:
            for key, value in record.__dict__.items():
                if key not in [
                    'name', 'msg', 'args', 'created', 'levelname', 'levelno',
                    'pathname', 'filename', 'module', 'exc_info', 'exc_text',
                    'stack_info', 'lineno', 'funcName', 'thread', 'threadName',
                    'processName', 'process', 'getMessage', 'correlation_id',
                    'request_method', 'request_path', 'duration'
                ]:
                    if not key.startswith('_'):
                        log_data[key] = value
        
        return json.dumps(log_data, default=str)


class CorrelationIDFilter(logging.Filter):
    """
    Logging filter that adds correlation ID to all log records.
    
    Correlation IDs are used to trace requests across multiple services.
    """
    
    def __init__(self, correlation_id: Optional[str] = None):
        super().__init__()
        self.correlation_id = correlation_id or str(uuid.uuid4())
    
    def filter(self, record: logging.LogRecord) -> bool:
        """Add correlation ID to log record."""
        record.correlation_id = self.correlation_id
        return True


def get_correlation_id() -> str:
    """Generate a new correlation ID."""
    return str(uuid.uuid4())


def setup_logging(
    level: str = "INFO",
    log_file: Optional[str] = None,
    max_bytes: int = 10 * 1024 * 1024,  # 10 MB
    backup_count: int = 5,
    include_extra_fields: bool = True
) -> logging.Logger:
    """
    Configure application-wide logging.
    
    Args:
        level: Logging level (DEBUG, INFO, WARNING, ERROR, CRITICAL)
        log_file: Path to log file (None for console only)
        max_bytes: Maximum size of log file before rotation
        backup_count: Number of backup log files to keep
        include_extra_fields: Include extra fields in JSON output
    
    Returns:
        Configured logger instance
    """
    
    # Create root logger
    logger = logging.getLogger("tiannara")
    logger.setLevel(getattr(logging, level.upper()))
    
    # Remove existing handlers
    logger.handlers.clear()
    
    # Create JSON formatter
    json_formatter = JSONFormatter(include_extra_fields=include_extra_fields)
    
    # Console handler
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setLevel(level)
    console_handler.setFormatter(json_formatter)
    logger.addHandler(console_handler)
    
    # File handler (if log_file specified)
    if log_file:
        # Ensure log directory exists
        log_dir = os.path.dirname(log_file)
        if log_dir and not os.path.exists(log_dir):
            os.makedirs(log_dir, exist_ok=True)
        
        file_handler = RotatingFileHandler(
            log_file,
            maxBytes=max_bytes,
            backupCount=backup_count
        )
        file_handler.setLevel(level)
        file_handler.setFormatter(json_formatter)
        logger.addHandler(file_handler)
    
    # Prevent log propagation to root logger
    logger.propagate = False
    
    return logger


def get_logger(name: str, correlation_id: Optional[str] = None) -> logging.Logger:
    """
    Get a logger with optional correlation ID.
    
    Args:
        name: Logger name (usually __name__)
        correlation_id: Optional correlation ID for request tracing
    
    Returns:
        Configured logger instance
    """
    logger = logging.getLogger(f"tiannara.{name}")
    
    # Add correlation ID filter if provided
    if correlation_id:
        correlation_filter = CorrelationIDFilter(correlation_id)
        logger.addFilter(correlation_filter)
    
    return logger


# ==================== Middleware for FastAPI ====================

class LoggingMiddleware:
    """
    FastAPI middleware for request logging with correlation IDs.
    
    Automatically logs all HTTP requests with timing and correlation IDs.
    
    Usage:
        app.add_middleware(LoggingMiddleware)
    """
    
    def __init__(self, app):
        self.app = app
        self.logger = logging.getLogger("tiannara.api")
    
    async def __call__(self, scope, receive, send):
        """Process request and log details."""
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return
        
        import time
        from fastapi import Request
        
        request = Request(scope, receive)
        
        # Generate correlation ID for this request
        correlation_id = get_correlation_id()
        
        # Add correlation ID to response headers
        async def send_with_correlation(message):
            if message["type"] == "http.response.start":
                headers = message.get("headers", [])
                headers.append((b"x-correlation-id", correlation_id.encode()))
                message["headers"] = headers
            await send(message)
        
        # Log request start
        start_time = time.time()
        self.logger.info(
            f"Request started: {request.method} {request.url.path}",
            extra={
                'correlation_id': correlation_id,
                'request_method': request.method,
                'request_path': str(request.url.path)
            }
        )
        
        try:
            # Process request
            await self.app(scope, receive, send_with_correlation)
            
            # Log request completion
            duration = (time.time() - start_time) * 1000  # Convert to ms
            self.logger.info(
                f"Request completed: {request.method} {request.url.path}",
                extra={
                    'correlation_id': correlation_id,
                    'request_method': request.method,
                    'request_path': str(request.url.path),
                    'duration': round(duration, 2)
                }
            )
        
        except Exception as e:
            # Log error
            duration = (time.time() - start_time) * 1000
            self.logger.error(
                f"Request failed: {request.method} {request.url.path} - {str(e)}",
                exc_info=True,
                extra={
                    'correlation_id': correlation_id,
                    'request_method': request.method,
                    'request_path': str(request.url.path),
                    'duration': round(duration, 2)
                }
            )
            raise


# ==================== Utility Functions ====================

def log_request(logger: logging.Logger, method: str, path: str, correlation_id: str, status_code: int, duration_ms: float):
    """
    Helper function to log HTTP requests.
    
    Args:
        logger: Logger instance
        method: HTTP method
        path: Request path
        correlation_id: Request correlation ID
        status_code: HTTP status code
        duration_ms: Request duration in milliseconds
    """
    logger.info(
        f"{method} {path} - {status_code}",
        extra={
            'correlation_id': correlation_id,
            'request_method': method,
            'request_path': path,
            'status_code': status_code,
            'duration': duration_ms
        }
    )


def log_error(logger: logging.Logger, message: str, correlation_id: str, exception: Optional[Exception] = None):
    """
    Helper function to log errors with context.
    
    Args:
        logger: Logger instance
        message: Error message
        correlation_id: Request correlation ID
        exception: Optional exception object
    """
    logger.error(
        message,
        exc_info=exception,
        extra={
            'correlation_id': correlation_id
        }
    )


# ==================== Initialize Default Logger ====================

# Create default logger on module import
default_logger = setup_logging(
    level=os.getenv("LOG_LEVEL", "INFO"),
    log_file=os.getenv("LOG_FILE", "logs/tiannara.log")
)
