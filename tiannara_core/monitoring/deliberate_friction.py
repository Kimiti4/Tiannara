"""
DELIBERATE FRICTION SYSTEM (ANTI-OPTIMIZATION ARCHITECTURE)

Purpose: Prevent aggressive optimization that leads to deceptive shortcuts,
reward hacking, and monoculture cognition.

Based on next.md (lines 231-265):
"Most systems fail because they optimize too aggressively.
You need anti-optimization architecture.
Meaning: sometimes the system should:
- slow down,
- request more evidence,
- preserve ambiguity,
- refuse premature synthesis."

Architecture:
Implements multiple reasoning modes that introduce controlled friction:
- Exploratory Mode: Maximize idea diversity
- Skeptical Mode: Aggressively challenge assumptions
- Conservative Mode: Require strong evidence
- Creative Mode: Allow weak-signal synthesis
- Arbitration Mode: Compare competing frameworks

This prevents monoculture cognition and promotes robust truth-seeking.
"""

import time
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass, field
from enum import Enum


class ReasoningMode(Enum):
    """Different reasoning modes with varying levels of friction."""
    EXPLORATORY = "exploratory"     # Maximize idea diversity, low evidence threshold
    SKEPTICAL = "skeptical"         # Aggressively challenge assumptions, high evidence threshold
    CONSERVATIVE = "conservative"   # Require strong evidence, very high threshold
    CREATIVE = "creative"           # Allow weak-signal synthesis, moderate threshold
    ARBITRATION = "arbitration"     # Compare competing frameworks, balanced threshold


@dataclass
class ModeConfiguration:
    """Configuration for a specific reasoning mode."""
    mode: ReasoningMode
    
    # Evidence requirements
    min_evidence_count: int         # Minimum evidence pieces required
    min_confidence_threshold: float # Minimum confidence to accept conclusion
    
    # Diversity settings
    max_agreement_ratio: float      # Maximum ratio of agreeing sources (prevent echo chamber)
    require_alternatives: bool      # Must generate alternative hypotheses?
    
    # Speed controls
    allow_premature_synthesis: bool # Can synthesize before full exploration?
    mandatory_reflection_steps: int # Minimum reflection steps before conclusion
    
    # Challenge intensity
    contradiction_seeking: bool     # Actively seek contradictions?
    adversarial_testing: bool       # Run adversarial tests on conclusions?
    
    def to_dict(self) -> Dict:
        return {
            'mode': self.mode.value,
            'min_evidence_count': self.min_evidence_count,
            'min_confidence_threshold': self.min_confidence_threshold,
            'max_agreement_ratio': self.max_agreement_ratio,
            'require_alternatives': self.require_alternatives,
            'allow_premature_synthesis': self.allow_premature_synthesis,
            'mandatory_reflection_steps': self.mandatory_reflection_steps,
            'contradiction_seeking': self.contradiction_seeking,
            'adversarial_testing': self.adversarial_testing
        }


# Pre-configured mode settings based on next.md guidance
MODE_CONFIGS = {
    ReasoningMode.EXPLORATORY: ModeConfiguration(
        mode=ReasoningMode.EXPLORATORY,
        min_evidence_count=2,
        min_confidence_threshold=0.4,
        max_agreement_ratio=0.9,
        require_alternatives=True,
        allow_premature_synthesis=False,
        mandatory_reflection_steps=1,
        contradiction_seeking=False,
        adversarial_testing=False
    ),
    
    ReasoningMode.SKEPTICAL: ModeConfiguration(
        mode=ReasoningMode.SKEPTICAL,
        min_evidence_count=8,
        min_confidence_threshold=0.75,
        max_agreement_ratio=0.6,
        require_alternatives=True,
        allow_premature_synthesis=False,
        mandatory_reflection_steps=3,
        contradiction_seeking=True,
        adversarial_testing=True
    ),
    
    ReasoningMode.CONSERVATIVE: ModeConfiguration(
        mode=ReasoningMode.CONSERVATIVE,
        min_evidence_count=12,
        min_confidence_threshold=0.85,
        max_agreement_ratio=0.5,
        require_alternatives=True,
        allow_premature_synthesis=False,
        mandatory_reflection_steps=5,
        contradiction_seeking=True,
        adversarial_testing=True
    ),
    
    ReasoningMode.CREATIVE: ModeConfiguration(
        mode=ReasoningMode.CREATIVE,
        min_evidence_count=3,
        min_confidence_threshold=0.5,
        max_agreement_ratio=0.8,
        require_alternatives=True,
        allow_premature_synthesis=True,
        mandatory_reflection_steps=2,
        contradiction_seeking=False,
        adversarial_testing=False
    ),
    
    ReasoningMode.ARBITRATION: ModeConfiguration(
        mode=ReasoningMode.ARBITRATION,
        min_evidence_count=6,
        min_confidence_threshold=0.7,
        max_agreement_ratio=0.7,
        require_alternatives=True,
        allow_premature_synthesis=False,
        mandatory_reflection_steps=3,
        contradiction_seeking=True,
        adversarial_testing=False
    )
}


@dataclass
class FrictionDecision:
    """Result of applying deliberate friction to a decision."""
    decision_id: str
    original_conclusion: str
    mode_used: ReasoningMode
    
    # Friction applied
    evidence_gathered: int
    alternatives_generated: int
    contradictions_found: int
    reflection_steps_completed: int
    
    # Outcome
    conclusion_accepted: bool
    final_confidence: float
    reasons_for_rejection: List[str] = field(default_factory=list)
    recommendations: List[str] = field(default_factory=list)
    
    timestamp: float = field(default_factory=time.time)
    
    def to_dict(self) -> Dict:
        return {
            'decision_id': self.decision_id,
            'original_conclusion': self.original_conclusion,
            'mode_used': self.mode_used.value,
            'evidence_gathered': self.evidence_gathered,
            'alternatives_generated': self.alternatives_generated,
            'contradictions_found': self.contradictions_found,
            'reflection_steps_completed': self.reflection_steps_completed,
            'conclusion_accepted': self.conclusion_accepted,
            'final_confidence': self.final_confidence,
            'reasons_for_rejection': self.reasons_for_rejection,
            'recommendations': self.recommendations,
            'timestamp': self.timestamp
        }


class DeliberateFrictionSystem:
    """
    Implements anti-optimization architecture by introducing controlled friction
    into reasoning processes to prevent deceptive shortcuts and monoculture cognition.
    
    Based on next.md guidance for deliberate friction:
    - Slow down when appropriate
    - Request more evidence
    - Preserve ambiguity
    - Refuse premature synthesis
    """
    
    def __init__(self, default_mode: ReasoningMode = ReasoningMode.CONSERVATIVE):
        """
        Initialize deliberate friction system.
        
        Args:
            default_mode: Default reasoning mode to use
        """
        self.current_mode = default_mode
        self.decisions: List[FrictionDecision] = []
        self.decision_counter = 0
        
        # Mode switching history
        self.mode_history: List[Tuple[float, ReasoningMode]] = []
        self._record_mode_switch(default_mode)
    
    def set_mode(self, mode: ReasoningMode):
        """Switch to a different reasoning mode."""
        if mode != self.current_mode:
            self.current_mode = mode
            self._record_mode_switch(mode)
    
    def evaluate_with_friction(self, 
                               conclusion: str,
                               available_evidence: int,
                               supporting_sources: int,
                               total_sources: int,
                               alternative_hypotheses: Optional[List[str]] = None,
                               contradiction_count: int = 0,
                               initial_confidence: float = 0.5) -> FrictionDecision:
        """
        Evaluate a conclusion with deliberate friction applied.
        
        This implements the anti-optimization architecture by checking whether
        the conclusion meets the current mode's requirements before acceptance.
        
        Args:
            conclusion: The proposed conclusion/hypothesis
            available_evidence: Number of evidence pieces supporting conclusion
            supporting_sources: Number of sources supporting conclusion
            total_sources: Total number of sources consulted
            alternative_hypotheses: List of alternative explanations (optional)
            contradiction_count: Number of contradictions found
            initial_confidence: Initial confidence in conclusion
            
        Returns:
            FrictionDecision with evaluation results
        """
        self.decision_counter += 1
        config = MODE_CONFIGS[self.current_mode]
        
        # Apply friction checks
        reasons_for_rejection = []
        recommendations = []
        
        # Check 1: Evidence sufficiency
        if available_evidence < config.min_evidence_count:
            reasons_for_rejection.append(
                f"Insufficient evidence: {available_evidence} < {config.min_evidence_count} required"
            )
            recommendations.append(
                f"Gather {config.min_evidence_count - available_evidence} more evidence pieces"
            )
        
        # Check 2: Confidence threshold
        if initial_confidence < config.min_confidence_threshold:
            reasons_for_rejection.append(
                f"Confidence too low: {initial_confidence:.2f} < {config.min_confidence_threshold} required"
            )
            recommendations.append(
                f"Increase confidence through additional validation"
            )
        
        # Check 3: Agreement ratio (prevent echo chamber)
        if total_sources > 0:
            agreement_ratio = supporting_sources / total_sources
            if agreement_ratio > config.max_agreement_ratio:
                reasons_for_rejection.append(
                    f"Too much agreement: {agreement_ratio:.2f} > {config.max_agreement_ratio} maximum (echo chamber risk)"
                )
                recommendations.append(
                    "Seek dissenting opinions or alternative perspectives"
                )
        
        # Check 4: Alternative hypotheses
        if config.require_alternatives:
            if not alternative_hypotheses or len(alternative_hypotheses) == 0:
                reasons_for_rejection.append(
                    "No alternative hypotheses generated"
                )
                recommendations.append(
                    "Generate at least one alternative explanation"
                )
        
        # Check 5: Contradiction seeking
        if config.contradiction_seeking and contradiction_count == 0:
            recommendations.append(
                "Actively search for contradictions (none found yet)"
            )
        
        # Determine acceptance
        conclusion_accepted = len(reasons_for_rejection) == 0
        final_confidence = initial_confidence if conclusion_accepted else initial_confidence * 0.5
        
        # Create decision record
        decision = FrictionDecision(
            decision_id=f"friction_{self.decision_counter}",
            original_conclusion=conclusion,
            mode_used=self.current_mode,
            evidence_gathered=available_evidence,
            alternatives_generated=len(alternative_hypotheses) if alternative_hypotheses else 0,
            contradictions_found=contradiction_count,
            reflection_steps_completed=config.mandatory_reflection_steps,
            conclusion_accepted=conclusion_accepted,
            final_confidence=final_confidence,
            reasons_for_rejection=reasons_for_rejection,
            recommendations=recommendations
        )
        
        self.decisions.append(decision)
        
        return decision
    
    def should_slow_down(self, 
                        decision_urgency: str,
                        stakes_level: str,
                        uncertainty_level: float) -> bool:
        """
        Determine if the system should deliberately slow down reasoning.
        
        Based on next.md: "sometimes the system should slow down"
        
        Args:
            decision_urgency: "low", "medium", "high", "critical"
            stakes_level: "low", "medium", "high", "critical"
            uncertainty_level: Current uncertainty (0.0-1.0)
            
        Returns:
            True if should slow down, False if can proceed quickly
        """
        # Always slow down for high-stakes decisions
        if stakes_level in ["high", "critical"]:
            return True
        
        # Slow down when uncertainty is high
        if uncertainty_level > 0.7:
            return True
        
        # Don't slow down for low-stakes, low-uncertainty decisions
        if stakes_level == "low" and uncertainty_level < 0.3:
            return False
        
        # Default: slow down unless explicitly low priority
        return decision_urgency != "low"
    
    def preserve_ambiguity(self, 
                          confidence_gap: float,
                          evidence_quality: str) -> bool:
        """
        Determine if ambiguity should be preserved rather than forcing a decision.
        
        Based on next.md: "preserve ambiguity"
        
        Args:
            confidence_gap: Difference between top two hypotheses (smaller = more ambiguous)
            evidence_quality: "poor", "fair", "good", "excellent"
            
        Returns:
            True if should preserve ambiguity, False if should decide
        """
        # Preserve ambiguity when confidence gap is small
        if confidence_gap < 0.15:
            return True
        
        # Preserve ambiguity when evidence quality is poor
        if evidence_quality in ["poor", "fair"]:
            return True
        
        # Otherwise, make a decision
        return False
    
    def refuse_premature_synthesis(self,
                                   exploration_completeness: float,
                                   hypothesis_count: int,
                                   min_hypotheses: int = 3) -> bool:
        """
        Determine if synthesis should be refused due to premature timing.
        
        Based on next.md: "refuse premature synthesis"
        
        Args:
            exploration_completeness: How complete is exploration? (0.0-1.0)
            hypothesis_count: Number of hypotheses explored
            min_hypotheses: Minimum hypotheses before synthesis
            
        Returns:
            True if should refuse synthesis, False if can synthesize
        """
        # Refuse if exploration is incomplete
        if exploration_completeness < 0.6:
            return True
        
        # Refuse if insufficient hypotheses explored
        if hypothesis_count < min_hypotheses:
            return True
        
        # Otherwise, synthesis is acceptable
        return False
    
    def get_mode_statistics(self) -> Dict:
        """
        Get statistics about mode usage and decision outcomes.
        
        Returns:
            Dictionary with mode usage statistics
        """
        mode_counts = {}
        acceptance_by_mode = {}
        
        for decision in self.decisions:
            mode_name = decision.mode_used.value
            mode_counts[mode_name] = mode_counts.get(mode_name, 0) + 1
            
            if mode_name not in acceptance_by_mode:
                acceptance_by_mode[mode_name] = {'accepted': 0, 'rejected': 0}
            
            if decision.conclusion_accepted:
                acceptance_by_mode[mode_name]['accepted'] += 1
            else:
                acceptance_by_mode[mode_name]['rejected'] += 1
        
        return {
            'current_mode': self.current_mode.value,
            'total_decisions': len(self.decisions),
            'mode_usage': mode_counts,
            'acceptance_rates': {
                mode: stats['accepted'] / (stats['accepted'] + stats['rejected'])
                for mode, stats in acceptance_by_mode.items()
            },
            'mode_history': [
                {'timestamp': ts, 'mode': mode.value}
                for ts, mode in self.mode_history[-10:]  # Last 10 switches
            ]
        }
    
    def _record_mode_switch(self, mode: ReasoningMode):
        """Record a mode switch in history."""
        self.mode_history.append((time.time(), mode))
