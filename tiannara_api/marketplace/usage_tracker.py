"""
Usage Tracker - API usage tracking and analytics

Tracks API call volumes, response times, error rates,
and provides detailed usage analytics per subscription.
"""

import logging
from typing import Dict, List, Optional, Any
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from collections import defaultdict

logger = logging.getLogger(__name__)


@dataclass
class UsageRecord:
    """API usage record."""
    record_id: str
    subscription_id: str
    timestamp: datetime
    endpoint: str
    method: str
    response_time_ms: float
    status_code: int
    request_size_bytes: int = 0
    response_size_bytes: int = 0


class UsageTracker:
    """API usage tracking and analytics system.
    
    Features:
    - Per-subscription usage tracking
    - Endpoint-level analytics
    - Response time monitoring
    - Error rate calculation
    - Usage pattern analysis
    """
    
    def __init__(self):
        self.records: Dict[str, List[UsageRecord]] = defaultdict(list)
        self.daily_usage: Dict[str, Dict[str, int]] = defaultdict(lambda: defaultdict(int))
        
    def track_request(
        self,
        subscription_id: str,
        endpoint: str,
        method: str,
        response_time_ms: float,
        status_code: int,
        request_size_bytes: int = 0,
        response_size_bytes: int = 0
    ) -> UsageRecord:
        """Track an API request.
        
        Args:
            subscription_id: Subscription identifier
            endpoint: API endpoint
            method: HTTP method
            response_time_ms: Response time in milliseconds
            status_code: HTTP status code
            request_size_bytes: Request payload size
            response_size_bytes: Response payload size
            
        Returns:
            Created usage record
        """
        import secrets
        record_id = f"usage_{secrets.token_hex(8)}"
        
        record = UsageRecord(
            record_id=record_id,
            subscription_id=subscription_id,
            timestamp=datetime.now(),
            endpoint=endpoint,
            method=method,
            response_time_ms=response_time_ms,
            status_code=status_code,
            request_size_bytes=request_size_bytes,
            response_size_bytes=response_size_bytes
        )
        
        self.records[subscription_id].append(record)
        
        # Track daily usage
        day_key = datetime.now().strftime('%Y-%m-%d')
        self.daily_usage[subscription_id][day_key] += 1
        
        logger.debug(f"Usage tracked: {subscription_id} - {endpoint}")
        return record
    
    def get_usage_summary(
        self,
        subscription_id: str,
        days: int = 30
    ) -> Dict[str, Any]:
        """Get usage summary for a subscription.
        
        Args:
            subscription_id: Subscription identifier
            days: Number of days to summarize
            
        Returns:
            Usage summary dictionary
        """
        cutoff = datetime.now() - timedelta(days=days)
        recent_records = [
            r for r in self.records.get(subscription_id, [])
            if r.timestamp >= cutoff
        ]
        
        if not recent_records:
            return {'total_requests': 0}
        
        total_requests = len(recent_records)
        avg_response_time = sum(r.response_time_ms for r in recent_records) / total_requests
        
        # Calculate error rate
        errors = sum(1 for r in recent_records if r.status_code >= 400)
        error_rate = errors / total_requests * 100
        
        # Top endpoints
        endpoint_counts = defaultdict(int)
        for r in recent_records:
            endpoint_counts[r.endpoint] += 1
        
        top_endpoints = sorted(
            endpoint_counts.items(),
            key=lambda x: x[1],
            reverse=True
        )[:10]
        
        return {
            'subscription_id': subscription_id,
            'period_days': days,
            'total_requests': total_requests,
            'avg_response_time_ms': round(avg_response_time, 2),
            'error_rate_percent': round(error_rate, 2),
            'total_errors': errors,
            'top_endpoints': [
                {'endpoint': ep, 'count': count}
                for ep, count in top_endpoints
            ],
            'daily_average': total_requests / days
        }
    
    def get_endpoint_analytics(
        self,
        subscription_id: str,
        endpoint: str,
        days: int = 7
    ) -> Dict[str, Any]:
        """Get analytics for a specific endpoint.
        
        Args:
            subscription_id: Subscription identifier
            endpoint: API endpoint
            days: Analysis period
            
        Returns:
            Endpoint analytics
        """
        cutoff = datetime.now() - timedelta(days=days)
        endpoint_records = [
            r for r in self.records.get(subscription_id, [])
            if r.endpoint == endpoint and r.timestamp >= cutoff
        ]
        
        if not endpoint_records:
            return {'endpoint': endpoint, 'total_requests': 0}
        
        response_times = [r.response_time_ms for r in endpoint_records]
        sorted_times = sorted(response_times)
        
        return {
            'endpoint': endpoint,
            'total_requests': len(endpoint_records),
            'avg_response_time_ms': sum(response_times) / len(response_times),
            'p50_response_time_ms': sorted_times[len(sorted_times) // 2],
            'p95_response_time_ms': sorted_times[int(len(sorted_times) * 0.95)],
            'p99_response_time_ms': sorted_times[int(len(sorted_times) * 0.99)],
            'max_response_time_ms': max(response_times),
            'min_response_time_ms': min(response_times),
            'error_count': sum(1 for r in endpoint_records if r.status_code >= 400)
        }
    
    def detect_anomalies(self, subscription_id: str, window_hours: int = 1) -> List[Dict[str, Any]]:
        """Detect usage anomalies.
        
        Args:
            subscription_id: Subscription identifier
            window_hours: Detection window
            
        Returns:
            List of detected anomalies
        """
        cutoff = datetime.now() - timedelta(hours=window_hours)
        recent = [
            r for r in self.records.get(subscription_id, [])
            if r.timestamp >= cutoff
        ]
        
        anomalies = []
        
        # Check for high error rate
        if recent:
            error_rate = sum(1 for r in recent if r.status_code >= 500) / len(recent)
            if error_rate > 0.1:  # More than 10% errors
                anomalies.append({
                    'type': 'high_error_rate',
                    'severity': 'critical' if error_rate > 0.5 else 'warning',
                    'value': error_rate,
                    'message': f'Error rate {error_rate*100:.1f}% exceeds threshold'
                })
        
        # Check for slow responses
        if recent:
            avg_response = sum(r.response_time_ms for r in recent) / len(recent)
            if avg_response > 1000:  # More than 1 second
                anomalies.append({
                    'type': 'slow_responses',
                    'severity': 'warning',
                    'value': avg_response,
                    'message': f'Average response time {avg_response:.0f}ms is high'
                })
        
        return anomalies
