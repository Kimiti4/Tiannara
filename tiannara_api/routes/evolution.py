from __future__ import annotations

from fastapi import APIRouter

from tiannara_api.schemas import EvolutionRunRequest
from tiannara_core.evolution.evolution import evolve

router = APIRouter()


@router.post("/evolution/run")
def run_evolution(req: EvolutionRunRequest):
    return evolve(
        question=req.question,
        population_size=req.population_size,
        generations=req.generations,
        fitness_function=req.fitness_function,
        genome_type=req.genome_type,
    )
