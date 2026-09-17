"""
Gateway Routes

Endpoints for:
- Gateway health check
- System metrics
- Engine status
- Request logs
- Sandbox testing
"""

import logging
from typing import Dict, Any

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from tiannara_api.gateway.routing import get_all_engines, register_engine
from tiannara_api.gateway.usage_tracker import usage_tracker
from tiannara_api.gateway.orchestrator import orchestrator

logger = logging.getLogger(__name__)

router = APIRouter()


# Request models
class TestRequest(BaseModel):
    """Test request for sandbox."""
    endpoint: str
    payload: Dict[str, Any]


@router.get("/gateway/health")
async def gateway_health() -> Dict[str, Any]:
    """
    Gateway health check.
    
    Returns overall system health status.
    """
    engines = get_all_engines()
    
    engine_health = {}
    for name, engine in engines.items():
        health = engine.get_health()
        engine_health[name] = health
    
    return {
        "status": "healthy",
        "version": "2.0.0-gateway",
        "uptime": "operational",
        "engines": engine_health,
        "engine_count": len(engines),
    }


@router.get("/gateway/metrics")
async def gateway_metrics() -> Dict[str, Any]:
    """
    System metrics for dashboard.
    
    Returns aggregated metrics for observability.
    """
    engines = get_all_engines()
    global_metrics = usage_tracker.get_global_metrics()
    
    # Calculate engine metrics
    engine_metrics = []
    total_requests = 0
    total_latency = 0.0
    total_success = 0
    total_failed = 0
    
    for name, engine in engines.items():
        metrics = engine.get_metrics()
        engine_metrics.append(metrics)
        
        total_requests += metrics["total_requests"]
        total_latency += metrics["avg_latency_ms"]
        if metrics["status"] == "healthy":
            total_success += metrics["total_requests"]
        else:
            total_failed += metrics["total_requests"]
    
    avg_latency = total_latency / len(engines) if engines else 0.0
    success_rate = (total_success / total_requests * 100) if total_requests > 0 else 100.0
    
    return {
        "total_requests": total_requests,
        "avg_response_time_ms": round(avg_latency, 2),
        "success_rate": round(success_rate, 2),
        "active_engines": len(engines),
        "global_metrics": global_metrics,
        "engines": engine_metrics,
    }


@router.get("/gateway/engines")
async def list_engines() -> Dict[str, Any]:
    """
    List all registered engines with status.
    
    Returns detailed information about each domain engine.
    """
    engines = get_all_engines()
    
    engine_list = []
    for name, engine in engines.items():
        engine_list.append({
            "name": engine.name,
            "version": engine.version,
            "health": engine.get_health(),
            "metrics": engine.get_metrics(),
        })
    
    return {
        "total_engines": len(engine_list),
        "engines": engine_list,
    }


@router.get("/gateway/logs")
async def get_logs(limit: int = 50) -> Dict[str, Any]:
    """
    Get recent request logs.
    
    Args:
        limit: Number of logs to return (default 50, max 100)
    """
    if limit > 100:
        limit = 100
    
    logs = usage_tracker.get_recent_logs(limit)
    
    return {
        "total_logs": len(logs),
        "logs": logs,
    }


@router.post("/gateway/test")
async def test_endpoint(request: TestRequest) -> Dict[str, Any]:
    """
    Test endpoint for sandbox.
    
    Allows testing different endpoints with custom payloads.
    """
    from tiannara_api.gateway.routing import get_engine
    
    engine = get_engine(request.endpoint)
    
    if not engine:
        raise HTTPException(
            status_code=404,
            detail=f"No engine found for endpoint: {request.endpoint}"
        )
    
    # Process the request through the engine
    result = engine.process(request.payload)
    
    return {
        "status": "success",
        "endpoint": request.endpoint,
        "result": result,
    }


@router.get("/gateway/flows")
async def get_active_flows(limit: int = 20) -> Dict[str, Any]:
    """
    Get recent orchestration flows.
    
    Args:
        limit: Number of flows to return (default 20, max 100)
    """
    if limit > 100:
        limit = 100
    
    flows = orchestrator.get_active_flows()
    
    return {
        "total_flows": len(flows),
        "flows": flows[-limit:],
    }
