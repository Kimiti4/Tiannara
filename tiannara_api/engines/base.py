"""
Base Engine Interface

All domain engines must implement this interface for consistent
processing, health monitoring, and metrics tracking.
"""

from abc import ABC, abstractmethod
from typing import Dict, Any
from datetime import datetime


class BaseEngine(ABC):
    """
    Abstract base class for all Tiannara domain engines.
    
    Provides standard interface for:
    - Request processing
    - Health monitoring
    - Metrics tracking (requests, latency, success rate)
    """
    
    def __init__(self, name: str, version: str = "1.0.0"):
        self.name = name
        self.version = version
        self.created_at = datetime.utcnow()
        self.last_request_at = None
        self.total_requests = 0
        self.total_successes = 0
        self.total_failures = 0
        self.total_latency_ms = 0.0
    
    @abstractmethod
    def process(self, request: Dict[str, Any]) -> Dict[str, Any]:
        """
        Process a request and return results.
        
        Args:
            request: Dictionary containing request parameters
            
        Returns:
            Dictionary containing processing results
            
        Raises:
            Exception: If processing fails
        """
        pass
    
    @abstractmethod
    def get_health(self) -> Dict[str, Any]:
        """
        Get engine health status.
        
        Returns:
            Dictionary with health metrics:
            - status: 'healthy', 'warning', 'error'
            - uptime_percentage: float
            - avg_latency_ms: float
            - success_rate: float
        """
        pass
    
    def track_request(self, latency_ms: float, success: bool):
        """
        Track request metrics for observability.
        
        Args:
            latency_ms: Request processing time in milliseconds
            success: Whether the request succeeded
        """
        self.total_requests += 1
        self.total_latency_ms += latency_ms
        self.last_request_at = datetime.utcnow()
        
        if success:
            self.total_successes += 1
        else:
            self.total_failures += 1
    
    def get_metrics(self) -> Dict[str, Any]:
        """
        Get detailed engine metrics.
        
        Returns:
            Dictionary with comprehensive metrics
        """
        avg_latency = (
            self.total_latency_ms / self.total_requests
            if self.total_requests > 0
            else 0.0
        )
        success_rate = (
            (self.total_successes / self.total_requests * 100)
            if self.total_requests > 0
            else 100.0
        )
        
        return {
            "name": self.name,
            "version": self.version,
            "status": self._determine_status(),
            "total_requests": self.total_requests,
            "avg_latency_ms": round(avg_latency, 2),
            "success_rate": round(success_rate, 2),
            "last_request_at": self.last_request_at.isoformat() if self.last_request_at else None,
        }
    
    def _determine_status(self) -> str:
        """
        Determine engine health status based on metrics.
        
        Returns:
            'healthy', 'warning', or 'error'
        """
        if self.total_requests == 0:
            return "healthy"
        
        success_rate = (self.total_successes / self.total_requests) * 100
        avg_latency = self.total_latency_ms / self.total_requests
        
        if success_rate < 95:
            return "error"
        elif success_rate < 98 or avg_latency > 1000:
            return "warning"
        else:
            return "healthy"
