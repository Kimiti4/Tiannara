from __future__ import annotations

import random
from typing import Any, Dict, List

from tiannara_core.evolution.graph_genome import GraphGenome, graph_crossover
from tiannara_core.evolution.neural_engine import NeuralGenome, crossover
from tiannara_core.evolution.novelty_search import (
    AdaptiveStrategySelector,
    BehaviorCharacterization,
    NoveltyArchive,
    compute_population_diversity,
)
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
    use_novelty_search: bool = True,  # NEW: Enable novelty search
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
    
    # NEW: Initialize novelty search components
    behavior_extractor = BehaviorCharacterization(feature_dim=5)
    novelty_archive = NoveltyArchive(max_size=100, similarity_threshold=0.15)
    strategy_selector = AdaptiveStrategySelector(
        initial_novelty_weight=0.3,
        adaptation_rate=0.1,
        diversity_threshold=0.2,
        stagnation_window=5
    )
    novelty_scores_history: List[float] = []
    strategies_used: List[str] = []

    for generation in range(generations):
        scored: List[tuple[float, object, Dict[str, float], Dict[str, float], Dict[str, float]]] = []
        population_behaviors: List[List[float]] = []  # NEW: Track behaviors

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
            
            # NEW: Extract behavior and compute novelty if enabled
            novelty_score = 0.0
            if use_novelty_search:
                behavior = behavior_extractor.extract_features(agent)
                population_behaviors.append(behavior)
                novelty_score = novelty_archive.novelty_score(behavior)
                enriched_breakdown["novelty"] = round(novelty_score, 4)
            
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
        
        # NEW: Adaptive strategy selection and novelty-based scoring
        current_fitness = best_entry[0]
        population_diversity = compute_population_diversity(population_behaviors) if use_novelty_search and population_behaviors else 0.5
        
        if use_novelty_search:
            strategy, novelty_weight = strategy_selector.select_strategy(
                current_fitness, population_diversity, generation
            )
            strategies_used.append(strategy)
            
            # Re-score population with combined fitness-novelty score
            novelty_scored = []
            for idx, (fitness, agent, breakdown, candidate, adversarial) in enumerate(scored):
                behavior = population_behaviors[idx] if idx < len(population_behaviors) else [0.0] * 5
                novelty = novelty_archive.novelty_score(behavior)
                novelty_scores_history.append(novelty)
                
                # Add to archive if novel enough
                novelty_archive.add_behavior(behavior)
                
                # Compute combined score
                combined_score = strategy_selector.compute_combined_score(fitness, novelty, novelty_weight)
                novelty_scored.append((combined_score, fitness, novelty, agent, breakdown, candidate, adversarial))
            
            # Sort by combined score
            novelty_scored.sort(reverse=True, key=lambda x: x[0])
            
            # Use combined scoring for selection
            survivor_count = max(2, int(pop_size * selection_pressure))
            survivors = [item[3] for item in novelty_scored[:survivor_count]]  # agent is at index 3
            population = [novelty_scored[0][3]]  # Best combined score
        else:
            # Original fitness-only selection
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
        # NEW: Novelty search statistics
        "novelty_search": {
            "enabled": use_novelty_search,
            "archive_stats": novelty_archive.get_stats() if use_novelty_search else {},
            "strategy_stats": strategy_selector.get_stats() if use_novelty_search else {},
            "avg_novelty": round(
                sum(novelty_scores_history) / len(novelty_scores_history), 4
            ) if novelty_scores_history else 0.0,
            "strategies_used": strategies_used if use_novelty_search else [],
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
