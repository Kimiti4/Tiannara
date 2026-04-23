from __future__ import annotations

from typing import Any, Dict, Iterable


def _numeric_score(entry: Dict[str, Any]) -> float | None:
    value = entry.get("score")
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


def extract_patterns(entries: Iterable[Dict[str, Any]]) -> Dict[str, Any]:
    usable = [entry for entry in entries if _numeric_score(entry) is not None]
    if not usable:
        return {}

    avg_score = sum(float(entry["score"]) for entry in usable) / len(usable)
    best = max(usable, key=lambda item: float(item["score"]))

    return {
        "count": len(usable),
        "avg_score": round(avg_score, 4),
        "best_score": round(float(best["score"]), 4),
        "best_config": dict(best.get("meta") or {}),
    }


def suggest_strategy(patterns: Dict[str, Any]) -> Dict[str, float] | None:
    if not patterns:
        return None

    meta = patterns.get("best_config") or {}
    strategy: Dict[str, float] = {}

    for key in ("mutation_rate", "reward_bias", "selection_pressure"):
        if key not in meta:
            continue
        try:
            strategy[key] = float(meta[key])
        except (TypeError, ValueError):
            continue

    return strategy or None
