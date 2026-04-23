from __future__ import annotations
from fastapi import APIRouter, HTTPException

from tiannara_api.schemas import (
    DiscoveryAnalyzeRequest,
    DiscoveryAnalyzeResponse,
    DiscoveryMemoryListResponse,
    DiscoveryMemoryGetResponse,
)

router = APIRouter()


@router.post("/discovery/analyze", response_model=DiscoveryAnalyzeResponse)
def discovery_analyze(req: DiscoveryAnalyzeRequest):
    from tiannara_api.main import DISCOVERY_ENGINE, DISCOVERY_MEMORY

    if DISCOVERY_ENGINE is None:
        raise HTTPException(status_code=500, detail="Discovery engine not initialized")

    report = DISCOVERY_ENGINE.analyze(
        question=req.question,
        text=req.text,
        source=req.source,
    )
    if DISCOVERY_MEMORY is not None:
        DISCOVERY_MEMORY.save_report(
            question=req.question,
            source=req.source,
            report=report,
            tags=["discovery"],
        )

    gate = report.get("safety_gate", {}) or {}
    return DiscoveryAnalyzeResponse(
        report=report,
        approved=bool(gate.get("approved")),
        reason=str(gate.get("reason", "")),
        alignment_score=float(gate.get("alignment_score", 0.0)),
    )


@router.get("/discovery/memory", response_model=DiscoveryMemoryListResponse)
def discovery_memory_list(limit: int = 20):
    from tiannara_api.main import DISCOVERY_MEMORY

    if DISCOVERY_MEMORY is None:
        raise HTTPException(status_code=500, detail="Discovery memory not initialized")

    items = DISCOVERY_MEMORY.list_reports(limit=limit)
    slim = [
        {
            "id": x["id"],
            "ts": x["ts"],
            "question": x["question"],
            "source": x["source"],
            "tags": x.get("tags", []),
        }
        for x in items
    ]
    return DiscoveryMemoryListResponse(items=slim)


@router.get("/discovery/memory/{report_id}", response_model=DiscoveryMemoryGetResponse)
def discovery_memory_get(report_id: str):
    from tiannara_api.main import DISCOVERY_MEMORY

    if DISCOVERY_MEMORY is None:
        raise HTTPException(status_code=500, detail="Discovery memory not initialized")

    item = DISCOVERY_MEMORY.get_report(report_id)
    if item is None:
        raise HTTPException(status_code=404, detail="Discovery report not found")

    return DiscoveryMemoryGetResponse(item=item)
