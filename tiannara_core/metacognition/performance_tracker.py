"""
Domain Performance Tracker

Monitors success rates, latency, and trends across all Tiannara domains.
Detects degradation before failures occur.
"""

from typing import Dict, List, Optional
from datetime import datetime, timedelta
import json
import os


class DomainPerformanceTracker:
    """Tracks and analyzes performance metrics for all domains."""
    
    def __init__(self, data_dir: str = "runs/metacognition"):
        self.data_dir = data_dir
        os.makedirs(data_dir, exist_ok=True)
        
        # Historical performance data
        self.performance_history: Dict[str, List[Dict]] = {}
        
        # Current state
        self.current_metrics: Dict[str, Dict] = {}
        
        # Alert thresholds
        self.alert_thresholds = {
            'success_rate_min': 95.0,  # Alert if below 95%
            'latency_max_ms': 500,     # Alert if above 500ms
            'degradation_rate': 5.0    # Alert if dropping >5% per hour
        }
    
    def record_metric(self, domain: str, metric_type: str, value: float, metadata: Optional[Dict] = None):
        """Record a performance metric for a domain."""
        timestamp = datetime.utcnow().isoformat()
        
        if domain not in self.performance_history:
            self.performance_history[domain] = []
        
        record = {
            'timestamp': timestamp,
            'metric_type': metric_type,
            'value': value,
            'metadata': metadata or {}
        }
        
        self.performance_history[domain].append(record)
        
        # Keep only last 1000 records per domain
        if len(self.performance_history[domain]) > 1000:
            self.performance_history[domain] = self.performance_history[domain][-1000:]
        
        # Update current metrics
        if domain not in self.current_metrics:
            self.current_metrics[domain] = {}
        
        self.current_metrics[domain][metric_type] = {
            'value': value,
            'timestamp': timestamp
        }
    
    def get_domain_health(self, domain: str, window_hours: int = 24) -> Dict:
        """Get comprehensive health assessment for a domain."""
        if domain not in self.performance_history:
            return {
                'status': 'unknown',
                'success_rate': 0.0,
                'avg_latency_ms': 0.0,
                'trend': 'no_data'
            }
        
        # Filter to time window
        cutoff = datetime.utcnow() - timedelta(hours=window_hours)
        recent_records = [
            r for r in self.performance_history[domain]
            if datetime.fromisoformat(r['timestamp']) > cutoff
        ]
        
        if not recent_records:
            return {
                'status': 'no_recent_data',
                'success_rate': 0.0,
                'avg_latency_ms': 0.0,
                'trend': 'insufficient_data'
            }
        
        # Calculate metrics
        success_rates = [r['value'] for r in recent_records if r['metric_type'] == 'success_rate']
        latencies = [r['value'] for r in recent_records if r['metric_type'] == 'latency_ms']
        
        avg_success = sum(success_rates) / len(success_rates) if success_rates else 0.0
        avg_latency = sum(latencies) / len(latencies) if latencies else 0.0
        
        # Determine trend
        trend = self._calculate_trend(domain, window_hours)
        
        # Determine status
        status = self._determine_status(avg_success, avg_latency, trend)
        
        return {
            'status': status,
            'success_rate': round(avg_success, 2),
            'avg_latency_ms': round(avg_latency, 2),
            'trend': trend,
            'data_points': len(recent_records),
            'window_hours': window_hours
        }
    
    def detect_degradation(self, domain: str) -> Optional[Dict]:
        """Detect if a domain is experiencing performance degradation."""
        health = self.get_domain_health(domain, window_hours=1)
        
        alerts = []
        
        # Check success rate
        if health['success_rate'] < self.alert_thresholds['success_rate_min']:
            alerts.append({
                'type': 'low_success_rate',
                'severity': 'high',
                'current_value': health['success_rate'],
                'threshold': self.alert_thresholds['success_rate_min'],
                'message': f"Success rate {health['success_rate']}% below threshold {self.alert_thresholds['success_rate_min']}%"
            })
        
        # Check latency
        if health['avg_latency_ms'] > self.alert_thresholds['latency_max_ms']:
            alerts.append({
                'type': 'high_latency',
                'severity': 'medium',
                'current_value': health['avg_latency_ms'],
                'threshold': self.alert_thresholds['latency_max_ms'],
                'message': f"Latency {health['avg_latency_ms']}ms exceeds threshold {self.alert_thresholds['latency_max_ms']}ms"
            })
        
        # Check trend
        if health['trend'] == 'declining':
            alerts.append({
                'type': 'declining_performance',
                'severity': 'medium',
                'message': "Performance trending downward over past hour"
            })
        
        if alerts:
            return {
                'domain': domain,
                'alerts': alerts,
                'recommendation': self._generate_recommendation(alerts)
            }
        
        return None
    
    def get_all_domains_health(self) -> Dict[str, Dict]:
        """Get health status for all tracked domains."""
        domains = list(self.performance_history.keys())
        return {
            domain: self.get_domain_health(domain)
            for domain in domains
        }
    
    def _calculate_trend(self, domain: str, window_hours: int) -> str:
        """Calculate performance trend over time window."""
        if domain not in self.performance_history:
            return 'no_data'
        
        cutoff = datetime.utcnow() - timedelta(hours=window_hours)
        recent_records = [
            r for r in self.performance_history[domain]
            if datetime.fromisoformat(r['timestamp']) > cutoff and r['metric_type'] == 'success_rate'
        ]
        
        if len(recent_records) < 2:
            return 'insufficient_data'
        
        # Compare first half vs second half
        mid_point = len(recent_records) // 2
        first_half_avg = sum(r['value'] for r in recent_records[:mid_point]) / mid_point
        second_half_avg = sum(r['value'] for r in recent_records[mid_point:]) / (len(recent_records) - mid_point)
        
        change = second_half_avg - first_half_avg
        
        if change > 2.0:
            return 'improving'
        elif change < -2.0:
            return 'declining'
        else:
            return 'stable'
    
    def _determine_status(self, success_rate: float, latency: float, trend: str) -> str:
        """Determine overall domain status."""
        if success_rate >= 99.0 and latency < 300 and trend != 'declining':
            return 'healthy'
        elif success_rate >= 95.0 and latency < 500:
            return 'degraded'
        else:
            return 'critical'
    
    def _generate_recommendation(self, alerts: List[Dict]) -> str:
        """Generate actionable recommendation based on alerts."""
        alert_types = [a['type'] for a in alerts]
        
        if 'low_success_rate' in alert_types:
            return "Investigate test failures and apply targeted fixes"
        elif 'high_latency' in alert_types:
            return "Optimize processing pipeline or scale resources"
        elif 'declining_performance' in alert_types:
            return "Monitor closely and prepare intervention if trend continues"
        else:
            return "Continue monitoring"
    
    def save_state(self):
        """Save performance history to disk."""
        filepath = os.path.join(self.data_dir, 'performance_history.json')
        with open(filepath, 'w') as f:
            json.dump(self.performance_history, f, indent=2)
    
    def load_state(self):
        """Load performance history from disk."""
        filepath = os.path.join(self.data_dir, 'performance_history.json')
        if os.path.exists(filepath):
            with open(filepath, 'r') as f:
                self.performance_history = json.load(f)
