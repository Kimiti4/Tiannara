from __future__ import annotations

import random
from typing import Any, Dict, Tuple


class LLMMutator:
    """
    Simulated LLM-guided meta mutation.
    The heuristics use recent telemetry to pick a strategy instead of mutating blindly.
    """

    strategies = (
        "increase_exploration",
        "reduce_noise",
        "favor_stability",
        "boost_diversity",
    )

    def mutate_meta(self, meta, signal: Dict[str, Any] | None = None) -> Tuple[object, str]:
        choice = self._choose_strategy(signal or {})

        if choice == "increase_exploration":
            meta.mutation_rate *= 1.2
        elif choice == "reduce_noise":
            meta.mutation_rate *= 0.85
        elif choice == "favor_stability":
            meta.reward_bias *= 1.1
        elif choice == "boost_diversity":
            meta.selection_pressure *= 0.9

        meta.mutation_rate = min(0.45, max(0.01, float(meta.mutation_rate)))
        meta.selection_pressure = min(0.95, max(0.35, float(meta.selection_pressure)))
        meta.reward_bias = min(1.5, max(0.6, float(meta.reward_bias)))

        return meta, choice

    def _choose_strategy(self, signal: Dict[str, Any]) -> str:
        delta = float(signal.get("delta", 0.0) or 0.0)
        risk = float(signal.get("risk", 0.0) or 0.0)
        difficulty = float(signal.get("difficulty", 1.0) or 1.0)
        diversity = float(signal.get("diversity", 0.5) or 0.5)

        if delta < 0.0 or difficulty >= 1.35:
            return "increase_exploration"
        if risk >= 0.18:
            return "favor_stability"
        if diversity <= 0.35:
            return "boost_diversity"
        if delta >= 0.08 and risk <= 0.08:
            return "reduce_noise"
        return random.choice(self.strategies)
