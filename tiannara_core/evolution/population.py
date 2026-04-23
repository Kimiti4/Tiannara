from __future__ import annotations

import random
from typing import Any, Dict, List

from tiannara_core.evolution.graph_genome import GraphGenome, graph_crossover
from tiannara_core.evolution.neural_engine import NeuralGenome, crossover
from tiannara_core.sim.adversarial_env import AdversarialEnvironment
from tiannara_core.sim.simulator import run_simulation


def _clamp(value: float, low: float = 0.0, high: float = 1.0) -> float:
    return max(low, min(high, float(value)))


def _resolve_genome_type(genome_type: str) -> str:
    return "graph" if str(genome_type).lower() == "graph" else "neural"


def _make_genome(genome_type: str):
    if _resolve_genome_type(genome_type) == "graph":
        return GraphGenome()
    return NeuralGenome()


def _crossover(parent_a, parent_b, genome_type: str):
    if _resolve_genome_type(genome_type) == "graph":
        return graph_crossover(parent_a, parent_b)
    return crossover(parent_a, parent_b)


def decode_candidate(agent) -> Dict[str, float]:
    probe = [0.15, -0.35, 0.65, -0.20, 0.40]
    output = [float(value) for value in agent.forward(probe)]
    if len(output) < 3:
        while len(output) < 3:
            output.append(output[len(output) % len(output)] if output else 0.0)

    scaled = [(value + 1.0) / 2.0 for value in output[:3]]
    return {
        "damping": round(_clamp(scaled[0]), 4),
        "stiffness": round(_clamp(scaled[1]), 4),
        "grip_force": round(_clamp(scaled[2]), 4),
    }


def evolve_details(
    *,
    question: str = "Optimize prosthetic grip stability",
    pop_size: int = 40,
    generations: int = 15,
    mutation_rate: float = 0.1,
    selection_pressure: float = 0.5,
    reward_bias: float = 1.0,
    fitness_function: str = "grip_stability",
    genome_type: str = "neural",
    use_adversary: bool = False,
    starting_difficulty: float = 1.0,
) -> Dict[str, Any]:
    pop_size = max(6, min(int(pop_size), 200))
    generations = max(1, min(int(generations), 200))
    mutation_rate = _clamp(mutation_rate, 0.01, 0.45)
    selection_pressure = _clamp(selection_pressure, 0.35, 0.95)
    reward_bias = max(0.6, min(1.5, float(reward_bias)))
    genome_type = _resolve_genome_type(genome_type)

    population = [_make_genome(genome_type) for _ in range(pop_size)]
    history: List[float] = []
    best_entry: tuple[float, NeuralGenome, Dict[str, float], Dict[str, float]] | None = None
    leaderboard: List[Dict[str, Any]] = []
    adversary = AdversarialEnvironment(difficulty=starting_difficulty) if use_adversary else None
    difficulty_history: List[float] = [round(adversary.difficulty, 4)] if adversary else []

    for generation in range(generations):
        scored: List[tuple[float, object, Dict[str, float], Dict[str, float], Dict[str, float]]] = []

        for agent in population:
            simulation_score, breakdown = run_simulation(agent, profile=fitness_function)
            adversarial = {
                "score": 0.0,
                "difficulty_before": round(adversary.difficulty, 4) if adversary else 0.0,
                "difficulty_after": round(adversary.difficulty, 4) if adversary else 0.0,
                "error": 0.0,
            }
            if adversary:
                adversarial = adversary.evaluate(agent)
                combined = _clamp((0.7 * simulation_score) + (0.3 * adversarial["score"]))
            else:
                combined = simulation_score

            fitness = _clamp(combined * reward_bias)
            enriched_breakdown = dict(breakdown)
            enriched_breakdown["adversarial"] = round(adversarial["score"], 4)
            enriched_breakdown["difficulty"] = round(adversarial["difficulty_after"], 4)
            scored.append((fitness, agent, enriched_breakdown, decode_candidate(agent), adversarial))

        scored.sort(reverse=True, key=lambda item: item[0])
        best_entry = scored[0]

        history.append(round(best_entry[0], 4))
        if adversary:
            difficulty_history.append(round(adversary.difficulty, 4))
        leaderboard = [
            {
                "rank": rank + 1,
                "fitness": round(score, 4),
                "candidate": candidate,
                "simulation": breakdown,
                "generation": generation + 1,
                "genome_type": genome_type,
                "adversarial": adversarial,
            }
            for rank, (score, _, breakdown, candidate, adversarial) in enumerate(scored[: min(5, len(scored))])
        ]

        survivor_count = max(2, int(pop_size * selection_pressure))
        survivors = [agent for _, agent, _, _, _ in scored[:survivor_count]]
        population = [best_entry[1]]

        while len(population) < pop_size:
            parent_a, parent_b = random.sample(survivors, 2)
            child = _crossover(parent_a, parent_b, genome_type)
            child.mutate(mutation_rate)
            population.append(child)

    if best_entry is None:
        raise RuntimeError("Evolution did not produce any agents")

    best_score, best_agent, best_breakdown, best_candidate, best_adversarial = best_entry
    converged = len(history) >= 3 and abs(history[-1] - history[-3]) < 0.01

    return {
        "question": question,
        "fitness_function": fitness_function,
        "population_size": pop_size,
        "generations_run": generations,
        "best_agent": best_agent,
        "best_score": round(best_score, 4),
        "best_breakdown": best_breakdown,
        "best_candidate": best_candidate,
        "history": history,
        "leaderboard": leaderboard,
        "converged": converged,
        "genome_type": genome_type,
        "selection_pressure": round(selection_pressure, 4),
        "reward_bias": round(reward_bias, 4),
        "adversarial": {
            "enabled": bool(adversary),
            "difficulty_start": round(starting_difficulty, 4),
            "difficulty_end": round(adversary.difficulty, 4) if adversary else round(starting_difficulty, 4),
            "history": difficulty_history,
            "best_score": round(best_adversarial["score"], 4),
        },
    }


def evolve(
    *,
    question: str = "Optimize prosthetic grip stability",
    pop_size: int = 40,
    generations: int = 15,
    mutation_rate: float = 0.1,
    selection_pressure: float = 0.5,
    reward_bias: float = 1.0,
    fitness_function: str = "grip_stability",
    genome_type: str = "neural",
    use_adversary: bool = False,
    starting_difficulty: float = 1.0,
):
    result = evolve_details(
        question=question,
        pop_size=pop_size,
        generations=generations,
        mutation_rate=mutation_rate,
        selection_pressure=selection_pressure,
        reward_bias=reward_bias,
        fitness_function=fitness_function,
        genome_type=genome_type,
        use_adversary=use_adversary,
        starting_difficulty=starting_difficulty,
    )
    return result["best_agent"], result["best_score"], result["best_breakdown"], result["history"]
