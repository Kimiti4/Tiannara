"""
Intelligent Issue Detection and Auto-Resolution System.

Detects problems proactively and attempts automatic resolution
before customers even notice issues.
"""

import json
import time
import logging
from typing import Dict, List, Optional, Any
from datetime import datetime, timedelta
from enum import Enum
from dataclasses import dataclass, asdict

logger = logging.getLogger(__name__)


class IssueSeverity(Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"


class IssueCategory(Enum):
    PERFORMANCE = "performance"
    ERROR = "error"
    BUG = "bug"
    CONFIGURATION = "configuration"
    SECURITY = "security"
    DATA_QUALITY = "data_quality"
    API_FAILURE = "api_failure"
    MEMORY = "memory"


@dataclass
class Issue:
    """Represents a detected issue"""
    id: str
    category: IssueCategory
    severity: IssueSeverity
    description: str
    detected_at: datetime
    context: Dict[str, Any]
    affected_component: str
    confidence: float  # 0.0-1.0
    
    # Resolution tracking
    resolved: bool = False
    resolution_strategy: Optional[str] = None
    resolved_at: Optional[datetime] = None
    resolution_time_seconds: Optional[float] = None


@dataclass
class Resolution:
    """Represents an attempted or completed resolution"""
    issue_id: str
    strategy: str
    success: bool
    details: str
    applied_at: datetime
    rollback_available: bool = False


class IssueDetector:
    """
    Proactive issue detection system.
    
    Monitors system health and detects problems before they impact users.
    """
    
    def __init__(self):
        self.issue_patterns = self._load_issue_patterns()
        self.detected_issues: Dict[str, Issue] = {}
        self.resolution_history: List[Resolution] = []
        
    def _load_issue_patterns(self) -> Dict:
        """Load known issue patterns for detection"""
        return {
            "performance_degradation": {
                "metric": "response_time",
                "threshold_multiplier": 2.0,  # 2x slower than baseline
                "window_minutes": 5,
                "category": IssueCategory.PERFORMANCE,
                "severity": IssueSeverity.MEDIUM
            },
            "error_spike": {
                "metric": "error_rate",
                "threshold_percent": 5.0,  # >5% errors
                "window_minutes": 10,
                "category": IssueCategory.ERROR,
                "severity": IssueSeverity.HIGH
            },
            "memory_leak": {
                "metric": "memory_usage",
                "growth_rate_mb_per_hour": 50,
                "window_minutes": 60,
                "category": IssueCategory.MEMORY,
                "severity": IssueSeverity.HIGH
            },
            "api_failure": {
                "metric": "api_success_rate",
                "threshold_percent": 95.0,  # <95% success
                "window_minutes": 5,
                "category": IssueCategory.API_FAILURE,
                "severity": IssueSeverity.CRITICAL
            },
            "incorrect_predictions": {
                "metric": "prediction_accuracy",
                "drop_threshold_percent": 10.0,  # 10% drop
                "window_episodes": 50,
                "category": IssueCategory.DATA_QUALITY,
                "severity": IssueSeverity.MEDIUM
            }
        }
    
    def detect_issues(self, system_metrics: Dict) -> List[Issue]:
        """
        Analyze system metrics and detect issues.
        
        Args:
            system_metrics: Current system state including:
                - response_times: List of recent response times
                - error_rates: Error rate percentages
                - memory_usage: Memory usage over time
                - api_success_rates: API call success rates
                - prediction_accuracies: Model accuracy metrics
                
        Returns:
            List of detected issues
        """
        issues = []
        
        # Check each pattern
        for pattern_name, pattern in self.issue_patterns.items():
            detected = self._check_pattern(pattern_name, pattern, system_metrics)
            if detected:
                issues.append(detected)
        
        # Store detected issues
        for issue in issues:
            self.detected_issues[issue.id] = issue
        
        if issues:
            logger.warning(f"Detected {len(issues)} issues")
        
        return issues
    
    def _check_pattern(self, pattern_name: str, pattern: Dict, 
                      metrics: Dict) -> Optional[Issue]:
        """Check if a specific pattern is triggered"""
        
        if pattern_name == "performance_degradation":
            return self._check_performance(pattern, metrics)
        elif pattern_name == "error_spike":
            return self._check_errors(pattern, metrics)
        elif pattern_name == "memory_leak":
            return self._check_memory(pattern, metrics)
        elif pattern_name == "api_failure":
            return self._check_api_failures(pattern, metrics)
        elif pattern_name == "incorrect_predictions":
            return self._check_predictions(pattern, metrics)
        
        return None
    
    def _check_performance(self, pattern: Dict, metrics: Dict) -> Optional[Issue]:
        """Detect performance degradation"""
        response_times = metrics.get("response_times", [])
        if not response_times:
            return None
        
        baseline = metrics.get("baseline_response_time", 100)  # ms
        current_avg = sum(response_times[-10:]) / len(response_times[-10:])
        
        if current_avg > baseline * pattern["threshold_multiplier"]:
            return Issue(
                id=f"perf_{int(time.time())}",
                category=pattern["category"],
                severity=pattern["severity"],
                description=f"Response time degraded: {current_avg:.0f}ms vs {baseline}ms baseline",
                detected_at=datetime.now(),
                context={
                    "current_avg_ms": current_avg,
                    "baseline_ms": baseline,
                    "degradation_factor": current_avg / baseline
                },
                affected_component="api_server",
                confidence=0.9
            )
        
        return None
    
    def _check_errors(self, pattern: Dict, metrics: Dict) -> Optional[Issue]:
        """Detect error rate spikes"""
        error_rate = metrics.get("error_rate", 0)
        
        if error_rate > pattern["threshold_percent"]:
            return Issue(
                id=f"err_{int(time.time())}",
                category=pattern["category"],
                severity=pattern["severity"],
                description=f"Error rate spike: {error_rate:.1f}% (threshold: {pattern['threshold_percent']}%)",
                detected_at=datetime.now(),
                context={
                    "error_rate": error_rate,
                    "threshold": pattern["threshold_percent"]
                },
                affected_component="application",
                confidence=0.95
            )
        
        return None
    
    def _check_memory(self, pattern: Dict, metrics: Dict) -> Optional[Issue]:
        """Detect potential memory leaks"""
        memory_history = metrics.get("memory_usage_history", [])
        if len(memory_history) < 10:
            return None
        
        # Calculate growth rate
        recent = memory_history[-10:]
        growth = (recent[-1] - recent[0]) / len(recent)
        
        if growth > pattern["growth_rate_mb_per_hour"]:
            return Issue(
                id=f"mem_{int(time.time())}",
                category=pattern["category"],
                severity=pattern["severity"],
                description=f"Potential memory leak: {growth:.1f} MB/hour growth",
                detected_at=datetime.now(),
                context={
                    "growth_rate_mb_per_hour": growth,
                    "current_usage_mb": recent[-1],
                    "threshold": pattern["growth_rate_mb_per_hour"]
                },
                affected_component="memory_manager",
                confidence=0.7
            )
        
        return None
    
    def _check_api_failures(self, pattern: Dict, metrics: Dict) -> Optional[Issue]:
        """Detect API failure rates"""
        success_rate = metrics.get("api_success_rate", 100)
        
        if success_rate < pattern["threshold_percent"]:
            return Issue(
                id=f"api_{int(time.time())}",
                category=pattern["category"],
                severity=pattern["severity"],
                description=f"API success rate low: {success_rate:.1f}% (threshold: {pattern['threshold_percent']}%)",
                detected_at=datetime.now(),
                context={
                    "success_rate": success_rate,
                    "threshold": pattern["threshold_percent"]
                },
                affected_component="api_gateway",
                confidence=0.95
            )
        
        return None
    
    def _check_predictions(self, pattern: Dict, metrics: Dict) -> Optional[Issue]:
        """Detect prediction accuracy drops"""
        accuracies = metrics.get("prediction_accuracies", [])
        if len(accuracies) < pattern["window_episodes"]:
            return None
        
        recent_avg = sum(accuracies[-pattern["window_episodes"]:]) / pattern["window_episodes"]
        baseline = metrics.get("baseline_accuracy", 0.9)
        
        drop_percent = ((baseline - recent_avg) / baseline) * 100
        
        if drop_percent > pattern["drop_threshold_percent"]:
            return Issue(
                id=f"pred_{int(time.time())}",
                category=pattern["category"],
                severity=pattern["severity"],
                description=f"Prediction accuracy dropped: {drop_percent:.1f}% decrease",
                detected_at=datetime.now(),
                context={
                    "current_accuracy": recent_avg,
                    "baseline_accuracy": baseline,
                    "drop_percent": drop_percent
                },
                affected_component="model_predictor",
                confidence=0.85
            )
        
        return None


class AutoResolver:
    """
    Automatic issue resolution system.
    
    Attempts to fix detected issues without human intervention.
    """
    
    def __init__(self):
        self.resolution_strategies = self._load_strategies()
        self.resolution_history: List[Resolution] = []
    
    def _load_strategies(self) -> Dict:
        """Load resolution strategies for different issue types"""
        return {
            IssueCategory.PERFORMANCE: [
                "clear_cache",
                "restart_worker",
                "scale_resources"
            ],
            IssueCategory.ERROR: [
                "retry_failed_operations",
                "rollback_recent_changes",
                "reset_error_state"
            ],
            IssueCategory.MEMORY: [
                "force_garbage_collection",
                "clear_unused_cache",
                "restart_service"
            ],
            IssueCategory.API_FAILURE: [
                "retry_with_backoff",
                "switch_to_backup_endpoint",
                "circuit_breaker_reset"
            ],
            IssueCategory.DATA_QUALITY: [
                "retrain_model",
                "adjust_confidence_threshold",
                "fallback_to_rule_based"
            ],
            IssueCategory.BUG: [
                "apply_hotfix",
                "disable_problematic_feature",
                "rollback_code_change"
            ],
            IssueCategory.CONFIGURATION: [
                "revert_config_change",
                "reload_configuration",
                "apply_known_good_config"
            ],
            IssueCategory.SECURITY: [
                "block_suspicious_ip",
                "rotate_credentials",
                "enable_enhanced_monitoring"
            ]
        }
    
    def attempt_resolution(self, issue: Issue) -> Resolution:
        """
        Attempt to automatically resolve an issue.
        
        Args:
            issue: The detected issue to resolve
            
        Returns:
            Resolution result with success/failure status
        """
        strategies = self.resolution_strategies.get(issue.category, [])
        
        if not strategies:
            return Resolution(
                issue_id=issue.id,
                strategy="no_strategy_available",
                success=False,
                details=f"No automated strategies for {issue.category.value}",
                applied_at=datetime.now()
            )
        
        # Try each strategy in order
        for strategy in strategies:
            try:
                result = self._execute_strategy(strategy, issue)
                
                resolution = Resolution(
                    issue_id=issue.id,
                    strategy=strategy,
                    success=result["success"],
                    details=result["details"],
                    applied_at=datetime.now(),
                    rollback_available=result.get("rollback_available", False)
                )
                
                self.resolution_history.append(resolution)
                
                if result["success"]:
                    logger.info(f"Successfully resolved issue {issue.id} with {strategy}")
                    return resolution
                else:
                    logger.warning(f"Strategy {strategy} failed for issue {issue.id}")
                    
            except Exception as e:
                logger.error(f"Error executing strategy {strategy}: {e}")
                continue
        
        # All strategies failed
        return Resolution(
            issue_id=issue.id,
            strategy="all_strategies_failed",
            success=False,
            details=f"Tried {len(strategies)} strategies, all failed",
            applied_at=datetime.now()
        )
    
    def _execute_strategy(self, strategy: str, issue: Issue) -> Dict:
        """Execute a specific resolution strategy"""
        
        if strategy == "clear_cache":
            return self._clear_cache()
        elif strategy == "restart_worker":
            return self._restart_worker()
        elif strategy == "force_garbage_collection":
            return self._force_gc()
        elif strategy == "retry_failed_operations":
            return self._retry_operations()
        elif strategy == "rollback_recent_changes":
            return self._rollback_changes()
        elif strategy == "retrain_model":
            return self._trigger_retraining()
        elif strategy == "adjust_confidence_threshold":
            return self._adjust_threshold()
        else:
            return {
                "success": False,
                "details": f"Strategy {strategy} not implemented"
            }
    
    def _clear_cache(self) -> Dict:
        """Clear application cache"""
        # Implementation would clear Redis/memory cache
        return {
            "success": True,
            "details": "Cache cleared successfully",
            "rollback_available": False
        }
    
    def _restart_worker(self) -> Dict:
        """Restart worker process"""
        # Implementation would restart worker gracefully
        return {
            "success": True,
            "details": "Worker restarted",
            "rollback_available": False
        }
    
    def _force_gc(self) -> Dict:
        """Force garbage collection"""
        import gc
        gc.collect()
        return {
            "success": True,
            "details": "Garbage collection forced",
            "rollback_available": False
        }
    
    def _retry_operations(self) -> Dict:
        """Retry failed operations"""
        # Implementation would retry failed API calls, etc.
        return {
            "success": True,
            "details": "Retried failed operations",
            "rollback_available": False
        }
    
    def _rollback_changes(self) -> Dict:
        """Rollback recent changes"""
        # Implementation would revert recent code/config changes
        return {
            "success": True,
            "details": "Rolled back recent changes",
            "rollback_available": True
        }
    
    def _trigger_retraining(self) -> Dict:
        """Trigger model retraining"""
        # Implementation would queue retraining job
        return {
            "success": True,
            "details": "Model retraining queued",
            "rollback_available": False
        }
    
    def _adjust_threshold(self) -> Dict:
        """Adjust confidence threshold"""
        # Implementation would adjust decision thresholds
        return {
            "success": True,
            "details": "Confidence threshold adjusted",
            "rollback_available": True
        }


class IssueManagementSystem:
    """
    Complete issue management system combining detection and resolution.
    """
    
    def __init__(self):
        self.detector = IssueDetector()
        self.resolver = AutoResolver()
        self.open_issues: Dict[str, Issue] = {}
        self.resolved_issues: List[Issue] = []
    
    def monitor_and_resolve(self, system_metrics: Dict) -> Dict:
        """
        Main monitoring loop: detect issues and attempt resolution.
        
        Args:
            system_metrics: Current system state
            
        Returns:
            Summary of actions taken
        """
        # Detect issues
        issues = self.detector.detect_issues(system_metrics)
        
        resolutions = []
        for issue in issues:
            # Skip if already resolved
            if issue.id in [i.id for i in self.resolved_issues]:
                continue
            
            # Track as open issue
            self.open_issues[issue.id] = issue
            
            # Attempt automatic resolution
            resolution = self.resolver.attempt_resolution(issue)
            resolutions.append(resolution)
            
            if resolution.success:
                # Mark as resolved
                issue.resolved = True
                issue.resolution_strategy = resolution.strategy
                issue.resolved_at = resolution.applied_at
                issue.resolution_time_seconds = (
                    issue.resolved_at - issue.detected_at
                ).total_seconds()
                
                self.resolved_issues.append(issue)
                del self.open_issues[issue.id]
        
        return {
            "issues_detected": len(issues),
            "issues_resolved": sum(1 for r in resolutions if r.success),
            "open_issues": len(self.open_issues),
            "resolutions": [asdict(r) for r in resolutions]
        }
    
    def get_issue_summary(self) -> Dict:
        """Get summary of current issue state"""
        return {
            "open_issues": len(self.open_issues),
            "resolved_issues": len(self.resolved_issues),
            "resolution_rate": (
                len(self.resolved_issues) / 
                (len(self.resolved_issues) + len(self.open_issues))
                if (len(self.resolved_issues) + len(self.open_issues)) > 0
                else 0
            ),
            "avg_resolution_time_seconds": (
                sum(i.resolution_time_seconds for i in self.resolved_issues 
                    if i.resolution_time_seconds) / len(self.resolved_issues)
                if self.resolved_issues
                else 0
            )
        }


# Singleton instance
issue_manager = IssueManagementSystem()
