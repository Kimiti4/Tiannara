"""
Bounded logical inference engine.

Implements deterministic Horn-style forward chaining over explicit facts and rules.
It never invents a conclusion and never reports an unproved proposition as true.
"""

import logging
import re
import time
from typing import Any, Dict, Iterable, List, Set, Tuple

from tiannara_api.engines.base import BaseEngine

logger = logging.getLogger(__name__)


class LogicEngine(BaseEngine):
    """Deterministic propositional/Horn reasoning with explicit proof traces."""

    def __init__(self):
        super().__init__(name="logic_engine", version="2.0.0")

    def process(self, request: Dict[str, Any]) -> Dict[str, Any]:
        start = time.perf_counter()
        try:
            if not isinstance(request, dict):
                raise ValueError("request must be a mapping")

            facts = self._normalise_facts(request.get("facts", request.get("premise")))
            rules = self._normalise_rules(request.get("rules", []))
            query = self._normalise_atom(request.get("question", request.get("query")))
            if not query:
                raise ValueError("question/query is required")
            if not facts and not rules:
                raise ValueError("at least one explicit fact or rule is required")

            derived = set(facts)
            proof = [{"conclusion": fact, "from": [], "rule": None} for fact in sorted(facts)]

            changed = True
            while changed:
                changed = False
                for antecedents, consequent in rules:
                    if consequent not in derived and all(a in derived for a in antecedents):
                        derived.add(consequent)
                        proof.append({
                            "conclusion": consequent,
                            "from": sorted(antecedents),
                            "rule": {"if": sorted(antecedents), "then": consequent},
                        })
                        changed = True

            entailed = query in derived
            supporting = next((p for p in proof if p["conclusion"] == query), None)
            result = {
                "query": query,
                "entailed": entailed,
                "conclusion": query if entailed else None,
                "proof": [supporting] if supporting else [],
                "derived_facts": sorted(derived),
                "rule_count": len(rules),
                "fact_count": len(facts),
            }

            latency_ms = (time.perf_counter() - start) * 1000
            self.track_request(latency_ms, True)
            return {
                "status": "success",
                "engine": self.name,
                "result": result,
                "latency_ms": round(latency_ms, 2),
            }
        except Exception as exc:
            latency_ms = (time.perf_counter() - start) * 1000
            self.track_request(latency_ms, False)
            logger.warning("Logic request rejected/failed: %s", exc)
            return {"status": "error", "engine": self.name, "error": str(exc),
                    "latency_ms": round(latency_ms, 2)}

    @staticmethod
    def _normalise_atom(value: Any) -> str:
        if not isinstance(value, str):
            return ""
        value = re.sub(r"\s+", " ", value.strip())
        if not value or any(ch in value for ch in ";{}"):
            raise ValueError("atoms must be non-empty strings without rule delimiters")
        return value

    @classmethod
    def _normalise_facts(cls, value: Any) -> Set[str]:
        if value is None:
            return set()
        values = [value] if isinstance(value, str) else value
        if not isinstance(values, Iterable) or isinstance(values, (bytes, dict)):
            raise ValueError("facts/premise must be a string or list of strings")
        return {atom for item in values if (atom := cls._normalise_atom(item))}

    @classmethod
    def _normalise_rules(cls, rules: Any) -> List[Tuple[List[str], str]]:
        if rules is None:
            return []
        if not isinstance(rules, list):
            raise ValueError("rules must be a list")
        normalised = []
        for rule in rules:
            if not isinstance(rule, dict):
                raise ValueError("each rule must be a mapping")
            antecedents = rule.get("if", rule.get("premises"))
            consequent = rule.get("then", rule.get("conclusion"))
            if isinstance(antecedents, str):
                antecedents = [antecedents]
            if not isinstance(antecedents, list) or not antecedents:
                raise ValueError("rule 'if' must contain at least one antecedent")
            ants = [cls._normalise_atom(a) for a in antecedents]
            cons = cls._normalise_atom(consequent)
            if not cons or any(not a for a in ants):
                raise ValueError("rule atoms must be non-empty strings")
            normalised.append((ants, cons))
        return normalised

    def get_health(self) -> Dict[str, Any]:
        metrics = self.get_metrics()
        return {"engine": self.name, "status": metrics["status"],
                "uptime_percentage": None, "uptime_status": "not_measured",
                "total_requests": metrics["total_requests"],
                "avg_latency_ms": metrics["avg_latency_ms"],
                "success_rate": metrics["success_rate"]}
