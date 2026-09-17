"""
Usage Tracker

Tracks API usage, metrics, and stores data for observability and billing.
Supports both PostgreSQL (production) and SQLite (development).
"""

import time
import logging
from typing import Dict, Any, Optional
from datetime import datetime

logger = logging.getLogger(__name__)


class UsageTracker:
    """
    Tracks API usage for observability, analytics, and billing.
    
    Records:
    - API calls per user/key
    - Processing time metrics
    - Feature usage statistics
    - Quota consumption
    - Error rates
    """
    
    def __init__(self, db_url: Optional[str] = None):
        self.db_url = db_url
        self.usage_data = {}  # In-memory storage: {api_key: {metrics}}
        self.request_logs = []  # Recent request logs
        self.max_logs = 1000  # Keep last 1000 logs in memory
        
        logger.info("Usage Tracker initialized")
    
    def log_request(
        self,
        api_key: str,
        endpoint: str,
        method: str,
        status_code: int,
        latency_ms: float,
        engine_used: Optional[str] = None,
        error_message: Optional[str] = None,
    ):
        """
        Log a single API request.
        
        Args:
            api_key: User's API key
            endpoint: API endpoint called
            method: HTTP method (GET, POST, etc.)
            status_code: Response status code
            latency_ms: Request processing time
            engine_used: Which domain engine handled the request
            error_message: Error message if request failed
        """
        log_entry = {
            "api_key": api_key,
            "endpoint": endpoint,
            "method": method,
            "status_code": status_code,
            "latency_ms": latency_ms,
            "engine_used": engine_used,
            "error_message": error_message,
            "timestamp": datetime.utcnow().isoformat(),
        }
        
        # Store in memory
        self.request_logs.append(log_entry)
        
        # Keep only recent logs
        if len(self.request_logs) > self.max_logs:
            self.request_logs = self.request_logs[-self.max_logs:]
        
        # Update usage metrics
        self._update_usage_metrics(api_key, status_code, latency_ms)
        
        # TODO: Store in PostgreSQL for persistence
        # self._store_in_database(log_entry)
    
    def _update_usage_metrics(self, api_key: str, status_code: int, latency_ms: float):
        """Update aggregated usage metrics for an API key."""
        if api_key not in self.usage_data:
            self.usage_data[api_key] = {
                "total_requests": 0,
                "successful_requests": 0,
                "failed_requests": 0,
                "total_latency_ms": 0.0,
                "last_request_at": None,
            }
        
        metrics = self.usage_data[api_key]
        metrics["total_requests"] += 1
        metrics["total_latency_ms"] += latency_ms
        metrics["last_request_at"] = datetime.utcnow().isoformat()
        
        if 200 <= status_code < 400:
            metrics["successful_requests"] += 1
        else:
            metrics["failed_requests"] += 1
    
    def get_usage_metrics(self, api_key: str) -> Dict[str, Any]:
        """
        Get usage metrics for a specific API key.
        
        Returns:
            Dictionary with usage statistics
        """
        if api_key not in self.usage_data:
            return {
                "total_requests": 0,
                "successful_requests": 0,
                "failed_requests": 0,
                "avg_latency_ms": 0.0,
                "error_rate": 0.0,
            }
        
        metrics = self.usage_data[api_key]
        total = metrics["total_requests"]
        
        return {
            "total_requests": total,
            "successful_requests": metrics["successful_requests"],
            "failed_requests": metrics["failed_requests"],
            "avg_latency_ms": metrics["total_latency_ms"] / total if total > 0 else 0.0,
            "error_rate": (metrics["failed_requests"] / total * 100) if total > 0 else 0.0,
            "last_request_at": metrics["last_request_at"],
        }
    
    def get_recent_logs(self, limit: int = 50) -> list:
        """Get recent request logs."""
        return self.request_logs[-limit:]
    
    def get_global_metrics(self) -> Dict[str, Any]:
        """
        Get global system metrics across all API keys.
        
        Returns:
            Aggregated metrics for the entire system
        """
        total_requests = 0
        total_success = 0
        total_failed = 0
        total_latency = 0.0
        
        for metrics in self.usage_data.values():
            total_requests += metrics["total_requests"]
            total_success += metrics["successful_requests"]
            total_failed += metrics["failed_requests"]
            total_latency += metrics["total_latency_ms"]
        
        return {
            "total_requests": total_requests,
            "total_success": total_success,
            "total_failed": total_failed,
            "avg_latency_ms": total_latency / total_requests if total_requests > 0 else 0.0,
            "global_error_rate": (total_failed / total_requests * 100) if total_requests > 0 else 0.0,
            "unique_api_keys": len(self.usage_data),
        }
    
    def reset_usage(self, api_key: str):
        """Reset usage metrics for a specific API key."""
        if api_key in self.usage_data:
            del self.usage_data[api_key]
            logger.info(f"Usage reset for: {api_key}")


# Create global instance
usage_tracker = UsageTracker()
