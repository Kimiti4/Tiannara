from __future__ import annotations
from dataclasses import dataclass
from typing import Dict, Any, List

from tiannara_core.memory.knowledge_store import KnowledgeStore


@dataclass
class ExperimentDesigner:
    store: KnowledgeStore

    def design(self, question: str, max_experiments: int = 6) -> List[Dict[str, Any]]:
        hyps = self.store.list("hypothesis")
        out: List[Dict[str, Any]] = []

        for h in hyps[:max_experiments]:
            exp = self._simulation_first_template(question=question, hypothesis=h.payload.get("hypothesis", ""))
            item = self.store.add(source="discovery", kind="experiment", payload=exp, trust=0.60)
            out.append({"id": item.id, **exp})

        if not out:
            exp = self._simulation_first_template(question=question, hypothesis="Baseline improvement exploration.")
            item = self.store.add(source="discovery", kind="experiment", payload=exp, trust=0.60)
            out.append({"id": item.id, **exp})

        return out[:max_experiments]

    def _simulation_first_template(self, question: str, hypothesis: str) -> Dict[str, Any]:
        return {
            "title": "Simulation-first parameter sweep",
            "question": question,
            "hypothesis": hypothesis,
            "type": "simulation",
            "variables": [
                {"name": "damping", "range": [0.1, 0.9], "step": 0.05},
                {"name": "stiffness", "range": [0.1, 0.9], "step": 0.05},
                {"name": "grip_force", "range": [0.1, 0.9], "step": 0.05},
            ],
            "measurements": [
                "success_rate",
                "slip_risk",
                "crush_risk",
                "jerk_risk",
                "fatigue_sensitivity",
            ],
            "controls": [
                "baseline configuration",
                "fixed input tags set (hand/precision/unknown)",
                "constant noise seed for repeatability",
            ],
            "acceptance_criteria": [
                "success_rate improves vs baseline",
                "risk metrics do not increase beyond thresholds",
            ],
            "risks_and_mitigation": [
                "Overfitting to simulator → validate with bench tests later",
                "Metric definition drift → lock metric schema version",
            ],
            "ethics_and_safety": [
                "No real-world activation without validation + safety gate approval.",
                "Prefer reversible, low-risk adjustments first.",
            ],
        }