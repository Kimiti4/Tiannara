"""
Core AI Proxy - Bridges SaaS to Tiannara Core

This module provides API endpoints that proxy requests from the SaaS platform
to the Tiannara Core AI engine. This allows clean separation between the
customer-facing SaaS and the internal Core AI system.

Architecture:
    User → SaaS Frontend → SaaS Backend → Core API Proxy → Tiannara Core
    
The Core can be deployed separately (different server, different port) and
the SaaS communicates with it via HTTP/REST API calls.
"""

import os
import httpx
from fastapi import APIRouter, HTTPException, Depends
from typing import Dict, Any, Optional

from tiannara_api.security.auth_deps import require_auth

router = APIRouter(
    prefix="/core",
    tags=["Core AI Integration"],
    dependencies=[Depends(require_auth)],
)

# Core API Configuration
CORE_API_URL = os.getenv("CORE_API_URL", "http://localhost:8001")
CORE_API_KEY = os.getenv("CORE_API_KEY", "")


async def get_core_client() -> httpx.AsyncClient:
    """
    Create authenticated HTTP client for Core API.
    
    Returns:
        Async HTTP client configured for Core API communication
    """
    headers = {
        "Content-Type": "application/json",
    }
    
    if CORE_API_KEY:
        headers["Authorization"] = f"Bearer {CORE_API_KEY}"
    
    return httpx.AsyncClient(
        base_url=CORE_API_URL,
        headers=headers,
        timeout=30.0
    )


@router.post("/reason")
async def submit_reasoning_task(task: Dict[str, Any]):
    """
    Submit a reasoning task to Tiannara Core.
    
    This endpoint accepts reasoning tasks from the SaaS frontend and forwards
    them to the Core AI engine for processing.
    
    Args:
        task: Reasoning task parameters including query, context, domain
        
    Returns:
        Reasoning results from Core AI
        
    Example:
        POST /api/v1/core/reason
        {
            "query": "What is the optimal strategy?",
            "domain": "strategic_planning",
            "context": {...}
        }
    """
    try:
        async with await get_core_client() as client:
            response = await client.post("/api/v1/reason", json=task)
            
            if response.status_code != 200:
                raise HTTPException(
                    status_code=response.status_code,
                    detail=f"Core API error: {response.text}"
                )
            
            return response.json()
            
    except httpx.RequestError as e:
        raise HTTPException(
            status_code=503,
            detail=f"Core service unavailable: {str(e)}"
        )
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Internal error: {str(e)}"
        )


@router.get("/domains")
async def list_available_domains():
    """
    Get list of available domain engines from Core.
    
    Returns information about which AI domain modules are available
    for reasoning tasks.
    
    Returns:
        List of available domains with metadata
    """
    try:
        async with await get_core_client() as client:
            response = await client.get("/api/v1/domains")
            
            if response.status_code != 200:
                raise HTTPException(
                    status_code=response.status_code,
                    detail="Failed to fetch domains from Core"
                )
            
            return response.json()
            
    except httpx.RequestError:
        raise HTTPException(
            status_code=503,
            detail="Core service unavailable"
        )


@router.post("/predict")
async def get_prediction(data: Dict[str, Any]):
    """
    Get prediction from Core ML models.
    
    Submits data to Core's prediction engine for analysis and returns
    predictions based on trained models.
    
    Args:
        data: Input data for prediction
        
    Returns:
        Prediction results with confidence scores
    """
    try:
        async with await get_core_client() as client:
            response = await client.post("/api/v1/predict", json=data)
            
            if response.status_code != 200:
                raise HTTPException(
                    status_code=response.status_code,
                    detail="Prediction failed"
                )
            
            return response.json()
            
    except httpx.RequestError:
        raise HTTPException(
            status_code=503,
            detail="Core service unavailable"
        )


@router.post("/evolve")
async def trigger_evolution(evolution_params: Dict[str, Any]):
    """
    Trigger evolution process in Core.
    
    Initiates the evolutionary algorithm to improve AI models or strategies.
    
    Args:
        evolution_params: Parameters for evolution process
        
    Returns:
        Evolution results and improvements
    """
    try:
        async with await get_core_client() as client:
            response = await client.post("/api/v1/evolve", json=evolution_params)
            
            if response.status_code != 200:
                raise HTTPException(
                    status_code=response.status_code,
                    detail="Evolution failed"
                )
            
            return response.json()
            
    except httpx.RequestError:
        raise HTTPException(
            status_code=503,
            detail="Core service unavailable"
        )


@router.get("/status")
async def core_health_check():
    """
    Check if Core API is healthy and accessible.
    
    Returns:
        Core service status and version info
    """
    try:
        async with await get_core_client() as client:
            response = await client.get("/api/v1/status")
            
            if response.status_code != 200:
                return {
                    "status": "degraded",
                    "message": "Core API responding but with errors"
                }
            
            return response.json()
            
    except httpx.RequestError:
        return {
            "status": "unavailable",
            "message": "Core service is not reachable"
        }


@router.post("/skill-transfer")
async def transfer_skill(transfer_data: Dict[str, Any]):
    """
    Transfer skills between domains using Core's skill memory.
    
    Leverages Core's cross-domain skill transfer capabilities.
    
    Args:
        transfer_data: Source domain, target domain, skill parameters
        
    Returns:
        Transferred skill and adaptation results
    """
    try:
        async with await get_core_client() as client:
            response = await client.post("/api/v1/skill-transfer", json=transfer_data)
            
            if response.status_code != 200:
                raise HTTPException(
                    status_code=response.status_code,
                    detail="Skill transfer failed"
                )
            
            return response.json()
            
    except httpx.RequestError:
        raise HTTPException(
            status_code=503,
            detail="Core service unavailable"
        )
