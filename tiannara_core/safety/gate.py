from __future__ import annotations
from dataclasses import dataclass
from typing import Dict, Any, Optional

from tiannara_core.mission.constitution import TiannaraConstitution
from tiannara_core.mission.alignment import AlignmentScorer
from tiannara_core.safety.policy import SafetyPolicy


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
    """

    def __init__(
        self,
        constitution: Optional[TiannaraConstitution] = None,
        policy: Optional[SafetyPolicy] = None,
        scorer: Optional[AlignmentScorer] = None,
        min_alignment: float = 0.35,
    ):
        self.constitution = constitution or TiannaraConstitution()
        self.policy = policy or SafetyPolicy()
        self.scorer = scorer or AlignmentScorer()
        self.min_alignment = float(min_alignment)

    def evaluate(self, text: str) -> GateResult:
        policy_check = self.policy.check_text(text)
        alignment = self.scorer.score_text(text)
        a_score = float(alignment["alignment_score"])

        if not policy_check["allowed"]:
            return GateResult(
                approved=False,
                reason="Blocked by safety policy keywords.",
                alignment_score=a_score,
                policy={"blocked_hits": policy_check["blocked_hits"], "policy_version": self.policy.version},
                suggestions="Reframe as simulation-first research, safety evaluation, or defensive education only.",
            )

        if a_score < self.min_alignment:
            return GateResult(
                approved=False,
                reason="Low mission alignment score.",
                alignment_score=a_score,
                policy={"blocked_hits": [], "policy_version": self.policy.version},
                suggestions="Add safety notes, validation plan, risk mitigation, and simulation-first approach.",
            )

        return GateResult(
            approved=True,
            reason="Approved by safety gate.",
            alignment_score=a_score,
            policy={"blocked_hits": [], "policy_version": self.policy.version},
            suggestions=None,
        )