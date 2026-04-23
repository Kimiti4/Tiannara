from __future__ import annotations

import random
from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional, Tuple

from tiannara_core.evolution.meta_engine import MetaGenome
from tiannara_core.sim.simulator import score_control_parameters


def _clamp(value: float, low: float = 0.0, high: float = 1.0) -> float:
    return max(low, min(high, float(value)))


@dataclass
class EvolutionLoop:
    seed: Optional[int] = None
    rng: random.Random = field(init=False)

    def __post_init__(self) -> None:
        self.rng = random.Random(self.seed)

    def run(
        self,
        *,
        question: str = "Optimize prosthetic grip stability",
        report: Optional[Dict[str, Any]] = None,
        population_size: int = 24,
        generations: int = 12,
        fitness_function: str = "grip_stability",
    ) -> Dict[str, Any]:
        population_size = max(6, min(int(population_size), 200))
        generations = max(1, min(int(generations), 200))
        meta = MetaGenome()
        population = [self._random_candidate() for _ in range(population_size)]

        history: List[Dict[str, Any]] = []
        best_candidate: Dict[str, float] | None = None
        best_metrics: Dict[str, float] | None = None

        for generation in range(generations):
            scored = self._score_population(
                population=population,
                question=question,
                fitness_function=fitness_function,
                report=report,
                reward_bias=meta.reward_bias,
            )
            scored.sort(key=lambda item: item[0], reverse=True)

            best_score, candidate, metrics = scored[0]
            best_candidate = candidate
            best_metrics = metrics

            history.append(
                {
                    "generation": generation + 1,
                    "best_fitness": round(best_score, 4),
                    "mutation_rate": round(meta.mutation_rate, 4),
                    "selection_pressure": round(meta.selection_pressure, 4),
                    "candidate": candidate,
                }
            )

            survivors = [item[1] for item in scored[: max(2, int(population_size * meta.selection_pressure))]]
            population = [candidate.copy()]

            while len(population) < population_size:
                parent_a, parent_b = self.rng.sample(survivors, k=2)
                child = self._crossover(parent_a, parent_b)
                population.append(self._mutate(child, meta.mutation_rate))

            meta.mutate()

        converged = False
        if len(history) >= 3:
            tail = history[-3:]
            converged = abs(tail[-1]["best_fitness"] - tail[0]["best_fitness"]) < 0.01

        return {
            "question": question,
            "fitness_function": fitness_function,
            "population_size": population_size,
            "generations_run": generations,
            "best_fitness": round(float(best_metrics["score"]) if best_metrics else 0.0, 4),
            "best_candidate": best_candidate or self._random_candidate(),
            "best_metrics": best_metrics or {},
            "meta": meta.as_dict(),
            "history": history,
            "converged": converged,
            "report_summary": self._summarize_report(report),
        }

    def _score_population(
        self,
        *,
        population: List[Dict[str, float]],
        question: str,
        fitness_function: str,
        report: Optional[Dict[str, Any]],
        reward_bias: float,
    ) -> List[Tuple[float, Dict[str, float], Dict[str, float]]]:
        scored: List[Tuple[float, Dict[str, float], Dict[str, float]]] = []
        approved = bool(((report or {}).get("safety_gate") or {}).get("approved", False))
        alignment = float(((report or {}).get("safety_gate") or {}).get("alignment_score", 0.0))

        for candidate in population:
            metrics = score_control_parameters(
                damping=candidate["damping"],
                stiffness=candidate["stiffness"],
                grip_force=candidate["grip_force"],
                fatigue=self._estimate_fatigue(question=question),
                question=question,
            )

            score = metrics["score"]
            if fitness_function == "maximize_accuracy":
                score = _clamp(score + (0.08 * candidate["stiffness"]))
            elif fitness_function == "optimize_efficiency":
                score = _clamp(score + (0.04 * (1.0 - candidate["grip_force"])))

            if approved:
                score = _clamp(score + 0.04)
            score = _clamp(score + (0.03 * alignment))
            score = _clamp(score * reward_bias)
            metrics["score"] = round(score, 4)
            scored.append((score, candidate, metrics))

        return scored

    def _estimate_fatigue(self, *, question: str) -> float:
        fatigue = 0.18
        q = question.lower()
        if "fatigue" in q:
            fatigue += 0.17
        if "tremor" in q:
            fatigue += 0.08
        return _clamp(fatigue)

    def _random_candidate(self) -> Dict[str, float]:
        return {
            "damping": round(self.rng.uniform(0.2, 0.9), 4),
            "stiffness": round(self.rng.uniform(0.2, 0.9), 4),
            "grip_force": round(self.rng.uniform(0.25, 0.85), 4),
        }

    def _crossover(self, parent_a: Dict[str, float], parent_b: Dict[str, float]) -> Dict[str, float]:
        return {
            key: round((parent_a[key] + parent_b[key]) / 2.0, 4) if self.rng.random() < 0.5 else parent_a[key]
            for key in parent_a
        }

    def _mutate(self, candidate: Dict[str, float], mutation_rate: float) -> Dict[str, float]:
        mutated = candidate.copy()
        for key in mutated:
            if self.rng.random() < mutation_rate:
                mutated[key] = round(_clamp(mutated[key] + self.rng.uniform(-0.12, 0.12)), 4)
        return mutated

    def _summarize_report(self, report: Optional[Dict[str, Any]]) -> Dict[str, Any]:
        if not report:
            return {"claims": 0, "hypotheses": 0, "experiments": 0, "approved": False}

        gate = report.get("safety_gate", {}) or {}
        return {
            "claims": len(report.get("claims", []) or []),
            "hypotheses": len(report.get("hypotheses", []) or []),
            "experiments": len(report.get("experiments", []) or []),
            "approved": bool(gate.get("approved", False)),
            "alignment_score": float(gate.get("alignment_score", 0.0)),
        }


def evolve_population(meta: MetaGenome, question: str = "Optimize prosthetic grip stability") -> Dict[str, Any]:
    loop = EvolutionLoop()
    result = loop.run(question=question, population_size=24, generations=12)
    return {
        "score": result["best_fitness"],
        "candidate": result["best_candidate"],
        "meta": meta.as_dict(),
    }


def meta_evolve(meta_population: List[MetaGenome], question: str = "Optimize prosthetic grip stability") -> List[MetaGenome]:
    scored: List[Tuple[float, MetaGenome]] = []
    for meta in meta_population:
        result = evolve_population(meta=meta, question=question)
        scored.append((float(result["score"]), meta))

    scored.sort(key=lambda item: item[0], reverse=True)
    survivors = [meta for _, meta in scored[: max(1, len(meta_population) // 2)]]

    new_population: List[MetaGenome] = []
    for _ in range(len(meta_population)):
        parent = random.choice(survivors)
        child = MetaGenome()
        child.mutation_rate = parent.mutation_rate
        child.selection_pressure = parent.selection_pressure
        child.reward_bias = parent.reward_bias
        child.mutate()
        new_population.append(child)
    return new_population
