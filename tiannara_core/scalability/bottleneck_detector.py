"""
Bottleneck Detector - Automatic performance bottleneck identification

Analyzes system metrics to identify performance bottlenecks
in CPU, memory, I/O, network, and application layers.
"""

import logging
from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum

logger = logging.getLogger(__name__)


class BottleneckType(Enum):
    """Types of performance bottlenecks."""
    CPU_BOUND = "cpu_bound"
    MEMORY_BOUND = "memory_bound"
    IO_BOUND = "io_bound"
    NETWORK_BOUND = "network_bound"
    DATABASE_BOUND = "database_bound"
    APPLICATION_BOUND = "application_bound"


@dataclass
class BottleneckReport:
    """Detailed report of identified bottleneck."""
    bottleneck_id: str
    bottleneck_type: BottleneckType
    severity: str  # 'low', 'medium', 'high', 'critical'
    description: str
    affected_component: str
    current_metric_value: float
    threshold_value: float
    impact_estimate: str
    recommendations: List[str] = field(default_factory=list)
    detected_at: datetime = field(default_factory=datetime.now)


class BottleneckDetector:
    """Automatic bottleneck detection and analysis system.
    
    Features:
    - Multi-layer bottleneck detection (CPU, memory, I/O, network, DB)
    - Severity classification
    - Root cause analysis
    - Actionable recommendations
    - Historical bottleneck tracking
    """
    
    def __init__(self):
        self.thresholds: Dict[str, float] = {
            'cpu_percent': 80.0,
            'memory_percent': 85.0,
            'disk_io_percent': 90.0,
            'network_bandwidth_percent': 80.0,
            'db_query_time_ms': 1000,
            'response_time_ms': 500
        }
        self.detected_bottlenecks: List[BottleneckReport] = []
        
    def analyze_system(self, metrics: Dict[str, Any]) -> List[BottleneckReport]:
        """Analyze system metrics for bottlenecks.
        
        Args:
            metrics: Dictionary of system metrics
            
        Returns:
            List of detected bottlenecks
        """
        bottlenecks = []
        
        # Check CPU bottleneck
        if metrics.get('cpu_percent', 0) > self.thresholds['cpu_percent']:
            bottlenecks.append(self._create_cpu_bottleneck(metrics))
        
        # Check memory bottleneck
        if metrics.get('memory_percent', 0) > self.thresholds['memory_percent']:
            bottlenecks.append(self._create_memory_bottleneck(metrics))
        
        # Check I/O bottleneck
        if metrics.get('disk_io_percent', 0) > self.thresholds['disk_io_percent']:
            bottlenecks.append(self._create_io_bottleneck(metrics))
        
        # Check network bottleneck
        if metrics.get('network_bandwidth_percent', 0) > self.thresholds['network_bandwidth_percent']:
            bottlenecks.append(self._create_network_bottleneck(metrics))
        
        # Check database bottleneck
        if metrics.get('avg_db_query_ms', 0) > self.thresholds['db_query_time_ms']:
            bottlenecks.append(self._create_database_bottleneck(metrics))
        
        # Check application bottleneck
        if metrics.get('avg_response_time_ms', 0) > self.thresholds['response_time_ms']:
            bottlenecks.append(self._create_application_bottleneck(metrics))
        
        self.detected_bottlenecks.extend(bottlenecks)
        
        if bottlenecks:
            logger.warning(f"Detected {len(bottlenecks)} bottleneck(s)")
        
        return bottlenecks
    
    def get_critical_bottlenecks(self) -> List[BottleneckReport]:
        """Get all critical and high severity bottlenecks."""
        return [
            b for b in self.detected_bottlenecks 
            if b.severity in ['critical', 'high']
        ]
    
    def get_recommendations(self) -> Dict[str, List[str]]:
        """Get consolidated recommendations by category."""
        recs_by_category: Dict[str, List[str]] = {}
        
        for bottleneck in self.detected_bottlenecks:
            category = bottleneck.bottleneck_type.value
            if category not in recs_by_category:
                recs_by_category[category] = []
            recs_by_category[category].extend(bottleneck.recommendations)
        
        return recs_by_category
    
    def _create_cpu_bottleneck(self, metrics: Dict[str, Any]) -> BottleneckReport:
        """Create CPU bottleneck report."""
        cpu_pct = metrics['cpu_percent']
        severity = 'critical' if cpu_pct > 95 else 'high' if cpu_pct > 90 else 'medium'
        
        return BottleneckReport(
            bottleneck_id=f"cpu_{datetime.now().strftime('%Y%m%d%H%M%S')}",
            bottleneck_type=BottleneckType.CPU_BOUND,
            severity=severity,
            description=f"CPU utilization at {cpu_pct:.1f}% exceeds threshold",
            affected_component="CPU",
            current_metric_value=cpu_pct,
            threshold_value=self.thresholds['cpu_percent'],
            impact_estimate="System responsiveness degraded, potential timeouts",
            recommendations=[
                "Optimize CPU-intensive operations",
                "Consider horizontal scaling",
                "Profile application for hot paths",
                "Implement caching for repeated computations"
            ]
        )
    
    def _create_memory_bottleneck(self, metrics: Dict[str, Any]) -> BottleneckReport:
        """Create memory bottleneck report."""
        mem_pct = metrics['memory_percent']
        severity = 'critical' if mem_pct > 95 else 'high' if mem_pct > 90 else 'medium'
        
        return BottleneckReport(
            bottleneck_id=f"mem_{datetime.now().strftime('%Y%m%d%H%M%S')}",
            bottleneck_type=BottleneckType.MEMORY_BOUND,
            severity=severity,
            description=f"Memory utilization at {mem_pct:.1f}% exceeds threshold",
            affected_component="Memory",
            current_metric_value=mem_pct,
            threshold_value=self.thresholds['memory_percent'],
            impact_estimate="Risk of OOM errors, increased garbage collection",
            recommendations=[
                "Investigate memory leaks",
                "Optimize data structures and caching",
                "Increase memory allocation",
                "Implement memory-efficient algorithms"
            ]
        )
    
    def _create_io_bottleneck(self, metrics: Dict[str, Any]) -> BottleneckReport:
        """Create I/O bottleneck report."""
        io_pct = metrics['disk_io_percent']
        
        return BottleneckReport(
            bottleneck_id=f"io_{datetime.now().strftime('%Y%m%d%H%M%S')}",
            bottleneck_type=BottleneckType.IO_BOUND,
            severity='high',
            description=f"Disk I/O utilization at {io_pct:.1f}% exceeds threshold",
            affected_component="Disk I/O",
            current_metric_value=io_pct,
            threshold_value=self.thresholds['disk_io_percent'],
            impact_estimate="Slow file operations, increased latency",
            recommendations=[
                "Upgrade to SSD storage",
                "Implement read/write caching",
                "Optimize file access patterns",
                "Consider distributed file system"
            ]
        )
    
    def _create_network_bottleneck(self, metrics: Dict[str, Any]) -> BottleneckReport:
        """Create network bottleneck report."""
        net_pct = metrics['network_bandwidth_percent']
        
        return BottleneckReport(
            bottleneck_id=f"net_{datetime.now().strftime('%Y%m%d%H%M%S')}",
            bottleneck_type=BottleneckType.NETWORK_BOUND,
            severity='high',
            description=f"Network bandwidth at {net_pct:.1f}% exceeds threshold",
            affected_component="Network",
            current_metric_value=net_pct,
            threshold_value=self.thresholds['network_bandwidth_percent'],
            impact_estimate="Increased latency, potential connection timeouts",
            recommendations=[
                "Upgrade network bandwidth",
                "Implement CDN for static assets",
                "Optimize payload sizes",
                "Use connection pooling"
            ]
        )
    
    def _create_database_bottleneck(self, metrics: Dict[str, Any]) -> BottleneckReport:
        """Create database bottleneck report."""
        query_time = metrics['avg_db_query_ms']
        
        return BottleneckReport(
            bottleneck_id=f"db_{datetime.now().strftime('%Y%m%d%H%M%S')}",
            bottleneck_type=BottleneckType.DATABASE_BOUND,
            severity='high' if query_time > 2000 else 'medium',
            description=f"Average DB query time {query_time:.0f}ms exceeds threshold",
            affected_component="Database",
            current_metric_value=query_time,
            threshold_value=self.thresholds['db_query_time_ms'],
            impact_estimate="Slow API responses, degraded user experience",
            recommendations=[
                "Optimize slow queries",
                "Add database indexes",
                "Implement query caching",
                "Consider read replicas"
            ]
        )
    
    def _create_application_bottleneck(self, metrics: Dict[str, Any]) -> BottleneckReport:
        """Create application-level bottleneck report."""
        response_time = metrics['avg_response_time_ms']
        
        return BottleneckReport(
            bottleneck_id=f"app_{datetime.now().strftime('%Y%m%d%H%M%S')}",
            bottleneck_type=BottleneckType.APPLICATION_BOUND,
            severity='high' if response_time > 1000 else 'medium',
            description=f"Average response time {response_time:.0f}ms exceeds threshold",
            affected_component="Application",
            current_metric_value=response_time,
            threshold_value=self.thresholds['response_time_ms'],
            impact_estimate="Poor user experience, potential timeout errors",
            recommendations=[
                "Profile application code",
                "Optimize critical paths",
                "Implement async processing",
                "Add response caching"
            ]
        )
