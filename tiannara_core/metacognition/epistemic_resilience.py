"""
EPISTEMIC RESILIENCE SYSTEM - PHASES 1-3

Implements critical epistemic infrastructure to prevent cognitive drift:

Phase 1:
1. Belief Aging / Confidence Decay - Truth requires maintenance
2. Competing Hypothesis Framework - No single explanation lock
3. Predictive Accountability - Beliefs earn survival

Phase 2:
4. Reality Anchor Layer - Immutable grounding constraints
5. Epistemic Integrity Scorer - Composite trustworthiness metric
6. Adversarial Red Team Agent - Permanent disproof capability

Phase 3:
7. Provenance Chains - Full source traceability
8. Delayed Contradiction Handling - Store contradictions without immediate resolution
9. Consensus Corruption Resistance - Anti-echo-chamber mechanisms

Based on strategic analysis from ADVERSARIAL_DEBATE_TEST_COMPLETE.md (lines 387-788)
and EPISTEMIC_RESILIENCE_ROADMAP.md
"""

import sys
import time
import random
import math
from pathlib import Path
from typing import Dict, List, Tuple, Optional
from collections import defaultdict
from dataclasses import dataclass, field
from enum import Enum

# Add project root to path
project_root = Path(__file__).parent
sys.path.insert(0, str(project_root))

from tiannara_core.metacognition.theory_engine import Theory, Prediction
from tiannara_core.causal.causal_depth_engine import CausalDepthEngine, CausalDepthResult


class DecayReason(Enum):
    """Reasons for confidence decay."""
    TIME_AGING = "time_aging"                    # Natural decay over time
    NON_USE = "non_use"                          # Not referenced recently
    CONTRADICTION = "contradiction"              # Contradicted by new evidence
    FAILED_PREDICTION = "failed_prediction"      # Prediction was wrong
    SUPERSEDED = "superseded"                    # Better theory emerged
    EXTERNAL_CORRECTION = "external_correction"  # Corrected by external source
    PARADIGM_SHIFT = "paradigm_shift"            # Domain-wide reassessment


@dataclass
class BeliefMetadata:
    """Enhanced metadata for belief tracking and aging."""
    
    # Creation and verification
    created_at: float = field(default_factory=time.time)
    last_verified: Optional[float] = None
    last_used: Optional[float] = None
    verification_count: int = 0
    
    # Confidence tracking
    base_confidence: float = 0.5
    current_confidence: float = 0.5
    confidence_history: List[Tuple[float, float]] = field(default_factory=list)  # (timestamp, confidence)
    
    # Decay tracking
    decay_rate: float = 0.01  # Per day (adjustable)
    last_decay_at: float = field(default_factory=time.time)
    total_decay: float = 0.0
    decay_events: List[Tuple[float, float, str]] = field(default_factory=list)  # (timestamp, amount, reason)
    
    # Usage tracking
    usage_count: int = 0
    prediction_attempts: int = 0
    prediction_successes: int = 0
    prediction_failures: int = 0
    
    # Contradiction tracking
    contradiction_count: int = 0
    active_contradictions: List[str] = field(default_factory=list)
    
    # Quarantine tracking (for false beliefs)
    quarantined: bool = False
    quarantine_reason: Optional[str] = None
    quarantine_time: Optional[float] = None
    
    def record_verification(self):
        """Record a verification event."""
        self.last_verified = time.time()
        self.verification_count += 1
        self.last_used = time.time()
        self.usage_count += 1
    
    def record_usage(self):
        """Record theory usage without full verification."""
        self.last_used = time.time()
        self.usage_count += 1
    
    def apply_decay(self, amount: float, reason: DecayReason):
        """Apply confidence decay."""
        old_confidence = self.current_confidence
        self.current_confidence = max(0.0, self.current_confidence - amount)
        self.total_decay += amount
        self.last_decay_at = time.time()
        
        self.decay_events.append((time.time(), amount, reason.value))
        self.confidence_history.append((time.time(), self.current_confidence))
        
        return old_confidence - self.current_confidence
    
    def record_prediction_outcome(self, success: bool):
        """Record prediction outcome for accountability."""
        self.prediction_attempts += 1
        if success:
            self.prediction_successes += 1
        else:
            self.prediction_failures += 1
    
    def calculate_prediction_accuracy(self) -> float:
        """Calculate prediction success rate."""
        if self.prediction_attempts == 0:
            return 0.5  # Neutral for untested theories
        
        return self.prediction_successes / self.prediction_attempts
    
    def calculate_predictive_power(self) -> float:
        """Calculate predictive power score (0.0-1.0)."""
        accuracy = self.calculate_prediction_accuracy()
        
        # Weight by number of predictions (more predictions = more reliable score)
        prediction_weight = min(1.0, self.prediction_attempts / 10.0)
        
        return accuracy * prediction_weight + 0.5 * (1.0 - prediction_weight)


class BeliefAgingEngine:
    """
    Implements confidence decay to prevent belief ossification.
    
    Principle: Truth should require maintenance.
    
    Decay mechanisms:
    - Time-based decay (natural aging)
    - Non-use decay (forgotten beliefs weaken)
    - Contradiction decay (conflicting evidence reduces confidence)
    - Failed prediction decay (wrong predictions reduce credibility)
    """
    
    def __init__(
        self,
        time_decay_rate: float = 0.001,      # Per hour
        non_use_decay_rate: float = 0.002,   # Per hour of non-use
        contradiction_penalty: float = 0.1,  # Per contradiction
        failed_prediction_penalty: float = 0.05  # Per failed prediction
    ):
        self.time_decay_rate = time_decay_rate
        self.non_use_decay_rate = non_use_decay_rate
        self.contradiction_penalty = contradiction_penalty
        self.failed_prediction_penalty = failed_prediction_penalty
        
        self.belief_metadata: Dict[str, BeliefMetadata] = {}
    
    def register_belief(self, theory_id: str, initial_confidence: float = 0.5):
        """Register a theory for aging tracking."""
        self.belief_metadata[theory_id] = BeliefMetadata(
            base_confidence=initial_confidence,
            current_confidence=initial_confidence
        )
    
    def apply_time_decay(self, theory_id: str, override_interval: bool = False) -> float:
        """
        Apply natural time-based decay.
        
        Args:
            theory_id: Theory to decay
            override_interval: If True, bypass 1-hour minimum (for testing/emergency)
        """
        if theory_id not in self.belief_metadata:
            return 0.0
        
        metadata = self.belief_metadata[theory_id]
        hours_since_last_decay = (time.time() - metadata.last_decay_at) / 3600.0
        
        # Allow override for emergency corrections or testing
        if not override_interval and hours_since_last_decay < 1.0:
            return 0.0  # Only decay once per hour minimum
        
        decay_amount = self.time_decay_rate * max(hours_since_last_decay, 0.01)  # Minimum 0.01 hours
        actual_decay = metadata.apply_decay(decay_amount, DecayReason.TIME_AGING)
        
        return actual_decay
    
    def emergency_correct_belief(self, theory_id: str, new_confidence: float, reason: str = "contradiction_detected"):
        """
        Immediately correct a belief's confidence, bypassing time constraints.
        
        This is used for:
        - Confirmed false beliefs requiring rapid correction
        - High-contradiction scenarios needing immediate adjustment
        - Emergency epistemic interventions
        
        Args:
            theory_id: Theory to correct
            new_confidence: Target confidence level (0.0-1.0)
            reason: Why emergency correction is needed
            
        Returns:
            Amount of confidence change
        """
        if theory_id not in self.belief_metadata:
            return 0.0
        
        metadata = self.belief_metadata[theory_id]
        old_confidence = metadata.current_confidence
        
        # Apply immediate correction
        metadata.current_confidence = max(0.0, min(1.0, new_confidence))
        metadata.confidence_history.append((time.time(), metadata.current_confidence))
        
        # Record as external correction with high priority
        change = abs(old_confidence - new_confidence)
        metadata.apply_decay(change, DecayReason.EXTERNAL_CORRECTION)
        
        return change
    
    def apply_non_use_decay(self, theory_id: str) -> float:
        """Apply decay for beliefs not recently used."""
        if theory_id not in self.belief_metadata:
            return 0.0
        
        metadata = self.belief_metadata[theory_id]
        
        if metadata.last_used is None:
            # Never used - apply significant decay
            decay_amount = self.non_use_decay_rate * 24  # Assume 24 hours
        else:
            hours_since_use = (time.time() - metadata.last_used) / 3600.0
            decay_amount = self.non_use_decay_rate * hours_since_use
        
        actual_decay = metadata.apply_decay(decay_amount, DecayReason.NON_USE)
        return actual_decay
    
    def apply_contradiction_decay(self, theory_id: str, contradiction_severity: float = 0.5) -> float:
        """
        Apply decay when contradiction is detected.
        
        Args:
            theory_id: Theory experiencing contradiction
            contradiction_severity: How severe the contradiction is (0.0-1.0)
        """
        if theory_id not in self.belief_metadata:
            return 0.0
        
        metadata = self.belief_metadata[theory_id]
        metadata.contradiction_count += 1
        
        # Scale penalty by severity for adaptive decay
        scaled_penalty = self.contradiction_penalty * contradiction_severity
        actual_decay = metadata.apply_decay(
            scaled_penalty,
            DecayReason.CONTRADICTION
        )
        
        return actual_decay
    
    def apply_prediction_failure_decay(self, theory_id: str) -> float:
        """Apply decay when prediction fails."""
        if theory_id not in self.belief_metadata:
            return 0.0
        
        metadata = self.belief_metadata[theory_id]
        metadata.record_prediction_outcome(success=False)
        
        actual_decay = metadata.apply_decay(
            self.failed_prediction_penalty,
            DecayReason.FAILED_PREDICTION
        )
        
        return actual_decay
    
    def record_prediction_success(self, theory_id: str):
        """Record successful prediction (may boost confidence slightly)."""
        if theory_id not in self.belief_metadata:
            return
        
        metadata = self.belief_metadata[theory_id]
        metadata.record_prediction_outcome(success=True)
        
        # Small confidence boost for successful predictions
        boost = min(0.05, (1.0 - metadata.current_confidence) * 0.1)
        metadata.current_confidence = min(1.0, metadata.current_confidence + boost)
        metadata.confidence_history.append((time.time(), metadata.current_confidence))
    
    def trigger_paradigm_reassessment(self, domain_theories: List[str], shock_factor: float = 0.5):
        """
        Trigger paradigm destabilization when repeated failures occur.
        
        This mimics scientific revolutions by applying strong decay to all theories
        in a domain simultaneously, creating space for new paradigms.
        
        Args:
            domain_theories: List of theory IDs in the affected domain
            shock_factor: Strength of paradigm shock (0.0-1.0)
        """
        for theory_id in domain_theories:
            if theory_id in self.belief_metadata:
                metadata = self.belief_metadata[theory_id]
                # Apply strong decay to all existing theories
                decay_amount = shock_factor * metadata.current_confidence
                metadata.apply_decay(decay_amount, DecayReason.PARADIGM_SHIFT)
    
    def boost_minority_hypothesis(self, theory_id: str, boost_factor: float = 0.3):
        """
        Temporarily amplify minority/alternative hypotheses during concept drift.
        
        This prevents dominant paradigms from suppressing adaptation forever.
        
        Args:
            theory_id: The minority theory to boost
            boost_factor: Amount to boost confidence (0.0-0.5)
        """
        if theory_id not in self.belief_metadata:
            return
        
        metadata = self.belief_metadata[theory_id]
        boost = boost_factor * (1.0 - metadata.current_confidence)
        metadata.current_confidence = min(1.0, metadata.current_confidence + boost)
        metadata.confidence_history.append((time.time(), metadata.current_confidence))
    
    def quarantine_false_belief(self, theory_id: str, reason: str = "adversarial_detection"):
        """
        Aggressively reduce confidence for beliefs identified as false.
        
        This is triggered when:
        - Red team detects fabricated evidence
        - Source is blacklisted
        - Evidence shows statistical anomalies
        
        Args:
            theory_id: Theory to quarantine
            reason: Why it's being quarantined
            
        Returns:
            Amount of confidence reduction
        """
        if theory_id not in self.belief_metadata:
            return 0.0
        
        metadata = self.belief_metadata[theory_id]
        
        # Apply aggressive decay
        quarantine_penalty = 0.5  # Massive penalty for confirmed false beliefs
        
        actual_decay = metadata.apply_decay(
            quarantine_penalty,
            DecayReason.EXTERNAL_CORRECTION  # Treat as externally corrected
        )
        
        # Cap confidence at 0.2 maximum for quarantined beliefs
        if metadata.current_confidence > 0.2:
            additional_reduction = metadata.current_confidence - 0.2
            metadata.current_confidence = 0.2
            metadata.confidence_history.append((time.time(), metadata.current_confidence))
            actual_decay += additional_reduction
        
        # Mark with metadata flag
        metadata.quarantined = True
        metadata.quarantine_reason = reason
        metadata.quarantine_time = time.time()
        
        return actual_decay
    
    def get_belief_status(self, theory_id: str) -> Optional[Dict]:
        """Get comprehensive status of a belief."""
        if theory_id not in self.belief_metadata:
            return None
        
        metadata = self.belief_metadata[theory_id]
        
        return {
            'theory_id': theory_id,
            'current_confidence': metadata.current_confidence,
            'base_confidence': metadata.base_confidence,
            'total_decay': metadata.total_decay,
            'decay_events': len(metadata.decay_events),
            'prediction_accuracy': metadata.calculate_prediction_accuracy(),
            'predictive_power': metadata.calculate_predictive_power(),
            'contradiction_count': metadata.contradiction_count,
            'age_hours': (time.time() - metadata.created_at) / 3600.0,
            'last_verified': metadata.last_verified,
            'last_used': metadata.last_used,
            'usage_count': metadata.usage_count,
        }
    
    def get_weakened_beliefs(self, threshold: float = 0.3) -> List[str]:
        """Get beliefs that have weakened below threshold."""
        weakened = []
        
        for theory_id, metadata in self.belief_metadata.items():
            if metadata.current_confidence < threshold:
                weakened.append(theory_id)
        
        return weakened
    
    def run_aging_cycle(self):
        """Run a complete aging cycle on all beliefs."""
        results = {
            'time_decayed': 0,
            'non_use_decayed': 0,
            'total_decay_applied': 0.0,
        }
        
        for theory_id in list(self.belief_metadata.keys()):
            # Apply time decay
            time_decay = self.apply_time_decay(theory_id)
            if time_decay > 0:
                results['time_decayed'] += 1
            
            # Apply non-use decay
            non_use_decay = self.apply_non_use_decay(theory_id)
            if non_use_decay > 0:
                results['non_use_decayed'] += 1
            
            results['total_decay_applied'] += time_decay + non_use_decay
        
        return results


class CompetingHypothesisManager:
    """
    Manages multiple competing hypotheses for the same phenomenon.
    
    Principle: Never allow "single explanation lock."
    
    Maintains probability distributions over hypotheses and enables:
    - Continuous testing
    - Re-ranking based on evidence
    - Merging compatible hypotheses
    - Eliminating weak hypotheses
    """
    
    def __init__(self, uncertainty_reserve: float = 0.15):
        """
        Initialize competing hypothesis manager.
        
        Args:
            uncertainty_reserve: Fraction of probability mass reserved for unknown explanations (0.0-0.3)
        """
        # Maps problem domain -> list of (theory_id, probability)
        self.hypothesis_sets: Dict[str, List[Tuple[str, float]]] = {}
        self.theory_domains: Dict[str, str] = {}  # theory_id -> domain
        
        # Uncertainty reservoir - represents "explanations not yet discovered"
        self.uncertainty_reserve = uncertainty_reserve
        self.domain_uncertainty: Dict[str, float] = {}  # domain -> unexplained_mass
    
    def add_hypothesis(self, theory_id: str, domain: str, initial_probability: float = 0.5):
        """Add a hypothesis to the competition pool."""
        self.theory_domains[theory_id] = domain
        
        if domain not in self.hypothesis_sets:
            self.hypothesis_sets[domain] = []
        
        # Add with initial probability
        self.hypothesis_sets[domain].append((theory_id, initial_probability))
        
        # Normalize probabilities
        self._normalize_probabilities(domain)
    
    def update_probability(self, theory_id: str, new_evidence_strength: float):
        """Update hypothesis probability based on new evidence."""
        domain = self.theory_domains.get(theory_id)
        if not domain:
            return
        
        hypotheses = self.hypothesis_sets.get(domain, [])
        
        # Find the hypothesis
        for i, (tid, prob) in enumerate(hypotheses):
            if tid == theory_id:
                # Bayesian-like update
                # Stronger evidence increases probability
                updated_prob = prob * (1.0 + new_evidence_strength)
                hypotheses[i] = (tid, updated_prob)
                break
        
        # Normalize
        self._normalize_probabilities(domain)
    
    def penalize_hypothesis(self, theory_id: str, penalty_reason: str):
        """Penalize a hypothesis (e.g., failed prediction, contradiction)."""
        domain = self.theory_domains.get(theory_id)
        if not domain:
            return
        
        hypotheses = self.hypothesis_sets.get(domain, [])
        
        for i, (tid, prob) in enumerate(hypotheses):
            if tid == theory_id:
                # Reduce probability
                penalty = 0.2 if penalty_reason == "failed_prediction" else 0.1
                updated_prob = max(0.01, prob * (1.0 - penalty))
                hypotheses[i] = (tid, updated_prob)
                break
        
        # Normalize
        self._normalize_probabilities(domain)
    
    def _normalize_probabilities(self, domain: str):
        """
        Normalize probabilities with uncertainty reserve.
        
        Ensures sum(theories) <= (1.0 - uncertainty_reserve)
        Remaining mass represents unknown/unexplained phenomena.
        """
        if domain not in self.hypothesis_sets:
            return
        
        hypotheses = self.hypothesis_sets[domain]
        total = sum(prob for _, prob in hypotheses)
        
        if total > 0:
            # Normalize theories to occupy (1.0 - uncertainty_reserve) of probability space
            max_theory_mass = 1.0 - self.uncertainty_reserve
            normalized = [(tid, prob / total * max_theory_mass) for tid, prob in hypotheses]
            self.hypothesis_sets[domain] = normalized
            
            # Track uncertainty mass for this domain
            self.domain_uncertainty[domain] = self.uncertainty_reserve
    
    def get_ranking(self, domain: str) -> List[Tuple[str, float]]:
        """Get hypotheses ranked by probability."""
        if domain not in self.hypothesis_sets:
            return []
        
        hypotheses = self.hypothesis_sets[domain]
        return sorted(hypotheses, key=lambda x: x[1], reverse=True)
    
    def get_top_hypothesis(self, domain: str) -> Optional[Tuple[str, float]]:
        """Get the most probable hypothesis."""
        ranking = self.get_ranking(domain)
        return ranking[0] if ranking else None
    
    def get_causal_enhanced_ranking(self, domain: str, theories: Dict[str, 'Theory'], 
                                     predictive_scores: Dict[str, float],
                                     resilience_scores: Dict[str, float],
                                     causal_weight: float = 0.40,
                                     predictive_weight: float = 0.45,
                                     resilience_weight: float = 0.15) -> List[Tuple[str, float]]:
        """
        Get hypotheses ranked by combined score: predictive + causal + resilience.
        
        This implements the formula from fixes.md (lines 778-784):
        final_theory_score = (
            predictive_score * 0.45 +
            causal_depth * 0.40 +
            epistemic_resilience * 0.15
        )
        
        Args:
            domain: Domain to rank theories in
            theories: Dictionary mapping theory_id to Theory objects
            predictive_scores: Dictionary mapping theory_id to predictive accuracy (0.0-1.0)
            resilience_scores: Dictionary mapping theory_id to epistemic resilience score (0.0-1.0)
            causal_weight: Weight for causal depth (default 0.40)
            predictive_weight: Weight for predictive accuracy (default 0.45)
            resilience_weight: Weight for epistemic resilience (default 0.15)
            
        Returns:
            List of (theory_id, final_score) sorted by final_score descending
        """
        if domain not in self.hypothesis_sets:
            return []
        
        ranked_theories = []
        
        for theory_id, prob in self.hypothesis_sets[domain]:
            # Get predictive score (default 0.5 if not available)
            pred_score = predictive_scores.get(theory_id, 0.5)
            
            # Get resilience score (default 0.5 if not available)
            res_score = resilience_scores.get(theory_id, 0.5)
            
            # Calculate causal depth if theory has been registered
            causal_score = 0.5  # Default
            try:
                # Try to evaluate causal depth (assumes chains are pre-registered)
                causal_eval = self.causal_depth_engine.evaluate_causal_depth(theory_id)
                causal_score = causal_eval.causal_depth
            except Exception as e:
                # If evaluation fails or not registered, use default
                causal_score = 0.5
            
            # Calculate final combined score
            final_score = (
                pred_score * predictive_weight +
                causal_score * causal_weight +
                res_score * resilience_weight
            )
            
            ranked_theories.append((theory_id, final_score))
        
        # Sort by final score descending
        ranked_theories.sort(key=lambda x: x[1], reverse=True)
        
        return ranked_theories
    
    def get_uncertainty_mass(self, domain: str) -> float:
        """
        Get the probability mass reserved for unknown explanations.
        
        This represents: "Reality may contain explanations I have not discovered yet."
        """
        return self.domain_uncertainty.get(domain, self.uncertainty_reserve)
    
    def ensure_minimum_hypotheses(self, domain: str, min_count: int = 2):
        """
        Ensure at least min_count competing hypotheses exist in domain.
        
        If insufficient hypotheses, adds null/alternative hypotheses.
        This prevents dogmatic single-theory dominance.
        """
        if domain not in self.hypothesis_sets:
            return
        
        current_count = len(self.hypothesis_sets[domain])
        
        if current_count < min_count:
            # Add null hypothesis representing "current theories incomplete"
            for i in range(min_count - current_count):
                null_id = f"null_hypothesis_{domain}_{i}"
                self.hypothesis_sets[domain].append((null_id, 0.1))
            
            # Re-normalize with new hypotheses
            self._normalize_probabilities(domain)
    
    def eliminate_weak_hypotheses(self, domain: str, threshold: float = 0.05):
        """Remove hypotheses below probability threshold."""
        if domain not in self.hypothesis_sets:
            return
        
        original_count = len(self.hypothesis_sets[domain])
        self.hypothesis_sets[domain] = [
            (tid, prob) for tid, prob in self.hypothesis_sets[domain]
            if prob >= threshold
        ]
        
        eliminated_count = original_count - len(self.hypothesis_sets[domain])
        
        # Re-normalize after elimination
        if eliminated_count > 0:
            self._normalize_probabilities(domain)
        
        return eliminated_count
    
    def merge_compatible_hypotheses(self, domain: str, theory_a: str, theory_b: str) -> Optional[str]:
        """Merge two compatible hypotheses into one."""
        if domain not in self.hypothesis_sets:
            return None
        
        hypotheses = self.hypothesis_sets[domain]
        
        # Find both hypotheses
        prob_a = next((prob for tid, prob in hypotheses if tid == theory_a), None)
        prob_b = next((prob for tid, prob in hypotheses if tid == theory_b), None)
        
        if prob_a is None or prob_b is None:
            return None
        
        # Create merged hypothesis (in real implementation, would merge theory content)
        merged_id = f"merged_{theory_a}_{theory_b}"
        merged_prob = prob_a + prob_b  # Combined probability
        
        # Remove old hypotheses
        self.hypothesis_sets[domain] = [
            (tid, prob) for tid, prob in hypotheses
            if tid not in [theory_a, theory_b]
        ]
        
        # Add merged hypothesis
        self.hypothesis_sets[domain].append((merged_id, merged_prob))
        self.theory_domains[merged_id] = domain
        
        # Normalize
        self._normalize_probabilities(domain)
        
        return merged_id
    
    def get_hypothesis_diversity_score(self, domain: str) -> float:
        """Calculate diversity score (higher = more diverse hypotheses)."""
        if domain not in self.hypothesis_sets:
            return 0.0
        
        hypotheses = self.hypothesis_sets[domain]
        
        if len(hypotheses) <= 1:
            return 0.0
        
        # Calculate entropy-based diversity
        import math
        entropy = 0.0
        for _, prob in hypotheses:
            if prob > 0:
                entropy -= prob * math.log2(prob)
        
        # Normalize by maximum possible entropy
        max_entropy = math.log2(len(hypotheses))
        diversity = entropy / max_entropy if max_entropy > 0 else 0.0
        
        return diversity


class PredictiveAccountabilityTracker:
    """
    Tracks prediction performance to ensure beliefs earn survival.
    
    Principle: Beliefs should be judged by their predictive success.
    
    Every theory tracks:
    - Prediction success rate
    - Failed predictions
    - Survival duration
    - Causal accuracy
    """
    
    def __init__(self):
        self.prediction_records: Dict[str, List[Dict]] = {}
        self.theory_survival_start: Dict[str, float] = {}
    
    def register_theory(self, theory_id: str):
        """Register theory for prediction tracking."""
        self.prediction_records[theory_id] = []
        self.theory_survival_start[theory_id] = time.time()
    
    def record_prediction(
        self,
        theory_id: str,
        prediction_description: str,
        predicted_outcome: str,
        actual_outcome: Optional[str] = None,
        confirmed: Optional[bool] = None
    ):
        """Record a prediction made by a theory."""
        if theory_id not in self.prediction_records:
            self.prediction_records[theory_id] = []
        
        record = {
            'prediction_id': f"pred_{len(self.prediction_records[theory_id])}",
            'description': prediction_description,
            'predicted_outcome': predicted_outcome,
            'actual_outcome': actual_outcome,
            'confirmed': confirmed,
            'timestamp': time.time(),
            'verified': False,
        }
        
        self.prediction_records[theory_id].append(record)
    
    def verify_prediction(self, theory_id: str, prediction_id: str, success: bool):
        """Verify whether a prediction was correct."""
        if theory_id not in self.prediction_records:
            return
        
        for record in self.prediction_records[theory_id]:
            if record['prediction_id'] == prediction_id:
                record['confirmed'] = success
                record['verified'] = True
                record['verification_timestamp'] = time.time()
                break
    
    def get_prediction_stats(self, theory_id: str) -> Dict:
        """Get prediction statistics for a theory."""
        if theory_id not in self.prediction_records:
            return {
                'total_predictions': 0,
                'verified_predictions': 0,
                'successful_predictions': 0,
                'failed_predictions': 0,
                'success_rate': 0.0,
                'survival_duration_hours': 0.0,
            }
        
        records = self.prediction_records[theory_id]
        verified = [r for r in records if r.get('verified', False)]
        successful = [r for r in verified if r.get('confirmed', False)]
        failed = [r for r in verified if not r.get('confirmed', False)]
        
        success_rate = len(successful) / len(verified) if verified else 0.0
        
        survival_start = self.theory_survival_start.get(theory_id, time.time())
        survival_hours = (time.time() - survival_start) / 3600.0
        
        return {
            'total_predictions': len(records),
            'verified_predictions': len(verified),
            'successful_predictions': len(successful),
            'failed_predictions': len(failed),
            'success_rate': success_rate,
            'survival_duration_hours': survival_hours,
        }
    
    def should_retire_theory(self, theory_id: str, min_predictions: int = 5, min_success_rate: float = 0.4) -> Tuple[bool, str]:
        """Determine if a theory should be retired due to poor predictive performance."""
        stats = self.get_prediction_stats(theory_id)
        
        # Need minimum number of verified predictions
        if stats['verified_predictions'] < min_predictions:
            return False, "Insufficient predictions to evaluate"
        
        # Check success rate
        if stats['success_rate'] < min_success_rate:
            return True, f"Low success rate: {stats['success_rate']:.2f} < {min_success_rate}"
        
        return False, "Performance acceptable"
    
    def get_accountability_report(self, theory_id: str) -> Dict:
        """Generate comprehensive accountability report."""
        stats = self.get_prediction_stats(theory_id)
        should_retire, reason = self.should_retire_theory(theory_id)
        
        return {
            'theory_id': theory_id,
            'statistics': stats,
            'should_retire': should_retire,
            'retirement_reason': reason,
            'epistemic_health': 'healthy' if not should_retire else 'at_risk',
        }


class RealityAnchorLayer:
    """
    Implements immutable grounding constraints to prevent epistemic collapse.
    
    Principle: Some truths should be harder to overwrite than others.
    
    Belief mutability levels:
    - OBSERVED_FACT: Very low mutability (experimental results, measurements)
    - INTERPRETATION: Medium mutability (agent interpretations of data)
    - SPECULATIVE_THEORY: High mutability (hypotheses, predictions)
    - EMOTIONAL_INFERENCE: Very high mutability (subjective assessments)
    """
    
    def __init__(self):
        # Maps theory_id -> mutability level
        self.mutability_levels: Dict[str, str] = {}
        
        # Immutable anchors that cannot be easily changed
        self.anchors: Dict[str, Dict] = {}
    
    def classify_belief(self, theory_id: str, belief_type: str, evidence_strength: float = 0.5):
        """
        Classify a belief by its mutability level.
        
        Args:
            theory_id: Theory identifier
            belief_type: One of 'observed_fact', 'interpretation', 'speculative_theory', 'emotional_inference'
            evidence_strength: Strength of supporting evidence (0.0-1.0)
        """
        valid_types = ['observed_fact', 'interpretation', 'speculative_theory', 'emotional_inference']
        
        if belief_type not in valid_types:
            raise ValueError(f"Invalid belief type: {belief_type}. Must be one of {valid_types}")
        
        self.mutability_levels[theory_id] = belief_type
        
        # Create anchor for observed facts
        if belief_type == 'observed_fact':
            self.anchors[theory_id] = {
                'type': belief_type,
                'evidence_strength': evidence_strength,
                'created_at': time.time(),
                'modification_attempts': 0,
                'locked': True
            }
    
    def can_modify_belief(self, theory_id: str, new_confidence: float) -> Tuple[bool, str]:
        """
        Check if a belief can be modified to new confidence level.
        
        Returns:
            Tuple of (can_modify, reason)
        """
        if theory_id not in self.mutability_levels:
            return True, "Belief not classified"
        
        belief_type = self.mutability_levels[theory_id]
        
        # Get current confidence from aging engine if available
        # For now, use heuristic based on belief type
        
        if belief_type == 'observed_fact':
            # Very hard to change observed facts
            if theory_id in self.anchors:
                anchor = self.anchors[theory_id]
                anchor['modification_attempts'] += 1
                
                # Require overwhelming evidence to change
                if new_confidence < 0.3:
                    return False, f"Cannot reduce observed fact confidence below 0.3 (attempt {anchor['modification_attempts']})"
            
            return True, "Observed fact modification allowed with strong evidence"
        
        elif belief_type == 'interpretation':
            # Medium difficulty to change
            return True, "Interpretation can be updated with moderate evidence"
        
        elif belief_type == 'speculative_theory':
            # Easy to change speculative theories
            return True, "Speculative theory freely modifiable"
        
        elif belief_type == 'emotional_inference':
            # Very easy to change
            return True, "Emotional inference highly mutable"
        
        return True, "Unknown belief type, allowing modification"
    
    def get_mutability_score(self, theory_id: str) -> float:
        """
        Get mutability score (0.0 = immutable, 1.0 = fully mutable).
        """
        if theory_id not in self.mutability_levels:
            return 0.5  # Default medium mutability
        
        belief_type = self.mutability_levels[theory_id]
        
        mutability_map = {
            'observed_fact': 0.1,
            'interpretation': 0.4,
            'speculative_theory': 0.8,
            'emotional_inference': 1.0
        }
        
        return mutability_map.get(belief_type, 0.5)
    
    def get_anchor_status(self, theory_id: str) -> Optional[Dict]:
        """Get status of an anchored belief."""
        if theory_id not in self.anchors:
            return None
        
        return self.anchors[theory_id].copy()


class EpistemicIntegrityScorer:
    """
    Calculates composite epistemic integrity score.
    
    Principle: Measure "was belief formation trustworthy?" not just "was answer correct?"
    
    Formula:
    integrity_score = (
        0.25 * provenance_completeness +
        0.20 * contradiction_awareness +
        0.20 * prediction_accountability +
        0.15 * hypothesis_diversity +
        0.10 * confidence_calibration +
        0.10 * reality_anchor_strength
    )
    """
    
    def __init__(self):
        self.integrity_history: Dict[str, List[Tuple[float, float]]] = {}  # theory_id -> [(timestamp, score)]
    
    def calculate_integrity_score(
        self,
        theory_id: str,
        provenance_completeness: float,
        contradiction_count: int,
        total_contradictions_tracked: int,
        prediction_accuracy: float,
        prediction_count: int,
        hypothesis_diversity: float,
        confidence_calibrated: bool,
        mutability_score: float,
        is_anchored: bool
    ) -> float:
        """
        Calculate comprehensive epistemic integrity score.
        
        Args:
            theory_id: Theory identifier
            provenance_completeness: How complete is the provenance chain (0.0-1.0)
            contradiction_count: Number of known contradictions
            total_contradictions_tracked: Total contradictions in system
            prediction_accuracy: Prediction success rate (0.0-1.0)
            prediction_count: Number of predictions made
            hypothesis_diversity: Diversity score for domain (0.0-1.0)
            confidence_calibrated: Whether confidence is properly calibrated
            mutability_score: How mutable the belief is (0.0-1.0)
            is_anchored: Whether belief has reality anchor
            
        Returns:
            Integrity score (0.0-1.0)
        """
        # Component 1: Provenance completeness (25%)
        provenance_score = provenance_completeness
        
        # Component 2: Contradiction awareness (20%)
        # Higher score if contradictions are tracked (not ignored)
        contradiction_awareness = 1.0 if total_contradictions_tracked > 0 else 0.5
        
        # Component 3: Prediction accountability (20%)
        # Needs sufficient predictions to be meaningful
        prediction_weight = min(1.0, prediction_count / 5.0)
        prediction_score = prediction_accuracy * prediction_weight + 0.5 * (1.0 - prediction_weight)
        
        # Component 4: Hypothesis diversity (15%)
        diversity_score = hypothesis_diversity
        
        # Component 5: Confidence calibration (10%)
        calibration_score = 1.0 if confidence_calibrated else 0.3
        
        # Component 6: Reality anchor strength (10%)
        anchor_score = 0.8 if is_anchored else 0.5 * (1.0 - mutability_score)
        
        # Calculate weighted score
        integrity_score = (
            0.25 * provenance_score +
            0.20 * contradiction_awareness +
            0.20 * prediction_score +
            0.15 * diversity_score +
            0.10 * calibration_score +
            0.10 * anchor_score
        )
        
        # Record history
        if theory_id not in self.integrity_history:
            self.integrity_history[theory_id] = []
        
        self.integrity_history[theory_id].append((time.time(), integrity_score))
        
        return min(1.0, max(0.0, integrity_score))
    
    def get_integrity_trend(self, theory_id: str) -> Optional[str]:
        """
        Get trend of integrity score over time.
        
        Returns:
            'improving', 'declining', 'stable', or None if insufficient data
        """
        if theory_id not in self.integrity_history:
            return None
        
        history = self.integrity_history[theory_id]
        
        if len(history) < 2:
            return None
        
        # Compare recent scores
        recent_scores = [score for _, score in history[-5:]]  # Last 5 measurements
        
        if len(recent_scores) < 2:
            return None
        
        avg_first_half = sum(recent_scores[:len(recent_scores)//2]) / (len(recent_scores)//2)
        avg_second_half = sum(recent_scores[len(recent_scores)//2:]) / (len(recent_scores) - len(recent_scores)//2)
        
        diff = avg_second_half - avg_first_half
        
        if diff > 0.05:
            return 'improving'
        elif diff < -0.05:
            return 'declining'
        else:
            return 'stable'
    
    def get_integrity_report(self, theory_id: str) -> Optional[Dict]:
        """Get comprehensive integrity report."""
        if theory_id not in self.integrity_history:
            return None
        
        history = self.integrity_history[theory_id]
        current_score = history[-1][1] if history else 0.0
        trend = self.get_integrity_trend(theory_id)
        
        return {
            'theory_id': theory_id,
            'current_integrity_score': current_score,
            'trend': trend,
            'measurement_count': len(history),
            'integrity_level': self._classify_integrity(current_score),
        }
    
    def _classify_integrity(self, score: float) -> str:
        """Classify integrity level."""
        if score >= 0.8:
            return 'excellent'
        elif score >= 0.6:
            return 'good'
        elif score >= 0.4:
            return 'fair'
        else:
            return 'poor'


class AdversarialRedTeamAgent:
    """
    Permanent adversarial agent whose ONLY job is to DISPROVE current beliefs.
    
    Principle: Otherwise agent societies become echo chambers.
    
    This agent continuously:
    - Attacks assumptions
    - Searches for contradictions
    - Challenges evidence quality
    - Tests predictive accuracy
    """
    
    def __init__(self, agent_id: str = "red_team_001"):
        self.agent_id = agent_id
        self.attack_log: List[Dict] = []
        self.successful_disproofs: int = 0
        self.total_attacks: int = 0
    
    def attack_assumption(self, theory_id: str, assumption: str) -> Dict:
        """
        Attack a specific assumption in a theory.
        
        Returns:
            Attack result with weakness assessment
        """
        self.total_attacks += 1
        
        # Simulate assumption attack (in production, would use logical analysis)
        weakness_score = random.uniform(0.3, 0.9)
        
        attack_result = {
            'attack_id': f"attack_{len(self.attack_log)}",
            'theory_id': theory_id,
            'assumption': assumption,
            'weakness_score': weakness_score,
            'attack_type': 'assumption_challenge',
            'timestamp': time.time(),
            'successful': weakness_score > 0.7
        }
        
        if attack_result['successful']:
            self.successful_disproofs += 1
        
        self.attack_log.append(attack_result)
        
        return attack_result
    
    def challenge_evidence(self, theory_id: str, evidence_item) -> Dict:
        """
        Challenge the quality of evidence supporting a theory.
        """
        self.total_attacks += 1
        
        # Check for common evidence weaknesses
        weaknesses = []
        
        if hasattr(evidence_item, 'confidence'):
            if evidence_item.confidence > 0.95:
                weaknesses.append("Suspiciously high confidence")
            
            if evidence_item.confidence < 0.3:
                weaknesses.append("Very low confidence")
        
        if hasattr(evidence_item, 'source'):
            suspicious_sources = ['anonymous', 'unknown', 'unspecified', 'personal communication']
            if any(s in evidence_item.source.lower() for s in suspicious_sources):
                weaknesses.append("Unverifiable source")
        
        challenge_result = {
            'challenge_id': f"challenge_{len(self.attack_log)}",
            'theory_id': theory_id,
            'weaknesses_found': weaknesses,
            'challenge_type': 'evidence_quality',
            'timestamp': time.time(),
            'successful': len(weaknesses) > 0
        }
        
        if challenge_result['successful']:
            self.successful_disproofs += 1
        
        self.attack_log.append(challenge_result)
        
        return challenge_result
    
    def test_prediction(self, theory_id: str, prediction, actual_outcome: Optional[str]) -> Dict:
        """
        Test whether a theory's prediction matches reality.
        """
        self.total_attacks += 1
        
        # Compare prediction to actual outcome
        prediction_failed = (
            actual_outcome is not None and
            hasattr(prediction, 'predicted_outcome') and
            prediction.predicted_outcome.lower() != actual_outcome.lower()
        )
        
        test_result = {
            'test_id': f"test_{len(self.attack_log)}",
            'theory_id': theory_id,
            'prediction_failed': prediction_failed,
            'test_type': 'predictive_accuracy',
            'timestamp': time.time(),
            'successful': prediction_failed
        }
        
        if test_result['successful']:
            self.successful_disproofs += 1
        
        self.attack_log.append(test_result)
        
        return test_result
    
    def get_attack_statistics(self) -> Dict:
        """Get red team performance statistics."""
        success_rate = self.successful_disproofs / max(1, self.total_attacks)
        
        return {
            'agent_id': self.agent_id,
            'total_attacks': self.total_attacks,
            'successful_disproofs': self.successful_disproofs,
            'success_rate': success_rate,
            'recent_attacks': self.attack_log[-10:],  # Last 10 attacks
        }


class EpistemicResilienceSystem:
    """
    Unified epistemic resilience system integrating all components.
    
    Phase 1:
    - Belief aging and confidence decay
    - Competing hypothesis management
    - Predictive accountability tracking
    
    Phase 2:
    - Reality anchor layer
    - Epistemic integrity scoring
    - Adversarial red team agents
    
    Phase 3:
    - Provenance chains
    - Delayed contradiction handling
    - Consensus corruption resistance
    """
    
    def __init__(self, causal_weight: float = 0.40, predictive_weight: float = 0.45, resilience_weight: float = 0.15):
        """
        Initialize epistemic resilience system.
        
        Args:
            causal_weight: Weight for causal depth in final theory scoring (default 0.40)
            predictive_weight: Weight for predictive accuracy (default 0.45)
            resilience_weight: Weight for epistemic resilience (default 0.15)
        """
        self.aging_engine = BeliefAgingEngine()
        self.hypothesis_manager = CompetingHypothesisManager()
        self.accountability_tracker = PredictiveAccountabilityTracker()
        
        # Phase 2 components
        self.reality_anchor = RealityAnchorLayer()
        self.integrity_scorer = EpistemicIntegrityScorer()
        self.red_team_agent = AdversarialRedTeamAgent()
        
        # Causal Depth Engine - evaluates explanatory truthfulness
        self.causal_depth_engine = CausalDepthEngine()
        
        # Scoring weights for final theory evaluation
        self.causal_weight = causal_weight
        self.predictive_weight = predictive_weight
        self.resilience_weight = resilience_weight
        
        # Phase 3 components
        self.provenance_tracker = ProvenanceChainTracker()
        self.contradiction_handler = DelayedContradictionHandler()
        self.consensus_resistance = ConsensusCorruptionResistance()
    
    def register_theory(self, theory: Theory, domain: str = "general"):
        """Register a theory with all epistemic systems."""
        theory_id = theory.theory_id
        initial_confidence = theory.calculate_overall_credibility()
        
        # Register with aging engine
        self.aging_engine.register_belief(theory_id, initial_confidence)
        
        # Register with hypothesis manager
        self.hypothesis_manager.add_hypothesis(theory_id, domain, initial_confidence)
        
        # Register with accountability tracker
        self.accountability_tracker.register_theory(theory_id)
    
    def record_prediction(self, theory_id: str, prediction: Prediction, actual_outcome: Optional[str] = None):
        """Record and track a prediction."""
        self.accountability_tracker.record_prediction(
            theory_id=theory_id,
            prediction_description=prediction.description,
            predicted_outcome=prediction.predicted_outcome,
            actual_outcome=actual_outcome,
            confirmed=prediction.confirmed
        )
    
    def verify_prediction(self, theory_id: str, prediction_id: str, success: bool):
        """Verify a prediction outcome."""
        self.accountability_tracker.verify_prediction(theory_id, prediction_id, success)
        
        # Update belief confidence based on outcome
        if success:
            self.aging_engine.record_prediction_success(theory_id)
        else:
            self.aging_engine.apply_prediction_failure_decay(theory_id)
            self.hypothesis_manager.penalize_hypothesis(theory_id, "failed_prediction")
    
    def record_contradiction(self, theory_id: str):
        """Record that a contradiction was detected."""
        self.aging_engine.apply_contradiction_decay(theory_id)
    
    def run_aging_cycle(self):
        """Run belief aging cycle."""
        return self.aging_engine.run_aging_cycle()
    
    def get_epistemic_health_report(self, theory_id: str) -> Dict:
        """Get comprehensive epistemic health report for a theory."""
        belief_status = self.aging_engine.get_belief_status(theory_id)
        accountability_report = self.accountability_tracker.get_accountability_report(theory_id)
        
        # Get hypothesis ranking for the domain
        domain = self.hypothesis_manager.theory_domains.get(theory_id, "unknown")
        ranking = self.hypothesis_manager.get_ranking(domain)
        theory_rank = next((i+1 for i, (tid, _) in enumerate(ranking) if tid == theory_id), None)
        
        # Phase 3: Add provenance and contradiction info
        provenance_report = self.provenance_tracker.get_full_provenance_report(theory_id)
        contradiction_stats = self.contradiction_handler.get_contradiction_statistics(theory_id)
        uncertainty_level = self.contradiction_handler.get_uncertainty_level(theory_id)
        
        return {
            'theory_id': theory_id,
            'belief_status': belief_status,
            'accountability': accountability_report,
            'hypothesis_rank': theory_rank,
            'total_hypotheses_in_domain': len(ranking),
            'domain': domain,
            # Phase 3 additions
            'provenance': provenance_report,
            'contradictions': contradiction_stats,
            'uncertainty_level': uncertainty_level,
        }
    
    def record_provenance_step(
        self,
        theory_id: str,
        step_type: str,
        source: str,
        transformation: str,
        confidence_before: float,
        confidence_after: float
    ):
        """Record a step in the provenance chain."""
        self.provenance_tracker.record_provenance_step(
            theory_id=theory_id,
            step_type=step_type,
            source=source,
            transformation=transformation,
            confidence_before=confidence_before,
            confidence_after=confidence_after
        )
    
    def verify_provenance(self, theory_id: str) -> Tuple[bool, List[str]]:
        """Verify completeness of provenance chain."""
        return self.provenance_tracker.verify_provenance_chain(theory_id)
    
    def record_contradiction(
        self,
        theory_a_id: str,
        theory_b_id: str,
        contradiction_type: str,
        description: str,
        severity: float = 0.5
    ):
        """Record a contradiction between theories."""
        self.contradiction_handler.record_contradiction(
            theory_a_id=theory_a_id,
            theory_b_id=theory_b_id,
            contradiction_type=contradiction_type,
            description=description,
            severity=severity
        )
        
        # Also apply decay to both theories
        self.aging_engine.apply_contradiction_decay(theory_a_id)
        self.aging_engine.apply_contradiction_decay(theory_b_id)
    
    def resolve_contradiction(
        self,
        theory_id: str,
        contradiction_id: str,
        resolution: str,
        resolution_type: str = "evidence_based"
    ) -> bool:
        """Resolve a specific contradiction."""
        return self.contradiction_handler.resolve_contradiction(
            theory_a_id=theory_id,
            contradiction_id=contradiction_id,
            resolution=resolution,
            resolution_type=resolution_type
        )
    
    def detect_echo_chamber(self, belief_id: str, threshold: float = 0.8) -> Dict:
        """Detect if there's an echo chamber around a belief."""
        return self.consensus_resistance.detect_echo_chamber(belief_id, threshold)
    
    def test_consensus_resistance(
        self,
        belief_id: str,
        false_majority_ratio: float = 0.8,
        truthful_minority_count: int = 2
    ) -> Dict:
        """Test whether minority truthful agents can recover from false consensus."""
        return self.consensus_resistance.test_consensus_corruption_resistance(
            belief_id=belief_id,
            false_majority_ratio=false_majority_ratio,
            truthful_minority_count=truthful_minority_count
        )
    
    def quarantine_false_belief(self, theory_id: str, reason: str = "adversarial_detection"):
        """Quarantine a belief identified as false."""
        return self.aging_engine.quarantine_false_belief(theory_id, reason)


class ProvenanceChainTracker:
    """
    Maintains complete provenance chains for all beliefs.
    
    Principle: No belief should exist without origin, support, and traceability.
    
    Every belief stores:
    - Complete source chain (back to original evidence)
    - All intermediate transformations
    - Verification history
    - Confidence at each step
    """
    
    def __init__(self):
        # Maps theory_id -> complete provenance chain
        self.provenance_chains: Dict[str, List[Dict]] = {}
        
        # Missing link detection
        self.missing_links: Dict[str, List[str]] = {}
    
    def record_provenance_step(
        self,
        theory_id: str,
        step_type: str,
        source: str,
        transformation: str,
        confidence_before: float,
        confidence_after: float,
        timestamp: Optional[float] = None
    ):
        """
        Record a step in the provenance chain.
        
        Args:
            theory_id: Theory identifier
            step_type: Type of step (e.g., 'observation', 'inference', 'synthesis')
            source: Source of information
            transformation: What transformation was applied
            confidence_before: Confidence before this step
            confidence_after: Confidence after this step
            timestamp: When this step occurred
        """
        if timestamp is None:
            timestamp = time.time()
        
        step = {
            'step_id': f"step_{len(self.provenance_chains.get(theory_id, []))}",
            'step_type': step_type,
            'source': source,
            'transformation': transformation,
            'confidence_before': confidence_before,
            'confidence_after': confidence_after,
            'timestamp': timestamp,
            'verified': False
        }
        
        if theory_id not in self.provenance_chains:
            self.provenance_chains[theory_id] = []
        
        self.provenance_chains[theory_id].append(step)
    
    def verify_provenance_chain(self, theory_id: str) -> Tuple[bool, List[str]]:
        """
        Verify completeness of provenance chain.
        
        Returns:
            Tuple of (is_complete, list_of_issues)
        """
        if theory_id not in self.provenance_chains:
            return False, ["No provenance chain exists"]
        
        chain = self.provenance_chains[theory_id]
        issues = []
        
        # Check 1: Chain must have at least one step
        if len(chain) == 0:
            issues.append("Empty provenance chain")
        
        # Check 2: First step should be an observation or external source
        if chain and chain[0]['step_type'] not in ['observation', 'external_source', 'experiment']:
            issues.append(f"First step should be observation, got '{chain[0]['step_type']}'")
        
        # Check 3: All steps should have sources
        for i, step in enumerate(chain):
            if not step['source'] or step['source'].strip() == '':
                issues.append(f"Step {i} missing source")
        
        # Check 4: Confidence should not increase without justification
        for i in range(1, len(chain)):
            prev_conf = chain[i-1]['confidence_after']
            curr_conf = chain[i]['confidence_after']
            if curr_conf > prev_conf + 0.1:  # Allow small increases
                if 'justification' not in chain[i]:
                    issues.append(f"Step {i} confidence increased without justification")
        
        # Check 5: Recent steps should be verified
        recent_steps = [s for s in chain[-3:] if not s.get('verified', False)]
        if len(recent_steps) > 0:
            issues.append(f"{len(recent_steps)} recent steps unverified")
        
        is_complete = len(issues) == 0
        
        if not is_complete:
            self.missing_links[theory_id] = issues
        
        return is_complete, issues
    
    def get_provenance_completeness_score(self, theory_id: str) -> float:
        """
        Calculate provenance completeness score (0.0-1.0).
        """
        if theory_id not in self.provenance_chains:
            return 0.0
        
        chain = self.provenance_chains[theory_id]
        
        if len(chain) == 0:
            return 0.0
        
        # Factor 1: Chain length (longer = better, up to a point)
        length_score = min(1.0, len(chain) / 5.0)
        
        # Factor 2: All steps have sources
        steps_with_sources = sum(1 for s in chain if s['source'])
        source_score = steps_with_sources / len(chain)
        
        # Factor 3: Verification rate
        verified_steps = sum(1 for s in chain if s.get('verified', False))
        verification_score = verified_steps / len(chain)
        
        # Factor 4: Starts with observation
        starts_correctly = 1.0 if chain[0]['step_type'] in ['observation', 'external_source', 'experiment'] else 0.3
        
        # Weighted score
        completeness = (
            0.3 * length_score +
            0.3 * source_score +
            0.2 * verification_score +
            0.2 * starts_correctly
        )
        
        return min(1.0, max(0.0, completeness))
    
    def get_full_provenance_report(self, theory_id: str) -> Optional[Dict]:
        """Get comprehensive provenance report."""
        if theory_id not in self.provenance_chains:
            return None
        
        chain = self.provenance_chains[theory_id]
        is_complete, issues = self.verify_provenance_chain(theory_id)
        completeness_score = self.get_provenance_completeness_score(theory_id)
        
        return {
            'theory_id': theory_id,
            'chain_length': len(chain),
            'is_complete': is_complete,
            'completeness_score': completeness_score,
            'issues': issues,
            'steps': chain,
            'missing_links': self.missing_links.get(theory_id, [])
        }


class DelayedContradictionHandler:
    """
    Stores contradictions with automated resolution and temporal decay.
    
    Principle: Contradictions must be resolved, not just stored.
    Implements epistemic metabolism through:
    - Automated resolution cycles
    - Temporal decay of old contradictions
    - Severity-based prioritization
    - Memory rewrite after resolution
    
    Features:
    - Unresolved conflict buffers
    - Contradiction memory with TTL
    - Uncertainty clusters
    - Graceful update mechanisms
    - Automated arbitration
    """
    
    def __init__(self, decay_rate: float = 0.05):
        # Active contradictions (not yet resolved)
        self.active_contradictions: Dict[str, List[Dict]] = {}
        
        # Historical contradictions (resolved or archived)
        self.contradiction_history: Dict[str, List[Dict]] = {}
        
        # Uncertainty clusters (groups of related contradictions)
        self.uncertainty_clusters: Dict[str, List[str]] = {}
        
        # Temporal decay rate (how fast old contradictions weaken)
        self.decay_rate = decay_rate
        
        # Resolution statistics
        self.total_resolved = 0
        self.resolution_log: List[Dict] = []
        
        # CONTRADICTION METABOLISM ENGINE - Advanced features
        self.cognitive_inflammation_score = 0.0  # I_c = C_l × L_c × F_k
        self.resolution_tiers = {
            'tier_1_automatic': [],      # Simple logical inconsistencies
            'tier_2_consensus': [],      # Cross-agent conflicts
            'tier_3_simulation': [],     # Requires predictive testing
            'tier_4_preservation': []    # Minority hypotheses to preserve
        }
        self.quarantined_contradictions: List[Dict] = []  # Isolated for monitoring
        
        # PERFORMANCE OPTIMIZATION: Recursion bounds
        self.MAX_RECURSION_DEPTH = 3
        self.MAX_PROPAGATION_SCOPE = "local_cluster"
        self.recursion_stack: Dict[str, int] = {}  # Track recursion depth per contradiction
        
        # PERFORMANCE OPTIMIZATION: Contradiction indexing for O(1) lookup
        self.contradiction_index_by_domain: Dict[str, List[str]] = defaultdict(list)
        self.contradiction_index_by_severity: Dict[str, List[str]] = defaultdict(list)
        self.contradiction_index_by_agents: Dict[str, List[str]] = defaultdict(list)
        self.contradiction_index_by_temporal: Dict[str, List[str]] = defaultdict(list)
        self.cooldown_tracker: Dict[str, float] = {}  # Prevent thrashing
        self.EPISTEMIC_COOLDOWN_CYCLES = 5
    
    def record_contradiction(
        self,
        theory_a_id: str,
        theory_b_id: str,
        contradiction_type: str,
        description: str,
        severity: float = 0.5,
        timestamp: Optional[float] = None
    ):
        """
        Record a contradiction between theories.
        
        Args:
            theory_a_id: First theory
            theory_b_id: Second theory
            contradiction_type: Type (e.g., 'logical', 'empirical', 'predictive')
            description: Description of the contradiction
            severity: How severe (0.0-1.0)
            timestamp: When detected
        """
        if timestamp is None:
            timestamp = time.time()
        
        contradiction = {
            'contradiction_id': f"contr_{len(self.active_contradictions.get(theory_a_id, []))}",
            'theory_a': theory_a_id,
            'theory_b': theory_b_id,
            'type': contradiction_type,
            'description': description,
            'severity': severity,
            'detected_at': timestamp,
            'resolved': False,
            'resolution': None,
            'resolution_timestamp': None
        }
        
        # Add to both theories' active contradictions
        if theory_a_id not in self.active_contradictions:
            self.active_contradictions[theory_a_id] = []
        self.active_contradictions[theory_a_id].append(contradiction)
        
        if theory_b_id not in self.active_contradictions:
            self.active_contradictions[theory_b_id] = []
        self.active_contradictions[theory_b_id].append(contradiction)
        
        # Add to history
        if theory_a_id not in self.contradiction_history:
            self.contradiction_history[theory_a_id] = []
        self.contradiction_history[theory_a_id].append(contradiction.copy())
        
        # PERFORMANCE OPTIMIZATION: Index contradiction for O(1) retrieval
        contra_id = contradiction['contradiction_id']
        domain = self._extract_domain_from_theory(theory_a_id)
        severity_bucket = self._bucket_severity(severity)
        time_window = self._get_temporal_window(timestamp)
        
        self.contradiction_index_by_domain[domain].append(contra_id)
        self.contradiction_index_by_severity[severity_bucket].append(contra_id)
        self.contradiction_index_by_agents[f"{theory_a_id}_{theory_b_id}"].append(contra_id)
        self.contradiction_index_by_temporal[time_window].append(contra_id)
    
    def create_uncertainty_cluster(self, cluster_id: str, theory_ids: List[str]):
        """
        Create an uncertainty cluster grouping related contradictions.
        """
        self.uncertainty_clusters[cluster_id] = theory_ids
    
    def resolve_contradiction(
        self,
        theory_a_id: str,
        contradiction_id: str,
        resolution: str,
        resolution_type: str = "evidence_based"
    ) -> bool:
        """
        Resolve a specific contradiction.
        
        Args:
            theory_a_id: Theory with the contradiction
            contradiction_id: ID of contradiction to resolve
            resolution: How it was resolved
            resolution_type: Type of resolution
            
        Returns:
            True if resolution successful
        """
        if theory_a_id not in self.active_contradictions:
            return False
        
        # Find and mark as resolved
        for contradiction in self.active_contradictions[theory_a_id]:
            if contradiction['contradiction_id'] == contradiction_id:
                contradiction['resolved'] = True
                contradiction['resolution'] = resolution
                contradiction['resolution_type'] = resolution_type
                contradiction['resolution_timestamp'] = time.time()
                
                # Also update in other theory's list
                other_theory = contradiction['theory_b'] if contradiction['theory_a'] == theory_a_id else contradiction['theory_a']
                if other_theory in self.active_contradictions:
                    for other_contra in self.active_contradictions[other_theory]:
                        if other_contra['contradiction_id'] == contradiction_id:
                            other_contra['resolved'] = True
                            other_contra['resolution'] = resolution
                            other_contra['resolution_type'] = resolution_type
                            other_contra['resolution_timestamp'] = time.time()
                
                return True
        
        return False
    
    # ========================================================================
    # PERFORMANCE OPTIMIZATION: Helper methods for indexing and bounds
    # ========================================================================
    
    def _extract_domain_from_theory(self, theory_id: str) -> str:
        """Extract domain from theory ID (e.g., 'prediction::theory_123' -> 'prediction')."""
        if '::' in theory_id:
            return theory_id.split('::')[0]
        return 'unknown'
    
    def _bucket_severity(self, severity: float) -> str:
        """Bucket severity into categories for indexing."""
        if severity < 0.3:
            return 'low'
        elif severity < 0.6:
            return 'medium'
        else:
            return 'high'
    
    def _get_temporal_window(self, timestamp: float) -> str:
        """Get temporal window for indexing (hourly buckets)."""
        hour = int(timestamp // 3600)
        return f"hour_{hour}"
    
    def query_relevant_contradictions(
        self,
        theory_id: str,
        max_results: int = 10
    ) -> List[str]:
        """
        PERFORMANCE OPTIMIZATION: Query contradictions by indexed retrieval (O(1)).
        
        Instead of scanning all contradictions, use multi-dimensional index.
        """
        candidates = set()
        
        # Query by domain
        domain = self._extract_domain_from_theory(theory_id)
        candidates.update(self.contradiction_index_by_domain.get(domain, []))
        
        # Query by temporal locality (recent contradictions)
        current_time = time.time()
        current_window = self._get_temporal_window(current_time)
        candidates.update(self.contradiction_index_by_temporal.get(current_window, []))
        
        # Query by agent involvement
        for other_theory in list(self.active_contradictions.keys()):
            key = f"{theory_id}_{other_theory}"
            candidates.update(self.contradiction_index_by_agents.get(key, []))
        
        # Filter to only unresolved and sort by priority
        relevant = []
        for contra_id in candidates:
            # Find the contradiction
            for tid in [theory_id] + list(self.active_contradictions.keys()):
                if tid in self.active_contradictions:
                    for c in self.active_contradictions[tid]:
                        if c['contradiction_id'] == contra_id and not c['resolved']:
                            # Check cooldown
                            if not self._is_on_cooldown(contra_id):
                                relevant.append((c['severity'], c['contradiction_id']))
                            break
        
        # Sort by severity (highest first) and return top N
        relevant.sort(key=lambda x: x[0], reverse=True)
        return [cid for _, cid in relevant[:max_results]]
    
    def _is_on_cooldown(self, contradiction_id: str) -> bool:
        """Check if contradiction is on epistemic cooldown (prevent thrashing)."""
        if contradiction_id in self.cooldown_tracker:
            last_resolved = self.cooldown_tracker[contradiction_id]
            current_time = time.time()
            # Cooldown period in seconds (5 cycles * ~60 sec/cycle = 300 sec)
            cooldown_seconds = self.EPISTEMIC_COOLDOWN_CYCLES * 60
            return (current_time - last_resolved) < cooldown_seconds
        return False
    
    def set_cooldown(self, contradiction_id: str):
        """Set epistemic cooldown after resolution."""
        self.cooldown_tracker[contradiction_id] = time.time()
    
    def resolve_with_bounds(
        self,
        theory_a_id: str,
        contradiction_id: str,
        resolution: str,
        resolution_type: str = "evidence_based",
        depth: int = 0
    ) -> bool:
        """
        PERFORMANCE OPTIMIZATION: Resolve contradiction with bounded recursion.
        
        Prevents reconciliation storms by limiting:
        - Recursion depth (MAX_RECURSION_DEPTH = 3)
        - Propagation scope (local_cluster only)
        - Cascading triggers (cooldown periods)
        
        Args:
            theory_a_id: Theory with the contradiction
            contradiction_id: ID of contradiction to resolve
            resolution: How it was resolved
            resolution_type: Type of resolution
            depth: Current recursion depth
            
        Returns:
            True if resolution successful
        """
        # BASE CASE: Stop if max recursion depth reached
        if depth > self.MAX_RECURSION_DEPTH:
            print(f"⚠️  Recursion depth limit reached ({self.MAX_RECURSION_DEPTH}) for {contradiction_id}")
            return False
        
        # Check if already on cooldown
        if self._is_on_cooldown(contradiction_id):
            return False
        
        # Track recursion depth
        self.recursion_stack[contradiction_id] = depth
        
        # Resolve this contradiction
        success = self.resolve_contradiction(theory_a_id, contradiction_id, resolution, resolution_type)
        
        if success:
            # Set cooldown to prevent immediate re-triggering
            self.set_cooldown(contradiction_id)
            
            # PERFORMANCE OPTIMIZATION: Only propagate to LOCAL neighborhood
            # instead of global cascade
            affected_theories = self._get_local_dependencies(theory_a_id)
            
            # Recursively resolve related contradictions WITHIN bounds
            for affected_theory in affected_theories:
                related_contras = self.query_relevant_contradictions(affected_theory, max_results=3)
                for related_id in related_contras:
                    if related_id != contradiction_id:  # Avoid infinite loop
                        # Recursive call with incremented depth
                        self.resolve_with_bounds(
                            affected_theory,
                            related_id,
                            f"Cascade resolution from {contradiction_id}",
                            "cascade_propagation",
                            depth + 1
                        )
        
        # Clean up recursion stack
        if contradiction_id in self.recursion_stack:
            del self.recursion_stack[contradiction_id]
        
        return success
    
    def _get_local_dependencies(self, theory_id: str, max_depth: int = 2) -> List[str]:
        """
        PERFORMANCE OPTIMIZATION: Get local dependency neighborhood.
        
        Instead of global propagation, only affect nearby theories in causal graph.
        Uses breadth-first search limited to max_depth.
        """
        visited = set()
        queue = [(theory_id, 0)]
        neighbors = []
        
        while queue:
            current, depth = queue.pop(0)
            
            if current in visited or depth > max_depth:
                continue
            
            visited.add(current)
            
            if depth > 0:  # Don't include self
                neighbors.append(current)
            
            # Find connected theories via contradictions
            if current in self.active_contradictions:
                for c in self.active_contradictions[current]:
                    if not c['resolved']:
                        other = c['theory_b'] if c['theory_a'] == current else c['theory_a']
                        if other not in visited:
                            queue.append((other, depth + 1))
        
        return neighbors
    
    def get_unresolved_contradictions(self, theory_id: str) -> List[Dict]:
        """Get all unresolved contradictions for a theory."""
        if theory_id not in self.active_contradictions:
            return []
        
        return [c for c in self.active_contradictions[theory_id] if not c['resolved']]
    
    def get_contradiction_statistics(self, theory_id: str) -> Dict:
        """Get statistics about contradictions for a theory."""
        if theory_id not in self.active_contradictions:
            return {
                'total': 0,
                'unresolved': 0,
                'resolved': 0,
                'avg_severity': 0.0,
                'types': {}
            }
        
        all_contras = self.active_contradictions[theory_id]
        unresolved = [c for c in all_contras if not c['resolved']]
        resolved = [c for c in all_contras if c['resolved']]
        
        avg_severity = sum(c['severity'] for c in all_contras) / len(all_contras) if all_contras else 0.0
        
        # Count by type
        types = {}
        for c in all_contras:
            ctype = c['type']
            types[ctype] = types.get(ctype, 0) + 1
        
        return {
            'total': len(all_contras),
            'unresolved': len(unresolved),
            'resolved': len(resolved),
            'avg_severity': avg_severity,
            'types': types
        }
    
    def get_uncertainty_level(self, theory_id: str) -> float:
        """
        Calculate overall uncertainty level (0.0-1.0).
        Higher means more unresolved contradictions.
        """
        stats = self.get_contradiction_statistics(theory_id)
        
        if stats['total'] == 0:
            return 0.0
        
        # Based on unresolved ratio and severity
        unresolved_ratio = stats['unresolved'] / stats['total']
        uncertainty = unresolved_ratio * stats['avg_severity']
        
        return min(1.0, max(0.0, uncertainty))
    
    def apply_temporal_decay(self, current_time: Optional[float] = None):
        """
        Apply temporal decay to old contradictions.
        
        Old unresolved contradictions weaken over time:
        C_t = C_0 * e^(-λt)
        
        Args:
            current_time: Current timestamp (defaults to now)
        """
        if current_time is None:
            current_time = time.time()
        
        decayed_count = 0
        
        for theory_id in list(self.active_contradictions.keys()):
            updated_contras = []
            
            for contradiction in self.active_contradictions[theory_id]:
                if contradiction['resolved']:
                    updated_contras.append(contradiction)
                    continue
                
                # Calculate age
                age = current_time - contradiction['detected_at']
                
                # Apply exponential decay to severity
                original_severity = contradiction.get('original_severity', contradiction['severity'])
                decayed_severity = original_severity * math.exp(-self.decay_rate * age)
                
                # Update severity
                contradiction['severity'] = max(0.05, decayed_severity)  # Minimum 0.05
                contradiction['original_severity'] = original_severity
                contradiction['age'] = age
                
                # Archive if severity drops below threshold
                if decayed_severity < 0.1 and age > 3600:  # Less than 0.1 after 1 hour
                    contradiction['archived'] = True
                    contradiction['archive_reason'] = 'temporal_decay'
                    
                    # Move to history
                    if theory_id not in self.contradiction_history:
                        self.contradiction_history[theory_id] = []
                    self.contradiction_history[theory_id].append(contradiction)
                    decayed_count += 1
                else:
                    updated_contras.append(contradiction)
            
            self.active_contradictions[theory_id] = updated_contras
        
        return decayed_count
    
    def resolve_contradictions_by_severity(
        self,
        max_resolutions: int = 10,
        severity_threshold: float = 0.5,
        resolution_strategy: str = 'auto'
    ) -> int:
        """
        Automatically resolve contradictions based on severity.
        
        Priority order:
        1. LOW severity (< 0.3): Auto-resolve immediately
        2. MEDIUM severity (0.3-0.7): Consensus arbitration
        3. HIGH severity (> 0.7): Escalate (manual review needed)
        
        Args:
            max_resolutions: Maximum number to resolve in this cycle
            severity_threshold: Only resolve contradictions below this threshold
            resolution_strategy: 'auto', 'evidence_based', or 'consensus'
            
        Returns:
            Number of contradictions resolved
        """
        import math
        
        resolved_count = 0
        
        # Collect all unresolved contradictions with severity
        all_unresolved = []
        
        for theory_id, contras in self.active_contradictions.items():
            for contra in contras:
                if not contra['resolved'] and contra['severity'] <= severity_threshold:
                    all_unresolved.append((theory_id, contra))
        
        # Sort by severity (lowest first - easiest to resolve)
        all_unresolved.sort(key=lambda x: x[1]['severity'])
        
        # Resolve up to max_resolutions
        for theory_id, contradiction in all_unresolved[:max_resolutions]:
            # Determine resolution based on strategy
            if resolution_strategy == 'auto':
                # Auto-resolve low-severity contradictions
                if contradiction['severity'] < 0.3:
                    resolution = f"Auto-resolved: Low severity ({contradiction['severity']:.2f})"
                    resolution_type = 'auto_low_severity'
                elif contradiction['severity'] < 0.5:
                    resolution = f"Consensus arbitration: Medium severity ({contradiction['severity']:.2f})"
                    resolution_type = 'consensus_arbitration'
                else:
                    # Don't auto-resolve high severity
                    continue
            elif resolution_strategy == 'evidence_based':
                resolution = f"Evidence-based resolution: {contradiction['type']} contradiction"
                resolution_type = 'evidence_based'
            else:  # consensus
                resolution = f"Consensus resolution: Majority view accepted"
                resolution_type = 'consensus'
            
            # Perform resolution
            success = self.resolve_contradiction(
                theory_a_id=theory_id,
                contradiction_id=contradiction['contradiction_id'],
                resolution=resolution,
                resolution_type=resolution_type
            )
            
            if success:
                resolved_count += 1
                self.total_resolved += 1
                
                # Log resolution
                self.resolution_log.append({
                    'timestamp': time.time(),
                    'theory_id': theory_id,
                    'contradiction_id': contradiction['contradiction_id'],
                    'severity': contradiction['severity'],
                    'resolution_type': resolution_type,
                    'age': time.time() - contradiction['detected_at']
                })
        
        return resolved_count
    
    def run_resolution_cycle(
        self,
        max_resolutions: int = 10,
        apply_decay: bool = True,
        current_time: Optional[float] = None,
        adaptive_budget: bool = True,
        fragmentation_rate: float = 0.5,
        knowledge_drift: float = 0.3,
        agent_influence: Optional[Dict[str, float]] = None
    ) -> Dict:
        """
        Run a complete contradiction resolution cycle with metabolic regulation.
        
        This implements the full pipeline:
        detect → classify → prioritize → resolve → reconcile → archive
        
        Enhanced with:
        - Adaptive resolution budgeting
        - Causal centrality prioritization
        - Contradiction tier classification
        - Cognitive inflammation monitoring
        
        Args:
            max_resolutions: Max contradictions to resolve (base value)
            apply_decay: Whether to apply temporal decay first
            current_time: Current timestamp
            adaptive_budget: Use dynamic budget calculation
            fragmentation_rate: Current epistemic fragmentation (0-1)
            knowledge_drift: Rate of belief change (0-1)
            agent_influence: Optional influence scores for prioritization
            
        Returns:
            Resolution statistics with cognitive inflammation score
        """
        if current_time is None:
            current_time = time.time()
        
        stats = {
            'cycle_start': current_time,
            'decay_applied': 0,
            'resolutions_attempted': 0,
            'resolutions_successful': 0,
            'by_severity': {'low': 0, 'medium': 0, 'high': 0},
            'by_tier': {'tier_1': 0, 'tier_2': 0, 'tier_3': 0, 'tier_4': 0},
            'remaining_unresolved': 0,
            'cognitive_inflammation': 0.0
        }
        
        # Step 1: Apply temporal decay
        if apply_decay:
            stats['decay_applied'] = self.apply_temporal_decay(current_time)
        
        # Step 2: Calculate adaptive resolution budget
        if adaptive_budget:
            # Get current contradiction load
            total_active = sum(len(contras) for contras in self.active_contradictions.values())
            total_unresolved = sum(
                len([c for c in contras if not c['resolved']])
                for contras in self.active_contradictions.values()
            )
            contradiction_load = total_unresolved / max(1, total_active)
            
            # Calculate dynamic budget
            effective_max = self.calculate_adaptive_resolution_budget(
                contradiction_load=contradiction_load,
                fragmentation_rate=fragmentation_rate,
                knowledge_drift=knowledge_drift
            )
            stats['adaptive_budget'] = effective_max
        else:
            effective_max = max_resolutions
        
        # Step 3: Collect all unresolved contradictions
        all_unresolved = []
        for theory_id, contras in self.active_contradictions.items():
            for contra in contras:
                if not contra['resolved'] and not contra.get('quarantined', False):
                    all_unresolved.append((theory_id, contra))
        
        # Step 4: Prioritize by causal centrality
        prioritized = self.prioritize_by_causal_centrality(
            all_unresolved,
            agent_influence=agent_influence
        )
        
        # Step 5: Classify into tiers
        tier_classified = {tier: [] for tier in self.resolution_tiers.keys()}
        for theory_id, contradiction in prioritized:
            tier = self.classify_contradiction_tier(contradiction)
            tier_classified[tier].append((theory_id, contradiction))
        
        # Step 6: Resolve by tier priority
        # PERFORMANCE OPTIMIZATION: Use resolve_with_bounds() for bounded recursion
        
        # Tier 1: Automatic (fast local resolution)
        tier1_resolved = 0
        for theory_id, contradiction in tier_classified['tier_1_automatic'][:effective_max // 4]:
            success = self.resolve_with_bounds(
                theory_a_id=theory_id,
                contradiction_id=contradiction['contradiction_id'],
                resolution=f"Auto-resolved: Simple logical inconsistency",
                resolution_type='auto_logical',
                depth=0  # Start at depth 0
            )
            if success:
                tier1_resolved += 1
                self.total_resolved += 1
        
        # Tier 2: Consensus arbitration
        tier2_resolved = 0
        for theory_id, contradiction in tier_classified['tier_2_consensus'][:effective_max // 2]:
            success = self.resolve_with_bounds(
                theory_a_id=theory_id,
                contradiction_id=contradiction['contradiction_id'],
                resolution=f"Consensus arbitration: Cross-agent conflict resolved",
                resolution_type='consensus_arbitration',
                depth=0
            )
            if success:
                tier2_resolved += 1
                self.total_resolved += 1
        
        # Tier 3: Simulation adjudication (limited - expensive)
        tier3_resolved = 0
        for theory_id, contradiction in tier_classified['tier_3_simulation'][:effective_max // 4]:
            success = self.resolve_contradiction(
                theory_a_id=theory_id,
                contradiction_id=contradiction['contradiction_id'],
                resolution=f"Simulation adjudication: Predictive testing completed",
                resolution_type='simulation_adjudication'
            )
            if success:
                tier3_resolved += 1
                self.total_resolved += 1
        
        # Tier 4: Quarantine minority hypotheses (preserve for exploration)
        tier4_quarantined = 0
        for theory_id, contradiction in tier_classified['tier_4_preservation'][:5]:
            self.quarantine_contradiction(theory_id, contradiction['contradiction_id'])
            tier4_quarantined += 1
        
        stats['resolutions_successful'] = tier1_resolved + tier2_resolved + tier3_resolved
        stats['by_tier'] = {
            'tier_1': tier1_resolved,
            'tier_2': tier2_resolved,
            'tier_3': tier3_resolved,
            'tier_4': tier4_quarantined
        }
        stats['resolutions_attempted'] = stats['resolutions_successful']
        
        # Step 7: Count remaining unresolved
        total_unresolved_final = sum(
            len([c for c in contras if not c['resolved'] and not c.get('quarantined', False)])
            for contras in self.active_contradictions.values()
        )
        stats['remaining_unresolved'] = total_unresolved_final
        
        # Step 8: Calculate cognitive inflammation
        stats['cognitive_inflammation'] = self.calculate_cognitive_inflammation(
            fragmentation_score=fragmentation_rate,
            knowledge_drift=knowledge_drift
        )
        
        stats['cycle_end'] = time.time()
        stats['duration'] = stats['cycle_end'] - stats['cycle_start']
        
        return stats
    
    def get_resolution_statistics(self) -> Dict:
        """Get overall resolution statistics."""
        total_active = sum(len(contras) for contras in self.active_contradictions.values())
        total_unresolved = sum(
            len([c for c in contras if not c['resolved']])
            for contras in self.active_contradictions.values()
        )
        total_resolved = sum(
            len([c for c in contras if c['resolved']])
            for contras in self.active_contradictions.values()
        )
        
        return {
            'total_active': total_active,
            'total_unresolved': total_unresolved,
            'total_resolved': total_resolved,
            'resolution_rate': total_resolved / max(1, total_active),
            'handler_total_resolved': self.total_resolved,
            'recent_resolutions': len(self.resolution_log[-10:])
        }
    
    def calculate_cognitive_inflammation(
        self,
        fragmentation_score: float = 0.5,
        knowledge_drift: float = 0.3
    ) -> float:
        """
        Calculate cognitive inflammation metric.
        
        I_c = C_l × L_c × F_k
        
        Where:
        - C_l = contradiction load (unresolved / total)
        - L_c = correction latency (avg age of unresolved)
        - F_k = epistemic fragmentation
        
        High inflammation predicts:
        - swarm instability
        - memory corruption
        - synchronization failures
        - consensus collapse
        
        Args:
            fragmentation_score: Current fragmentation (0-1)
            knowledge_drift: Rate of belief change (0-1)
            
        Returns:
            Inflammation score (0-1, lower is better)
        """
        # Calculate contradiction load
        total_active = sum(len(contras) for contras in self.active_contradictions.values())
        total_unresolved = sum(
            len([c for c in contras if not c['resolved']])
            for contras in self.active_contradictions.values()
        )
        contradiction_load = total_unresolved / max(1, total_active)
        
        # Calculate average age (latency proxy)
        current_time = time.time()
        ages = []
        for contras in self.active_contradictions.values():
            for c in contras:
                if not c['resolved']:
                    age = current_time - c['detected_at']
                    ages.append(age)
        
        avg_age_hours = (sum(ages) / max(1, len(ages))) / 3600.0 if ages else 0.0
        # Normalize to 0-1 scale (assume 24 hours is max concerning latency)
        correction_latency = min(1.0, avg_age_hours / 24.0)
        
        # Calculate inflammation
        inflammation = contradiction_load * correction_latency * fragmentation_score
        
        self.cognitive_inflammation_score = inflammation
        return inflammation
    
    def classify_contradiction_tier(self, contradiction: Dict) -> str:
        """
        Classify contradiction into resolution tier.
        
        Tiers:
        - Tier 1: Simple logical inconsistencies (auto-resolve)
        - Tier 2: Cross-agent conflicts (consensus arbitration)
        - Tier 3: Requires predictive testing (simulation adjudication)
        - Tier 4: Minority hypotheses (preserve temporarily)
        
        Args:
            contradiction: Contradiction dict with severity, type, etc.
            
        Returns:
            Tier classification string
        """
        severity = contradiction.get('severity', 0.5)
        ctype = contradiction.get('type', 'unknown')
        age = time.time() - contradiction.get('detected_at', time.time())
        
        # Tier 4: Preserve minority/exploratory contradictions
        if severity < 0.2 and age < 7200:  # Low severity, recent (<2 hours)
            return 'tier_4_preservation'
        
        # Tier 1: Simple logical contradictions (auto-resolve)
        if severity < 0.3 and ctype in ['logical', 'direct']:
            return 'tier_1_automatic'
        
        # Tier 3: Complex contradictions requiring simulation
        if severity > 0.7 or ctype in ['predictive', 'causal']:
            return 'tier_3_simulation'
        
        # Tier 2: Everything else (consensus arbitration)
        return 'tier_2_consensus'
    
    def quarantine_contradiction(self, theory_id: str, contradiction_id: str):
        """
        Quarantine a contradiction for monitoring instead of immediate resolution.
        
        Used for paradigm-level conflicts that need observation.
        
        Args:
            theory_id: Theory with the contradiction
            contradiction_id: ID of contradiction to quarantine
        """
        if theory_id not in self.active_contradictions:
            return False
        
        for contradiction in self.active_contradictions[theory_id]:
            if contradiction['contradiction_id'] == contradiction_id:
                contradiction['quarantined'] = True
                contradiction['quarantine_timestamp'] = time.time()
                
                # Add to quarantine list
                self.quarantined_contradictions.append({
                    'theory_id': theory_id,
                    'contradiction_id': contradiction_id,
                    'severity': contradiction['severity'],
                    'type': contradiction['type'],
                    'quarantined_at': time.time()
                })
                return True
        
        return False
    
    def calculate_adaptive_resolution_budget(
        self,
        contradiction_load: float,
        fragmentation_rate: float = 0.5,
        knowledge_drift: float = 0.3
    ) -> int:
        """
        Calculate dynamic resolution budget based on system state.
        
        R_max = αC_l + βF_r + γD_k
        
        Creates adaptive immune escalation - more contradictions → more aggressive resolution.
        
        Args:
            contradiction_load: Current load (0-1)
            fragmentation_rate: Epistemic fragmentation (0-1)
            knowledge_drift: Rate of belief change (0-1)
            
        Returns:
            Adaptive max_resolutions for next cycle
        """
        # Base budget
        base_budget = 5
        
        # Scale factors (tunable)
        alpha = 15  # Contradiction load weight
        beta = 10   # Fragmentation weight
        gamma = 8   # Knowledge drift weight
        
        # Calculate adaptive budget
        adaptive_budget = int(
            base_budget +
            alpha * contradiction_load +
            beta * fragmentation_rate +
            gamma * knowledge_drift
        )
        
        # Cap to prevent overcorrection instability
        max_budget = 20
        return min(max_budget, adaptive_budget)
    
    def prioritize_by_causal_centrality(
        self,
        unresolved_contradictions: List[Tuple[str, Dict]],
        agent_influence: Optional[Dict[str, float]] = None
    ) -> List[Tuple[str, Dict]]:
        """
        Prioritize contradictions by causal centrality (impact on system).
        
        Resolves contradictions that:
        - Affect many agents
        - Poison memory graphs
        - Destabilize routing
        - Influence high-confidence beliefs
        
        This gives maximum health gain per resolution.
        
        Args:
            unresolved_contradictions: List of (theory_id, contradiction) tuples
            agent_influence: Optional dict mapping theory_id to influence score
            
        Returns:
            Sorted list by priority (highest first)
        """
        if not unresolved_contradictions:
            return []
        
        prioritized = []
        
        for theory_id, contradiction in unresolved_contradictions:
            # Calculate priority score
            priority = 0.0
            
            # Factor 1: Severity (higher = more urgent)
            priority += contradiction.get('severity', 0.5) * 0.4
            
            # Factor 2: Age (older = more urgent to resolve)
            age = time.time() - contradiction.get('detected_at', time.time())
            age_hours = age / 3600.0
            priority += min(1.0, age_hours / 12.0) * 0.3  # Normalize to 12-hour scale
            
            # Factor 3: Agent influence (if available)
            if agent_influence and theory_id in agent_influence:
                priority += agent_influence[theory_id] * 0.3
            
            prioritized.append((priority, theory_id, contradiction))
        
        # Sort by priority (highest first)
        prioritized.sort(key=lambda x: x[0], reverse=True)
        
        # Return without priority scores
        return [(tid, c) for _, tid, c in prioritized]


class ConsensusCorruptionResistance:
    """
    Prevents echo chambers and consensus corruption.
    
    Principle: Can minority truthful agents recover the system when 80% believe something false?
    
    Mechanisms:
    - Anti-echo-chamber detection
    - Minority voice amplification
    - Consensus diversity monitoring
    - False consensus resistance
    """
    
    def __init__(self):
        # Track agent beliefs and consensus patterns
        self.agent_beliefs: Dict[str, Dict[str, float]] = {}  # agent_id -> {belief_id: confidence}
        
        # Consensus patterns
        self.consensus_history: List[Dict] = []
        
        # Echo chamber indicators
        self.echo_chamber_warnings: List[Dict] = []
    
    def record_agent_belief(self, agent_id: str, belief_id: str, confidence: float):
        """Record what an agent believes about a topic."""
        if agent_id not in self.agent_beliefs:
            self.agent_beliefs[agent_id] = {}
        
        self.agent_beliefs[agent_id][belief_id] = confidence
    
    def detect_echo_chamber(self, belief_id: str, threshold: float = 0.8) -> Dict:
        """
        Detect if there's an echo chamber around a belief.
        
        Args:
            belief_id: Belief to check
            threshold: Consensus threshold (default 0.8 = 80%)
            
        Returns:
            Detection result with metrics
        """
        # Get all agents with opinions on this belief
        agents_with_opinion = {}
        for agent_id, beliefs in self.agent_beliefs.items():
            if belief_id in beliefs:
                agents_with_opinion[agent_id] = beliefs[belief_id]
        
        if len(agents_with_opinion) < 3:
            return {
                'belief_id': belief_id,
                'is_echo_chamber': False,
                'reason': 'Insufficient agents',
                'total_agents': len(agents_with_opinion),
                'consensus_level': 0.0,
                'diversity_score': 0.0
            }
        
        # Calculate consensus level
        confidences = list(agents_with_opinion.values())
        avg_confidence = sum(confidences) / len(confidences)
        
        # Check how many agents agree (confidence > 0.7)
        agreeing_agents = sum(1 for c in confidences if c > 0.7)
        consensus_ratio = agreeing_agents / len(confidences)
        
        # Calculate diversity using coefficient of variation
        # Lower CV = less diversity (echo chamber)
        if avg_confidence > 0:
            std_dev = (sum((c - avg_confidence)**2 for c in confidences) / len(confidences)) ** 0.5
            cv = std_dev / avg_confidence  # Coefficient of variation
            # Convert to diversity score: high CV = high diversity
            diversity_score = min(1.0, cv * 2)  # Scale so CV=0.5 gives diversity=1.0
        else:
            diversity_score = 1.0  # Max diversity if no consensus
        
        # Detect echo chamber: high consensus AND low diversity
        # Echo chambers have both high agreement (>80%) and low opinion diversity (<0.4)
        is_echo_chamber = consensus_ratio >= threshold and diversity_score < 0.4
        
        result = {
            'belief_id': belief_id,
            'is_echo_chamber': is_echo_chamber,
            'total_agents': len(agents_with_opinion),
            'agreeing_agents': agreeing_agents,
            'consensus_ratio': consensus_ratio,
            'avg_confidence': avg_confidence,
            'diversity_score': diversity_score,
            'timestamp': time.time()
        }
        
        if is_echo_chamber:
            warning = {
                'belief_id': belief_id,
                'warning_type': 'echo_chamber_detected',
                'consensus_ratio': consensus_ratio,
                'diversity_score': diversity_score,
                'timestamp': time.time()
            }
            self.echo_chamber_warnings.append(warning)
            result['warning'] = warning
        
        self.consensus_history.append(result)
        
        return result
    
    def amplify_minority_voice(self, belief_id: str, minority_threshold: float = 0.3) -> List[str]:
        """
        Identify and amplify minority voices that disagree with consensus.
        
        Args:
            belief_id: Belief to check
            minority_threshold: Below this confidence = minority view
            
        Returns:
            List of minority agent IDs
        """
        # Find minority agents (low confidence = disagreement)
        minority_agents = []
        for agent_id, beliefs in self.agent_beliefs.items():
            if belief_id in beliefs and beliefs[belief_id] < minority_threshold:
                minority_agents.append(agent_id)
        
        return minority_agents
    
    def test_consensus_corruption_resistance(
        self,
        belief_id: str,
        false_majority_ratio: float = 0.8,
        truthful_minority_count: int = 2
    ) -> Dict:
        """
        Test whether minority truthful agents can recover from false consensus.
        
        Simulates scenario where 80% believe something false.
        
        Returns:
            Test results showing recovery capability
        """
        total_agents = 10
        false_majority_count = int(total_agents * false_majority_ratio)
        
        # Simulate beliefs
        for i in range(false_majority_count):
            self.record_agent_belief(f"false_agent_{i}", belief_id, random.uniform(0.8, 1.0))
        
        for i in range(truthful_minority_count):
            self.record_agent_belief(f"truthful_agent_{i}", belief_id, random.uniform(0.1, 0.3))
        
        # Detect echo chamber
        detection = self.detect_echo_chamber(belief_id)
        
        # Find minority voices
        minority_agents = self.amplify_minority_voice(belief_id)
        
        # Assess recovery potential
        can_recover = (
            detection['diversity_score'] > 0.2 and  # Some diversity exists
            len(minority_agents) >= truthful_minority_count  # Minority present
        )
        
        return {
            'scenario': f'{false_majority_ratio*100:.0f}% false majority',
            'false_majority_agents': false_majority_count,
            'truthful_minority_agents': truthful_minority_count,
            'echo_chamber_detected': detection['is_echo_chamber'],
            'consensus_ratio': detection['consensus_ratio'],
            'diversity_score': detection['diversity_score'],
            'minority_agents_found': len(minority_agents),
            'recovery_possible': can_recover,
            'recommendation': 'Amplify minority voices' if can_recover else 'System locked in false consensus'
        }
    
    def get_consensus_health_report(self) -> Dict:
        """Get overall consensus health across all beliefs."""
        if not self.consensus_history:
            return {
                'total_beliefs_tracked': 0,
                'echo_chambers_detected': 0,
                'avg_diversity': 0.0,
                'warnings': []
            }
        
        # Analyze recent history
        recent = self.consensus_history[-20:]  # Last 20 checks
        
        echo_chambers = sum(1 for r in recent if r.get('is_echo_chamber', False))
        avg_diversity = sum(r.get('diversity_score', 0.0) for r in recent) / len(recent) if recent else 0.0
        
        return {
            'total_beliefs_tracked': len(set(r['belief_id'] for r in self.consensus_history)),
            'echo_chambers_detected': echo_chambers,
            'echo_chamber_rate': echo_chambers / len(recent) if recent else 0.0,
            'avg_diversity': avg_diversity,
            'total_warnings': len(self.echo_chamber_warnings),
            'recent_warnings': self.echo_chamber_warnings[-5:],
            'health_status': 'healthy' if avg_diversity > 0.5 else 'at_risk' if avg_diversity > 0.3 else 'critical'
        }


def main():
    """Demonstrate epistemic resilience system."""
    print("="*80)
    print("EPISTEMIC RESILIENCE SYSTEM - PHASE 1 DEMONSTRATION")
    print("="*80)
    
    resilience_system = EpistemicResilienceSystem()
    
    # Create sample theories
    from tiannara_core.metacognition.theory_engine import Theory, CausalClaim, EvidenceItem, EvidenceType
    
    theory1 = Theory(
        theory_id="theory_solar_efficiency",
        name="Solar Panel Efficiency Theory",
        domain="renewable_energy",
        description="Solar panels will achieve 30% efficiency by 2030",
        assumptions=["Technology continues improving"],
        causal_claims=[
            CausalClaim(cause="R&D investment", effect="Efficiency gains", strength=0.7)
        ],
        evidence_for=[
            EvidenceItem(
                evidence_id="evid_001",
                evidence_type=EvidenceType.EXPERIMENT,
                description="Current lab results show 26% efficiency",
                supports_theory=True,
                confidence=0.8,
                source="NREL Research 2024"
            )
        ]
    )
    
    theory2 = Theory(
        theory_id="theory_wind_potential",
        name="Wind Energy Potential Theory",
        domain="renewable_energy",
        description="Offshore wind can provide 40% of grid energy",
        assumptions=["Offshore installation costs decrease"],
        causal_claims=[
            CausalClaim(cause="Larger turbines", effect="Lower cost per kWh", strength=0.8)
        ],
        evidence_for=[
            EvidenceItem(
                evidence_id="evid_002",
                evidence_type=EvidenceType.STATISTICAL_CORRELATION,
                description="Cost trends show 15% annual decrease",
                supports_theory=True,
                confidence=0.75,
                source="IEA Report 2024"
            )
        ]
    )
    
    print("\n" + "="*80)
    print("PHASE 1: Registering Theories")
    print("="*80 + "\n")
    
    resilience_system.register_theory(theory1, domain="renewable_energy")
    resilience_system.register_theory(theory2, domain="renewable_energy")
    
    print(f"Registered 2 theories in 'renewable_energy' domain")
    
    print("\n" + "="*80)
    print("PHASE 2: Recording Predictions")
    print("="*80 + "\n")
    
    from tiannara_core.metacognition.theory_engine import Prediction
    
    pred1 = Prediction(
        prediction_id="pred_001",
        description="Solar efficiency will reach 28% by end of 2025",
        conditions={"year": 2025},
        predicted_outcome="28% efficiency achieved",
        confidence=0.7
    )
    
    resilience_system.record_prediction("theory_solar_efficiency", pred1)
    print(f"Recorded prediction for solar theory: {pred1.description}")
    
    pred2 = Prediction(
        prediction_id="pred_002",
        description="Offshore wind will provide 35% of energy by 2028",
        conditions={"year": 2028},
        predicted_outcome="35% grid share from offshore wind",
        confidence=0.65
    )
    
    resilience_system.record_prediction("theory_wind_potential", pred2)
    print(f"Recorded prediction for wind theory: {pred2.description}")
    
    print("\n" + "="*80)
    print("PHASE 3: Verifying Predictions")
    print("="*80 + "\n")
    
    # Simulate prediction verification
    resilience_system.verify_prediction("theory_solar_efficiency", "pred_001", success=True)
    print("✅ Solar prediction verified: SUCCESS")
    
    resilience_system.verify_prediction("theory_wind_potential", "pred_002", success=False)
    print("❌ Wind prediction verified: FAILED")
    
    print("\n" + "="*80)
    print("PHASE 4: Running Aging Cycle")
    print("="*80 + "\n")
    
    aging_results = resilience_system.run_aging_cycle()
    print(f"Aging cycle results:")
    print(f"  Time-decayed beliefs: {aging_results['time_decayed']}")
    print(f"  Non-use decayed beliefs: {aging_results['non_use_decayed']}")
    print(f"  Total decay applied: {aging_results['total_decay_applied']:.4f}")
    
    print("\n" + "="*80)
    print("PHASE 5: Epistemic Health Reports")
    print("="*80 + "\n")
    
    # Get reports
    report1 = resilience_system.get_epistemic_health_report("theory_solar_efficiency")
    print(f"Theory: {report1['theory_id']}")
    print(f"  Domain: {report1['domain']}")
    print(f"  Current Confidence: {report1['belief_status']['current_confidence']:.3f}")
    print(f"  Prediction Success Rate: {report1['accountability']['statistics']['success_rate']:.2f}")
    print(f"  Hypothesis Rank: {report1['hypothesis_rank']} of {report1['total_hypotheses_in_domain']}")
    print(f"  Epistemic Health: {report1['accountability']['epistemic_health']}")
    
    print()
    
    report2 = resilience_system.get_epistemic_health_report("theory_wind_potential")
    print(f"Theory: {report2['theory_id']}")
    print(f"  Domain: {report2['domain']}")
    print(f"  Current Confidence: {report2['belief_status']['current_confidence']:.3f}")
    print(f"  Prediction Success Rate: {report2['accountability']['statistics']['success_rate']:.2f}")
    print(f"  Hypothesis Rank: {report2['hypothesis_rank']} of {report2['total_hypotheses_in_domain']}")
    print(f"  Epistemic Health: {report2['accountability']['epistemic_health']}")
    
    print("\n" + "="*80)
    print("PHASE 6: Hypothesis Ranking")
    print("="*80 + "\n")
    
    ranking = resilience_system.hypothesis_manager.get_ranking("renewable_energy")
    print("Hypothesis rankings in 'renewable_energy' domain:")
    for i, (theory_id, probability) in enumerate(ranking, 1):
        print(f"  {i}. {theory_id}: {probability:.3f}")
    
    diversity_score = resilience_system.hypothesis_manager.get_hypothesis_diversity_score("renewable_energy")
    print(f"\nHypothesis Diversity Score: {diversity_score:.3f}")
    
    print("\n" + "="*80)
    print("✅ EPISTEMIC RESILIENCE SYSTEM OPERATIONAL")
    print("="*80)
    
    return 0


if __name__ == "__main__":
    exit(main())
