"""
MAPE-K Security Routes for Tiannara API

Endpoints for autonomous adversarial security intelligence:
- Monitor threats and anomalies
- Analyze attack patterns causally
- Plan defensive strategies
- Execute countermeasures
- Query security knowledge memory

Based on: tiannara_api/sec-evolve.md (Phase 15)

Date: May 1, 2026
Status: Week 28 Day 10 - MAPE-K Security Implementation
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query, Request
from sqlalchemy.orm import Session
from typing import Optional, List
import json

from tiannara_api.database import get_db
from tiannara_api.database.model_classes.mapek_security import (
    SecurityEvent,
    SecurityAnalysis,
    DefensePlan,
    DefenseExecution,
    SecurityKnowledge,
    ThreatLevel,
    AttackType,
    DefenseAction,
)
from tiannara_api.services.mapek_security import MAPEKSecurityEngine
from tiannara_api.routes.auth import get_current_user

router = APIRouter(prefix="/security", tags=["MAPE-K Security"])


# ==================== Request/Response Models ====================

from pydantic import BaseModel, Field
from typing import Dict, Any


class ReportThreatRequest(BaseModel):
    """Report a detected threat."""
    source_ip: str = Field(..., description="Source IP address")
    user_id: Optional[str] = Field(None, description="User ID if authenticated")
    attack_type: AttackType = Field(..., description="Type of attack detected")
    severity: ThreatLevel = Field(ThreatLevel.MEDIUM, description="Threat severity")
    description: str = Field(..., description="Detailed description")
    payload_sample: Optional[str] = Field(None, description="Sample of malicious payload")
    metadata: Dict[str, Any] = Field(default_factory=dict, description="Additional context")


class ExecuteDefenseRequest(BaseModel):
    """Execute a planned defense."""
    plan_id: str = Field(..., description="Defense plan ID")
    force: bool = Field(False, description="Force execution without validation")


class SimulateAttackRequest(BaseModel):
    """Simulate an attack for testing."""
    target_module: str = Field(..., description="Target module to test")
    attack_type: AttackType = Field(..., description="Type of attack to simulate")
    constraints: Dict[str, Any] = Field(default_factory=dict, description="Attack constraints")


# ==================== MONITOR ENDPOINTS ====================

@router.post("/threats/report")
async def report_threat(
    request: ReportThreatRequest,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Report a detected security threat."""
    try:
        engine = MAPEKSecurityEngine(db)
        
        event = engine.monitor_threat(
            source_ip=request.source_ip,
            user_id=request.user_id or current_user.get("user", {}).get("id"),
            attack_type=request.attack_type,
            severity=request.severity,
            description=request.description,
            payload_sample=request.payload_sample,
            metadata=request.metadata
        )
        
        return {
            "status": "success",
            "event_id": event.id,
            "message": "Threat reported and queued for analysis"
        }
    
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))


@router.get("/threats/recent")
async def get_recent_threats(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
    limit: int = Query(50, ge=1, le=500, description="Number of events"),
    severity: Optional[ThreatLevel] = Query(None, description="Filter by severity"),
    attack_type: Optional[AttackType] = Query(None, description="Filter by attack type")
):
    """Get recent security events."""
    query = db.query(SecurityEvent).order_by(SecurityEvent.detected_at.desc())
    
    if severity:
        query = query.filter(SecurityEvent.severity == severity.value)
    
    if attack_type:
        query = query.filter(SecurityEvent.attack_type == attack_type.value)
    
    events = query.limit(limit).all()
    
    return {
        "count": len(events),
        "events": [
            {
                "id": event.id,
                "attack_type": event.attack_type,
                "severity": event.severity,
                "source_ip": event.source_ip,
                "detected_at": event.detected_at.isoformat(),
                "description": event.description,
                "status": event.status
            }
            for event in events
        ]
    }


# ==================== ANALYZE ENDPOINTS ====================

@router.post("/analyze/{event_id}")
async def analyze_threat(
    event_id: str,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Perform causal analysis on a security event."""
    try:
        engine = MAPEKSecurityEngine(db)
        
        analysis = engine.analyze_threat(event_id)
        
        return {
            "status": "success",
            "analysis_id": analysis.id,
            "root_causes": analysis.root_causes,
            "vulnerability_score": analysis.vulnerability_score,
            "exploit_chain": analysis.exploit_chain,
            "recommendations": analysis.recommendations
        }
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))


@router.get("/analysis/recent")
async def get_recent_analysis(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
    limit: int = Query(20, ge=1, le=100)
):
    """Get recent security analyses."""
    analyses = db.query(SecurityAnalysis).order_by(
        SecurityAnalysis.analyzed_at.desc()
    ).limit(limit).all()
    
    return {
        "count": len(analyses),
        "analyses": [
            {
                "id": a.id,
                "event_id": a.event_id,
                "vulnerability_score": a.vulnerability_score,
                "analyzed_at": a.analyzed_at.isoformat(),
                "root_causes_count": len(a.root_causes or [])
            }
            for a in analyses
        ]
    }


# ==================== PLAN ENDPOINTS ====================

@router.post("/plan/{analysis_id}")
async def create_defense_plan(
    analysis_id: str,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Generate a defensive strategy based on analysis."""
    try:
        engine = MAPEKSecurityEngine(db)
        
        plan = engine.plan_defense(analysis_id)
        
        return {
            "status": "success",
            "plan_id": plan.id,
            "actions": plan.proposed_actions,
            "priority": plan.priority,
            "estimated_impact": plan.estimated_impact
        }
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))


@router.get("/plans/pending")
async def get_pending_plans(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
    limit: int = Query(20, ge=1, le=100)
):
    """Get pending defense plans awaiting execution."""
    plans = db.query(DefensePlan).filter(
        DefensePlan.status == "pending"
    ).order_by(
        DefensePlan.created_at.desc()
    ).limit(limit).all()
    
    return {
        "count": len(plans),
        "plans": [
            {
                "id": p.id,
                "analysis_id": p.analysis_id,
                "priority": p.priority,
                "created_at": p.created_at.isoformat(),
                "actions_count": len(p.proposed_actions or [])
            }
            for p in plans
        ]
    }


# ==================== EXECUTE ENDPOINTS ====================

@router.post("/execute")
async def execute_defense(
    request: ExecuteDefenseRequest,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Execute a planned defense action."""
    try:
        engine = MAPEKSecurityEngine(db)
        
        execution = engine.execute_defense(
            plan_id=request.plan_id,
            executed_by=current_user.get("user", {}).get("id"),
            force=request.force
        )
        
        return {
            "status": "success",
            "execution_id": execution.id,
            "result": execution.result,
            "executed_at": execution.executed_at.isoformat()
        }
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))


@router.get("/executions/recent")
async def get_recent_executions(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
    limit: int = Query(20, ge=1, le=100)
):
    """Get recent defense executions."""
    executions = db.query(DefenseExecution).order_by(
        DefenseExecution.executed_at.desc()
    ).limit(limit).all()
    
    return {
        "count": len(executions),
        "executions": [
            {
                "id": e.id,
                "plan_id": e.plan_id,
                "status": e.status,
                "result": e.result,
                "executed_at": e.executed_at.isoformat()
            }
            for e in executions
        ]
    }


# ==================== KNOWLEDGE ENDPOINTS ====================

@router.get("/knowledge/search")
async def search_knowledge(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
    query: str = Query(..., description="Search query"),
    category: Optional[str] = Query(None, description="Filter by category"),
    limit: int = Query(20, ge=1, le=100)
):
    """Search security knowledge base."""
    from sqlalchemy import or_
    
    db_query = db.query(SecurityKnowledge).filter(
        or_(
            SecurityKnowledge.title.ilike(f"%{query}%"),
            SecurityKnowledge.description.ilike(f"%{query}%"),
            SecurityKnowledge.tags.contains([query])
        )
    )
    
    if category:
        db_query = db_query.filter(SecurityKnowledge.category == category)
    
    knowledge = db_query.order_by(
        SecurityKnowledge.confidence.desc()
    ).limit(limit).all()
    
    return {
        "count": len(knowledge),
        "results": [
            {
                "id": k.id,
                "title": k.title,
                "category": k.category,
                "confidence": k.confidence,
                "tags": k.tags,
                "created_at": k.created_at.isoformat()
            }
            for k in knowledge
        ]
    }


@router.get("/knowledge/stats")
async def get_knowledge_stats(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get security knowledge statistics."""
    total = db.query(SecurityKnowledge).count()
    
    categories = db.query(
        SecurityKnowledge.category,
        db.func.count(SecurityKnowledge.id)
    ).group_by(SecurityKnowledge.category).all()
    
    avg_confidence = db.query(
        db.func.avg(SecurityKnowledge.confidence)
    ).scalar() or 0
    
    return {
        "total_knowledge_entries": total,
        "average_confidence": round(avg_confidence, 3),
        "categories": {cat: count for cat, count in categories}
    }


# ==================== SIMULATION ENDPOINTS ====================

@router.post("/simulate/attack")
async def simulate_attack(
    request: SimulateAttackRequest,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Simulate an attack for security testing."""
    try:
        # Check if user has admin/owner role
        user_role = current_user.get("user", {}).get("role", "")
        if user_role not in ["admin", "owner"]:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only admins can run attack simulations"
            )
        
        engine = MAPEKSecurityEngine(db)
        
        result = engine.simulate_attack(
            target_module=request.target_module,
            attack_type=request.attack_type,
            constraints=request.constraints,
            initiated_by=current_user.get("user", {}).get("id")
        )
        
        return {
            "status": "success",
            "simulation_id": result.get("event_id"),
            "target": request.target_module,
            "attack_type": request.attack_type.value,
            "message": "Attack simulation completed"
        }
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))


# ==================== DASHBOARD ENDPOINTS ====================

@router.get("/dashboard/summary")
async def get_security_dashboard(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get comprehensive security dashboard summary."""
    from datetime import timedelta
    
    now = datetime.now(timezone.utc)
    last_24h = now - timedelta(hours=24)
    last_7d = now - timedelta(days=7)
    
    # Recent threats
    threats_24h = db.query(SecurityEvent).filter(
        SecurityEvent.detected_at >= last_24h
    ).count()
    
    threats_7d = db.query(SecurityEvent).filter(
        SecurityEvent.detected_at >= last_7d
    ).count()
    
    # Critical threats
    critical_threats = db.query(SecurityEvent).filter(
        SecurityEvent.severity == ThreatLevel.CRITICAL.value,
        SecurityEvent.detected_at >= last_7d
    ).count()
    
    # Analyses performed
    analyses_count = db.query(SecurityAnalysis).filter(
        SecurityAnalysis.analyzed_at >= last_7d
    ).count()
    
    # Defenses executed
    defenses_count = db.query(DefenseExecution).filter(
        DefenseExecution.executed_at >= last_7d
    ).count()
    
    # Knowledge base size
    knowledge_count = db.query(SecurityKnowledge).count()
    
    # Top attack types
    top_attacks = db.query(
        SecurityEvent.attack_type,
        db.func.count(SecurityEvent.id)
    ).filter(
        SecurityEvent.detected_at >= last_7d
    ).group_by(SecurityEvent.attack_type).order_by(
        db.func.count(SecurityEvent.id).desc()
    ).limit(5).all()
    
    return {
        "period": "last_7_days",
        "threats_detected": {
            "last_24_hours": threats_24h,
            "last_7_days": threats_7d,
            "critical": critical_threats
        },
        "responses": {
            "analyses_performed": analyses_count,
            "defenses_executed": defenses_count
        },
        "knowledge_base": {
            "total_entries": knowledge_count
        },
        "top_attack_types": [
            {"type": attack_type, "count": count}
            for attack_type, count in top_attacks
        ]
    }


# Import datetime for dashboard
from datetime import datetime
