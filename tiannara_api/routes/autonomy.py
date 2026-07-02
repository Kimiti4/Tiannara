from fastapi import APIRouter, Depends
from tiannara_core.autonomy.self_improver import SelfImprover
from tiannara_api.security.auth_deps import require_auth

router = APIRouter(dependencies=[Depends(require_auth)])

@router.post("/autonomous/run")
def run_autonomous():
    system = SelfImprover()
    result = system.run(cycles=10)
    return result