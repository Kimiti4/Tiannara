from __future__ import annotations

from typing import Any, Dict

from tiannara_core.evolution.population import evolve_details


def evolve(
    *,
    question: str = "Optimize prosthetic grip stability",
    population_size: int = 24,
    generations: int = 12,
    fitness_function: str = "grip_stability",
    mutation_rate: float = 0.1,
    genome_type: str = "neural",
    use_adversary: bool = True,
) -> Dict[str, Any]:
    result = evolve_details(
        question=question,
        pop_size=population_size,
        generations=generations,
        mutation_rate=mutation_rate,
        fitness_function=fitness_function,
        genome_type=genome_type,
        use_adversary=use_adversary,
    )

    return {
        "question": question,
        "fitness_function": fitness_function,
        "population_size": result["population_size"],
        "generations_run": result["generations_run"],
        "best_fitness": result["best_score"],
        "best_candidate": result["best_candidate"],
        "best_metrics": result["best_breakdown"],
        "history": result["history"],
        "leaderboard": result["leaderboard"],
        "converged": result["converged"],
        "genome_type": result["genome_type"],
        "adversarial": result["adversarial"],
        "selection_pressure": result["selection_pressure"],
        "reward_bias": result["reward_bias"],
    }
