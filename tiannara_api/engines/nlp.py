"""
Evidence-backed NLP API engine.

The API adapter delegates to the repository's implemented AdvancedNLPEngine.
Unsupported capabilities fail explicitly; no synthetic NLP result is returned.
"""

import logging
import time
from typing import Any, Dict

from tiannara_api.engines.base import BaseEngine
from tiannara_core.nlp.advanced_nlp import AdvancedNLPEngine

logger = logging.getLogger(__name__)


class NLPEngine(BaseEngine):
    """Bounded NLP adapter over the implemented core NLP engine."""

    SUPPORTED_TASKS = {"analyze", "sentiment", "entities", "classify_intent", "semantic_search"}

    def __init__(self):
        super().__init__(name="nlp_engine", version="2.0.0")
        self.core = AdvancedNLPEngine()

    def process(self, request: Dict[str, Any]) -> Dict[str, Any]:
        start = time.perf_counter()
        try:
            if not isinstance(request, dict):
                raise ValueError("request must be a mapping")

            task = str(request.get("task", "analyze")).strip().lower()
            text = request.get("text")

            if task not in self.SUPPORTED_TASKS:
                raise ValueError(
                    f"unsupported_nlp_task:{task}; supported={sorted(self.SUPPORTED_TASKS)}"
                )
            if task != "semantic_search" and (not isinstance(text, str) or not text.strip()):
                raise ValueError("text must be a non-empty string")

            if task in {"analyze", "classify_intent"}:
                result = self.core.classify_intent(text).to_dict() if hasattr(
                    self.core.classify_intent(text), "to_dict"
                ) else self._intent_to_dict(self.core.classify_intent(text))
            elif task == "sentiment":
                result = {"sentiment": self.core.analyze_sentiment(text)}
            elif task == "entities":
                result = {
                    "entities": [self._entity_to_dict(e) for e in self.core.extract_entities(text)]
                }
            else:
                query = text if isinstance(text, str) else request.get("query")
                if not isinstance(query, str) or not query.strip():
                    raise ValueError("query must be a non-empty string for semantic_search")
                for item in request.get("knowledge_base", []):
                    if isinstance(item, dict) and isinstance(item.get("text"), str):
                        self.core.add_to_knowledge_base(item["text"], item.get("metadata", {}))
                matches = self.core.semantic_search(query, int(request.get("top_k", 5)))
                result = {
                    "matches": [
                        {
                            "matched_text": m.matched_text,
                            "similarity_score": m.similarity_score,
                            "metadata": m.metadata,
                        }
                        for m in matches
                    ]
                }

            latency_ms = (time.perf_counter() - start) * 1000
            self.track_request(latency_ms, True)
            return {
                "status": "success",
                "engine": self.name,
                "task": task,
                "result": result,
                "latency_ms": round(latency_ms, 2),
            }
        except Exception as exc:
            latency_ms = (time.perf_counter() - start) * 1000
            self.track_request(latency_ms, False)
            logger.warning("NLP request rejected/failed: %s", exc)
            return {
                "status": "error",
                "engine": self.name,
                "error": str(exc),
                "latency_ms": round(latency_ms, 2),
            }

    @staticmethod
    def _entity_to_dict(entity):
        return {
            "entity_type": entity.entity_type,
            "value": entity.text,
            "confidence": entity.confidence,
            "start_pos": entity.start_pos,
            "end_pos": entity.end_pos,
        }

    @staticmethod
    def _intent_to_dict(result):
        return {
            "category": result.category.value,
            "sub_intent": result.sub_intent,
            "confidence": result.confidence,
            "entities": [NLPEngine._entity_to_dict(e) for e in result.entities],
            "sentiment": result.sentiment,
            "raw_scores": result.raw_scores,
        }

    def get_health(self) -> Dict[str, Any]:
        metrics = self.get_metrics()
        return {
            "engine": self.name,
            "status": metrics["status"],
            "uptime_percentage": None,
            "uptime_status": "not_measured",
            "total_requests": metrics["total_requests"],
            "avg_latency_ms": metrics["avg_latency_ms"],
            "success_rate": metrics["success_rate"],
        }
