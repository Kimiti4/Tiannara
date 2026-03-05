from __future__ import annotations
from fastapi import APIRouter, HTTPException
from typing import Dict, Any

from tiannara_api.schemas import DiscoveryAnalyzeRequest, DiscoveryAnalyzeResponse

router = APIRouter()


@router.post("/discovery/analyze", response_model=DiscoveryAnalyzeResponse)
def discovery_analyze(req: DiscoveryAnalyzeRequest):
    from tiannara_api.main import DISCOVERY_ENGINE

    if not DISCOVERY_ENGINE:
        raise HTTPException(status_code=500, detail="Discovery engine not initialized")

    report = DISCOVERY_ENGINE["analyze"](question=req.question, text=req.text, source=req.source)

    gate = report.get("safety_gate", {}) or {}
    return DiscoveryAnalyzeResponse(
        report=report,
        approved=bool(gate.get("approved")),
        reason=str(gate.get("reason", "")),
        alignment_score=float(gate.get("alignment_score", 0.0)),
    )