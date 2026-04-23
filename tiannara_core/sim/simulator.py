from __future__ import annotations

import random
from dataclasses import dataclass, field
from typing import Any, Dict

from tiannara_core.sim.environments import control_task, energy_efficiency_task, stability_task


SIMULATION_PROFILES: dict[str, dict[str, float]] = {
    "grip_stability": {"control": 0.4, "stability": 0.3, "efficiency": 0.3},
    "maximize_accuracy": {"control": 0.55, "stability": 0.25, "efficiency": 0.20},
    "optimize_efficiency": {"control": 0.25, "stability": 0.20, "efficiency": 0.55},
}


def clamp(value: float, low: float = 0.0, high: float = 1.0) -> float:
    return max(low, min(high, float(value)))


def score_control_parameters(
    damping: float,
    stiffness: float,
    grip_force: float,
    *,
    fatigue: float = 0.0,
    question: str = "",
) -> Dict[str, float]:
    """
    Lightweight simulator scoring for grip-stability tuning.
    The numbers are heuristic, but stable and easy to inspect.
    """

    damping = clamp(damping)
    stiffness = clamp(stiffness)
    grip_force = clamp(grip_force)
    fatigue = clamp(fatigue)

    balance_bonus = 1.0 - abs(damping - stiffness)
    grip_window_bonus = 1.0 - abs(grip_force - 0.62)

    slip_risk = clamp(0.68 - (0.52 * damping) - (0.14 * grip_force) + (0.10 * abs(stiffness - damping)))
    crush_risk = clamp((grip_force - 0.82) * 2.4)
    fatigue_penalty = clamp(0.10 + (fatigue * 0.25))

    stability = clamp(
        (0.42 * damping)
        + (0.26 * stiffness)
        + (0.18 * balance_bonus)
        + (0.14 * grip_window_bonus)
        - fatigue_penalty
    )

    context_bonus = 0.0
    q = question.lower()
    if "fatigue" in q:
        context_bonus += 0.04 * damping
    if "slip" in q or "stability" in q:
        context_bonus += 0.03 * balance_bonus

    score = clamp(stability - (0.55 * slip_risk) - (0.45 * crush_risk) + context_bonus)

    return {
        "score": round(score, 4),
        "stability": round(stability, 4),
        "slip_risk": round(slip_risk, 4),
        "crush_risk": round(crush_risk, 4),
        "fatigue_penalty": round(fatigue_penalty, 4),
    }


def run_simulation(agent, *, profile: str = "grip_stability") -> tuple[float, Dict[str, float]]:
    weights = SIMULATION_PROFILES.get(profile, SIMULATION_PROFILES["grip_stability"])
    scores = {
        "control": round(control_task(agent), 4),
        "stability": round(stability_task(agent), 4),
        "efficiency": round(energy_efficiency_task(agent), 4),
    }

    total = clamp(sum(weights[name] * scores[name] for name in scores))
    return round(total, 4), scores


class ProstheticSimulator:
    """
    Realism helpers:
    - tremor/noise injection into joint angles
    - fatigue accumulation over time (dt-based)
    - stability penalty based on fatigue
    """

    def __init__(self):
        self.fatigue = 0.0  # 0..1

        # Rates are per second (tunable)
        self.fatigue_rise_grip = 0.30  # /sec
        self.fatigue_recover_release = 0.15  # /sec
        self.fatigue_recover_stabilize = 0.08  # /sec

    def add_tremor(self, joint_angles, intensity=0.8):
        return [a + random.uniform(-intensity, intensity) for a in joint_angles]

    def update_fatigue(self, intent, dt=0.05):
        """
        dt in seconds. Example: dt=0.05 means 20Hz control loop.
        """
        if intent == "grip":
            self.fatigue = min(1.0, self.fatigue + self.fatigue_rise_grip * dt)
        elif intent == "release":
            self.fatigue = max(0.0, self.fatigue - self.fatigue_recover_release * dt)
        elif intent == "stabilize":
            self.fatigue = max(0.0, self.fatigue - self.fatigue_recover_stabilize * dt)
        else:
            self.fatigue = max(0.0, self.fatigue - 0.05 * dt)

    def stability_penalty(self):
        return 0.15 * self.fatigue


@dataclass
class Simulator:
    prosthetic: ProstheticSimulator = field(default_factory=ProstheticSimulator)

    def evaluate(self, evolution_result: Dict[str, Any], report: Dict[str, Any] | None = None) -> Dict[str, Any]:
        candidate = evolution_result.get("best_candidate", {}) or {}
        metrics = score_control_parameters(
            damping=float(candidate.get("damping", 0.5)),
            stiffness=float(candidate.get("stiffness", 0.5)),
            grip_force=float(candidate.get("grip_force", 0.5)),
            fatigue=self._estimate_fatigue(report=report, evolution_result=evolution_result),
            question=str((report or {}).get("question") or evolution_result.get("question") or ""),
        )

        approved = bool(((report or {}).get("safety_gate") or {}).get("approved", False))
        adjustment = 0.05 if approved else -0.08
        metrics["score"] = round(clamp(metrics["score"] + adjustment), 4)
        metrics["approved"] = approved
        metrics["alignment_score"] = float(((report or {}).get("safety_gate") or {}).get("alignment_score", 0.0))
        return metrics

    def _estimate_fatigue(self, report: Dict[str, Any] | None, evolution_result: Dict[str, Any]) -> float:
        question = str((report or {}).get("question") or evolution_result.get("question") or "").lower()
        fatigue = 0.20
        if "fatigue" in question or "tremor" in question:
            fatigue += 0.15
        if "stability" in question or "slip" in question:
            fatigue += 0.05
        return clamp(fatigue)
