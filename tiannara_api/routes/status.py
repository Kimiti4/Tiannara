from __future__ import annotations
from fastapi import APIRouter
from tiannara_api.schemas import StatusResponse

router = APIRouter()


@router.get("/status", response_model=StatusResponse)
def status():
    from tiannara_api.main import REGISTRY, APP_VERSION

    return {
        "status": "ok",
        "version": APP_VERSION,
        "modules": sorted(REGISTRY.modules.keys()),
    }
