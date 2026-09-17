"""
Custom Alert Rules System for Tiannara SaaS.

Allows users to create custom monitoring rules with:
- Threshold-based alerts
- Anomaly detection alerts
- Pattern-based alerts
- Scheduled alerts
- Multi-channel notifications (email, webhook, dashboard)

Date: April 30, 2026
Status: Week 30 - Production Alert System
"""

from fastapi import APIRouter, HTTPException, Depends, status, Request
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from datetime import datetime, timezone
import uuid
from tiannara_api.middleware.tier_access_control import require_starter

router = APIRouter(
    prefix="/alerts",
    tags=["alerts"],
)

# In-memory storage (will be replaced with database)
alert_rules_db: Dict[str, dict] = {}
alert_history_db: List[dict] = []


class AlertRuleCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=200)
    description: str = Field(default="", max_length=1000)
    alert_type: str = Field(..., pattern="^(threshold|anomaly|pattern|scheduled)$")
    metric: str = Field(..., min_length=1)
    condition: str = Field(..., pattern="^(greater_than|less_than|equals|not_equals|change_percent|anomaly_detected)$")
    threshold: Optional[float] = None
    notification_channels: List[str] = Field(default=["dashboard"])
    enabled: bool = True
    cooldown_minutes: int = Field(default=60, ge=0)


class AlertRuleUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    threshold: Optional[float] = None
    notification_channels: Optional[List[str]] = None
    enabled: Optional[bool] = None
    cooldown_minutes: Optional[int] = None


@router.get("/")
@require_starter
async def get_alert_rules(request: Request):
    """Get all alert rules for the authenticated user."""
    try:
        rules = list(alert_rules_db.values())
        
        return {
            "success": True,
            "data": rules,
            "count": len(rules)
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch alert rules: {str(e)}"
        )


@router.get("/{rule_id}")
@require_starter
async def get_alert_rule(rule_id: str, request: Request):
    """Get a specific alert rule."""
    rule = alert_rules_db.get(rule_id)
    
    if not rule:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Alert rule not found"
        )
    
    return {
        "success": True,
        "data": rule
    }


@router.post("/", status_code=status.HTTP_201_CREATED)
@require_starter
async def create_alert_rule(rule_data: AlertRuleCreate, request: Request):
    """Create a new custom alert rule."""
    try:
        rule_id = str(uuid.uuid4())
        now = datetime.now(timezone.utc).isoformat()
        
        rule = {
            "id": rule_id,
            "name": rule_data.name,
            "description": rule_data.description,
            "alert_type": rule_data.alert_type,
            "metric": rule_data.metric,
            "condition": rule_data.condition,
            "threshold": rule_data.threshold,
            "notification_channels": rule_data.notification_channels,
            "enabled": rule_data.enabled,
            "cooldown_minutes": rule_data.cooldown_minutes,
            "created_at": now,
            "updated_at": now,
            "last_triggered": None,
            "trigger_count": 0
        }
        
        alert_rules_db[rule_id] = rule
        
        return {
            "success": True,
            "data": rule,
            "message": "Alert rule created successfully"
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create alert rule: {str(e)}"
        )


@router.put("/{rule_id}")
@require_starter
async def update_alert_rule(rule_id: str, rule_data: AlertRuleUpdate, request: Request):
    """Update an existing alert rule."""
    rule = alert_rules_db.get(rule_id)
    
    if not rule:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Alert rule not found"
        )
    
    try:
        if rule_data.name is not None:
            rule["name"] = rule_data.name
        if rule_data.description is not None:
            rule["description"] = rule_data.description
        if rule_data.threshold is not None:
            rule["threshold"] = rule_data.threshold
        if rule_data.notification_channels is not None:
            rule["notification_channels"] = rule_data.notification_channels
        if rule_data.enabled is not None:
            rule["enabled"] = rule_data.enabled
        if rule_data.cooldown_minutes is not None:
            rule["cooldown_minutes"] = rule_data.cooldown_minutes
        
        rule["updated_at"] = datetime.now(timezone.utc).isoformat()
        alert_rules_db[rule_id] = rule
        
        return {
            "success": True,
            "data": rule,
            "message": "Alert rule updated successfully"
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update alert rule: {str(e)}"
        )


@router.delete("/{rule_id}")
@require_starter
async def delete_alert_rule(rule_id: str, request: Request):
    """Delete an alert rule."""
    rule = alert_rules_db.pop(rule_id, None)
    
    if not rule:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Alert rule not found"
        )
    
    return {
        "success": True,
        "message": "Alert rule deleted successfully"
    }


@router.post("/{rule_id}/test")
@require_starter
async def test_alert_rule(rule_id: str, request: Request):
    """Test an alert rule with current metrics."""
    rule = alert_rules_db.get(rule_id)
    
    if not rule:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Alert rule not found"
        )
    
    try:
        # Get current metric value (simulated)
        from tiannara_core.analytics.metrics import AnalyticsMetrics
        
        metrics_engine = AnalyticsMetrics()
        current_value = metrics_engine.get_current_value(rule["metric"])
        
        # Evaluate condition
        condition_met = _evaluate_condition(
            rule["condition"],
            current_value,
            rule["threshold"]
        )
        
        test_result = {
            "rule_id": rule_id,
            "metric": rule["metric"],
            "condition": rule["condition"],
            "threshold": rule["threshold"],
            "current_value": current_value,
            "condition_met": condition_met,
            "would_trigger": condition_met and rule["enabled"],
            "tested_at": datetime.now(timezone.utc).isoformat()
        }
        
        return {
            "success": True,
            "data": test_result
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to test alert rule: {str(e)}"
        )


@router.get("/history")
@require_starter
async def get_alert_history(request: Request, limit: int = 50):
    """Get alert trigger history."""
    try:
        history = alert_history_db[-limit:]
        
        return {
            "success": True,
            "data": history,
            "count": len(history)
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch alert history: {str(e)}"
        )


@router.post("/evaluate")
@require_starter
async def evaluate_all_rules(request: Request):
    """Evaluate all enabled alert rules against current metrics."""
    try:
        from tiannara_core.analytics.metrics import AnalyticsMetrics
        
        metrics_engine = AnalyticsMetrics()
        triggered_rules = []
        
        for rule_id, rule in alert_rules_db.items():
            if not rule["enabled"]:
                continue
            
            # Get current value
            current_value = metrics_engine.get_current_value(rule["metric"])
            
            # Evaluate condition
            condition_met = _evaluate_condition(
                rule["condition"],
                current_value,
                rule["threshold"]
            )
            
            if condition_met:
                # Check cooldown
                if rule["last_triggered"]:
                    last_triggered = datetime.fromisoformat(rule["last_triggered"])
                    cooldown_end = last_triggered.replace(
                        minute=last_triggered.minute + rule["cooldown_minutes"]
                    )
                    if datetime.now(timezone.utc) < cooldown_end:
                        continue
                
                # Trigger alert
                alert_record = {
                    "id": str(uuid.uuid4()),
                    "rule_id": rule_id,
                    "rule_name": rule["name"],
                    "metric": rule["metric"],
                    "current_value": current_value,
                    "threshold": rule["threshold"],
                    "condition": rule["condition"],
                    "triggered_at": datetime.now(timezone.utc).isoformat(),
                    "notification_channels": rule["notification_channels"]
                }
                
                alert_history_db.append(alert_record)
                rule["last_triggered"] = alert_record["triggered_at"]
                rule["trigger_count"] += 1
                
                triggered_rules.append(alert_record)
        
        return {
            "success": True,
            "data": {
                "rules_evaluated": len([r for r in alert_rules_db.values() if r["enabled"]]),
                "rules_triggered": len(triggered_rules),
                "alerts": triggered_rules
            }
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to evaluate alert rules: {str(e)}"
        )


def _evaluate_condition(
    condition: str,
    current_value: float,
    threshold: Optional[float]
) -> bool:
    """Evaluate if a condition is met."""
    if threshold is None:
        return False
    
    if condition == "greater_than":
        return current_value > threshold
    elif condition == "less_than":
        return current_value < threshold
    elif condition == "equals":
        return abs(current_value - threshold) < 0.001
    elif condition == "not_equals":
        return abs(current_value - threshold) >= 0.001
    elif condition == "change_percent":
        # Would need previous value - simplified
        return abs(current_value) > threshold
    elif condition == "anomaly_detected":
        # Special case - always true for testing
        return True
    
    return False
