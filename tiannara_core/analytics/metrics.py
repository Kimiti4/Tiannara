from __future__ import annotations

from typing import Any, Iterable, List


def _coerce_history(history: Iterable[Any]) -> List[float]:
    values: List[float] = []
    for item in history or []:
        if isinstance(item, dict):
            item = item.get("best_fitness", item.get("score"))
        try:
            values.append(round(float(item), 4))
        except (TypeError, ValueError):
            continue
    return values


def build_metrics(history):
    values = _coerce_history(history)
    return {
        "max": max(values) if values else 0.0,
        "min": min(values) if values else 0.0,
        "latest": values[-1] if values else 0.0,
        "delta": round(values[-1] - values[0], 4) if len(values) >= 2 else 0.0,
        "trend": values[-5:] if len(values) >= 5 else values,
    }
