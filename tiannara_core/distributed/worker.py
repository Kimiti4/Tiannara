from __future__ import annotations

from tiannara_core.evolution.population import evolve_details


def run_worker(config):
    result = evolve_details(
        question=config.get("question", "Optimize prosthetic grip stability"),
        pop_size=config.get("population_size", 24),
        generations=config.get("generations", 12),
        mutation_rate=config.get("mutation_rate", 0.1),
        selection_pressure=config.get("selection_pressure", 0.5),
        reward_bias=config.get("reward_bias", 1.0),
        fitness_function=config.get("fitness_function", "grip_stability"),
        genome_type=config.get("genome_type", "neural"),
        use_adversary=bool(config.get("use_adversary", True)),
        starting_difficulty=config.get("difficulty", 1.0),
    )

    meta = {
        "mutation_rate": round(float(config.get("mutation_rate", 0.1)), 4),
        "selection_pressure": round(float(config.get("selection_pressure", 0.5)), 4),
        "reward_bias": round(float(config.get("reward_bias", 1.0)), 4),
        "genome_type": config.get("genome_type", "neural"),
        "worker_id": config.get("worker_id"),
    }

    return {
        "worker_id": config.get("worker_id"),
        "score": result["best_score"],
        "history": result["history"],
        "meta": meta,
        "best_candidate": result["best_candidate"],
        "simulation": result["best_breakdown"],
        "leaderboard": result["leaderboard"],
        "converged": result["converged"],
        "genome_type": result["genome_type"],
        "adversarial": result["adversarial"],
    }
