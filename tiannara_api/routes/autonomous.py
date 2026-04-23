from __future__ import annotations

from fastapi import APIRouter, HTTPException

from tiannara_api.schemas import AutonomousCycleRequest

router = APIRouter()


def _run(req: AutonomousCycleRequest):
    from tiannara_api.main import AUTONOMOUS_ORCHESTRATOR

    if AUTONOMOUS_ORCHESTRATOR is None:
        raise HTTPException(status_code=500, detail="Autonomous orchestrator not initialized")

    return AUTONOMOUS_ORCHESTRATOR.run_cycle(
        question=req.question,
        text=req.text,
        source=req.source,
        population_size=req.population_size,
        generations=req.generations,
        fitness_function=req.fitness_function,
        workers=req.workers,
        genome_type=req.genome_type,
    )


@router.post("/autonomous/cycle")
def run_cycle(req: AutonomousCycleRequest | None = None):
    return _run(req or AutonomousCycleRequest())


@router.post("/autonomous/run")
def run_legacy(req: AutonomousCycleRequest | None = None):
    return _run(req or AutonomousCycleRequest())


@router.get("/autonomous/history")
def history(limit: int = 50):
    from tiannara_api.main import AUTONOMOUS_ORCHESTRATOR

    if AUTONOMOUS_ORCHESTRATOR is None:
        raise HTTPException(status_code=500, detail="Autonomous orchestrator not initialized")

    return AUTONOMOUS_ORCHESTRATOR.memory.get_all(limit=limit)
