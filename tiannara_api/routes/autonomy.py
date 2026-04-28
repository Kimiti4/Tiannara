from fastapi import APIRouter
from tiannara_core.autonomy.self_improver import SelfImprover

router = APIRouter()

@router.post("/autonomous/run")
def run_autonomous():
    system = SelfImprover()
    result = system.run(cycles=10)
    return result