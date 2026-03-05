from __future__ import annotations
from dataclasses import dataclass
from typing import Dict, Any, List
import re

from tiannara_core.memory.knowledge_store import KnowledgeStore


@dataclass
class Extractor:
    store: KnowledgeStore

    def _extract_numbers(self, text: str) -> List[Dict[str, Any]]:
        # captures patterns like "0.25", "25%", "60 Hz", "10nm"
        pattern = r"(?P<num>\d+(\.\d+)?)\s*(?P<unit>%|hz|khz|mhz|ghz|nm|mm|cm|m|kg|g|a|ma|v|mv|w|kw|mw|s|ms|us)?"
        out = []
        for m in re.finditer(pattern, text.lower()):
            num = m.group("num")
            unit = m.group("unit") or ""
            try:
                out.append({"value": float(num), "unit": unit})
            except Exception:
                continue
        return out

    def _claim_candidates(self, text: str) -> List[str]:
        """
        Heuristic: treat assertive sentences as claims.
        """
        sents = re.split(r"(?<=[.!?])\s+", text.strip())
        claims = []
        for s in sents:
            sl = s.lower()
            if any(w in sl for w in ("is ", "are ", "causes", "leads to", "improves", "reduces", "increases", "decreases")):
                if len(s.strip()) >= 25:
                    claims.append(s.strip())
        return claims[:8]

    def extract_from_chunks(self, source: str = "ingest") -> List[Dict[str, Any]]:
        chunks = self.store.list("chunk")
        extracted: List[Dict[str, Any]] = []

        for ch in chunks:
            text = (ch.payload.get("text") or "").strip()
            if not text:
                continue

            nums = self._extract_numbers(text)
            claims = self._claim_candidates(text)

            payload = {
                "chunk_id": ch.id,
                "claims": claims,
                "numbers": nums,
                "entities_hint": self._simple_entities(text),
                "confidence": self._rough_confidence(claims, nums),
            }
            item = self.store.add(source=source, kind="claim", payload=payload, trust=0.55)
            extracted.append({"id": item.id, **payload})

        return extracted

    def _simple_entities(self, text: str) -> List[str]:
        """
        Very lightweight entity hint:
        - extract capitalized tokens and common tech terms
        """
        tech_terms = []
        low = text.lower()
        for k in ("prosthetic", "sensor", "emg", "imu", "actuator", "stiffness", "damping", "grip", "tremor", "fatigue"):
            if k in low:
                tech_terms.append(k)

        caps = re.findall(r"\b[A-Z][a-zA-Z0-9_-]{2,}\b", text)
        caps = [c for c in caps if c.lower() not in ("the", "and", "for", "with")]
        # dedupe preserving order
        seen = set()
        ents = []
        for e in tech_terms + caps:
            if e not in seen:
                ents.append(e)
                seen.add(e)
        return ents[:15]

    def _rough_confidence(self, claims: List[str], nums: List[Dict[str, Any]]) -> float:
        # more claims + more numbers => slightly higher confidence
        c = 0.35
        c += min(0.35, 0.06 * len(claims))
        c += min(0.25, 0.03 * len(nums))
        return max(0.0, min(1.0, c))