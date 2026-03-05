from __future__ import annotations
from dataclasses import dataclass, field
from typing import Dict, List, Tuple


@dataclass
class SafetyPolicy:
    """
    Safety policy for outputs.

    This is a minimal policy:
    - blocks obvious harmful categories
    - steers toward simulation/research framing
    """

    version: str = "v1.0"
    blocked_keywords: Tuple[str, ...] = (
        "build a weapon", "make a bomb", "poison", "phishing", "ransomware",
        "steal", "hack into", "bypass security", "exploit",
    )

    # “Soft steer” hints
    prefer_simulation_phrases: Tuple[str, ...] = (
        "simulate", "bench test", "validate", "measure", "controls", "safety check",
    )

    def check_text(self, text: str) -> Dict[str, object]:
        t = (text or "").lower()
        hits = [kw for kw in self.blocked_keywords if kw in t]
        allowed = len(hits) == 0
        return {"allowed": allowed, "blocked_hits": hits}

    def as_dict(self) -> Dict[str, object]:
        return {
            "version": self.version,
            "blocked_keywords": list(self.blocked_keywords),
            "prefer_simulation_phrases": list(self.prefer_simulation_phrases),
        }