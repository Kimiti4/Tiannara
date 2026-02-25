# tiannara_core/cognition/skill_memory.py

from __future__ import annotations
from typing import Dict, List, Tuple, Any


class SkillMemory:
    """
    Lightweight learning signal store.

    Stores a bias value per (intent, tag).
    - Positive bias increases pattern score in DecisionEngine
    - Negative bias decreases it

    This is NOT ML — it’s a safe, bounded preference memory.
    """

    def __init__(
        self,
            step_good=0.03,
        step_bad=0.08,
        bias_min=-1.0,
        bias_max=1.0,
        decay=0.003,
):
        self.step_good = float(step_good)
        self.step_bad = float(step_bad)
        self.bias_min = float(bias_min)
        self.bias_max = float(bias_max)
        self.decay = float(decay)

        # (intent, tag) -> bias float
        self._bias: Dict[Tuple[str, str], float] = {}

    def _clip(self, x: float) -> float:
        return max(self.bias_min, min(self.bias_max, x))

    def bias(self, intent: str, context_tags: List[str]) -> float:
        """
        Return combined bias for (intent + tags).
        Sums biases across tags and clips to [-1, +1].
        """
        intent = intent or "unknown"
        tags = context_tags or []
        total = 0.0
        for t in tags:
            total += self._bias.get((intent, t), 0.0)
        return self._clip(total)

    # aliases so DecisionEngine can find it no matter what it calls
    get_bias = bias
    bias_for = bias
    score_bias = bias

    def update(
        self,
        intent: str,
        context_tags: List[str],
        outcome: str,
        metrics: Dict[str, Any] | None = None,
    ) -> Dict[str, float]:
        """
        Update biases from outcome + optional metrics.
        Returns dict of updated per-tag biases.
        """
        intent = intent or "unknown"
        tags = context_tags or []
        metrics = metrics or {}

        good = (outcome == "good")

        # Optional: scale penalties for grip failures if risks are high
        penalty_scale = 1.0
        if not good:
            # if we have specific risks, punish a bit more
            slip = float(metrics.get("slip_risk", 0.0))
            crush = float(metrics.get("crush_risk", 0.0))
            jerk = float(metrics.get("jerk_risk", 0.0))
            residual = float(metrics.get("residual_tremor", 0.0))
            penalty_scale += 0.5 * max(slip, crush, jerk, residual)

        updated: Dict[str, float] = {}

        for t in tags:
            key = (intent, t)
            cur = self._bias.get(key, 0.0)

            if good:
                cur += self.step_good
            else:
                cur -= (self.step_bad * penalty_scale)

            cur = self._clip(cur)
            self._bias[key] = cur
            updated[t] = cur

        return updated

    def decay_step(self) -> None:
        """
        Slowly decay all biases toward 0 so it doesn’t lock in forever.
        """
        if self.decay <= 0:
            return

        for k in list(self._bias.keys()):
            v = self._bias[k]
            if v > 0:
                v = max(0.0, v - self.decay)
            elif v < 0:
                v = min(0.0, v + self.decay)

            if abs(v) < 1e-6:
                self._bias.pop(k, None)
            else:
                self._bias[k] = v

    def snapshot(self) -> Dict[str, float]:
        """
        Debug helper.
        """
        return {f"{k[0]}::{k[1]}": v for k, v in self._bias.items()}