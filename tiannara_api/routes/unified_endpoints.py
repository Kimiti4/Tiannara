"""
Unified API Endpoints

Main entry points for all Tiannara Core domain APIs.
Routes requests through the gateway orchestrator with proper auth, rate limiting, and tracking.

Endpoints:
- POST /api/v1/predict - Prediction domain
- POST /api/v1/reason - Reasoning/Logic domain  
- POST /api/v1/analyze - NLP analysis domain
- POST /api/v1/causal - Causal inference domain
- POST /api/v1/workflow - Multi-domain orchestration
"""

import logging
import time
from typing import Dict, Any, Optional, List
from datetime import datetime

from fastapi import APIRouter, HTTPException, Depends, Header
from pydantic import BaseModel, Field

from tiannara_api.gateway.auth import get_api_key, check_permission, get_user_tier_for_api_key
from tiannara_api.security.auth_deps import require_auth
from tiannara_api.gateway.routing import get_engine, ROUTE_MAP
from tiannara_api.gateway.usage_tracker import usage_tracker
from tiannara_api.gateway.orchestrator import orchestrator
from tiannara_api.gateway.rate_limit import rate_limiter

logger = logging.getLogger(__name__)

router = APIRouter(dependencies=[Depends(require_auth)])


# Request/Response Models
class PredictRequest(BaseModel):
    """Prediction request payload."""
    data: List[float] = Field(..., description="Input data points")
    model_type: str = Field(default="auto", description="Model type (auto, linear, polynomial, etc.)")
    horizon: int = Field(default=7, description="Forecast horizon")
    metadata: Optional[Dict[str, Any]] = Field(default=None, description="Additional metadata")


class PredictResponse(BaseModel):
    """Prediction response."""
    forecast: List[float]
    confidence: float
    model_used: str
    latency_ms: float
    timestamp: str


class ReasonRequest(BaseModel):
    """Reasoning request payload."""
    prompt: str = Field(..., description="Question or task to reason about")
    context: Optional[Dict[str, Any]] = Field(default=None, description="Additional context")
    iterations: int = Field(default=3, description="Number of reasoning iterations")
    mode: str = Field(default="auto", description="Reasoning mode (code, logic, analysis)")


class ReasonResponse(BaseModel):
    """Reasoning response."""
    result: str
    quality_score: float
    steps_taken: int
    latency_ms: float
    timestamp: str


class AnalyzeRequest(BaseModel):
    """NLP analysis request payload."""
    text: str = Field(..., description="Text to analyze")
    tasks: List[str] = Field(default=["sentiment"], description="Analysis tasks (sentiment, entities, summary, etc.)")
    language: str = Field(default="en", description="Language code")


class AnalyzeResponse(BaseModel):
    """NLP analysis response."""
    results: Dict[str, Any]
    processing_time_ms: float
    tokens_processed: int
    timestamp: str


class CausalRequest(BaseModel):
    """Causal inference request payload."""
    variables: List[str] = Field(..., description="Variable names")
    data: List[List[float]] = Field(..., description="Observation data")
    method: str = Field(default="notears", description="Causal discovery method")


class CausalResponse(BaseModel):
    """Causal inference response."""
    graph: Dict[str, Any]
    causal_effects: List[Dict[str, Any]]
    confidence: float
    latency_ms: float
    timestamp: str


class WorkflowRequest(BaseModel):
    """Multi-domain workflow request."""
    workflow_name: str = Field(..., description="Workflow identifier")
    steps: List[Dict[str, Any]] = Field(..., description="Workflow steps with engine and params")
    input_data: Dict[str, Any] = Field(..., description="Initial input data")


class WorkflowResponse(BaseModel):
    """Workflow execution response."""
    workflow_id: str
    result: Dict[str, Any]
    steps_executed: List[Dict[str, Any]]
    total_latency_ms: float
    timestamp: str


# Helper Functions
def track_and_execute(api_key: str, endpoint: str, engine_func, request_data: Dict[str, Any]) -> Dict[str, Any]:
    """Execute engine function with tracking and error handling."""
    start_time = time.time()
    
    try:
        # Execute the engine function
        result = engine_func(request_data)
        
        # Calculate latency
        latency_ms = (time.time() - start_time) * 1000
        
        # Log successful request
        usage_tracker.log_request(
            api_key=api_key or "anonymous",
            endpoint=endpoint,
            method="POST",
            status_code=200,
            latency_ms=latency_ms,
            engine_used=endpoint.split("/")[-1]
        )
        
        return {
            "success": True,
            "result": result,
            "latency_ms": round(latency_ms, 2),
            "timestamp": datetime.utcnow().isoformat()
        }
    
    except Exception as e:
        latency_ms = (time.time() - start_time) * 1000
        
        # Log failed request
        usage_tracker.log_request(
            api_key=api_key or "anonymous",
            endpoint=endpoint,
            method="POST",
            status_code=500,
            latency_ms=latency_ms,
            engine_used=endpoint.split("/")[-1],
            error_message=str(e)
        )
        
        logger.error(f"Engine execution failed: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Engine error: {str(e)}")


# API Endpoints

@router.post("/predict", response_model=PredictResponse)
async def predict(
    request: PredictRequest,
    api_key: Optional[str] = Depends(get_api_key)
):
    """
    Prediction endpoint.
    
    Forecasts future values based on historical data using ML models.
    """
    # Check permission
    user_tier = get_user_tier_for_api_key(api_key)
    if api_key and not check_permission(user_tier, "predict"):
        raise HTTPException(status_code=403, detail="Insufficient permissions for prediction")
    
    # Get prediction engine
    engine = get_engine("/api/predict")
    if not engine:
        raise HTTPException(status_code=503, detail="Prediction engine unavailable")
    
    # Execute prediction
    response = track_and_execute(
        api_key=api_key,
        endpoint="/api/v1/predict",
        engine_func=lambda data: engine.predict(data["data"], model_type=data.get("model_type", "auto")),
        request_data=request.dict()
    )
    
    return PredictResponse(
        forecast=response["result"].get("forecast", []),
        confidence=response["result"].get("confidence", 0.0),
        model_used=response["result"].get("model_used", "unknown"),
        latency_ms=response["latency_ms"],
        timestamp=response["timestamp"]
    )


@router.post("/reason", response_model=ReasonResponse)
async def reason(
    request: ReasonRequest,
    api_key: Optional[str] = Depends(get_api_key)
):
    """
    Reasoning endpoint.
    
    Performs autonomous reasoning, code generation, and logical analysis.
    """
    # Check permission
    user_tier = get_user_tier_for_api_key(api_key)
    if api_key and not check_permission(user_tier, "reason"):
        raise HTTPException(status_code=403, detail="Professional tier required for reasoning")
    
    # Get logic/reasoning engine
    engine = get_engine("/api/reason")
    if not engine:
        raise HTTPException(status_code=503, detail="Reasoning engine unavailable")
    
    # Execute reasoning
    response = track_and_execute(
        api_key=api_key,
        endpoint="/api/v1/reason",
        engine_func=lambda data: engine.reason(
            prompt=data["prompt"],
            context=data.get("context"),
            iterations=data.get("iterations", 3)
        ),
        request_data=request.dict()
    )
    
    return ReasonResponse(
        result=response["result"],
        quality_score=response.get("quality_score", 0.0),
        steps_taken=response.get("iterations", 0),
        latency_ms=response["latency_ms"],
        timestamp=response["timestamp"]
    )


@router.post("/analyze", response_model=AnalyzeResponse)
async def analyze(
    request: AnalyzeRequest,
    api_key: Optional[str] = Depends(get_api_key)
):
    """
    NLP Analysis endpoint.
    
    Performs sentiment analysis, entity extraction, summarization, and more.
    """
    # Check permission
    user_tier = get_user_tier_for_api_key(api_key)
    if api_key and not check_permission(user_tier, "analyze"):
        raise HTTPException(status_code=403, detail="Insufficient permissions for analysis")
    
    # Get NLP engine
    engine = get_engine("/api/analyze")
    if not engine:
        raise HTTPException(status_code=503, detail="NLP engine unavailable")
    
    # Execute analysis
    response = track_and_execute(
        api_key=api_key,
        endpoint="/api/v1/analyze",
        engine_func=lambda data: engine.analyze(
            text=data["text"],
            tasks=data.get("tasks", ["sentiment"]),
            language=data.get("language", "en")
        ),
        request_data=request.dict()
    )
    
    return AnalyzeResponse(
        results=response["result"],
        processing_time_ms=response["latency_ms"],
        tokens_processed=len(request.text.split()),
        timestamp=response["timestamp"]
    )


@router.post("/causal", response_model=CausalResponse)
async def causal_inference(
    request: CausalRequest,
    api_key: Optional[str] = Depends(get_api_key)
):
    """
    Causal Inference endpoint.
    
    Discovers causal relationships from observational data.
    """
    # Check permission
    user_tier = get_user_tier_for_api_key(api_key)
    if api_key and not check_permission(user_tier, "causal"):
        raise HTTPException(status_code=403, detail="Professional tier required for causal inference")
    
    # Get causal engine
    engine = get_engine("/api/causal")
    if not engine:
        raise HTTPException(status_code=503, detail="Causal engine unavailable")
    
    # Execute causal analysis
    response = track_and_execute(
        api_key=api_key,
        endpoint="/api/v1/causal",
        engine_func=lambda data: engine.discover_causality(
            variables=data["variables"],
            data=data["data"],
            method=data.get("method", "notears")
        ),
        request_data=request.dict()
    )
    
    return CausalResponse(
        graph=response["result"].get("graph", {}),
        causal_effects=response["result"].get("effects", []),
        confidence=response["result"].get("confidence", 0.0),
        latency_ms=response["latency_ms"],
        timestamp=response["timestamp"]
    )


@router.post("/workflow", response_model=WorkflowResponse)
async def execute_workflow(
    request: WorkflowRequest,
    api_key: Optional[str] = Depends(get_api_key)
):
    """
    Multi-domain workflow execution.
    
    Orchestrates multiple domain engines in sequence for complex tasks.
    """
    # Check permission (workflows require pro tier)
    user_tier = get_user_tier_for_api_key(api_key)
    if api_key and not check_permission(user_tier, "reason"):
        raise HTTPException(status_code=403, detail="Professional tier required for workflows")
    
    start_time = time.time()
    
    try:
        # Execute workflow through orchestrator
        engine_sequence = [step.get("engine") for step in request.steps]
        
        result = orchestrator.orchestrate(
            request=request.input_data,
            engine_sequence=engine_sequence
        )
        
        total_latency_ms = (time.time() - start_time) * 1000
        
        # Log workflow execution
        usage_tracker.log_request(
            api_key=api_key or "anonymous",
            endpoint="/api/v1/workflow",
            method="POST",
            status_code=200,
            latency_ms=total_latency_ms,
            engine_used="orchestrator"
        )
        
        return WorkflowResponse(
            workflow_id=result["flow_id"],
            result=result["result"],
            steps_executed=result["steps"],
            total_latency_ms=result["latency_ms"],
            timestamp=datetime.utcnow().isoformat()
        )
    
    except Exception as e:
        total_latency_ms = (time.time() - start_time) * 1000
        
        usage_tracker.log_request(
            api_key=api_key or "anonymous",
            endpoint="/api/v1/workflow",
            method="POST",
            status_code=500,
            latency_ms=total_latency_ms,
            engine_used="orchestrator",
            error_message=str(e)
        )
        
        logger.error(f"Workflow execution failed: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Workflow error: {str(e)}")
