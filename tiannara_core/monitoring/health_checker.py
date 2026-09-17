"""
Health Checker - System health monitoring and status reporting

Performs comprehensive health checks on all system components
including databases, caches, APIs, and external services.
"""

import logging
from typing import Dict, List, Optional, Any, Callable
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum

logger = logging.getLogger(__name__)


class HealthStatus(Enum):
    """System health status levels."""
    HEALTHY = "healthy"
    DEGRADED = "degraded"
    UNHEALTHY = "unhealthy"
    UNKNOWN = "unknown"


@dataclass
class ComponentHealth:
    """Health status of a single component."""
    component_name: str
    status: HealthStatus
    response_time_ms: float
    last_check: datetime
    details: Dict[str, Any] = field(default_factory=dict)
    error_message: Optional[str] = None


@dataclass
class SystemHealth:
    """Overall system health status."""
    overall_status: HealthStatus
    timestamp: datetime
    components: List[ComponentHealth]
    uptime_seconds: float
    version: str


class HealthChecker:
    """Comprehensive system health checking service.
    
    Features:
    - Multi-component health monitoring
    - Configurable health check intervals
    - Dependency chain validation
    - Detailed health reports
    - Integration with alerting systems
    """
    
    def __init__(self, system_version: str = "1.0.0"):
        self.system_version = system_version
        self.start_time = datetime.now()
        self.health_checks: Dict[str, Callable] = {}
        self.last_health_report: Optional[SystemHealth] = None
        
    def register_health_check(self, component_name: str, check_fn: Callable):
        """Register a health check function for a component.
        
        Args:
            component_name: Name of the component
            check_fn: Function that returns ComponentHealth
        """
        self.health_checks[component_name] = check_fn
        logger.info(f"Registered health check for: {component_name}")
    
    def check_all_components(self) -> SystemHealth:
        """Perform health checks on all registered components.
        
        Returns:
            SystemHealth with overall status and component details
        """
        component_healths = []
        
        for component_name, check_fn in self.health_checks.items():
            try:
                health = check_fn()
                component_healths.append(health)
            except Exception as e:
                logger.error(f"Health check failed for {component_name}: {e}")
                component_healths.append(ComponentHealth(
                    component_name=component_name,
                    status=HealthStatus.UNHEALTHY,
                    response_time_ms=0,
                    last_check=datetime.now(),
                    error_message=str(e)
                ))
        
        # Determine overall status
        overall_status = self._determine_overall_status(component_healths)
        
        uptime = (datetime.now() - self.start_time).total_seconds()
        
        report = SystemHealth(
            overall_status=overall_status,
            timestamp=datetime.now(),
            components=component_healths,
            uptime_seconds=uptime,
            version=self.system_version
        )
        
        self.last_health_report = report
        logger.info(f"System health: {overall_status.value}")
        
        return report
    
    def get_health_report(self) -> Optional[SystemHealth]:
        """Get the most recent health report."""
        return self.last_health_report
    
    def is_healthy(self) -> bool:
        """Check if system is currently healthy."""
        if not self.last_health_report:
            self.check_all_components()
        
        return self.last_health_report.overall_status == HealthStatus.HEALTHY
    
    def _determine_overall_status(
        self, components: List[ComponentHealth]
    ) -> HealthStatus:
        """Determine overall system health from component statuses."""
        if not components:
            return HealthStatus.UNKNOWN
        
        statuses = [c.status for c in components]
        
        if HealthStatus.UNHEALTHY in statuses:
            return HealthStatus.UNHEALTHY
        elif HealthStatus.DEGRADED in statuses:
            return HealthStatus.DEGRADED
        else:
            return HealthStatus.HEALTHY
    
    def get_component_status(self, component_name: str) -> Optional[ComponentHealth]:
        """Get health status for a specific component."""
        if not self.last_health_report:
            return None
        
        for component in self.last_health_report.components:
            if component.component_name == component_name:
                return component
        
        return None
