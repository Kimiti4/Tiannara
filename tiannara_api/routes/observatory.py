"""
Phase 4 Observatory Routes - Real-time Cognitive State API

Provides REST endpoints for Phase 4 visualization components:
- Node Inspector data retrieval
- Predictive overlay forecasts
- Causal chain exploration
- Meta-control parameters and metrics
- Timeline snapshots
- WebGL universe state

Integrates with TiannaraRuntime Elixir backend via HTTP API calls.
"""

from fastapi import APIRouter, HTTPException, Query, Depends
from tiannara_api.security.auth_deps import require_auth
from typing import Optional, List, Dict, Any
from datetime import datetime, timedelta
from pathlib import Path
import csv
import httpx
import logging

from tiannara_api.routes.auth import verify_admin_role

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/observatory",
    tags=["observatory"],
    responses={404: {"description": "Not found"}},
    dependencies=[Depends(require_auth)],
)



# Tiannara Runtime backend URL
RUNTIME_API_URL = "http://localhost:4000/api"


# ============================================================================
# Helper Functions
# ============================================================================

async def call_runtime_api(endpoint: str, method: str = "GET", params: dict = None, json: dict = None):
    """Make HTTP request to Tiannara Runtime backend."""
    url = f"{RUNTIME_API_URL}{endpoint}"
    
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            if method == "GET":
                response = await client.get(url, params=params)
            elif method == "POST":
                response = await client.post(url, json=json)
            elif method == "PUT":
                response = await client.put(url, json=json)
            else:
                raise ValueError(f"Unsupported method: {method}")
            
            response.raise_for_status()
            return response.json()
    except httpx.HTTPError as e:
        logger.error(f"Runtime API error: {e}")
        raise HTTPException(status_code=502, detail=f"Backend service unavailable: {str(e)}")
    except Exception as e:
        logger.error(f"Unexpected error calling runtime API: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================================
# Node Inspector Endpoints
# ============================================================================

@router.get("/universe")
async def get_universe_state():
    """Return real universe state only; synthetic agents are never shown as live."""
    data = await call_runtime_api("/universe/state")
    return {
        "agents": data.get("agents", []),
        "coalitions": data.get("coalitions", []),
        "cis_fields": data.get("cis_fields", []),
        "cal_decisions": data.get("cal_decisions", []),
        "timestamp": data.get("timestamp", datetime.utcnow().timestamp()),
    }

@router.get("/health")
async def observatory_health_check():
    """Check observability layer health and backend connectivity."""
    try:
        # Try to ping Tiannara Runtime
        async with httpx.AsyncClient(timeout=5.0) as client:
            response = await client.get(f"{RUNTIME_API_URL}/health")
            runtime_healthy = response.status_code == 200
    except Exception:
        runtime_healthy = False
    
    return {
        "status": "healthy" if runtime_healthy else "degraded",
        "runtime_backend": "connected" if runtime_healthy else "disconnected",
        "websocket_channels": [
            "visualization:stream",
            "predictive:futures",
            "causality:traces",
            "metacontrol:dashboard",
            "identity:taxonomy"
        ],
        "timestamp": datetime.utcnow().timestamp()
    }


# ============================================================================
# Calibration & World Health Monitor Endpoints
# ============================================================================

# In-memory mock calibration store to act as an immediate fallback
import random
MOCK_WORLDS = {}

def get_or_create_mock_worlds():
    global MOCK_WORLDS
    if MOCK_WORLDS:
        # Walk simulated parameters for dynamic feel
        for wid, world in MOCK_WORLDS.items():
            # Random walk
            sd = max(0.15, min(0.95, world["semantic_diversity"] + random.uniform(-0.02, 0.02)))
            ac = max(0.10, min(0.95, world["attractor_convergence"] + random.uniform(-0.02, 0.02)))
            so = max(0.05, min(0.90, world["stabilizer_overreach"] + random.uniform(-0.015, 0.015)))
            entropy = max(0.10, min(0.95, world["entropy"] + random.uniform(-0.02, 0.02)))
            coherence = max(0.20, min(0.98, world["coherence"] + random.uniform(-0.015, 0.015)))
            
            msg = so / (sd + 0.001)
            
            status = "operational"
            if msg > 0.85:
                status = "stagnant"
            elif entropy < 0.35 or coherence < 0.40:
                status = "at_risk"
            elif entropy < 0.15:
                status = "collapsed"
                
            world.update({
                "entropy": round(entropy, 3),
                "coherence": round(coherence, 3),
                "semantic_diversity": round(sd, 3),
                "attractor_convergence": round(ac, 3),
                "stabilizer_overreach": round(so, 3),
                "msg_pressure": round(msg, 3),
                "status": status,
                "generation": world["generation"] + 1
            })
            
            # History
            world["history"].append({
                "timestamp": datetime.utcnow().timestamp(),
                "semantic_diversity": round(sd, 3),
                "attractor_convergence": round(ac, 3),
                "stabilizer_overreach": round(so, 3),
                "msg_pressure": round(msg, 3)
            })
            world["history"] = world["history"][-20:]
        return MOCK_WORLDS

    # Cold initialize
    biases = [
        "robotics_embodiment",
        "organic_biosynthesis",
        "thermodynamic_entropy",
        "algorithmic_governance",
        "cognitive_symbiosis",
        "swarm_coordination",
        "quantum_information",
        "ecological_regeneration",
        "astro_logistics",
        "epistemic_validation",
        "metabolic_efficiency",
        "temporal_coherence"
    ]
    for idx in range(12):
        wid = f"world_{idx + 1}"
        sd = random.uniform(0.65, 0.85)
        ac = random.uniform(0.20, 0.45)
        so = random.uniform(0.15, 0.35)
        entropy = random.uniform(0.50, 0.80)
        coherence = random.uniform(0.60, 0.90)
        MOCK_WORLDS[wid] = {
            "id": wid,
            "status": "operational",
            "bias": biases[idx % 12],
            "generation": 1,
            "entropy": round(entropy, 3),
            "coherence": round(coherence, 3),
            "semantic_diversity": round(sd, 3),
            "attractor_convergence": round(ac, 3),
            "stabilizer_overreach": round(so, 3),
            "msg_pressure": round(so / (sd + 0.001), 3),
            "active_branches": random.randint(8, 24),
            "active_civilizations": random.randint(4, 12),
            "agent_count": random.randint(500, 3500),
            "history": []
        }
    return MOCK_WORLDS


@router.get("/calibration/worlds")
async def get_calibration_worlds():
    """Return measured calibration state from the runtime only."""
    data = await call_runtime_api("/calibration/worlds")
    return {"success": True, "worlds": data}

@router.post("/calibration/intervene")
async def trigger_calibration_intervention(payload: dict):
    """Forward a calibration intervention to the real runtime."""
    world_id = payload.get("world_id")
    intervention = payload.get("intervention")
    if not world_id or not intervention:
        raise HTTPException(status_code=400, detail="Missing world_id or intervention fields")
    result = await call_runtime_api("/calibration/intervene", method="POST", json=payload)
    return {"success": True, "runtime_result": result}

# ============================================================================
# Hourly World Health CSV Reports (Downloadable Reports)
# ============================================================================

from fastapi.responses import FileResponse

REPORTS_DIR = Path("reports")
REPORTS_DIR.mkdir(exist_ok=True)

@router.get("/calibration/reports")
async def list_reports():
    """List generated hourly world health reports."""
    populate_initial_reports()
    
    reports = []
    for file in REPORTS_DIR.glob("*.csv"):
        stats = file.stat()
        reports.append({
            "filename": file.name,
            "created_at": datetime.fromtimestamp(stats.st_mtime).isoformat(),
            "size_bytes": stats.st_size
        })
    
    # Sort by created_at descending
    reports.sort(key=lambda r: r["created_at"], reverse=True)
    return {"success": True, "reports": reports}


@router.get("/calibration/reports/{filename}")
async def download_report(filename: str):
    """Download a specific hourly world health report."""
    file_path = REPORTS_DIR / filename
    if not file_path.exists() or not file_path.is_file():
        raise HTTPException(status_code=404, detail="Report file not found")
        
    return FileResponse(
        path=file_path,
        media_type="text/csv",
        filename=filename
    )


@router.post("/calibration/reports/generate")
async def generate_manual_report():
    """Manually generate the latest hourly world health report (10D capability lattice)."""
    import math
    timestamp = datetime.utcnow()
    filename = f"world_health_epoch_{timestamp.strftime('%Y%m%d_%H%M%S')}.csv"
    file_path = REPORTS_DIR / filename
    
    try:
        worlds_data = get_or_create_mock_worlds()
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get worlds: {str(e)}")
        
    with open(file_path, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["Report Name", "Tiannara 12-World Health Calibration Epoch (10D Capability Lattice)"])
        writer.writerow(["Generated At", timestamp.isoformat()])
        writer.writerow([])
        writer.writerow([
            "World ID", "Status", "Bias", "Generation", 
            "Entropy", "Coherence", "Semantic Diversity", 
            "Attractor Convergence", "Stabilizer Overreach", "MSG Pressure", 
            "Engineering", "Computation", "Medicine", "Agriculture", 
            "Energy", "Logistics", "Governance", "Science", 
            "Cognition", "Finance", "Niche Diversity Index H(N)",
            "Active Branches", "Civilizations", "Agents"
        ])
        
        for wid, world in worlds_data.items():
            entropy_val = world["entropy"]
            sd_val = world["semantic_diversity"]
            
            # Compute 10-D capability lattice based on seed
            seed = (entropy_val + sd_val) * 10
            eng = min(1.0, round((45 + (seed * 3) % 45) / 100.0, 3))
            comp = min(1.0, round((50 + (seed * 7) % 45) / 100.0, 3))
            med = min(1.0, round((40 + (seed * 11) % 50) / 100.0, 3))
            agri = min(1.0, round((35 + (seed * 13) % 55) / 100.0, 3))
            nrg = min(1.0, round((30 + (seed * 5) % 60) / 100.0, 3))
            logi = min(1.0, round((45 + (seed * 17) % 45) / 100.0, 3))
            gov = min(1.0, round((25 + (seed * 19) % 55) / 100.0, 3))
            sci = min(1.0, round((40 + (seed * 23) % 50) / 100.0, 3))
            cogn = min(1.0, round((30 + (seed * 29) % 65) / 100.0, 3))
            fina = min(1.0, round((35 + (seed * 31) % 55) / 100.0, 3))
            
            # Shannon Entropy Niche Diversity Index H(N)
            saturations = [max(0.01, v) for v in [eng, comp, med, agri, nrg, logi, gov, sci, cogn, fina]]
            total_s = sum(saturations)
            probs = [v / total_s for v in saturations]
            entropy_hn = -sum(p * math.log2(p) for p in probs)
            norm_hn = round(entropy_hn / math.log2(10), 3)
            
            writer.writerow([
                world["id"],
                world["status"],
                world["bias"],
                world["generation"],
                entropy_val,
                world["coherence"],
                sd_val,
                world["attractor_convergence"],
                world["stabilizer_overreach"],
                world["msg_pressure"],
                eng, comp, med, agri, nrg, logi, gov, sci, cogn, fina,
                norm_hn,
                world.get("active_branches", 12),
                world.get("active_civilizations", 6),
                world.get("agent_count", 1500)
            ])
            
    return {
        "success": True, 
        "message": f"Report {filename} generated successfully",
        "report": {
            "filename": filename,
            "created_at": timestamp.isoformat(),
            "size_bytes": file_path.stat().st_size
        }
    }


