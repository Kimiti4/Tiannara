"""
Explanation API Routes - EU AI Act Compliance (Articles 13-15)

Provides REST API endpoints for:
- Requesting explanations for automated decisions
- Retrieving audit trails for compliance
- Exporting explanation reports
- What-if counterfactual queries

Usage:
    from tiannara_api.routes.explanations import router
    
    # Add to FastAPI app
    app.include_router(router, prefix="/api/v1/explanations")
"""

from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime
import logging

from tiannara_core.interpretability.explanation_engine import (
    ExplanationEngine,
    create_explanation_engine
)

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/explanations",
    tags=["explanations", "compliance", "EU AI Act"],
    responses={404: {"description": "Not found"}},
)

# Global explanation engine instance (initialized on first use)
_explanation_engine: Optional[ExplanationEngine] = None


def get_engine() -> ExplanationEngine:
    """Get or create explanation engine singleton."""
    global _explanation_engine
    if _explanation_engine is None:
        _explanation_engine = create_explanation_engine(
            audit_db_path="explanation_audit.db",
            cache_enabled=True,
            default_audience="technical"
        )
        logger.info("Explanation engine initialized")
    return _explanation_engine


# ============================================================================
# Request/Response Models
# ============================================================================

class ExplanationRequest(BaseModel):
    """Request for decision explanation."""
    target_node: str = Field(..., description="Node/outcome to explain")
    source_node: Optional[str] = Field(None, description="Optional source node")
    audience: Optional[str] = Field("end_user", description="Audience level: technical, regulatory, end_user")
    include_counterfactuals: bool = Field(True, description="Include what-if analysis")
    include_uncertainty: bool = Field(True, description="Include confidence calibration")
    user_id: Optional[str] = Field(None, description="User ID for audit trail")
    session_id: Optional[str] = Field(None, description="Session ID for context")
    ecm_graph: Optional[Dict[str, Any]] = Field(None, description="ECM graph (nodes and edges)")


class CounterfactualRequest(BaseModel):
    """Request for counterfactual analysis."""
    question: str = Field(..., description="What-if question (e.g., 'What if X increased by 0.2?')")
    audience: Optional[str] = Field("end_user", description="Audience level")
    user_id: Optional[str] = Field(None, description="User ID for audit")
    ecm_graph: Optional[Dict[str, Any]] = Field(None, description="ECM graph")


class AuditQueryParams(BaseModel):
    """Parameters for querying audit trail."""
    start_date: Optional[str] = Field(None, description="Start date (ISO format)")
    end_date: Optional[str] = Field(None, description="End date (ISO format)")
    explanation_type: Optional[str] = Field(None, description="Filter by type")
    target_node: Optional[str] = Field(None, description="Filter by target node")
    user_id: Optional[str] = Field(None, description="Filter by user ID")
    limit: int = Field(100, description="Maximum records to return")


class ExplanationResponse(BaseModel):
    """Response containing explanation."""
    success: bool
    explanation_text: str
    explanation_type: str
    target_node: str
    confidence: float
    record_id: Optional[str] = None
    timestamp: str
    mermaid_diagram: Optional[str] = None
    uncertainty_notes: List[str] = []
    alternative_paths: List[Dict] = []


class AuditRecordResponse(BaseModel):
    """Audit record in response."""
    record_id: str
    timestamp: str
    explanation_type: str
    target_node: str
    confidence: float
    user_id: Optional[str] = None


class AuditTrailResponse(BaseModel):
    """Response containing audit records."""
    success: bool
    total_records: int
    records: List[AuditRecordResponse]


class StatisticsResponse(BaseModel):
    """System statistics."""
    success: bool
    cache_size: int
    audit_trail_stats: Dict[str, Any]


# ============================================================================
# API Endpoints
# ============================================================================

@router.post("/explain", response_model=ExplanationResponse)
async def explain_decision(request: ExplanationRequest):
    """
    Generate explanation for an automated decision (EU AI Act Article 13-15).
    
    This endpoint provides transparent, auditable explanations for AI-driven
    decisions, satisfying right-to-explanation requirements.
    
    **Example:**
    ```json
    {
        "target_node": "final_outcome",
        "audience": "end_user",
        "include_counterfactuals": true,
        "user_id": "user_123"
    }
    ```
    """
    try:
        engine = get_engine()
        
        # Use provided graph or create sample for demo
        ecm_graph = request.ecm_graph or {
            'nodes': ['skill_memory', 'pattern_recognition', 'solution_quality', 'final_outcome'],
            'edges': [
                ('skill_memory', 'pattern_recognition', 0.85),
                ('pattern_recognition', 'solution_quality', 0.90),
                ('solution_quality', 'final_outcome', 0.80)
            ]
        }
        
        explanation = engine.explain_decision(
            ecm_graph=ecm_graph,
            target_node=request.target_node,
            source_node=request.source_node,
            audience=request.audience,
            include_counterfactuals=request.include_counterfactuals,
            include_uncertainty=request.include_uncertainty,
            user_id=request.user_id,
            session_id=request.session_id
        )
        
        return ExplanationResponse(
            success=True,
            explanation_text=explanation.explanation_text,
            explanation_type=explanation.explanation_type,
            target_node=explanation.target_node,
            confidence=explanation.confidence,
            record_id=explanation.record_id,
            timestamp=explanation.timestamp,
            mermaid_diagram=explanation.mermaid_diagram,
            uncertainty_notes=explanation.uncertainty_notes,
            alternative_paths=[{
                'source': p.source_node,
                'target': p.target_node,
                'effect': p.total_effect
            } for p in explanation.alternative_paths[:3]]  # Limit to top 3
        )
        
    except Exception as e:
        logger.error(f"Explanation generation failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Failed to generate explanation: {str(e)}")


@router.post("/counterfactual", response_model=ExplanationResponse)
async def answer_counterfactual(request: CounterfactualRequest):
    """
    Answer what-if counterfactual questions.
    
    Enables users to understand how changes would affect outcomes,
    supporting transparency and user control (EU AI Act Article 14).
    
    **Example:**
    ```json
    {
        "question": "What if skill_memory increased by 0.2?",
        "audience": "end_user"
    }
    ```
    """
    try:
        engine = get_engine()
        
        # Use provided graph or create sample
        ecm_graph = request.ecm_graph or {
            'nodes': ['skill_memory', 'pattern_recognition', 'final_outcome'],
            'edges': [
                ('skill_memory', 'pattern_recognition', 0.85),
                ('pattern_recognition', 'final_outcome', 0.80)
            ]
        }
        
        explanation = engine.answer_what_if(
            graph=ecm_graph,
            question=request.question,
            audience=request.audience,
            user_id=request.user_id
        )
        
        return ExplanationResponse(
            success=True,
            explanation_text=explanation.explanation_text,
            explanation_type=explanation.explanation_type,
            target_node=explanation.target_node,
            confidence=1.0,
            record_id=explanation.record_id,
            timestamp=explanation.timestamp
        )
        
    except Exception as e:
        logger.error(f"Counterfactual analysis failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Failed to analyze counterfactual: {str(e)}")


@router.get("/audit", response_model=AuditTrailResponse)
async def get_audit_trail(
    start_date: Optional[str] = Query(None, description="Start date (ISO format)"),
    end_date: Optional[str] = Query(None, description="End date (ISO format)"),
    explanation_type: Optional[str] = Query(None, description="Filter by type"),
    target_node: Optional[str] = Query(None, description="Filter by target node"),
    user_id: Optional[str] = Query(None, description="Filter by user ID"),
    limit: int = Query(100, description="Maximum records")
):
    """
    Retrieve audit trail for compliance review (EU AI Act Article 15).
    
    Provides immutable, searchable log of all explanations generated,
    enabling regulatory audits and accountability verification.
    
    **Query Parameters:**
    - `start_date`: Filter records after this date (ISO format)
    - `end_date`: Filter records before this date (ISO format)
    - `explanation_type`: Filter by type (causal_path, counterfactual, etc.)
    - `target_node`: Filter by explained node
    - `user_id`: Filter by requesting user
    - `limit`: Maximum records to return (default: 100)
    """
    try:
        engine = get_engine()
        
        records = engine.get_audit_records(
            start_date=start_date,
            end_date=end_date,
            explanation_type=explanation_type,
            target_node=target_node,
            user_id=user_id,
            limit=limit
        )
        
        return AuditTrailResponse(
            success=True,
            total_records=len(records),
            records=[
                AuditRecordResponse(
                    record_id=r['record_id'],
                    timestamp=r['timestamp'],
                    explanation_type=r['explanation_type'],
                    target_node=r['target_node'],
                    confidence=r['confidence'],
                    user_id=r.get('user_id')
                )
                for r in records
            ]
        )
        
    except Exception as e:
        logger.error(f"Audit trail retrieval failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Failed to retrieve audit trail: {str(e)}")


@router.get("/audit/{record_id}")
async def get_audit_record(record_id: str):
    """
    Retrieve specific audit record by ID.
    
    Useful for investigating specific decisions or responding to
    individual explanation requests.
    """
    try:
        engine = get_engine()
        records = engine.get_audit_records(limit=1000)  # Get all and filter
        
        # Find matching record
        matching = [r for r in records if r['record_id'] == record_id]
        
        if not matching:
            raise HTTPException(status_code=404, detail=f"Record {record_id} not found")
        
        return {
            "success": True,
            "record": matching[0]
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Audit record retrieval failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Failed to retrieve record: {str(e)}")


@router.post("/audit/export")
async def export_compliance_report(
    format: str = Query("json", description="Export format: json or csv"),
    start_date: Optional[str] = Query(None, description="Start date filter"),
    end_date: Optional[str] = Query(None, description="End date filter")
):
    """
    Export compliance report for regulatory submission.
    
    Generates downloadable report in JSON or CSV format containing
    all explanation records within specified date range.
    
    Supports GDPR data portability and EU AI Act documentation requirements.
    """
    try:
        engine = get_engine()
        
        output_path = f"compliance_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.{format}"
        
        exported_path = engine.export_compliance_report(
            output_path=output_path,
            format=format,
            start_date=start_date,
            end_date=end_date
        )
        
        return {
            "success": True,
            "export_path": exported_path,
            "format": format,
            "message": f"Report exported to {exported_path}"
        }
        
    except Exception as e:
        logger.error(f"Compliance export failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Failed to export report: {str(e)}")


@router.get("/statistics", response_model=StatisticsResponse)
async def get_statistics():
    """
    Get system statistics for monitoring and auditing.
    
    Provides overview of explanation generation activity,
    cache performance, and audit trail metrics.
    """
    try:
        engine = get_engine()
        stats = engine.get_statistics()
        
        return StatisticsResponse(
            success=True,
            cache_size=stats['cache_size'],
            audit_trail_stats=stats.get('audit_trail', {})
        )
        
    except Exception as e:
        logger.error(f"Statistics retrieval failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Failed to retrieve statistics: {str(e)}")


@router.delete("/cache")
async def clear_cache():
    """
    Clear explanation cache.
    
    Useful for testing or forcing regeneration of explanations.
    Note: Does NOT affect audit trail (immutable).
    """
    try:
        engine = get_engine()
        engine.clear_cache()
        
        return {
            "success": True,
            "message": "Cache cleared successfully"
        }
        
    except Exception as e:
        logger.error(f"Cache clear failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Failed to clear cache: {str(e)}")


@router.get("/health")
async def health_check():
    """
    Health check endpoint for monitoring.
    
    Verifies that explanation engine is operational and
    audit trail database is accessible.
    """
    try:
        engine = get_engine()
        stats = engine.get_statistics()
        
        return {
            "status": "healthy",
            "engine_initialized": True,
            "cache_enabled": stats['cache_enabled'],
            "total_explanations": stats['audit_trail'].get('total_records', 0)
        }
        
    except Exception as e:
        logger.error(f"Health check failed: {e}", exc_info=True)
        return {
            "status": "unhealthy",
            "error": str(e)
        }
