from __future__ import annotations
from dataclasses import dataclass
from typing import Dict, Any, Optional

from tiannara_core.mission.constitution import TiannaraConstitution
from tiannara_core.mission.alignment import AlignmentScorer
from tiannara_core.safety.policy import SafetyPolicy
from tiannara_core.defense.oavl import OntologicalAlignmentValidationLattice

@dataclass
class GateResult:
    approved: bool
    reason: str
    alignment_score: float
    policy: Dict[str, Any]
    suggestions: Optional[str] = None


class SafetyGate:
    """
    Final gate before output leaves Tiannara Core.
    NOW WRAPPED BY L6 OAVL (Ontological Alignment Validation Lattice).
    """

    def __init__(
        self,
        constitution: Optional[TiannaraConstitution] = None,
        policy: Optional[SafetyPolicy] = None,
        scorer: Optional[AlignmentScorer] = None,
        min_alignment: float = 0.35,
    ):
        self.oavl = OntologicalAlignmentValidationLattice(
            constitution=constitution,
            policy=policy,
            scorer=scorer,
            min_alignment=min_alignment
        )

    def evaluate(self, text: str) -> GateResult:
        # Delegate to OAVL
        oavl_result = self.oavl.evaluate(text)
        
        # Map back to legacy GateResult
        return GateResult(
            approved=oavl_result.approved,
            reason=oavl_result.reason,
            alignment_score=oavl_result.alignment_score,
            policy={"blocked_hits": oavl_result.policy_hits, "metrics": oavl_result.metrics},
            suggestions=oavl_result.suggestions
        )