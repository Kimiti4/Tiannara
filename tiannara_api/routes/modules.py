from __future__ import annotations
from fastapi import APIRouter, Depends, HTTPException

from tiannara_api.security.auth_deps import require_auth
from typing import Dict, Any

from tiannara_core.modules.registry import ModuleRegistry
from tiannara_api.models import ModuleToggleRequest

router = APIRouter(dependencies=[Depends(require_auth)])


def get_registry() -> ModuleRegistry:
    # set by tiannara_api.main
    from tiannara_api.main import REGISTRY
    return REGISTRY


@router.get("/modules")
def list_modules() -> Dict[str, Any]:
    return get_registry().list()


@router.post("/modules/{name}/enabled")
def set_module_enabled(name: str, req: ModuleToggleRequest):
    reg = get_registry()
    if name not in reg.modules:
        raise HTTPException(status_code=404, detail="Unknown module")
    reg.set_enabled(name, req.enabled)
    return {"ok": True, "name": name, "enabled": req.enabled}