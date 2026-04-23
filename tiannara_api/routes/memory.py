from __future__ import annotations

from fastapi import APIRouter, HTTPException

router = APIRouter()


@router.get("/memory/all")
def memory_all(limit: int = 20):
    from tiannara_api.main import DISCOVERY_MEMORY, EXPERIENCE_DB

    if DISCOVERY_MEMORY is None or EXPERIENCE_DB is None:
        raise HTTPException(status_code=500, detail="Memory services not initialized")

    return {
        "discovery_reports": DISCOVERY_MEMORY.list_reports(limit=limit),
        "experiences": EXPERIENCE_DB.list_entries(limit=limit),
    }


@router.get("/memory/experiences")
def memory_experiences(limit: int = 20):
    from tiannara_api.main import EXPERIENCE_DB

    if EXPERIENCE_DB is None:
        raise HTTPException(status_code=500, detail="Experience DB not initialized")

    return {"items": EXPERIENCE_DB.list_entries(limit=limit)}
