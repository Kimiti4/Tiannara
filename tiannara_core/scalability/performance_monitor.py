"""
Performance Monitor - Real-time system performance tracking

Monitors CPU, memory, latency, throughput, and custom metrics
with alerting and trend analysis capabilities.
"""

import logging
import time
import psutil
from typing import Dict, List, Optional, Any, Callable
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from collections import defaultdict

logger = logging.getLogger(__name__)


@dataclass
class PerformanceMetrics:
    """Snapshot of system performance metrics."""
    timestamp: datetime
    cpu_percent: float
    memory_percent: float
    memory_used_mb: float
    disk_io_read_mb: float
    disk_io_write_mb: float
    network_sent_mb: float
    network_recv_mb: float
    active_threads: int
    custom_metrics: Dict[str, float] = field(default_factory=dict)


class PerformanceMonitor:
    """Real-time performance monitoring system.
    
    Features:
    - System resource tracking (CPU, memory, disk, network)
    - Custom metric collection
    - Alert threshold configuration
    - Historical data retention
    - Trend analysis and anomaly detection
    """
    
    def __init__(self, retention_minutes: int = 60):
        self.retention_minutes = retention_minutes
        self.metrics_history: List[PerformanceMetrics] = []
        self.alerts: List[Dict[str, Any]] = []
        self.thresholds: Dict[str, float] = {
            'cpu_percent': 80.0,
            'memory_percent': 85.0,
            'active_threads': 1000
        }
        self._monitoring = False
        self._custom_collectors: Dict[str, Callable] = {}
        
    def start_monitoring(self, interval_seconds: int = 5):
        """Start continuous performance monitoring."""
        self._monitoring = True
        logger.info(f"Performance monitoring started (interval={interval_seconds}s)")
        
        while self._monitoring:
            try:
                metrics = self.collect_metrics()
                self.metrics_history.append(metrics)
                self._check_alerts(metrics)
                self._cleanup_old_data()
            except Exception as e:
                logger.error(f"Monitoring error: {e}")
            
            time.sleep(interval_seconds)
    
    def stop_monitoring(self):
        """Stop performance monitoring."""
        self._monitoring = False
        logger.info("Performance monitoring stopped")
    
    def collect_metrics(self) -> PerformanceMetrics:
        """Collect current system performance metrics."""
        cpu = psutil.cpu_percent(interval=0.1)
        memory = psutil.virtual_memory()
        disk_io = psutil.disk_io_counters()
        net_io = psutil.net_io_counters()
        
        custom = {}
        for name, collector in self._custom_collectors.items():
            try:
                custom[name] = collector()
            except Exception as e:
                logger.warning(f"Custom metric '{name}' failed: {e}")
        
        return PerformanceMetrics(
            timestamp=datetime.now(),
            cpu_percent=cpu,
            memory_percent=memory.percent,
            memory_used_mb=memory.used / (1024 ** 2),
            disk_io_read_mb=disk_io.read_bytes / (1024 ** 2) if disk_io else 0,
            disk_io_write_mb=disk_io.write_bytes / (1024 ** 2) if disk_io else 0,
            network_sent_mb=net_io.bytes_sent / (1024 ** 2) if net_io else 0,
            network_recv_mb=net_io.bytes_recv / (1024 ** 2) if net_io else 0,
            active_threads=threading.active_count(),
            custom_metrics=custom
        )
    
    def register_custom_metric(self, name: str, collector: Callable):
        """Register a custom metric collector function."""
        self._custom_collectors[name] = collector
        logger.info(f"Registered custom metric: {name}")
    
    def set_threshold(self, metric_name: str, threshold: float):
        """Set alert threshold for a metric."""
        self.thresholds[metric_name] = threshold
        logger.info(f"Threshold set: {metric_name} > {threshold}")
    
    def get_current_metrics(self) -> PerformanceMetrics:
        """Get latest performance metrics."""
        return self.metrics_history[-1] if self.metrics_history else self.collect_metrics()
    
    def get_average_metrics(self, window_minutes: int = 5) -> Dict[str, float]:
        """Calculate average metrics over a time window."""
        cutoff = datetime.now() - timedelta(minutes=window_minutes)
        recent = [m for m in self.metrics_history if m.timestamp >= cutoff]
        
        if not recent:
            return {}
        
        return {
            'avg_cpu': sum(m.cpu_percent for m in recent) / len(recent),
            'avg_memory': sum(m.memory_percent for m in recent) / len(recent),
            'avg_threads': sum(m.active_threads for m in recent) / len(recent)
        }
    
    def _check_alerts(self, metrics: PerformanceMetrics):
        """Check if any metrics exceed thresholds."""
        for metric_name, threshold in self.thresholds.items():
            value = getattr(metrics, metric_name, None)
            if value is not None and value > threshold:
                alert = {
                    'timestamp': datetime.now(),
                    'metric': metric_name,
                    'value': value,
                    'threshold': threshold,
                    'severity': 'high' if value > threshold * 1.2 else 'medium'
                }
                self.alerts.append(alert)
                logger.warning(f"ALERT: {metric_name}={value:.1f} > {threshold}")
    
    def _cleanup_old_data(self):
        """Remove metrics older than retention period."""
        cutoff = datetime.now() - timedelta(minutes=self.retention_minutes)
        self.metrics_history = [
            m for m in self.metrics_history 
            if m.timestamp >= cutoff
        ]
    
    def get_alerts(self, last_n: int = 10) -> List[Dict[str, Any]]:
        """Get recent alerts."""
        return self.alerts[-last_n:]
