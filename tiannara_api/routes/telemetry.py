"""
Telemetry API Routes

Provides REST endpoints for cognitive telemetry system:
- Record metrics
- Query historical data
- Detect anomalies
- Export data
- Dashboard summary

Based on tiannara_core/telemetry/cognitive_telemetry.py
"""

from fastapi import APIRouter, HTTPException, Query
from typing import Dict, Any, Optional, List
from pydantic import BaseModel
import time

router = APIRouter(prefix="/telemetry", tags=["Cognitive Telemetry"])

# Initialize telemetry collector
from tiannara_core.telemetry.cognitive_telemetry import CognitiveTelemetryCollector, MetricType
telemetry_collector = CognitiveTelemetryCollector()


# Request/Response Models
class RecordMetricRequest(BaseModel):
    """Request to record a telemetry metric."""
    metric_type: str  # e.g., "contradiction_density"
    value: float
    domain: Optional[str] = None
    session_id: Optional[str] = None
    metadata: Optional[Dict[str, Any]] = {}
    confidence: float = 0.9
    sample_size: int = 1


class QueryMetricsRequest(BaseModel):
    """Request to query telemetry records."""
    metric_types: Optional[List[str]] = None
    time_range_start: Optional[float] = None
    time_range_end: Optional[float] = None
    domain: Optional[str] = None
    session_id: Optional[str] = None
    limit: Optional[int] = None


# ========== METRIC RECORDING ENDPOINTS ==========

@router.post("/record", response_model=Dict[str, Any])
async def record_metric(request: RecordMetricRequest):
    """
    Record a single cognitive telemetry metric.
    
    Tracks metrics like:
    - contradiction_density
    - synthesis_convergence
    - confidence_calibration
    - theory_survival
    - communication_entropy
    - causal_consistency
    - epistemic_recovery
    - memory_fidelity
    """
    try:
        # Convert string to enum
        try:
            metric_type = MetricType(request.metric_type)
        except ValueError:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid metric type: {request.metric_type}. Valid types: {[m.value for m in MetricType]}"
            )
        
        # Record metric
        record = telemetry_collector.record_metric(
            metric_type=metric_type,
            value=request.value,
            domain=request.domain,
            session_id=request.session_id,
            metadata=request.metadata,
            confidence=request.confidence,
            sample_size=request.sample_size
        )
        
        return {
            'success': True,
            'record_id': record.record_id,
            'message': 'Metric recorded successfully',
            'anomalies_detected': len([a for a in telemetry_collector.anomalies if a.metric_type == metric_type])
        }
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to record metric: {str(e)}")


# ========== QUERY ENDPOINTS ==========

@router.post("/query", response_model=Dict[str, Any])
async def query_metrics(request: QueryMetricsRequest):
    """
    Query telemetry records with filters.
    
    Supports filtering by:
    - Metric types
    - Time range
    - Domain
    - Session ID
    - Limit
    """
    try:
        # Convert metric type strings to enums
        metric_types = None
        if request.metric_types:
            try:
                metric_types = [MetricType(mt) for mt in request.metric_types]
            except ValueError as e:
                raise HTTPException(
                    status_code=400,
                    detail=f"Invalid metric type: {str(e)}"
                )
        
        # Build time range
        time_range = None
        if request.time_range_start and request.time_range_end:
            time_range = (request.time_range_start, request.time_range_end)
        
        # Query records
        records = telemetry_collector.query_metrics(
            metric_types=metric_types,
            time_range=time_range,
            domain=request.domain,
            session_id=request.session_id,
            limit=request.limit
        )
        
        return {
            'success': True,
            'count': len(records),
            'data': [
                {
                    'record_id': r.record_id,
                    'metric_type': r.metric_type.value,
                    'value': r.value,
                    'timestamp': r.timestamp,
                    'domain': r.domain,
                    'session_id': r.session_id,
                    'confidence': r.confidence,
                    'sample_size': r.sample_size
                }
                for r in records
            ]
        }
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Query failed: {str(e)}")


@router.get("/statistics/{metric_type}", response_model=Dict[str, Any])
async def get_metric_statistics(metric_type: str, window_size: int = Query(default=100)):
    """
    Get statistics for a specific metric.
    
    Returns mean, std, min, max, median, count, and trend.
    """
    try:
        # Convert to enum
        try:
            metric_enum = MetricType(metric_type)
        except ValueError:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid metric type: {metric_type}"
            )
        
        stats = telemetry_collector.get_metric_statistics(metric_enum, window_size)
        
        return {
            'success': True,
            'metric_type': metric_type,
            'window_size': window_size,
            'statistics': stats
        }
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get statistics: {str(e)}")


# ========== ANOMALY DETECTION ENDPOINTS ==========

@router.get("/anomalies", response_model=Dict[str, Any])
async def get_anomalies(
    metric_type: Optional[str] = None,
    severity: Optional[str] = None,
    limit: int = Query(default=50)
):
    """
    Get detected anomalies.
    
    Filters:
    - metric_type: Specific metric to check
    - severity: Filter by severity level
    - limit: Maximum anomalies to return
    """
    try:
        anomalies = telemetry_collector.anomalies
        
        # Apply filters
        if metric_type:
            try:
                metric_enum = MetricType(metric_type)
                anomalies = [a for a in anomalies if a.metric_type == metric_enum]
            except ValueError:
                pass  # Ignore invalid metric type
        
        if severity:
            anomalies = [a for a in anomalies if a.severity == severity]
        
        # Sort by detection time (most recent first)
        anomalies.sort(key=lambda a: a.detected_at, reverse=True)
        
        # Limit results
        anomalies = anomalies[:limit]
        
        return {
            'success': True,
            'count': len(anomalies),
            'data': [
                {
                    'anomaly_id': a.anomaly_id,
                    'metric_type': a.metric_type.value,
                    'severity': a.severity,
                    'description': a.description,
                    'detected_at': a.detected_at,
                    'current_value': a.current_value,
                    'expected_range': list(a.expected_range),
                    'deviation_score': a.deviation_score,
                    'recommended_actions': a.recommended_actions
                }
                for a in anomalies
            ]
        }
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get anomalies: {str(e)}")


@router.post("/detect-anomalies/{metric_type}", response_model=Dict[str, Any])
async def detect_anomalies(metric_type: str, window_size: int = Query(default=100)):
    """
    Manually trigger anomaly detection for a metric.
    
    Uses statistical methods (z-score) to identify outliers.
    """
    try:
        # Convert to enum
        try:
            metric_enum = MetricType(metric_type)
        except ValueError:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid metric type: {metric_type}"
            )
        
        anomalies = telemetry_collector.detect_anomalies(metric_enum, window_size)
        
        return {
            'success': True,
            'metric_type': metric_type,
            'anomalies_found': len(anomalies),
            'data': [
                {
                    'anomaly_id': a.anomaly_id,
                    'severity': a.severity,
                    'description': a.description,
                    'deviation_score': a.deviation_score
                }
                for a in anomalies
            ]
        }
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Anomaly detection failed: {str(e)}")


# ========== EXPORT ENDPOINTS ==========

@router.get("/export", response_model=Dict[str, Any])
async def export_metrics(
    format: str = Query(default="csv"),
    metric_types: Optional[str] = None,
    time_range_start: Optional[float] = None,
    time_range_end: Optional[float] = None
):
    """
    Export telemetry data to CSV or JSON.
    
    Parameters:
    - format: "csv" or "json"
    - metric_types: Comma-separated list of metric types
    - time_range_start: Start timestamp
    - time_range_end: End timestamp
    """
    try:
        # Parse metric types
        metric_type_list = None
        if metric_types:
            try:
                metric_type_list = [MetricType(mt.strip()) for mt in metric_types.split(",")]
            except ValueError as e:
                raise HTTPException(
                    status_code=400,
                    detail=f"Invalid metric type: {str(e)}"
                )
        
        # Parse time range
        time_range = None
        if time_range_start and time_range_end:
            time_range = (time_range_start, time_range_end)
        
        # Export
        filename = telemetry_collector.export_metrics(
            format=format,
            metric_types=metric_type_list,
            time_range=time_range
        )
        
        return {
            'success': True,
            'filename': filename,
            'message': f'Exported to {filename}'
        }
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Export failed: {str(e)}")


# ========== DASHBOARD ENDPOINT ==========

@router.get("/dashboard", response_model=Dict[str, Any])
async def get_telemetry_dashboard():
    """
    Get comprehensive telemetry dashboard summary.
    
    Includes:
    - Latest statistics for all metrics
    - Recent anomalies
    - Total record counts
    """
    try:
        summary = telemetry_collector.get_dashboard_summary()
        
        return {
            'success': True,
            'data': summary
        }
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Dashboard fetch failed: {str(e)}")


# ========== MAINTENANCE ENDPOINTS ==========

@router.post("/cleanup", response_model=Dict[str, Any])
async def cleanup_old_records(days_to_keep: int = Query(default=90)):
    """
    Remove old telemetry records to manage database size.
    
    Default: Keep last 90 days
    """
    try:
        deleted_count = telemetry_collector.cleanup_old_records(days_to_keep)
        
        return {
            'success': True,
            'deleted_records': deleted_count,
            'message': f'Deleted {deleted_count} records older than {days_to_keep} days'
        }
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Cleanup failed: {str(e)}")


@router.get("/available-metrics", response_model=Dict[str, Any])
async def get_available_metrics():
    """
    Get list of all available metric types with descriptions.
    """
    metrics_info = {
        "contradiction_density": "Ratio of unresolved contradictions to total beliefs",
        "synthesis_convergence": "Rate at which competing theories converge",
        "confidence_calibration": "How well confidence matches actual accuracy",
        "theory_survival": "Percentage of theories surviving over time",
        "communication_entropy": "Diversity and novelty in agent communications",
        "causal_consistency": "Consistency of causal reasoning chains",
        "epistemic_recovery": "Speed of recovery from false beliefs",
        "memory_fidelity": "Accuracy of memory retrieval and reconstruction",
        "identity_drift": "Deviation from core constitution/principles",
        "agent_coordination": "Effectiveness of multi-agent collaboration"
    }
    
    return {
        'success': True,
        'metrics': metrics_info,
        'total_count': len(MetricType)
    }
