from fastapi import APIRouter, HTTPException
from typing import List, Dict, Any, Optional
from datetime import datetime
import httpx

import logging

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/worlds",
    tags=["Phase 5A - Multi-World Branching"]
)

# Tiannara Runtime API URL
RUNTIME_API_URL = "http://localhost:4000/api"

@router.get("/")
async def list_worlds(mock: bool = False):
    """
    Get list of all active worlds with their metadata.
    
    Returns:
        List of world objects with fitness, generation, lineage info
    """
    if mock:
        return get_mock_worlds()
        
    try:
        # Call Elixir backend to get world list
        async with httpx.AsyncClient(timeout=5.0) as client:
            response = await client.get(f"{RUNTIME_API_URL}/worlds")
            
            if response.status_code == 200:
                worlds_data = response.json()
                
                # Transform to frontend-friendly format
                worlds = []
                for world in worlds_data.get("worlds", []):
                    worlds.append({
                        "id": world.get("id"),
                        "parent_world": world.get("parent_world"),
                        "generation": world.get("generation", 0),
                        "fitness": world.get("fitness", 0.5),
                        "collapse_risk": calculate_collapse_risk(world),
                        "coherence": world.get("coherence", 0.5),
                        "entropy": world.get("entropy", 0.5),
                        "status": world.get("status", "active"),
                        "children": world.get("children", []),
                        "created_at": world.get("created_at"),
                        "last_updated": world.get("last_updated")
                    })
                
                return {
                    "worlds": worlds,
                    "total_count": len(worlds),
                    "timestamp": datetime.utcnow().timestamp(),
                    "mock": False
                }
            else:
                raise HTTPException(status_code=503, detail="Elixir backend runtime returned error status")
    
    except Exception as e:
        logger.error(f"Backend unavailable: {e}")
        raise HTTPException(status_code=503, detail=f"Elixir backend runtime unavailable: {e}")


@router.get("/{world_id}")
async def get_world_details(world_id: str):
    """
    Get detailed information about a specific world.
    
    Args:
        world_id: ID of the world to query
        
    Returns:
        Detailed world state including CAL/CIS state, memory timeline, etc.
    """
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            response = await client.get(f"{RUNTIME_API_URL}/worlds/{world_id}")
            
            if response.status_code == 200:
                return response.json()
            else:
                raise HTTPException(status_code=404, detail=f"World {world_id} not found")
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Backend unavailable: {str(e)}")


@router.post("/fork")
async def fork_world(request: Dict[str, Any]):
    """
    Fork an existing world to create a new branch.
    
    Request Body:
        parent_world_id: ID of world to fork
        mutation: Optional configuration changes to apply
    
    Returns:
        New world ID and metadata
    """
    parent_world_id = request.get("parent_world_id")
    mutation = request.get("mutation", {})
    
    if not parent_world_id:
        raise HTTPException(status_code=400, detail="parent_world_id is required")
    
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.post(
                f"{RUNTIME_API_URL}/worlds/fork",
                json={
                    "parent_world_id": parent_world_id,
                    "mutation": mutation
                }
            )
            
            if response.status_code == 200:
                return response.json()
            else:
                raise HTTPException(
                    status_code=response.status_code,
                    detail=f"Fork failed: {response.text}"
                )
    
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Backend unavailable: {str(e)}")


@router.get("/{world_id}/lineage")
async def get_world_lineage(world_id: str):
    """
    Get complete lineage tree for a world (ancestors and descendants).
    
    Args:
        world_id: ID of the world
        
    Returns:
        Lineage tree structure
    """
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            response = await client.get(f"{RUNTIME_API_URL}/worlds/{world_id}/lineage")
            
            if response.status_code == 200:
                return response.json()
            else:
                raise HTTPException(status_code=404, detail=f"World {world_id} not found")
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Backend unavailable: {str(e)}")


@router.get("/metrics")
async def get_world_metrics():
    """
    Get aggregated metrics across all worlds.
    
    Returns:
        System-wide statistics
    """
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            response = await client.get(f"{RUNTIME_API_URL}/worlds/metrics")
            
            if response.status_code == 200:
                return response.json()
            else:
                # Return calculated metrics from world list
                worlds_response = await list_worlds()
                worlds = worlds_response.get("worlds", [])
                
                if not worlds:
                    return {
                        "total_worlds": 0,
                        "active_worlds": 0,
                        "avg_fitness": 0,
                        "max_generation": 0,
                        "fork_count": 0
                    }
                
                active = len([w for w in worlds if w.get("status") == "active"])
                avg_fitness = sum(w.get("fitness", 0) for w in worlds) / len(worlds)
                max_gen = max(w.get("generation", 0) for w in worlds)
                forks = len([w for w in worlds if w.get("parent_world") is not None])
                
                return {
                    "total_worlds": len(worlds),
                    "active_worlds": active,
                    "avg_fitness": round(avg_fitness, 3),
                    "max_generation": max_gen,
                    "fork_count": forks
                }
    
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Backend unavailable: {str(e)}")


# ============================================================================
# Helper Functions
# ============================================================================

def calculate_collapse_risk(world_data: Dict[str, Any]) -> float:
    """
    Calculate collapse risk based on entropy and stability metrics.
    
    Higher entropy + lower coherence = higher collapse risk
    """
    entropy = world_data.get("entropy", 0.5)
    coherence = world_data.get("coherence", 0.5)
    stability = world_data.get("stability_score", 0.5)
    
    # Simple risk formula (can be enhanced)
    risk = (entropy * 0.6) + ((1 - coherence) * 0.3) + ((1 - stability) * 0.1)
    
    return min(max(risk, 0.0), 1.0)  # Clamp to [0, 1]


def get_mock_worlds() -> Dict[str, Any]:
    """
    Return mock world data for development/testing when backend is unavailable.
    """
    mock_worlds = [
        {
            "id": "W-root-001",
            "parent_world": None,
            "generation": 0,
            "fitness": 0.85,
            "collapse_risk": 0.15,
            "coherence": 0.78,
            "entropy": 0.32,
            "status": "active",
            "children": ["W-child-001", "W-child-002"],
            "created_at": datetime.utcnow().timestamp() - 3600,
            "last_updated": datetime.utcnow().timestamp()
        },
        {
            "id": "W-child-001",
            "parent_world": "W-root-001",
            "generation": 1,
            "fitness": 0.72,
            "collapse_risk": 0.28,
            "coherence": 0.65,
            "entropy": 0.45,
            "status": "active",
            "children": [],
            "created_at": datetime.utcnow().timestamp() - 1800,
            "last_updated": datetime.utcnow().timestamp()
        },
        {
            "id": "W-child-002",
            "parent_world": "W-root-001",
            "generation": 1,
            "fitness": 0.45,
            "collapse_risk": 0.55,
            "coherence": 0.42,
            "entropy": 0.68,
            "status": "active",
            "children": ["W-grandchild-001"],
            "created_at": datetime.utcnow().timestamp() - 1200,
            "last_updated": datetime.utcnow().timestamp()
        },
        {
            "id": "W-grandchild-001",
            "parent_world": "W-child-002",
            "generation": 2,
            "fitness": 0.38,
            "collapse_risk": 0.72,
            "coherence": 0.35,
            "entropy": 0.78,
            "status": "active",
            "children": [],
            "created_at": datetime.utcnow().timestamp() - 600,
            "last_updated": datetime.utcnow().timestamp()
        }
    ]
    
    return {
        "worlds": mock_worlds,
        "total_count": len(mock_worlds),
        "timestamp": datetime.utcnow().timestamp(),
        "note": "Mock data (backend unavailable)",
        "mock": True
    }
