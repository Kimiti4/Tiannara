# tiannara_core/api/research_routes.py

from fastapi import APIRouter
from tiannara_core.research.autonomous_scientist import AutonomousScientist

router = APIRouter()

scientist = None  # inject from main

@router.post("/research/run")
def run_research():
    scientist.run_cycle()
    return {"status": "cycle complete"}

@router.post("/research/auto")
def run_auto():
    scientist.run_forever(5)
    return {"status": "auto research started"}