"""
Evidence-backed causal API adapter.

Uses DoWhy for causal-effect estimation and PCMCI for temporal discovery.
Missing scientific backends fail closed. Correlation-only fallback output is never
labelled as causal evidence.
"""

import logging
import time
from typing import Any, Dict

import numpy as np

from tiannara_api.engines.base import BaseEngine

logger = logging.getLogger(__name__)


class CausalEngine(BaseEngine):
    """Bounded causal inference/discovery adapter."""

    def __init__(self):
        super().__init__(name="causal_engine", version="2.0.0")

    def process(self, request: Dict[str, Any]) -> Dict[str, Any]:
        start = time.perf_counter()
        try:
            if not isinstance(request, dict):
                raise ValueError("request must be a mapping")
            task = str(request.get("task", "estimate_effect")).strip().lower()

            if task == "estimate_effect":
                result = self._estimate_effect(request)
            elif task in {"discover_temporal", "discover_causal_graph"}:
                result = self._discover_temporal(request)
            else:
                raise ValueError("unsupported_causal_task")

            latency_ms = (time.perf_counter() - start) * 1000
            self.track_request(latency_ms, True)
            return {"status": "success", "engine": self.name, "task": task,
                    "result": result, "latency_ms": round(latency_ms, 2)}
        except Exception as exc:
            latency_ms = (time.perf_counter() - start) * 1000
            self.track_request(latency_ms, False)
            logger.warning("Causal request rejected/failed: %s", exc)
            return {"status": "error", "engine": self.name, "error": str(exc),
                    "latency_ms": round(latency_ms, 2)}

    def _estimate_effect(self, request: Dict[str, Any]) -> Dict[str, Any]:
        try:
            from tiannara_core.causal.dowhy_integration import CausalGraphDiscovery
        except Exception as exc:
            raise RuntimeError(f"causal_backend_unavailable:{exc}") from exc

        data = np.asarray(request.get("data"), dtype=float)
        names = request.get("variable_names")
        treatment = request.get("treatment")
        outcome = request.get("outcome")
        if data.ndim != 2 or data.shape[0] < 100:
            raise ValueError("causal estimation requires a 2-D dataset with at least 100 observations")
        if not isinstance(names, list) or len(names) != data.shape[1]:
            raise ValueError("variable_names must match data columns")
        if treatment not in names or outcome not in names or treatment == outcome:
            raise ValueError("treatment and outcome must be distinct named columns")

        common_causes = request.get("confounders", [])
        if not isinstance(common_causes, list) or any(c not in names for c in common_causes):
            raise ValueError("confounders must be a list of known variable names")

        discovery = CausalGraphDiscovery(min_observations=100)
        estimate = discovery.estimate_causal_effect(
            data, treatment, outcome, names, common_causes=common_causes,
            method=request.get("method", "linear_regression")
        )
        return {
            "treatment": estimate.treatment,
            "outcome": estimate.outcome,
            "estimated_effect": estimate.estimated_effect,
            "confidence_interval": estimate.confidence_interval,
            "p_value": estimate.p_value,
            "method_used": estimate.method_used,
            "num_samples": estimate.num_samples,
            "assumptions": {
                "unconfoundedness": "not independently established by this adapter",
                "overlap": "not independently established by this adapter",
                "consistency": "not independently established by this adapter",
            },
            "epistemic_status": "causal_estimate_conditional_on_model_assumptions",
        }

    def _discover_temporal(self, request: Dict[str, Any]) -> Dict[str, Any]:
        try:
            from tiannara_core.causal.pcmci_discovery import PCMCIDiscovery
        except Exception as exc:
            raise RuntimeError(f"causal_backend_unavailable:{exc}") from exc

        data = np.asarray(request.get("data"), dtype=float)
        names = request.get("variable_names")
        if data.ndim != 2 or data.shape[0] < 20:
            raise ValueError("temporal discovery requires a 2-D dataset with at least 20 observations")
        if not isinstance(names, list) or len(names) != data.shape[1]:
            raise ValueError("variable_names must match data columns")

        discovery = PCMCIDiscovery(
            tau_max=int(request.get("tau_max", 5)),
            alpha=float(request.get("alpha", 0.05)),
        )
        if not discovery.tigramite_available:
            raise RuntimeError("causal_backend_unavailable:tigramite")

        graph = discovery.discover_causal_graph(data, names)
        return {
            "variables": graph.variables,
            "links": [
                {"source": l.source, "target": l.target, "lag": l.lag,
                 "strength": l.strength, "p_value": l.p_value}
                for l in graph.links
            ],
            "discovery_metadata": graph.discovery_metadata,
            "epistemic_status": "temporal_causal_discovery_candidate_links",
        }

    def get_health(self) -> Dict[str, Any]:
        metrics = self.get_metrics()
        return {"engine": self.name, "status": metrics["status"],
                "uptime_percentage": None, "uptime_status": "not_measured",
                "total_requests": metrics["total_requests"],
                "avg_latency_ms": metrics["avg_latency_ms"],
                "success_rate": metrics["success_rate"]}
