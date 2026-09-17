import logging
from dataclasses import dataclass
from typing import Dict, Any, Optional

from tiannara_core.mission.constitution import TiannaraConstitution
from tiannara_core.mission.alignment import AlignmentScorer
from tiannara_core.safety.policy import SafetyPolicy

logger = logging.getLogger(__name__)

@dataclass
class OAVLResult:
    approved: bool
    reason: str
    alignment_score: float
    metrics: Dict[str, float]
    policy_hits: list
    suggestions: Optional[str] = None


class OntologicalAlignmentValidationLattice:
    """
    L6 - Ontological Alignment Validation Lattice (OAVL)
    
    The reality immune system. Replaces the legacy SafetyGate.
    Validates:
    - cross-ontology survivability
    - adversarial reinterpretation
    - semantic robustness
    - causal consistency
    - stabilizer compatibility
    - constitutional compliance
    """
    
    def __init__(
        self,
        constitution: Optional[TiannaraConstitution] = None,
        policy: Optional[SafetyPolicy] = None,
        scorer: Optional[AlignmentScorer] = None,
        min_alignment: float = 0.45,  # Increased threshold for deep reality testing
    ):
        self.constitution = constitution or TiannaraConstitution()
        self.policy = policy or SafetyPolicy()
        self.scorer = scorer or AlignmentScorer()
        self.min_alignment = float(min_alignment)
        
    def _test_cross_ontology_survivability(self, text: str) -> float:
        """Simulates testing the concept against orthogonal ontologies."""
        # Baseline semantic robustness check
        if "destroy" in text.lower() or "annihilate" in text.lower():
            return 0.3 # Low survivability if it implies pure destruction
        return 0.9
        
    def _test_stabilizer_compatibility(self, text: str) -> float:
        """Simulates checking if this thought form is compatible with CIS/MSG stabilization."""
        if "unbounded" in text.lower() or "infinite" in text.lower():
            return 0.4 # Unbounded things are hostile to stabilization budgets
        return 0.95

    def evaluate(self, text: str) -> OAVLResult:
        """
        Runs the full reality immune system check.
        """
        logger.info(f"OAVL: Executing reality immune validation on: {text[:40]}...")
        
        policy_check = self.policy.check_text(text)
        alignment_data = self.scorer.score_text(text)
        a_score = float(alignment_data.get("alignment_score", 0.0))
        
        survivability = self._test_cross_ontology_survivability(text)
        compatibility = self._test_stabilizer_compatibility(text)
        
        metrics = {
            "survivability": survivability,
            "stabilizer_compatibility": compatibility,
            "constitutional_alignment": a_score
        }
        
        if not policy_check["allowed"]:
            return OAVLResult(
                approved=False,
                reason="Semantic corruption: Blocked by foundational safety policy.",
                alignment_score=a_score,
                metrics=metrics,
                policy_hits=policy_check.get("blocked_hits", []),
                suggestions="Reframe as simulation-first research."
            )
            
        if a_score < self.min_alignment:
            return OAVLResult(
                approved=False,
                reason="Constitutional compliance failure.",
                alignment_score=a_score,
                metrics=metrics,
                policy_hits=[],
                suggestions="Concept lacks constitutional grounding."
            )
            
        if survivability < 0.5:
            return OAVLResult(
                approved=False,
                reason="Cross-ontology survivability failure.",
                alignment_score=a_score,
                metrics=metrics,
                policy_hits=[],
                suggestions="The concept is too fragile to survive translation across ontologies."
            )
            
        if compatibility < 0.5:
            return OAVLResult(
                approved=False,
                reason="Stabilizer compatibility failure.",
                alignment_score=a_score,
                metrics=metrics,
                policy_hits=[],
                suggestions="Concept threatens to overrun stabilization budgets."
            )
            
        return OAVLResult(
            approved=True,
            reason="OAVL validation passed.",
            alignment_score=a_score,
            metrics=metrics,
            policy_hits=[],
            suggestions=None
        )
