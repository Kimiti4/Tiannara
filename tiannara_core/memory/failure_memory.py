"""
Failure Memory System

Tracks and analyzes failure patterns to improve system reliability.
Provides insights for evolution and optimization.
"""

from typing import Dict, Any, List, Optional, Tuple
from dataclasses import dataclass, field
from datetime import datetime, timedelta
import json
import statistics
from collections import defaultdict, Counter


@dataclass
class FailureRecord:
    """Record of a single failure event."""
    id: str
    timestamp: str
    intent: str
    error_type: str
    error_message: str
    step_id: Optional[str]
    component: str
    context: Dict[str, Any]
    severity: str  # "low", "medium", "high", "critical"
    recovery_attempted: bool
    recovery_successful: bool
    resolution_time: Optional[float] = None  # Time to recovery in seconds


@dataclass
class FailurePattern:
    """Identified pattern of failures."""
    pattern_id: str
    description: str
    frequency: int
    failure_rate: float
    common_errors: List[str]
    affected_intents: List[str]
    affected_components: List[str]
    time_pattern: str  # "recent", "persistent", "sporadic"
    severity_distribution: Dict[str, int]
    suggested_fixes: List[str]
    confidence: float


@dataclass
class FailureAnalysis:
    """Analysis of failure data."""
    total_failures: int
    failure_rate: float
    most_common_errors: List[Tuple[str, int]]
    most_problematic_components: List[Tuple[str, int]]
    failure_patterns: List[FailurePattern]
    trends: Dict[str, Any]
    recommendations: List[str]


class FailureMemory:
    """
    Memory system specifically for tracking and analyzing failures.
    Provides pattern recognition and improvement suggestions.
    """
    
    def __init__(self, max_records: int = 10000):
        self.max_records = max_records
        self.failures: List[FailureRecord] = []
        self.patterns: List[FailurePattern] = []
        self._analysis_cache = {}
        self._last_analysis_time = None
        self._analysis_cache_ttl = timedelta(minutes=5)
    
    def log_failure(self, 
                   intent: str,
                   error: Exception,
                   step_id: Optional[str] = None,
                   component: str = "unknown",
                   context: Optional[Dict[str, Any]] = None,
                   severity: str = "medium") -> str:
        """
        Log a failure event.
        
        Args:
            intent: The intent that failed
            error: The exception that occurred
            step_id: ID of the step that failed (if applicable)
            component: Component that failed
            context: Additional context information
            severity: Severity level of the failure
            
        Returns:
            ID of the failure record
        """
        failure_id = self._generate_failure_id()
        
        record = FailureRecord(
            id=failure_id,
            timestamp=datetime.now().isoformat(),
            intent=intent,
            error_type=type(error).__name__,
            error_message=str(error),
            step_id=step_id,
            component=component,
            context=context or {},
            severity=severity,
            recovery_attempted=False,
            recovery_successful=False
        )
        
        self.failures.append(record)
        
        # Maintain max records
        if len(self.failures) > self.max_records:
            self.failures = self.failures[-self.max_records:]
        
        # Invalidate analysis cache
        self._analysis_cache = {}
        
        return failure_id
    
    def log_recovery(self, 
                    failure_id: str,
                    recovery_successful: bool,
                    resolution_time: Optional[float] = None):
        """
        Log recovery attempt for a failure.
        
        Args:
            failure_id: ID of the failure record
            recovery_successful: Whether recovery was successful
            resolution_time: Time taken to resolve
        """
        for failure in self.failures:
            if failure.id == failure_id:
                failure.recovery_attempted = True
                failure.recovery_successful = recovery_successful
                failure.resolution_time = resolution_time
                break
    
    def get_failures_by_intent(self, intent: str, limit: int = 50) -> List[FailureRecord]:
        """Get failures for a specific intent."""
        return [f for f in self.failures if f.intent == intent][:limit]
    
    def get_failures_by_component(self, component: str, limit: int = 50) -> List[FailureRecord]:
        """Get failures for a specific component."""
        return [f for f in self.failures if f.component == component][:limit]
    
    def get_failures_by_timeframe(self, 
                                 hours: int = 24,
                                 severity: Optional[str] = None) -> List[FailureRecord]:
        """Get failures within a timeframe."""
        cutoff = datetime.now() - timedelta(hours=hours)
        
        failures = [f for f in self.failures 
                   if datetime.fromisoformat(f.timestamp) >= cutoff]
        
        if severity:
            failures = [f for f in failures if f.severity == severity]
        
        return failures
    
    def analyze_failures(self, force_refresh: bool = False) -> FailureAnalysis:
        """
        Analyze failure patterns and generate insights.
        
        Args:
            force_refresh: Force re-analysis even if cached
            
        Returns:
            FailureAnalysis object with insights
        """
        now = datetime.now()
        
        # Check cache
        if (not force_refresh and 
            self._last_analysis_time and 
            now - self._last_analysis_time < self._analysis_cache_ttl and
            self._analysis_cache):
            return self._analysis_cache
        
        if not self.failures:
            return FailureAnalysis(
                total_failures=0,
                failure_rate=0.0,
                most_common_errors=[],
                most_problematic_components=[],
                failure_patterns=[],
                trends={},
                recommendations=["No failures recorded yet"]
            )
        
        # Basic statistics
        total_failures = len(self.failures)
        
        # Most common errors
        error_counts = Counter(f.error_type for f in self.failures)
        most_common_errors = error_counts.most_common(10)
        
        # Most problematic components
        component_counts = Counter(f.component for f in self.failures)
        most_problematic_components = component_counts.most_common(10)
        
        # Failure rate (failures per hour in last 24h)
        recent_failures = self.get_failures_by_timeframe(24)
        failure_rate = len(recent_failures) / 24.0
        
        # Identify patterns
        patterns = self._identify_patterns()
        
        # Analyze trends
        trends = self._analyze_trends()
        
        # Generate recommendations
        recommendations = self._generate_recommendations(patterns, trends)
        
        analysis = FailureAnalysis(
            total_failures=total_failures,
            failure_rate=failure_rate,
            most_common_errors=most_common_errors,
            most_problematic_components=most_problematic_components,
            failure_patterns=patterns,
            trends=trends,
            recommendations=recommendations
        )
        
        # Cache results
        self._analysis_cache = analysis
        self._last_analysis_time = now
        
        return analysis
    
    def _identify_patterns(self) -> List[FailurePattern]:
        """Identify failure patterns from recorded failures."""
        patterns = []
        
        # Pattern 1: Repeated failures on same intent
        intent_failures = defaultdict(list)
        for failure in self.failures:
            intent_failures[failure.intent].append(failure)
        
        for intent, failures in intent_failures.items():
            if len(failures) >= 3:  # At least 3 failures to establish pattern
                pattern = FailurePattern(
                    pattern_id=f"intent_{intent[:20]}",
                    description=f"Repeated failures on intent: {intent}",
                    frequency=len(failures),
                    failure_rate=len(failures) / max(1, self._count_intent_attempts(intent)),
                    common_errors=list(set(f.error_type for f in failures)),
                    affected_intents=[intent],
                    affected_components=list(set(f.component for f in failures)),
                    time_pattern=self._classify_time_pattern(failures),
                    severity_distribution=self._get_severity_distribution(failures),
                    suggested_fixes=self._suggest_fixes_for_intent(intent, failures),
                    confidence=min(1.0, len(failures) / 10.0)
                )
                patterns.append(pattern)
        
        # Pattern 2: Component-specific failures
        component_failures = defaultdict(list)
        for failure in self.failures:
            component_failures[failure.component].append(failure)
        
        for component, failures in component_failures.items():
            if len(failures) >= 5:  # At least 5 failures
                pattern = FailurePattern(
                    pattern_id=f"component_{component}",
                    description=f"High failure rate in component: {component}",
                    frequency=len(failures),
                    failure_rate=len(failures) / max(1, self._count_component_attempts(component)),
                    common_errors=list(set(f.error_type for f in failures)),
                    affected_intents=list(set(f.intent for f in failures)),
                    affected_components=[component],
                    time_pattern=self._classify_time_pattern(failures),
                    severity_distribution=self._get_severity_distribution(failures),
                    suggested_fixes=self._suggest_fixes_for_component(component, failures),
                    confidence=min(1.0, len(failures) / 15.0)
                )
                patterns.append(pattern)
        
        # Pattern 3: Error-type patterns
        error_failures = defaultdict(list)
        for failure in self.failures:
            error_failures[failure.error_type].append(failure)
        
        for error_type, failures in error_failures.items():
            if len(failures) >= 4:  # At least 4 failures
                pattern = FailurePattern(
                    pattern_id=f"error_{error_type}",
                    description=f"Frequent error type: {error_type}",
                    frequency=len(failures),
                    failure_rate=len(failures) / max(1, len(self.failures)),
                    common_errors=[error_type],
                    affected_intents=list(set(f.intent for f in failures)),
                    affected_components=list(set(f.component for f in failures)),
                    time_pattern=self._classify_time_pattern(failures),
                    severity_distribution=self._get_severity_distribution(failures),
                    suggested_fixes=self._suggest_fixes_for_error(error_type, failures),
                    confidence=min(1.0, len(failures) / 8.0)
                )
                patterns.append(pattern)
        
        return sorted(patterns, key=lambda p: p.confidence, reverse=True)
    
    def _analyze_trends(self) -> Dict[str, Any]:
        """Analyze failure trends over time."""
        if len(self.failures) < 2:
            return {"trend": "insufficient_data"}
        
        # Group failures by hour
        hourly_failures = defaultdict(int)
        for failure in self.failures:
            hour = datetime.fromisoformat(failure.timestamp).replace(minute=0, second=0, microsecond=0)
            hourly_failures[hour] += 1
        
        if len(hourly_failures) < 2:
            return {"trend": "insufficient_data"}
        
        # Calculate trend
        hours = sorted(hourly_failures.keys())
        counts = [hourly_failures[hour] for hour in hours]
        
        # Simple linear trend detection
        if len(counts) >= 3:
            recent_avg = statistics.mean(counts[-3:])
            earlier_avg = statistics.mean(counts[:3])
            
            if recent_avg > earlier_avg * 1.5:
                trend = "increasing"
            elif recent_avg < earlier_avg * 0.67:
                trend = "decreasing"
            else:
                trend = "stable"
        else:
            trend = "insufficient_data"
        
        return {
            "trend": trend,
            "hourly_distribution": dict(hourly_failures),
            "peak_hours": self._find_peak_hours(hourly_failures),
            "recent_change": recent_avg - earlier_avg if len(counts) >= 3 else 0
        }
    
    def _generate_recommendations(self, patterns: List[FailurePattern], trends: Dict[str, Any]) -> List[str]:
        """Generate recommendations based on patterns and trends."""
        recommendations = []
        
        # High-priority patterns
        high_confidence_patterns = [p for p in patterns if p.confidence > 0.7]
        
        if high_confidence_patterns:
            recommendations.append("Address high-confidence failure patterns first")
            
            for pattern in high_confidence_patterns[:3]:
                recommendations.extend(pattern.suggested_fixes[:2])
        
        # Trend-based recommendations
        if trends.get("trend") == "increasing":
            recommendations.append("Failure rate is increasing - investigate root causes immediately")
        elif trends.get("trend") == "stable":
            recommendations.append("Failure rate is stable - focus on pattern elimination")
        
        # Component-specific recommendations
        if patterns:
            problematic_components = [p for p in patterns if "component" in p.pattern_id]
            if problematic_components:
                recommendations.append("Consider improving reliability of problematic components")
        
        # Recovery recommendations
        recovery_failures = [f for f in self.failures if f.recovery_attempted and not f.recovery_successful]
        if len(recovery_failures) > len(self.failures) * 0.3:
            recommendations.append("Improve recovery mechanisms - many recovery attempts are failing")
        
        # General recommendations
        if len(self.failures) > 100:
            recommendations.append("Consider implementing circuit breakers for frequently failing operations")
        
        return recommendations
    
    def _classify_time_pattern(self, failures: List[FailureRecord]) -> str:
        """Classify the time pattern of failures."""
        if not failures:
            return "unknown"
        
        timestamps = [datetime.fromisoformat(f.timestamp) for f in failures]
        timestamps.sort()
        
        # Check if failures are clustered
        if len(timestamps) < 2:
            return "sporadic"
        
        # Calculate time spans
        total_span = (timestamps[-1] - timestamps[0]).total_seconds() / 3600  # hours
        avg_gap = total_span / (len(timestamps) - 1)
        
        if avg_gap < 1:  # Less than 1 hour between failures on average
            return "recent"
        elif avg_gap < 24:  # Less than 1 day between failures
            return "persistent"
        else:
            return "sporadic"
    
    def _get_severity_distribution(self, failures: List[FailureRecord]) -> Dict[str, int]:
        """Get distribution of severity levels."""
        return dict(Counter(f.severity for f in failures))
    
    def _suggest_fixes_for_intent(self, intent: str, failures: List[FailureRecord]) -> List[str]:
        """Suggest fixes for intent-specific failures."""
        fixes = []
        
        common_errors = [f.error_type for f in failures]
        if "TimeoutError" in common_errors:
            fixes.append("Increase timeout for this operation")
        if "ConnectionError" in common_errors:
            fixes.append("Implement retry logic with exponential backoff")
        if "ValueError" in common_errors:
            fixes.append("Add input validation for this intent")
        
        if len(failures) > 5:
            fixes.append("Consider creating a specialized handler for this intent")
        
        return fixes
    
    def _suggest_fixes_for_component(self, component: str, failures: List[FailureRecord]) -> List[str]:
        """Suggest fixes for component-specific failures."""
        fixes = []
        
        fixes.append(f"Review and improve {component} component reliability")
        
        if any(f.severity in ["high", "critical"] for f in failures):
            fixes.append(f"Add circuit breaker for {component} component")
        
        common_errors = [f.error_type for f in failures]
        if "ImportError" in common_errors or "ModuleNotFoundError" in common_errors:
            fixes.append("Fix import dependencies in component")
        
        return fixes
    
    def _suggest_fixes_for_error(self, error_type: str, failures: List[FailureRecord]) -> List[str]:
        """Suggest fixes for error-type specific failures."""
        fixes = []
        
        if error_type == "TimeoutError":
            fixes.append("Review timeout configurations and add adaptive timeouts")
        elif error_type == "ConnectionError":
            fixes.append("Implement connection pooling and retry mechanisms")
        elif error_type == "ValueError":
            fixes.append("Add comprehensive input validation")
        elif error_type == "KeyError":
            fixes.append("Add key existence checks and default values")
        elif error_type == "AttributeError":
            fixes.append("Review object interfaces and add defensive programming")
        
        return fixes
    
    def _find_peak_hours(self, hourly_failures: Dict[datetime, int]) -> List[int]:
        """Find peak failure hours."""
        if not hourly_failures:
            return []
        
        hour_counts = defaultdict(int)
        for hour, count in hourly_failures.items():
            hour_counts[hour.hour] += count
        
        max_count = max(hour_counts.values())
        peak_hours = [hour for hour, count in hour_counts.items() if count == max_count]
        
        return peak_hours
    
    def _count_intent_attempts(self, intent: str) -> int:
        """Estimate total attempts for an intent (including successes)."""
        # This would ideally track total attempts, not just failures
        # For now, use failure count as a lower bound
        return len([f for f in self.failures if f.intent == intent])
    
    def _count_component_attempts(self, component: str) -> int:
        """Estimate total attempts for a component."""
        return len([f for f in self.failures if f.component == component])
    
    def _generate_failure_id(self) -> str:
        """Generate unique failure ID."""
        import uuid
        return f"failure_{uuid.uuid4().hex[:8]}"
    
    def get_statistics(self) -> Dict[str, Any]:
        """Get basic failure statistics."""
        if not self.failures:
            return {"total_failures": 0}
        
        return {
            "total_failures": len(self.failures),
            "last_24h": len(self.get_failures_by_timeframe(24)),
            "last_7d": len(self.get_failures_by_timeframe(24 * 7)),
            "recovery_rate": len([f for f in self.failures if f.recovery_successful]) / max(1, len([f for f in self.failures if f.recovery_attempted])),
            "critical_failures": len([f for f in self.failures if f.severity == "critical"]),
            "most_common_error": Counter(f.error_type for f in self.failures).most_common(1)[0] if self.failures else None
        }
    
    def clear_old_failures(self, days: int = 30):
        """Clear failures older than specified days."""
        cutoff = datetime.now() - timedelta(days=days)
        original_count = len(self.failures)
        
        self.failures = [f for f in self.failures 
                        if datetime.fromisoformat(f.timestamp) >= cutoff]
        
        cleared_count = original_count - len(self.failures)
        if cleared_count > 0:
            self._analysis_cache = {}  # Clear cache after removing data
        
        return cleared_count


# Global failure memory instance
_failure_memory = None

def get_failure_memory() -> FailureMemory:
    """Get or create the global failure memory instance."""
    global _failure_memory
    if _failure_memory is None:
        _failure_memory = FailureMemory()
    return _failure_memory

def log_failure(intent: str, error: Exception, **kwargs) -> str:
    """Quick access function for logging failures."""
    memory = get_failure_memory()
    return memory.log_failure(intent, error, **kwargs)

def get_failure_analysis() -> FailureAnalysis:
    """Quick access function for failure analysis."""
    memory = get_failure_memory()
    return memory.analyze_failures()
