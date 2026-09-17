"""
Issue Detection & Auto-Resolution API.

Monitors system health, detects issues proactively, and attempts automatic resolution.

Usage:
    from tiannara_api.routes.monitoring import router
    
    app.include_router(router, prefix="/api/v1/monitoring")
"""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime
import logging

from tiannara_core.evaluation.issue_detection_system import (
    IssueDetector,
    AutoResolver,
    IssueSeverity,
    IssueCategory
)

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/monitoring",
    tags=["monitoring", "issues", "auto-resolution"],
    responses={404: {"description": "Not found"}},
)

# Initialize monitoring components
_issue_detector = None
_resolution_system = None


def get_issue_detector() -> IssueDetector:  # Changed return type
    """Get or create issue detector singleton."""
    global _issue_detector
    if _issue_detector is None:
        _issue_detector = IssueDetector()  # Changed from IssueDetectionEngine()
    return _issue_detector


def get_resolution_system() -> AutoResolver:
    """Get or create resolution system singleton."""
    global _resolution_system
    if _resolution_system is None:
        _resolution_system = AutoResolver()
    return _resolution_system


# ============================================================================
# Request/Response Models
# ============================================================================

class MetricUpdate(BaseModel):
    """System metric update."""
    metric_name: str = Field(..., description="Metric name: response_time, error_rate, memory_usage, etc.")
    value: float = Field(..., description="Current metric value")
    timestamp: Optional[str] = Field(default=None, description="ISO format timestamp")


class IssueResponse(BaseModel):
    """Detected issue."""
    id: str
    category: str
    severity: str
    description: str
    detected_at: str
    status: str
    auto_resolved: bool
    resolution_action: Optional[str] = None


class MonitoringDashboard(BaseModel):
    """Monitoring dashboard data."""
    active_issues: int
    resolved_today: int
    system_health: str
    metrics_summary: Dict[str, Any]
    recent_issues: List[IssueResponse]


# ============================================================================
# API Endpoints
# ============================================================================

@router.post("/metrics/update")
async def update_metric(metric: MetricUpdate):
    """
    Update system metric for monitoring.
    
    Call this endpoint regularly to feed metrics into the detection engine.
    
    **Example:**
    ```json
    {
        "metric_name": "response_time_ms",
        "value": 250.5,
        "timestamp": "2026-05-07T10:30:00"
    }
    ```
    """
    try:
        engine = get_issue_detector()
        
        # Record metric
        engine.record_metric(
            metric_name=metric.metric_name,
            value=metric.value,
            timestamp=metric.timestamp or datetime.now().isoformat()
        )
        
        return {
            "success": True,
            "message": f"Metric '{metric.metric_name}' recorded",
            "value": metric.value
        }
        
    except Exception as e:
        logger.error(f"Failed to update metric: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/issues/active")
async def get_active_issues(
    severity: Optional[str] = None,
    category: Optional[str] = None,
    limit: int = 50
):
    """
    Get list of active (unresolved) issues.
    
    Filter by severity or category if needed.
    """
    try:
        engine = get_issue_detector()
        
        # Get all issues
        all_issues = engine.get_all_issues()
        
        # Filter active issues
        active_issues = [i for i in all_issues if i.status == "active"]
        
        # Apply filters
        if severity:
            active_issues = [i for i in active_issues if i.severity.value == severity]
        if category:
            active_issues = [i for i in active_issues if i.category.value == category]
        
        # Sort by severity (critical first)
        severity_order = {"critical": 0, "high": 1, "medium": 2, "low": 3}
        active_issues.sort(key=lambda x: severity_order.get(x.severity.value, 4))
        
        # Limit results
        active_issues = active_issues[:limit]
        
        return {
            "success": True,
            "total_active": len(active_issues),
            "issues": [
                {
                    "id": issue.id,
                    "category": issue.category.value,
                    "severity": issue.severity.value,
                    "description": issue.description,
                    "detected_at": issue.detected_at.isoformat(),
                    "status": issue.status
                }
                for issue in active_issues
            ]
        }
        
    except Exception as e:
        logger.error(f"Failed to get active issues: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/issues/{issue_id}/resolve")
async def resolve_issue(issue_id: str, action: Optional[str] = None):
    """
    Manually resolve an issue or trigger auto-resolution.
    
    If action is provided, use that specific resolution strategy.
    Otherwise, let the system choose the best action.
    """
    try:
        resolution_system = get_resolution_system()
        
        # Attempt resolution
        result = resolution_system.resolve_issue(
            issue_id=issue_id,
            forced_action=action
        )
        
        return {
            "success": result["success"],
            "issue_id": issue_id,
            "action_taken": result.get("action"),
            "message": result.get("message", "Issue resolved"),
            "requires_human_review": result.get("requires_human_review", False)
        }
        
    except Exception as e:
        logger.error(f"Failed to resolve issue: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/scan")
async def scan_for_issues():
    """
    Trigger immediate scan for all issue types.
    
    Checks performance, errors, memory, API failures, and prediction accuracy.
    """
    try:
        engine = get_issue_detector()
        
        # Run all detectors
        issues_found = []
        
        # Performance check
        perf_issues = engine.detect_performance_degradation()
        issues_found.extend(perf_issues)
        
        # Error rate check
        error_issues = engine.detect_error_rate_spike()
        issues_found.extend(error_issues)
        
        # Memory leak check
        memory_issues = engine.detect_memory_leak()
        issues_found.extend(memory_issues)
        
        # API failure check
        api_issues = engine.detect_api_failures()
        issues_found.extend(api_issues)
        
        # Prediction accuracy check
        pred_issues = engine.detect_prediction_accuracy_drop()
        issues_found.extend(pred_issues)
        
        # Auto-resolve where possible
        resolution_system = get_resolution_system()
        auto_resolved = 0
        
        for issue in issues_found:
            if issue.severity in [IssueSeverity.LOW, IssueSeverity.MEDIUM]:
                try:
                    resolution_system.resolve_issue(issue.id)
                    auto_resolved += 1
                except Exception:
                    pass  # Some issues need manual intervention
        
        return {
            "success": True,
            "scan_timestamp": datetime.now().isoformat(),
            "issues_found": len(issues_found),
            "auto_resolved": auto_resolved,
            "requires_attention": len(issues_found) - auto_resolved,
            "issues": [
                {
                    "id": issue.id,
                    "category": issue.category.value,
                    "severity": issue.severity.value,
                    "description": issue.description,
                    "auto_resolved": issue.status == "resolved"
                }
                for issue in issues_found
            ]
        }
        
    except Exception as e:
        logger.error(f"Scan failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/dashboard")
async def get_monitoring_dashboard():
    """
    Get comprehensive monitoring dashboard data.
    
    Includes active issues, system health, metrics summary, and recent activity.
    """
    try:
        engine = get_issue_detector()
        resolution_system = get_resolution_system()
        
        # Get all issues
        all_issues = engine.get_all_issues()
        active_issues = [i for i in all_issues if i.status == "active"]
        resolved_today = [
            i for i in all_issues 
            if i.status == "resolved" and 
            i.resolved_at and 
            i.resolved_at.date() == datetime.now().date()
        ]
        
        # Determine system health
        critical_count = sum(1 for i in active_issues if i.severity == IssueSeverity.CRITICAL)
        high_count = sum(1 for i in active_issues if i.severity == IssueSeverity.HIGH)
        
        if critical_count > 0:
            system_health = "critical"
        elif high_count > 2:
            system_health = "degraded"
        elif len(active_issues) > 10:
            system_health = "warning"
        else:
            system_health = "healthy"
        
        # Get metrics summary
        metrics_summary = engine.get_metrics_summary()
        
        # Get recent issues (last 10)
        recent_issues = sorted(
            all_issues,
            key=lambda x: x.detected_at,
            reverse=True
        )[:10]
        
        return {
            "success": True,
            "dashboard": {
                "active_issues": len(active_issues),
                "resolved_today": len(resolved_today),
                "system_health": system_health,
                "metrics_summary": metrics_summary,
                "recent_issues": [
                    {
                        "id": issue.id,
                        "category": issue.category.value,
                        "severity": issue.severity.value,
                        "description": issue.description,
                        "detected_at": issue.detected_at.isoformat(),
                        "status": issue.status,
                        "auto_resolved": issue.resolution_history[-1].get("auto_resolved", False) if issue.resolution_history else False
                    }
                    for issue in recent_issues
                ]
            },
            "timestamp": datetime.now().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Dashboard fetch failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/health")
async def health_check():
    """Health check for monitoring system."""
    return {
        "status": "healthy",
        "components": {
            "detection_engine": "ready",
            "resolution_system": "ready",
            "monitors_active": True
        },
        "timestamp": datetime.now().isoformat()
    }
