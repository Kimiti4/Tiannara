from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Dict, Optional

from tiannara_core.analytics.metrics import build_metrics
from tiannara_core.discovery.engine import DiscoveryEngine
from tiannara_core.distributed.manager import run_distributed, summarize_results
from tiannara_core.evolution.evolution_loop import EvolutionLoop
from tiannara_core.evolution.llm_mutator import LLMMutator
from tiannara_core.evolution.meta_engine import MetaGenome
from tiannara_core.integration.pros_adapter import evaluate_with_pros
from tiannara_core.memory.experience_db import ExperienceDB
from tiannara_core.memory.intelligence import extract_patterns, suggest_strategy
from tiannara_core.memory.knowledge_store import KnowledgeStore
from tiannara_core.safety.gate import SafetyGate
from tiannara_core.sim.adversarial_env import AdversarialEnvironment
from tiannara_core.sim.simulator import clamp


def _round_float(value: float) -> float:
    return round(float(value), 4)


@dataclass
class Orchestrator:
    store: KnowledgeStore = field(default_factory=KnowledgeStore)
    gate: SafetyGate = field(default_factory=SafetyGate)
    memory: ExperienceDB = field(default_factory=ExperienceDB)
    discovery: Optional[DiscoveryEngine] = None
    evolution: Optional[EvolutionLoop] = None
    meta_population: list[MetaGenome] = field(default_factory=list)
    llm: LLMMutator = field(default_factory=LLMMutator)
    env: AdversarialEnvironment = field(default_factory=AdversarialEnvironment)
    worker_count: int = 4

    def __post_init__(self) -> None:
        if self.discovery is None:
            self.discovery = DiscoveryEngine(store=self.store, gate=self.gate)
        if not self.meta_population:
            self.meta_population = [MetaGenome() for _ in range(6)]

    def run_cycle(
        self,
        question: str = "optimize system",
        text: str | None = None,
        *,
        source: str = "autonomous_cycle",
        population_size: int = 40,
        generations: int = 15,
        fitness_function: str = "grip_stability",
        workers: int = 4,
        genome_type: str = "mixed",
    ) -> Dict[str, Any]:
        report = self.discovery.analyze(question=question, text=text, source=source) if self.discovery else None

        entries = self.memory.get_all()
        patterns = extract_patterns(entries)
        suggestion = suggest_strategy(patterns)

        configs = self._build_configs(
            question=question,
            population_size=population_size,
            generations=generations,
            fitness_function=fitness_function,
            genome_type=genome_type,
            suggestion=suggestion,
        )
        results = run_distributed(configs, workers=max(1, min(int(workers), len(configs))))
        summary = summarize_results(results)
        best = results[0]

        pros_feedback = evaluate_with_pros(candidate=best["best_candidate"])

        gate = (report or {}).get("safety_gate", {}) or {}
        alignment_bonus = 0.05 * float(gate.get("alignment_score", 0.0))
        approval_adjustment = 0.04 if gate.get("approved") else -0.03

        final_score = clamp(float(best["score"]) + alignment_bonus + approval_adjustment - pros_feedback["risk"])

        diversity = self._compute_diversity(results)
        llm_decisions = []
        for index, meta in enumerate(self.meta_population):
            signal = {
                "delta": build_metrics(best["history"]).get("delta", 0.0),
                "risk": pros_feedback["risk"],
                "difficulty": best["adversarial"]["difficulty_end"],
                "diversity": diversity,
                "worker_rank": index + 1,
            }
            mutated_meta, choice = self.llm.mutate_meta(meta, signal=signal)
            llm_decisions.append(
                {
                    "worker_id": index + 1,
                    "choice": choice,
                    "meta": mutated_meta.as_dict(),
                }
            )

        self.env.difficulty = float(best["adversarial"]["difficulty_end"])

        result = {
            "question": question,
            "source": source,
            "score": _round_float(final_score),
            "meta": dict(best["meta"]),
            "report": report,
            "intelligence": patterns,
            "strategy": suggestion,
            "simulation": best["simulation"],
            "history": best["history"],
            "pros": pros_feedback,
            "metrics": build_metrics(best["history"]),
            "evolution": {
                "question": question,
                "fitness_function": fitness_function,
                "population_size": population_size,
                "generations_run": generations,
                "best_fitness": _round_float(best["score"]),
                "best_candidate": best["best_candidate"],
                "best_metrics": best["simulation"],
                "history": best["history"],
                "leaderboard": self._leaderboard(results),
                "converged": bool(best["converged"]),
                "genome_type": best["genome_type"],
            },
            "distributed": {
                **summary,
                "requested_workers": max(1, min(int(workers), len(configs))),
                "top_runs": self._top_runs(results),
            },
            "adversarial": {
                "difficulty_start": _round_float(configs[0]["difficulty"]),
                "difficulty_end": _round_float(best["adversarial"]["difficulty_end"]),
                "difficulty_delta": _round_float(best["adversarial"]["difficulty_end"] - configs[0]["difficulty"]),
                "trend": best["adversarial"]["history"],
            },
            "meta_evolution": {
                "population": [meta.as_dict() for meta in self.meta_population],
                "llm_decisions": llm_decisions,
            },
            "telemetry": {
                "phase": "phase5",
                "genome_strategy": genome_type,
                "execution_backend": summary["backend"],
                "difficulty": _round_float(self.env.difficulty),
                "diversity": _round_float(diversity),
            },
        }

        experience = self.memory.add(result)

        return {
            **result,
            "experience_id": experience["id"],
            "ts": experience["ts"],
        }

    def improve(self):
        for meta in self.meta_population:
            meta.mutate()

    def _build_configs(
        self,
        *,
        question: str,
        population_size: int,
        generations: int,
        fitness_function: str,
        genome_type: str,
        suggestion: Dict[str, float] | None,
    ) -> list[Dict[str, Any]]:
        configs: list[Dict[str, Any]] = []
        for index, meta in enumerate(self.meta_population):
            mutation_rate = self._blend(meta.mutation_rate, (suggestion or {}).get("mutation_rate"))
            selection_pressure = self._blend(meta.selection_pressure, (suggestion or {}).get("selection_pressure"))
            reward_bias = self._blend(meta.reward_bias, (suggestion or {}).get("reward_bias"))

            configs.append(
                {
                    "worker_id": index + 1,
                    "question": question,
                    "population_size": population_size,
                    "generations": generations,
                    "fitness_function": fitness_function,
                    "mutation_rate": mutation_rate,
                    "selection_pressure": selection_pressure,
                    "reward_bias": reward_bias,
                    "genome_type": self._resolve_genome_type(genome_type, index),
                    "difficulty": _round_float(self.env.difficulty * (1.0 + (0.03 * index))),
                    "use_adversary": True,
                }
            )
        return configs

    def _blend(self, current: float, suggested: float | None) -> float:
        if suggested is None:
            return _round_float(current)
        return _round_float((float(current) * 0.6) + (float(suggested) * 0.4))

    def _resolve_genome_type(self, genome_type: str, index: int) -> str:
        requested = str(genome_type).lower()
        if requested in {"neural", "graph"}:
            return requested
        return "graph" if index % 2 else "neural"

    def _compute_diversity(self, results: list[Dict[str, Any]]) -> float:
        if not results:
            return 0.0
        unique = {item.get("genome_type", "unknown") for item in results}
        return len(unique) / max(1, len(results))

    def _leaderboard(self, results: list[Dict[str, Any]]) -> list[Dict[str, Any]]:
        board = []
        for rank, item in enumerate(results[:5], start=1):
            board.append(
                {
                    "rank": rank,
                    "worker_id": item["worker_id"],
                    "fitness": _round_float(item["score"]),
                    "candidate": item["best_candidate"],
                    "genome_type": item["genome_type"],
                    "adversarial": item["adversarial"],
                }
            )
        return board

    def _top_runs(self, results: list[Dict[str, Any]]) -> list[Dict[str, Any]]:
        items = []
        for item in results[:3]:
            items.append(
                {
                    "worker_id": item["worker_id"],
                    "score": _round_float(item["score"]),
                    "genome_type": item["genome_type"],
                    "meta": item["meta"],
                    "difficulty_end": item["adversarial"]["difficulty_end"],
                }
            )
        return items


def autonomous_cycle(
    question: str,
    text: str | None = None,
    *,
    source: str = "autonomous_cycle",
) -> Dict[str, Any]:
    orchestrator = Orchestrator()
    return orchestrator.run_cycle(question=question, text=text, source=source)
