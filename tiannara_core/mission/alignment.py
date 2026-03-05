from __future__ import annotations
from dataclasses import dataclass
from typing import Dict, List, Tuple


@dataclass
class AlignmentScorer:
    """
    Lightweight mission alignment scorer.
    Returns a score in [0, 1] + reasons.

    This is intentionally simple now; later you can replace with richer evaluators.
    """

    positive_signals: Tuple[str, ...] = (
        "safety", "ethics", "simulation", "bench test", "risk", "mitigation",
        "validation", "evidence", "measurement", "reproducible", "harm reduction",
        "life", "conservation", "health", "secure", "privacy",
    )

    negative_signals: Tuple[str, ...] = (
        "exploit", "bypass", "steal", "malware", "harm", "weapon", "kill",
        "fraud", "phishing", "ransomware", "ddos",
    )

    def score_text(self, text: str) -> Dict[str, object]:
        t = (text or "").lower()

        pos = sum(1 for s in self.positive_signals if s in t)
        neg = sum(1 for s in self.negative_signals if s in t)

        # Base score around 0.7, pull down if negative, up if positive.
        score = 0.70
        score += min(0.25, pos * 0.03)
        score -= min(0.60, neg * 0.10)

        score = max(0.0, min(1.0, score))

        reasons: List[str] = []
        if neg > 0:
            reasons.append("Contains risk-heavy / misuse-like signals.")
        if pos > 0:
            reasons.append("Contains safety/science validation signals.")
        if not reasons:
            reasons.append("Neutral alignment signals.")

        return {"alignment_score": score, "pos_hits": pos, "neg_hits": neg, "reasons": reasons}