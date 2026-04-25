"""
Real-Time Dashboard Telemetry System

Provides comprehensive logging and monitoring for Tiannara operations.
Enables debugging, performance analysis, and system observability.
"""

from typing import Dict, Any, List, Optional, Callable
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum
import json
import logging
import threading
import time
import statistics
from collections import defaultdict, deque
from pathlib import Path

# Import other Tiannara components for telemetry
try:
    from tiannara_core.memory.failure_memory import get_failure_memory
    from tiannara_core.plugins.registry import get_plugin_registry
    from tiannara_core.goals.goal_system import get_goal_system
    from tiannara_core.agents.multi_agent_system import get_multi_agent_system
except ImportError:
    # Fallback for standalone usage
    def get_failure_memory(): return None
    def get_plugin_registry(): return None
    def get_goal_system(): return None
    def get_multi_agent_system(): return None


class EventType(Enum):
    INTENT_RECEIVED = "intent_received"
    PLANNING_STARTED = "planning_started"
    PLANNING_COMPLETED = "planning_completed"
    EXECUTION_STARTED = "execution_started"
    EXECUTION_COMPLETED = "execution_completed"
    FAILURE_OCCURRED = "failure_occurred"
    TOOL_EXECUTED = "tool_executed"
    GOAL_CREATED = "goal_created"
    GOAL_COMPLETED = "goal_completed"
    AGENT_TASK = "agent_task"
    SYSTEM_EVENT = "system_event"
    PERFORMANCE_METRIC = "performance_metric"


class Severity(Enum):
    DEBUG = "debug"
    INFO = "info"
    WARNING = "warning"
    ERROR = "error"
    CRITICAL = "critical"


@dataclass
class TelemetryEvent:
    """Single telemetry event."""
    timestamp: str
    event_type: EventType
    severity: Severity
    component: str
    message: str
    data: Dict[str, Any] = field(default_factory=dict)
    session_id: str = ""
    correlation_id: Optional[str] = None
    duration_ms: Optional[float] = None
    user_id: Optional[str] = None


@dataclass
class SystemMetrics:
    """System performance metrics."""
    cpu_usage: float = 0.0
    memory_usage: float = 0.0
    disk_usage: float = 0.0
    active_tasks: int = 0
    queue_size: int = 0
    response_time_avg: float = 0.0
    error_rate: float = 0.0
    uptime: float = 0.0


@dataclass
class ComponentMetrics:
    """Metrics for a specific component."""
    name: str
    requests_total: int = 0
    requests_successful: int = 0
    requests_failed: int = 0
    avg_response_time: float = 0.0
    last_request_time: Optional[str] = None
    error_rate: float = 0.0
    status: str = "active"


class TelemetryCollector:
    """Collects and manages telemetry data."""
    
    def __init__(self, max_events: int = 10000, retention_hours: int = 24):
        self.max_events = max_events
        self.retention_hours = retention_hours
        
        # Event storage (ring buffer)
        self.events: deque = deque(maxlen=max_events)
        
        # Metrics storage
        self.system_metrics = SystemMetrics()
        self.component_metrics: Dict[str, ComponentMetrics] = {}
        
        # Performance tracking
        self.response_times: deque = deque(maxlen=1000)
        self.error_counts: Dict[str, int] = defaultdict(int)
        
        # Session tracking
        self.session_id = f"session_{int(time.time())}"
        self.start_time = time.time()
        
        # Thread safety
        self.lock = threading.RLock()
        
        # Logger
        self.logger = logging.getLogger("tiannara.telemetry")
    
    def log_event(self, 
                 event_type: EventType,
                 component: str,
                 message: str,
                 severity: Severity = Severity.INFO,
                 data: Optional[Dict[str, Any]] = None,
                 correlation_id: Optional[str] = None,
                 duration_ms: Optional[float] = None,
                 user_id: Optional[str] = None):
        """Log a telemetry event."""
        
        event = TelemetryEvent(
            timestamp=datetime.now().isoformat(),
            event_type=event_type,
            severity=severity,
            component=component,
            message=message,
            data=data or {},
            session_id=self.session_id,
            correlation_id=correlation_id,
            duration_ms=duration_ms,
            user_id=user_id
        )
        
        with self.lock:
            self.events.append(event)
            
            # Update metrics
            self._update_metrics(event)
            
            # Log to standard logger
            log_level = getattr(logging, severity.value.upper(), logging.INFO)
            self.logger.log(log_level, f"[{component}] {message}")
    
    def _update_metrics(self, event: TelemetryEvent):
        """Update metrics based on event."""
        # Update component metrics
        if event.component not in self.component_metrics:
            self.component_metrics[event.component] = ComponentMetrics(name=event.component)
        
        metrics = self.component_metrics[event.component]
        metrics.requests_total += 1
        metrics.last_request_time = event.timestamp
        
        if event.severity in [Severity.ERROR, Severity.CRITICAL]:
            metrics.requests_failed += 1
            self.error_counts[event.component] += 1
        else:
            metrics.requests_successful += 1
        
        # Update response time
        if event.duration_ms is not None:
            self.response_times.append(event.duration_ms)
            metrics.avg_response_time = statistics.mean(self.response_times)
        
        # Calculate error rate
        if metrics.requests_total > 0:
            metrics.error_rate = metrics.requests_failed / metrics.requests_total
        
        # Update system metrics
        self._update_system_metrics()
    
    def _update_system_metrics(self):
        """Update system-wide metrics."""
        self.system_metrics.uptime = time.time() - self.start_time
        self.system_metrics.active_tasks = len([e for e in self.events 
                                              if e.event_type in [EventType.EXECUTION_STARTED, EventType.PLANNING_STARTED]])
        
        if self.response_times:
            self.system_metrics.response_time_avg = statistics.mean(self.response_times)
        
        # Calculate overall error rate
        total_requests = sum(m.requests_total for m in self.component_metrics.values())
        total_errors = sum(m.requests_failed for m in self.component_metrics.values())
        self.system_metrics.error_rate = total_errors / max(1, total_requests)
    
    def get_events(self, 
                   event_type: Optional[EventType] = None,
                   component: Optional[str] = None,
                   severity: Optional[Severity] = None,
                   limit: int = 100,
                   since_hours: Optional[int] = None) -> List[TelemetryEvent]:
        """Get filtered events."""
        with self.lock:
            events = list(self.events)
        
        # Apply filters
        if event_type:
            events = [e for e in events if e.event_type == event_type]
        
        if component:
            events = [e for e in events if e.component == component]
        
        if severity:
            events = [e for e in events if e.severity == severity]
        
        if since_hours:
            cutoff = datetime.now() - timedelta(hours=since_hours)
            events = [e for e in events if datetime.fromisoformat(e.timestamp) >= cutoff]
        
        # Sort by timestamp (newest first) and limit
        events.sort(key=lambda e: e.timestamp, reverse=True)
        return events[:limit]
    
    def get_metrics_summary(self) -> Dict[str, Any]:
        """Get comprehensive metrics summary."""
        with self.lock:
            return {
                "system": {
                    "uptime_seconds": self.system_metrics.uptime,
                    "uptime_formatted": self._format_duration(self.system_metrics.uptime),
                    "active_tasks": self.system_metrics.active_tasks,
                    "avg_response_time_ms": self.system_metrics.response_time_avg,
                    "error_rate": self.system_metrics.error_rate,
                    "total_events": len(self.events),
                    "session_id": self.session_id
                },
                "components": {
                    name: {
                        "requests_total": m.requests_total,
                        "success_rate": 1.0 - m.error_rate,
                        "avg_response_time_ms": m.avg_response_time,
                        "last_request": m.last_request_time,
                        "status": m.status
                    }
                    for name, m in self.component_metrics.items()
                },
                "recent_errors": [
                    {
                        "timestamp": e.timestamp,
                        "component": e.component,
                        "message": e.message,
                        "severity": e.severity.value
                    }
                    for e in self.get_events(severity=Severity.ERROR, limit=10)
                ],
                "performance": {
                    "response_time_p50": self._percentile(self.response_times, 0.5),
                    "response_time_p95": self._percentile(self.response_times, 0.95),
                    "response_time_p99": self._percentile(self.response_times, 0.99)
                }
            }
    
    def _format_duration(self, seconds: float) -> str:
        """Format duration in human-readable format."""
        hours = int(seconds // 3600)
        minutes = int((seconds % 3600) // 60)
        secs = int(seconds % 60)
        
        if hours > 0:
            return f"{hours}h {minutes}m {secs}s"
        elif minutes > 0:
            return f"{minutes}m {secs}s"
        else:
            return f"{secs}s"
    
    def _percentile(self, data: deque, percentile: float) -> float:
        """Calculate percentile of data."""
        if not data:
            return 0.0
        
        sorted_data = sorted(data)
        index = int(len(sorted_data) * percentile)
        return sorted_data[min(index, len(sorted_data) - 1)]
    
    def cleanup_old_events(self):
        """Clean up events older than retention period."""
        cutoff = datetime.now() - timedelta(hours=self.retention_hours)
        
        with self.lock:
            original_count = len(self.events)
            self.events = deque(
                (e for e in self.events if datetime.fromisoformat(e.timestamp) >= cutoff),
                maxlen=self.max_events
            )
            
            cleaned = original_count - len(self.events)
            if cleaned > 0:
                self.logger.info(f"Cleaned up {cleaned} old telemetry events")


class DashboardAPI:
    """API for accessing telemetry data."""
    
    def __init__(self, collector: TelemetryCollector):
        self.collector = collector
        self.logger = logging.getLogger("tiannara.dashboard")
    
    def get_logs(self, 
                component: Optional[str] = None,
                severity: Optional[str] = None,
                limit: int = 100,
                since_hours: Optional[int] = None) -> Dict[str, Any]:
        """Get log entries."""
        # Parse severity
        sev = None
        if severity:
            try:
                sev = Severity(severity.lower())
            except ValueError:
                pass
        
        events = self.collector.get_events(
            component=component,
            severity=sev,
            limit=limit,
            since_hours=since_hours
        )
        
        return {
            "logs": [
                {
                    "timestamp": e.timestamp,
                    "event_type": e.event_type.value,
                    "severity": e.severity.value,
                    "component": e.component,
                    "message": e.message,
                    "data": e.data,
                    "duration_ms": e.duration_ms,
                    "correlation_id": e.correlation_id
                }
                for e in events
            ],
            "total": len(events),
            "filters": {
                "component": component,
                "severity": severity,
                "limit": limit,
                "since_hours": since_hours
            }
        }
    
    def get_goals(self) -> Dict[str, Any]:
        """Get goal system status."""
        goal_system = get_goal_system()
        
        if not goal_system:
            return {"error": "Goal system not available"}
        
        overview = goal_system.get_system_overview()
        active_goals = goal_system.get_active_goals()
        
        return {
            "overview": overview,
            "active_goals": [
                {
                    "id": g.id,
                    "objective": g.objective,
                    "status": g.status.value,
                    "progress": g.progress,
                    "priority": g.priority.name,
                    "created_at": g.created_at,
                    "step_count": len(g.steps)
                }
                for g in active_goals[:10]  # Limit to 10 most recent
            ]
        }
    
    def get_tools(self) -> Dict[str, Any]:
        """Get plugin system status."""
        registry = get_plugin_registry()
        
        if not registry:
            return {"error": "Plugin system not available"}
        
        stats = registry.get_tool_statistics()
        tools = registry.list_tools()
        
        return {
            "statistics": stats,
            "tools": [
                {
                    "name": name,
                    "metadata": {
                        "description": metadata.description,
                        "version": metadata.version,
                        "author": metadata.author,
                        "usage_count": metadata.usage_count,
                        "success_rate": metadata.success_rate
                    }
                }
                for name, metadata in registry.tools.items()
            ]
        }
    
    def get_failures(self) -> Dict[str, Any]:
        """Get failure analysis."""
        failure_memory = get_failure_memory()
        
        if not failure_memory:
            return {"error": "Failure memory not available"}
        
        analysis = failure_memory.analyze_failures()
        stats = failure_memory.get_statistics()
        
        return {
            "analysis": {
                "total_failures": analysis.total_failures,
                "failure_rate": analysis.failure_rate,
                "most_common_errors": analysis.most_common_errors,
                "recommendations": analysis.recommendations
            },
            "statistics": stats,
            "recent_failures": [
                {
                    "timestamp": f.timestamp,
                    "intent": f.intent,
                    "error_type": f.error_type,
                    "error_message": f.error_message,
                    "component": f.component,
                    "severity": f.severity
                }
                for f in failure_memory.get_failures_by_timeframe(24, limit=20)
            ]
        }
    
    def get_agents(self) -> Dict[str, Any]:
        """Get multi-agent system status."""
        agent_system = get_multi_agent_system()
        
        if not agent_system:
            return {"error": "Multi-agent system not available"}
        
        status = agent_system.get_agent_status()
        
        return {
            "agent_status": status,
            "total_agents": len(status),
            "active_agents": len([s for s in status.values() if s.get("performance", {}).get("tasks_completed", 0) > 0])
        }
    
    def get_metrics(self) -> Dict[str, Any]:
        """Get comprehensive metrics."""
        return self.collector.get_metrics_summary()
    
    def get_health(self) -> Dict[str, Any]:
        """Get system health check."""
        metrics = self.collector.get_metrics_summary()
        
        # Health checks
        checks = {
            "error_rate": metrics["system"]["error_rate"] < 0.1,  # Less than 10% errors
            "response_time": metrics["system"]["avg_response_time_ms"] < 5000,  # Less than 5 seconds
            "active_tasks": metrics["system"]["active_tasks"] < 50,  # Less than 50 active tasks
            "component_health": all(
                comp["success_rate"] > 0.8 
                for comp in metrics["components"].values()
                if comp["requests_total"] > 0
            )
        }
        
        overall_health = all(checks.values())
        
        return {
            "healthy": overall_health,
            "checks": checks,
            "system_metrics": metrics["system"],
            "timestamp": datetime.now().isoformat()
        }


class TelemetryDashboard:
    """Main telemetry dashboard system."""
    
    def __init__(self, storage_path: str = "data/telemetry"):
        self.storage_path = Path(storage_path)
        self.storage_path.mkdir(parents=True, exist_ok=True)
        
        # Initialize components
        self.collector = TelemetryCollector()
        self.api = DashboardAPI(self.collector)
        
        # Background cleanup thread
        self.cleanup_thread = threading.Thread(target=self._background_cleanup, daemon=True)
        self.cleanup_thread.start()
        
        self.logger = logging.getLogger("tiannara.dashboard")
        self.logger.info("Telemetry dashboard initialized")
    
    def _background_cleanup(self):
        """Background thread for cleaning up old data."""
        while True:
            try:
                time.sleep(3600)  # Run every hour
                self.collector.cleanup_old_events()
            except Exception as e:
                self.logger.error(f"Background cleanup failed: {e}")
    
    def log_intent(self, intent: str, context: Optional[Dict[str, Any]] = None, user_id: Optional[str] = None):
        """Log an intent event."""
        self.collector.log_event(
            EventType.INTENT_RECEIVED,
            "core",
            f"Intent received: {intent}",
            Severity.INFO,
            data={"intent": intent, "context": context},
            user_id=user_id
        )
    
    def log_planning(self, intent: str, method: str, success: bool, duration_ms: float, plan_id: Optional[str] = None):
        """Log a planning event."""
        severity = Severity.INFO if success else Severity.ERROR
        message = f"Planning {'completed' if success else 'failed'} using {method}"
        
        self.collector.log_event(
            EventType.PLANNING_COMPLETED,
            "planner",
            message,
            severity,
            data={
                "intent": intent,
                "method": method,
                "plan_id": plan_id,
                "success": success
            },
            duration_ms=duration_ms
        )
    
    def log_execution(self, plan_id: str, success: bool, duration_ms: float, result: Optional[Dict[str, Any]] = None):
        """Log an execution event."""
        severity = Severity.INFO if success else Severity.ERROR
        message = f"Execution {'completed' if success else 'failed'}"
        
        self.collector.log_event(
            EventType.EXECUTION_COMPLETED,
            "executor",
            message,
            severity,
            data={
                "plan_id": plan_id,
                "success": success,
                "result_summary": str(result)[:200] if result else None
            },
            duration_ms=duration_ms
        )
    
    def log_failure(self, component: str, error: str, context: Optional[Dict[str, Any]] = None):
        """Log a failure event."""
        self.collector.log_event(
            EventType.FAILURE_OCCURRED,
            component,
            f"Failure: {error}",
            Severity.ERROR,
            data={"error": error, "context": context}
        )
    
    def log_tool_execution(self, tool_name: str, success: bool, duration_ms: float, params: Optional[Dict[str, Any]] = None):
        """Log a tool execution event."""
        severity = Severity.INFO if success else Severity.WARNING
        message = f"Tool {tool_name} {'executed' if success else 'failed'}"
        
        self.collector.log_event(
            EventType.TOOL_EXECUTED,
            "plugins",
            message,
            severity,
            data={
                "tool_name": tool_name,
                "success": success,
                "params_summary": str(params)[:100] if params else None
            },
            duration_ms=duration_ms
        )
    
    def get_dashboard_data(self) -> Dict[str, Any]:
        """Get all dashboard data for frontend."""
        return {
            "metrics": self.api.get_metrics(),
            "health": self.api.get_health(),
            "logs": self.api.get_logs(limit=50),
            "goals": self.api.get_goals(),
            "tools": self.api.get_tools(),
            "failures": self.api.get_failures(),
            "agents": self.api.get_agents(),
            "timestamp": datetime.now().isoformat()
        }


# Global dashboard instance
_telemetry_dashboard = None

def get_telemetry_dashboard() -> TelemetryDashboard:
    """Get or create the global telemetry dashboard instance."""
    global _telemetry_dashboard
    if _telemetry_dashboard is None:
        _telemetry_dashboard = TelemetryDashboard()
    return _telemetry_dashboard

def log_intent(intent: str, **kwargs):
    """Quick access function for logging intents."""
    dashboard = get_telemetry_dashboard()
    dashboard.log_intent(intent, **kwargs)

def log_planning(intent: str, method: str, success: bool, duration_ms: float, **kwargs):
    """Quick access function for logging planning."""
    dashboard = get_telemetry_dashboard()
    dashboard.log_planning(intent, method, success, duration_ms, **kwargs)

def log_execution(plan_id: str, success: bool, duration_ms: float, **kwargs):
    """Quick access function for logging execution."""
    dashboard = get_telemetry_dashboard()
    dashboard.log_execution(plan_id, success, duration_ms, **kwargs)

def log_failure(component: str, error: str, **kwargs):
    """Quick access function for logging failures."""
    dashboard = get_telemetry_dashboard()
    dashboard.log_failure(component, error, **kwargs)

def get_dashboard_data() -> Dict[str, Any]:
    """Quick access function for getting dashboard data."""
    dashboard = get_telemetry_dashboard()
    return dashboard.get_dashboard_data()
