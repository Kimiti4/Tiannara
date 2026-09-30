"""Deterministic curiosity and research-thread selector.

Curiosity is driven by epistemic value: novelty, unresolved contradiction,
knowledge gap and expected information gain. It is not random choice.
"""
from __future__ import annotations

from dataclasses import dataclass
from typing import Any


@dataclass(frozen=True)
class CuriosityCandidate:
    goal: Any
    score: float
    reasons: tuple[str, ...]


class CuriosityEngine:
    def __init__(self):
        self.history: list[Any] = []

    def score_novelty(self, trace):
        if not self.history or not trace:
            return 1.0
        previous = self.history[-1]
        try:
            current = trace[-1]["state"]
            prior = previous[-1]["state"]
            numeric = [
                abs(float(v) - float(prior.get(k, v)))
                for k, v in current.items()
                if isinstance(v, (int, float)) and isinstance(prior.get(k), (int, float))
            ]
            return min(1.0, sum(numeric) / max(1, len(numeric)))
        except (KeyError, TypeError, ValueError):
            return 0.5

    def rank_candidates(self, candidates: list[Any]) -> list[CuriosityCandidate]:
        ranked = []
        for candidate in candidates:
            if isinstance(candidate, dict):
                novelty = float(candidate.get("novelty", 0.0))
                uncertainty = float(candidate.get("uncertainty", 0.0))
                contradiction = float(candidate.get("contradiction", 0.0))
                impact = float(candidate.get("impact", 0.0))
            else:
                novelty = uncertainty = contradiction = 0.0
                impact = 0.1
            score = 0.30 * novelty + 0.30 * uncertainty + 0.25 * contradiction + 0.15 * impact
            reasons = tuple(k for k, v in {
                "novelty": novelty, "uncertainty": uncertainty,
                "contradiction": contradiction, "impact": impact
            }.items() if v > 0.5)
            ranked.append(CuriosityCandidate(candidate, score, reasons))
        return sorted(ranked, key=lambda x: x.score, reverse=True)

    def select_goal(self, hypotheses):
        ranked = self.rank_candidates(hypotheses or [])
        if not ranked:
            return {"goal": "inspect_knowledge_gaps", "reason": "no_candidate_hypotheses"}
        selected = ranked[0]
        self.history.append(hypotheses)
        return {
            "goal": selected.goal,
            "score": selected.score,
            "reasons": list(selected.reasons),
            "selection_basis": "epistemic_value",
        }
