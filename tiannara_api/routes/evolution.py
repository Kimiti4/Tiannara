from __future__ import annotations

from fastapi import APIRouter, Depends

from tiannara_api.models import EvolutionRunRequest
from tiannara_core.evolution.evolution import evolve
from tiannara_api.security.auth_deps import require_auth

router = APIRouter(dependencies=[Depends(require_auth)])


@router.post("/evolution/run")
def run_evolution(req: EvolutionRunRequest):
    return evolve(
        question=req.question,
        population_size=req.population_size,
        generations=req.generations,
        fitness_function=req.fitness_function,
        genome_type=req.genome_type,
    )
