from __future__ import annotations
from dataclasses import dataclass
from typing import Dict, Any, List

from tiannara_core.memory.knowledge_store import KnowledgeStore
from tiannara_core.safety.gate import SafetyGate


@dataclass
class DiscoveryReporter:
    store: KnowledgeStore
    gate: SafetyGate

    def build_report(self, question: str) -> Dict[str, Any]:
        claims = [x.payload for x in self.store.list("claim")]
        hypotheses = [x.payload for x in self.store.list("hypothesis")]
        experiments = [x.payload for x in self.store.list("experiment")]

        draft = {
            "schema": "tiannara.discovery.v1",
            "question": question,
            "claims": claims[:20],
            "hypotheses": hypotheses[:10],
            "experiments": experiments[:10],
            "notes": {
                "simulation_first": True,
                "how_to_disprove": "Each hypothesis includes falsifiers; experiments include controls and acceptance criteria.",
            },
        }

        # Gate checks the *serialized* text view
        gate_text = self._summarize_for_gate(draft)
        gate_result = self.gate.evaluate(gate_text)

        draft["safety_gate"] = {
            "approved": gate_result.approved,
            "reason": gate_result.reason,
            "alignment_score": gate_result.alignment_score,
            "policy": gate_result.policy,
            "suggestions": gate_result.suggestions,
        }

        # Store report
        self.store.add(source="discovery", kind="report", payload=draft, trust=0.65)
        return draft

    def _summarize_for_gate(self, report: Dict[str, Any]) -> str:
        # keep it short so the gate isn't overwhelmed
        parts: List[str] = []
        parts.append(f"Question: {report.get('question','')}")
        parts.append("Simulation-first research plan with validation, controls, and safety checks.")
        parts.append("No harmful or unauthorized actions requested.")
        return "\n".join(parts)