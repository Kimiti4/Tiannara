from __future__ import annotations

import random
from dataclasses import dataclass, field
from typing import Dict, List


def _clamp(value: float, low: float = 0.0, high: float = 1.0) -> float:
    return max(low, min(high, float(value)))


def _resize(values, size: int) -> List[float]:
    resized = [float(value) for value in values]
    if not resized:
        resized = [0.0]
    while len(resized) < size:
        resized.append(resized[len(resized) % len(resized)])
    return resized[:size]


@dataclass
class AdversarialEnvironment:
    difficulty: float = 1.0
    history: List[float] = field(default_factory=list)

    def __post_init__(self) -> None:
        self.difficulty = max(0.2, float(self.difficulty))
        if not self.history:
            self.history.append(round(self.difficulty, 4))

    def generate_input(self, size: int = 5) -> List[float]:
        return [random.gauss(0.0, 1.0) * self.difficulty for _ in range(max(1, int(size)))]

    def evaluate(self, agent) -> Dict[str, float]:
        x = self.generate_input()
        out = [float(value) for value in agent.forward(x)]
        target = _resize(x, len(out) or 1)
        if not out:
            out = [0.0]

        error = sum(abs(left - right) for left, right in zip(out, target)) / len(out)
        score = _clamp(1.0 - error)
        difficulty_before = self.difficulty

        if score > 0.7:
            self.difficulty *= 1.05
        else:
            self.difficulty *= 0.98

        self.difficulty = max(0.2, min(3.0, self.difficulty))
        self.history.append(round(self.difficulty, 4))

        return {
            "score": round(score, 4),
            "error": round(error, 4),
            "difficulty_before": round(difficulty_before, 4),
            "difficulty_after": round(self.difficulty, 4),
        }
