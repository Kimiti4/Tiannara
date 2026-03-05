from __future__ import annotations
from dataclasses import dataclass
from typing import Dict, Any, List

from tiannara_core.memory.knowledge_store import KnowledgeStore


@dataclass
class Hypothesizer:
    store: KnowledgeStore

    def generate(self, question: str, max_hypotheses: int = 5) -> List[Dict[str, Any]]:
        claims = self.store.list("claim")
        # pick top claims by confidence
        ranked = sorted(claims, key=lambda x: float(x.payload.get("confidence", 0.0)), reverse=True)
        top_claim_texts: List[str] = []
        for c in ranked[:8]:
            for s in (c.payload.get("claims") or []):
                top_claim_texts.append(s)

        hypotheses: List[Dict[str, Any]] = []

        # Simple heuristic hypotheses: convert “claim” → “if we adjust X, then Y improves”
        for s in top_claim_texts[:max_hypotheses]:
            h = {
                "hypothesis": f"If we validate and tune parameters related to: '{self._shorten(s)}', then outcome metrics will improve.",
                "based_on_claim": s,
                "testable": True,
                "falsifier": "If controlled tests show no metric improvement or negative side effects (e.g., higher risk), reject.",
            }
            item = self.store.add(source="discovery", kind="hypothesis", payload=h, trust=0.55)
            hypotheses.append({"id": item.id, **h})

        # Always add one “null hypothesis”
        if len(hypotheses) < max_hypotheses:
            h0 = {
                "hypothesis": "Null: Proposed changes produce no measurable improvement compared to baseline under controlled conditions.",
                "based_on_claim": None,
                "testable": True,
                "falsifier": "If improvement exceeds threshold with statistical confidence, reject null.",
            }
            item = self.store.add(source="discovery", kind="hypothesis", payload=h0, trust=0.60)
            hypotheses.append({"id": item.id, **h0})

        return hypotheses[:max_hypotheses]

    def _shorten(self, s: str, n: int = 120) -> str:
        s = s.strip()
        return s if len(s) <= n else s[: n - 3] + "..."