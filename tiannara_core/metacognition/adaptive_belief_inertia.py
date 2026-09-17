"""
ADAPTIVE BELIEF INERTIA SYSTEM

Prevents dogmatic lock-in and enables healthy paradigm transitions.

Based on fixes.md (lines 168-270):
"Your system has strong memory stability, but weak paradigm transition dynamics."
"Most systems forget too fast. Yours forgets too slowly."

This module implements:
1. Multi-step decay curves per belief type
2. Adaptive decay rate based on contradiction pressure
3. Paradigm destabilization triggers
4. Minority hypothesis boosting during drift

Belief Type Inertia Hierarchy (from fixes.md):
- Fundamental physics: Very high inertia (hard to change)
- Strategy heuristics: Medium inertia
- Environmental assumptions: Low inertia
- Active hypotheses: Dynamic inertia

Key principle: Different belief types should decay differently.
Instead of uniform normalization, use adaptive_decay_rate based on:
- contradiction_pressure
- prediction_failure
- evidence_recency
- environmental_shift
"""

import sys
import time
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass, field
from enum import Enum

# Add project root to path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))


class BeliefType(Enum):
    """Types of beliefs with different inertia levels."""
    FUNDAMENTAL_PHYSICS = "fundamental_physics"   # Very high inertia
    STRATEGY_HEURISTIC = "strategy_heuristic"     # Medium inertia
    ENVIRONMENTAL_ASSUMPTION = "environmental"    # Low inertia
    ACTIVE_HYPOTHESIS = "active_hypothesis"       # Dynamic inertia


@dataclass
class BeliefState:
    """Tracks state of a single belief/theory."""
    belief_id: str
    belief_type: BeliefType
    domain: str
    probability: float               # Current belief strength (0.0-1.0)
    last_updated: float              # Timestamp of last update
    age: float                       # Time since creation
    contradiction_count: int = 0     # Number of contradictions encountered
    prediction_failures: int = 0     # Number of failed predictions
    successful_predictions: int = 0  # Number of successful predictions
    evidence_recency: float = 1.0    # Recency weight (1.0 = fresh, decays over time)
    is_minority: bool = False        # Is this a minority hypothesis?
    boost_factor: float = 1.0        # Temporary amplification factor
    
    def get_base_inertia(self) -> float:
        """Get base inertia for this belief type."""
        inertia_map = {
            BeliefType.FUNDAMENTAL_PHYSICS: 0.95,      # Very hard to change
            BeliefType.STRATEGY_HEURISTIC: 0.75,       # Moderate resistance
            BeliefType.ENVIRONMENTAL_ASSUMPTION: 0.50, # Easy to update
            BeliefType.ACTIVE_HYPOTHESIS: 0.30         # Highly dynamic
        }
        return inertia_map.get(self.belief_type, 0.70)
    
    def to_dict(self) -> Dict:
        return {
            'belief_id': self.belief_id,
            'belief_type': self.belief_type.value,
            'domain': self.domain,
            'probability': self.probability,
            'age': self.age,
            'contradiction_count': self.contradiction_count,
            'prediction_failures': self.prediction_failures,
            'successful_predictions': self.successful_predictions,
            'evidence_recency': self.evidence_recency,
            'is_minority': self.is_minority,
            'boost_factor': self.boost_factor
        }


@dataclass
class DecayResult:
    """Result of applying adaptive decay to a belief."""
    belief_id: str
    old_probability: float
    new_probability: float
    decay_rate: float                # Applied decay rate
    inertia: float                   # Base inertia for this belief type
    contradiction_pressure: float    # Pressure from contradictions
    prediction_pressure: float       # Pressure from failures
    recency_factor: float            # Evidence recency impact
    boost_applied: float             # Minority boost factor
    reason: str                      # Explanation of decay decision


@dataclass
class ParadigmDestabilizationEvent:
    """Event triggered when paradigm destabilization occurs."""
    domain: str
    trigger_type: str                # "repeated_failures", "contradiction_spike", "environmental_shift"
    severity: float                  # 0.0-1.0 destabilization severity
    affected_beliefs: List[str]      # Belief IDs affected
    timestamp: float
    recommendation: str              # Suggested action


class AdaptiveBeliefInertia:
    """
    Manages adaptive decay rates for beliefs based on type and context.
    
    Prevents dogmatic lock-in while maintaining necessary stability.
    Implements multi-step decay curves with contextual modulation.
    """
    
    def __init__(
        self,
        base_decay_rate: float = 0.1,
        contradiction_weight: float = 0.30,
        prediction_failure_weight: float = 0.25,
        recency_weight: float = 0.20,
        environmental_shift_weight: float = 0.25,
        minority_boost_threshold: float = 0.15,
        minority_boost_multiplier: float = 2.0,
        destabilization_threshold: float = 0.7
    ):
        """
        Initialize adaptive belief inertia system.
        
        Args:
            base_decay_rate: Base decay rate per time step (default 0.1)
            contradiction_weight: Weight for contradiction pressure (0.30)
            prediction_failure_weight: Weight for prediction failures (0.25)
            recency_weight: Weight for evidence recency (0.20)
            environmental_shift_weight: Weight for environmental changes (0.25)
            minority_boost_threshold: Probability threshold for minority status (<0.15)
            minority_boost_multiplier: Boost multiplier for minority hypotheses (2.0x)
            destabilization_threshold: Threshold for triggering paradigm reassessment (0.7)
        """
        self.base_decay_rate = base_decay_rate
        
        # Weights for adaptive decay calculation
        self.contradiction_weight = contradiction_weight
        self.prediction_failure_weight = prediction_failure_weight
        self.recency_weight = recency_weight
        self.environmental_shift_weight = environmental_shift_weight
        
        # Minority hypothesis parameters
        self.minority_boost_threshold = minority_boost_threshold
        self.minority_boost_multiplier = minority_boost_multiplier
        
        # Destabilization parameters
        self.destabilization_threshold = destabilization_threshold
        
        # Track belief states
        self.beliefs: Dict[str, BeliefState] = {}
        
        # Track domain-level statistics
        self.domain_stats: Dict[str, Dict] = {}
        
        # Destabilization event log
        self.destabilization_log: List[ParadigmDestabilizationEvent] = []
    
    def register_belief(
        self,
        belief_id: str,
        belief_type: BeliefType,
        domain: str,
        initial_probability: float = 0.5
    ):
        """
        Register a new belief in the system.
        
        Args:
            belief_id: Unique identifier for belief
            belief_type: Type of belief (determines base inertia)
            domain: Problem domain
            initial_probability: Initial belief strength
        """
        self.beliefs[belief_id] = BeliefState(
            belief_id=belief_id,
            belief_type=belief_type,
            domain=domain,
            probability=initial_probability,
            last_updated=time.time(),
            age=0.0
        )
        
        # Initialize domain stats if needed
        if domain not in self.domain_stats:
            self.domain_stats[domain] = {
                'total_beliefs': 0,
                'avg_probability': 0.0,
                'contradiction_pressure': 0.0,
                'prediction_accuracy': 0.5,
                'last_environmental_shift': time.time()
            }
        
        self.domain_stats[domain]['total_beliefs'] += 1
    
    def update_belief_state(
        self,
        belief_id: str,
        prediction_success: Optional[bool] = None,
        contradiction_detected: bool = False,
        new_evidence_strength: float = 0.0,
        environmental_shift: float = 0.0
    ) -> DecayResult:
        """
        Update belief state and apply adaptive decay.
        
        This is the core method that implements multi-step decay curves.
        
        Args:
            belief_id: Belief to update
            prediction_success: Whether latest prediction succeeded (None if N/A)
            contradiction_detected: Whether contradiction was detected
            new_evidence_strength: Strength of new supporting evidence (0.0-1.0)
            environmental_shift: Magnitude of environmental change (0.0-1.0)
            
        Returns:
            DecayResult with detailed decay information
        """
        if belief_id not in self.beliefs:
            raise ValueError(f"Belief {belief_id} not registered")
        
        belief = self.beliefs[belief_id]
        old_probability = belief.probability
        
        # Update counters
        if prediction_success is not None:
            if prediction_success:
                belief.successful_predictions += 1
            else:
                belief.prediction_failures += 1
        
        if contradiction_detected:
            belief.contradiction_count += 1
        
        # Update evidence recency (decay over time)
        time_since_update = time.time() - belief.last_updated
        belief.evidence_recency *= (1.0 - 0.01 * time_since_update)  # 1% decay per second
        belief.evidence_recency = max(0.1, min(1.0, belief.evidence_recency))
        
        # Apply new evidence
        if new_evidence_strength > 0:
            belief.evidence_recency = min(1.0, belief.evidence_recency + new_evidence_strength * 0.3)
        
        # Calculate adaptive decay rate
        decay_rate = self._calculate_adaptive_decay_rate(belief, environmental_shift)
        
        # Check for minority status and apply boost
        self._update_minority_status(belief)
        
        # Apply decay with boost
        decay_amount = old_probability * decay_rate
        boosted_decay = decay_amount / belief.boost_factor
        
        # Calculate new probability
        new_probability = max(0.01, old_probability - boosted_decay + new_evidence_strength * 0.1)
        new_probability = min(1.0, new_probability)
        
        # Update belief
        belief.probability = new_probability
        belief.last_updated = time.time()
        belief.age += time_since_update
        
        # Update domain statistics
        self._update_domain_stats(belief.domain)
        
        # Check for paradigm destabilization
        self._check_destabilization(belief.domain)
        
        # Create result
        result = DecayResult(
            belief_id=belief_id,
            old_probability=old_probability,
            new_probability=new_probability,
            decay_rate=decay_rate,
            inertia=belief.get_base_inertia(),
            contradiction_pressure=self._calculate_contradiction_pressure(belief),
            prediction_pressure=self._calculate_prediction_pressure(belief),
            recency_factor=belief.evidence_recency,
            boost_applied=belief.boost_factor,
            reason=self._explain_decay(decay_rate, belief)
        )
        
        return result
    
    def _calculate_adaptive_decay_rate(
        self,
        belief: BeliefState,
        environmental_shift: float
    ) -> float:
        """
        Calculate adaptive decay rate based on multiple factors.
        
        Formula:
        adaptive_decay_rate = base_rate × (1 - inertia) × 
                             (1 + contradiction_pressure × w1 +
                              prediction_failure × w2 +
                              (1 - recency) × w3 +
                              environmental_shift × w4)
        """
        base_rate = self.base_decay_rate
        inertia = belief.get_base_inertia()
        
        # Calculate pressure components
        contradiction_pressure = self._calculate_contradiction_pressure(belief)
        prediction_pressure = self._calculate_prediction_pressure(belief)
        recency_factor = 1.0 - belief.evidence_recency
        
        # Weighted combination
        pressure_multiplier = (
            1.0 +
            contradiction_pressure * self.contradiction_weight +
            prediction_pressure * self.prediction_failure_weight +
            recency_factor * self.recency_weight +
            environmental_shift * self.environmental_shift_weight
        )
        
        # Final decay rate (higher inertia = lower decay)
        decay_rate = base_rate * (1.0 - inertia * 0.8) * pressure_multiplier
        
        # Clamp to reasonable range
        return max(0.01, min(0.5, decay_rate))
    
    def _calculate_contradiction_pressure(self, belief: BeliefState) -> float:
        """Calculate contradiction pressure (0.0-1.0)."""
        total_tests = belief.successful_predictions + belief.prediction_failures
        if total_tests == 0:
            return 0.0
        
        # Contradiction ratio
        contradiction_ratio = belief.contradiction_count / max(1, total_tests)
        
        # Scale to pressure (more contradictions = higher pressure)
        return min(1.0, contradiction_ratio * 2.0)
    
    def _calculate_prediction_pressure(self, belief: BeliefState) -> float:
        """Calculate prediction failure pressure (0.0-1.0)."""
        total_predictions = belief.successful_predictions + belief.prediction_failures
        if total_predictions == 0:
            return 0.0
        
        # Failure ratio
        failure_ratio = belief.prediction_failures / total_predictions
        
        # Scale to pressure
        return min(1.0, failure_ratio * 1.5)
    
    def _update_minority_status(self, belief: BeliefState):
        """Update minority status and apply boost if needed."""
        domain = belief.domain
        
        # Get all beliefs in same domain
        domain_beliefs = [b for b in self.beliefs.values() if b.domain == domain]
        
        if not domain_beliefs:
            return
        
        # Calculate average probability
        avg_prob = sum(b.probability for b in domain_beliefs) / len(domain_beliefs)
        
        # Check if this belief is minority
        is_minority = belief.probability < (avg_prob * self.minority_boost_threshold)
        
        if is_minority and not belief.is_minority:
            # Just became minority - apply boost
            belief.is_minority = True
            belief.boost_factor = self.minority_boost_multiplier
        
        elif not is_minority and belief.is_minority:
            # No longer minority - remove boost
            belief.is_minority = False
            belief.boost_factor = 1.0
    
    def _update_domain_stats(self, domain: str):
        """Update domain-level statistics."""
        if domain not in self.domain_stats:
            return
        
        domain_beliefs = [b for b in self.beliefs.values() if b.domain == domain]
        
        if not domain_beliefs:
            return
        
        # Calculate averages
        total_beliefs = len(domain_beliefs)
        avg_probability = sum(b.probability for b in domain_beliefs) / total_beliefs
        
        total_predictions = sum(b.successful_predictions + b.prediction_failures for b in domain_beliefs)
        total_successes = sum(b.successful_predictions for b in domain_beliefs)
        
        prediction_accuracy = total_successes / max(1, total_predictions)
        
        avg_contradictions = sum(b.contradiction_count for b in domain_beliefs) / total_beliefs
        
        # Update stats
        self.domain_stats[domain].update({
            'total_beliefs': total_beliefs,
            'avg_probability': avg_probability,
            'contradiction_pressure': avg_contradictions,
            'prediction_accuracy': prediction_accuracy
        })
    
    def _check_destabilization(self, domain: str):
        """Check if paradigm destabilization should be triggered."""
        if domain not in self.domain_stats:
            return
        
        stats = self.domain_stats[domain]
        
        # Check for repeated prediction failures
        prediction_accuracy = stats.get('prediction_accuracy', 0.5)
        contradiction_pressure = stats.get('contradiction_pressure', 0.0)
        
        # Destabilization conditions
        should_destabilize = False
        trigger_type = ""
        severity = 0.0
        
        if prediction_accuracy < 0.3:
            # Repeated failures
            should_destabilize = True
            trigger_type = "repeated_failures"
            severity = (0.3 - prediction_accuracy) / 0.3
        
        elif contradiction_pressure > self.destabilization_threshold:
            # Contradiction spike
            should_destabilize = True
            trigger_type = "contradiction_spike"
            severity = min(1.0, contradiction_pressure)
        
        if should_destabilize:
            # Get affected beliefs
            affected = [b.belief_id for b in self.beliefs.values() 
                       if b.domain == domain and b.probability > 0.2]
            
            event = ParadigmDestabilizationEvent(
                domain=domain,
                trigger_type=trigger_type,
                severity=severity,
                affected_beliefs=affected,
                timestamp=time.time(),
                recommendation=self._generate_destabilization_recommendation(trigger_type, severity)
            )
            
            self.destabilization_log.append(event)
    
    def _generate_destabilization_recommendation(self, trigger_type: str, severity: float) -> str:
        """Generate recommendation for handling destabilization."""
        if trigger_type == "repeated_failures":
            if severity > 0.7:
                return "CRITICAL: Initiate full paradigm reassessment. Consider replacing dominant theories."
            else:
                return "WARNING: Increase exploration of alternative hypotheses. Reduce confidence in current paradigm."
        
        elif trigger_type == "contradiction_spike":
            if severity > 0.7:
                return "CRITICAL: High contradiction pressure detected. Trigger theory competition and allow minority hypotheses to compete."
            else:
                return "WARNING: Monitor contradiction accumulation. Prepare for potential paradigm shift."
        
        else:
            return "INFO: Review belief ecosystem health."
    
    def _explain_decay(self, decay_rate: float, belief: BeliefState) -> str:
        """Generate human-readable explanation for decay decision."""
        reasons = []
        
        if belief.contradiction_count > 0:
            reasons.append(f"{belief.contradiction_count} contradictions")
        
        if belief.prediction_failures > 0:
            reasons.append(f"{belief.prediction_failures} prediction failures")
        
        if belief.evidence_recency < 0.5:
            reasons.append("stale evidence")
        
        if belief.is_minority:
            reasons.append(f"minority boost ({belief.boost_factor}x)")
        
        reason_str = ", ".join(reasons) if reasons else "normal decay"
        
        return f"Decay rate {decay_rate:.3f} applied due to: {reason_str}"
    
    def trigger_paradigm_reassessment(self, domain: str) -> List[str]:
        """
        Manually trigger paradigm reassessment for a domain.
        
        This boosts all minority hypotheses and increases decay rates
        for dominant beliefs.
        
        Returns:
            List of belief IDs that were boosted
        """
        boosted_beliefs = []
        
        domain_beliefs = [b for b in self.beliefs.values() if b.domain == domain]
        
        if not domain_beliefs:
            return boosted_beliefs
        
        # Calculate current average
        avg_prob = sum(b.probability for b in domain_beliefs) / len(domain_beliefs)
        
        for belief in domain_beliefs:
            if belief.probability < avg_prob:
                # Boost minority beliefs
                belief.boost_factor = self.minority_boost_multiplier * 1.5
                belief.is_minority = True
                boosted_beliefs.append(belief.belief_id)
            else:
                # Reduce boost for dominant beliefs
                belief.boost_factor = 0.8
        
        # Log destabilization event
        event = ParadigmDestabilizationEvent(
            domain=domain,
            trigger_type="manual_reassessment",
            severity=0.8,
            affected_beliefs=boosted_beliefs,
            timestamp=time.time(),
            recommendation="Manual paradigm reassessment triggered. Minority hypotheses amplified."
        )
        
        self.destabilization_log.append(event)
        
        return boosted_beliefs
    
    def get_domain_health(self, domain: str) -> Dict:
        """
        Get health metrics for a domain's belief ecosystem.
        
        Returns:
            Dictionary with domain health indicators
        """
        if domain not in self.domain_stats:
            return {'status': 'unknown', 'message': 'Domain not found'}
        
        stats = self.domain_stats[domain].copy()
        
        domain_beliefs = [b for b in self.beliefs.values() if b.domain == domain]
        
        if not domain_beliefs:
            stats['status'] = 'empty'
            return stats
        
        # Calculate diversity metric
        probabilities = [b.probability for b in domain_beliefs]
        max_prob = max(probabilities)
        min_prob = min(probabilities)
        diversity = 1.0 - (max_prob - min_prob)  # Higher = more diverse
        
        # Determine status
        prediction_accuracy = stats.get('prediction_accuracy', 0.5)
        contradiction_pressure = stats.get('contradiction_pressure', 0.0)
        
        if prediction_accuracy > 0.7 and contradiction_pressure < 0.3:
            status = 'healthy'
        elif prediction_accuracy < 0.3 or contradiction_pressure > 0.7:
            status = 'critical'
        else:
            status = 'degraded'
        
        stats.update({
            'status': status,
            'diversity': diversity,
            'belief_count': len(domain_beliefs),
            'dominant_belief_prob': max_prob,
            'minority_belief_count': sum(1 for b in domain_beliefs if b.is_minority)
        })
        
        return stats
    
    def get_recent_destabilizations(self, limit: int = 10) -> List[Dict]:
        """Get recent paradigm destabilization events."""
        recent = sorted(self.destabilization_log, key=lambda e: e.timestamp, reverse=True)[:limit]
        
        return [
            {
                'domain': e.domain,
                'trigger_type': e.trigger_type,
                'severity': e.severity,
                'timestamp': e.timestamp,
                'recommendation': e.recommendation,
                'affected_beliefs_count': len(e.affected_beliefs)
            }
            for e in recent
        ]


if __name__ == "__main__":
    """Test the Adaptive Belief Inertia system."""
    print("="*80)
    print("ADAPTIVE BELIEF INERTIA - TEST")
    print("="*80)
    
    abi = AdaptiveBeliefInertia()
    
    # Test 1: Register beliefs with different types
    print("\nTest 1: Register Beliefs")
    abi.register_belief("physics_law_1", BeliefType.FUNDAMENTAL_PHYSICS, "physics", 0.8)
    abi.register_belief("heuristic_1", BeliefType.STRATEGY_HEURISTIC, "strategy", 0.6)
    abi.register_belief("env_assumption_1", BeliefType.ENVIRONMENTAL_ASSUMPTION, "environment", 0.5)
    abi.register_belief("hypothesis_1", BeliefType.ACTIVE_HYPOTHESIS, "research", 0.4)
    
    print("  ✓ Registered 4 beliefs with different inertia levels")
    
    # Test 2: Apply decay with different scenarios
    print("\nTest 2: Adaptive Decay Scenarios")
    
    # Scenario A: Successful prediction (low decay)
    result_a = abi.update_belief_state("physics_law_1", prediction_success=True)
    print(f"  Physics Law (success): {result_a.old_probability:.3f} → {result_a.new_probability:.3f}")
    print(f"    Decay rate: {result_a.decay_rate:.3f}, Inertia: {result_a.inertia:.2f}")
    
    # Scenario B: Failed prediction (higher decay)
    result_b = abi.update_belief_state("heuristic_1", prediction_success=False)
    print(f"  Heuristic (failure): {result_b.old_probability:.3f} → {result_b.new_probability:.3f}")
    print(f"    Decay rate: {result_b.decay_rate:.3f}, Inertia: {result_b.inertia:.2f}")
    
    # Scenario C: Contradiction detected (high decay)
    result_c = abi.update_belief_state("env_assumption_1", contradiction_detected=True)
    print(f"  Env Assumption (contradiction): {result_c.old_probability:.3f} → {result_c.new_probability:.3f}")
    print(f"    Decay rate: {result_c.decay_rate:.3f}, Inertia: {result_c.inertia:.2f}")
    
    # Scenario D: Multiple failures (very high decay)
    for i in range(3):
        abi.update_belief_state("hypothesis_1", prediction_success=False)
    result_d = abi.update_belief_state("hypothesis_1", prediction_success=False)
    print(f"  Hypothesis (3+ failures): {result_d.old_probability:.3f} → {result_d.new_probability:.3f}")
    print(f"    Decay rate: {result_d.decay_rate:.3f}, Inertia: {result_d.inertia:.2f}")
    
    # Test 3: Minority hypothesis boosting
    print("\nTest 3: Minority Hypothesis Boosting")
    abi.register_belief("dominant_theory", BeliefType.ACTIVE_HYPOTHESIS, "test_domain", 0.7)
    abi.register_belief("minority_theory", BeliefType.ACTIVE_HYPOTHESIS, "test_domain", 0.1)
    
    # Apply updates
    abi.update_belief_state("dominant_theory", prediction_success=True)
    result_minority = abi.update_belief_state("minority_theory", prediction_success=True)
    
    print(f"  Dominant theory: boost={abi.beliefs['dominant_theory'].boost_factor:.1f}x")
    print(f"  Minority theory: boost={result_minority.boost_applied:.1f}x")
    print(f"  Minority received {result_minority.boost_applied:.1f}x decay reduction")
    
    # Test 4: Paradigm destabilization
    print("\nTest 4: Paradigm Destabilization")
    abi.register_belief("failing_theory", BeliefType.STRATEGY_HEURISTIC, "crisis_domain", 0.6)
    
    # Simulate repeated failures
    for i in range(10):
        abi.update_belief_state("failing_theory", prediction_success=False)
    
    health = abi.get_domain_health("crisis_domain")
    print(f"  Domain status: {health['status']}")
    print(f"  Prediction accuracy: {health.get('prediction_accuracy', 0):.3f}")
    print(f"  Contradiction pressure: {health.get('contradiction_pressure', 0):.3f}")
    
    # Check destabilization log
    destabs = abi.get_recent_destabilizations(1)
    if destabs:
        print(f"  Destabilization triggered: {destabs[0]['trigger_type']}")
        print(f"  Recommendation: {destabs[0]['recommendation'][:80]}...")
    
    # Test 5: Manual paradigm reassessment
    print("\nTest 5: Manual Paradigm Reassessment")
    boosted = abi.trigger_paradigm_reassessment("crisis_domain")
    print(f"  Boosted {len(boosted)} minority hypotheses")
    
    health_after = abi.get_domain_health("crisis_domain")
    print(f"  Domain status after reassessment: {health_after['status']}")
    
    print("\n" + "="*80)
    print("✅ ADAPTIVE BELIEF INERTIA TEST COMPLETE")
    print("="*80)
