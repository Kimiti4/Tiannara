"""
CAUSAL DEPTH ENGINE

Structural causal evaluator that measures explanatory truthfulness, not statistical usefulness.

Based on fixes.md (lines 461-856):
"Prediction quality ≠ causal validity"

This module evaluates theories on:
1. Mechanistic Integrity - Does it explain HOW?
2. Intervention Stability - Does it survive manipulation?
3. Counterfactual Coherence - Would effect occur without cause?
4. Temporal Validity - Did cause precede effect?
5. Explanatory Compression - Does it reduce complexity elegantly?
6. Spurious Correlation Detection - Could hidden factor C cause both?

Key principle: Predictive accuracy is INTENTIONALLY absent from causal scoring.
Prediction belongs elsewhere. Causal depth measures explanatory truthfulness.
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


class CausalLinkType(Enum):
    """Types of causal relationships."""
    DIRECT = "direct"                    # A directly causes B
    INDIRECT = "indirect"                # A causes C which causes B
    MODERATED = "moderated"              # A causes B under condition C
    MEDIATED = "mediated"                # A causes B through mechanism M
    SPURIOUS = "spurious"                # A and B both caused by C


@dataclass
class CausalMechanism:
    """Represents a causal mechanism linking cause to effect."""
    mechanism_id: str
    description: str                     # How the causation works
    link_type: CausalLinkType
    strength: float                      # 0.0-1.0 causal strength
    evidence_count: int = 0
    intervention_tests: int = 0
    intervention_successes: int = 0
    counterfactual_tests: int = 0
    counterfactual_coherent: int = 0
    
    def get_intervention_stability(self) -> float:
        """Calculate intervention success rate."""
        if self.intervention_tests == 0:
            return 0.5  # Neutral if untested
        return self.intervention_successes / self.intervention_tests
    
    def get_counterfactual_coherence(self) -> float:
        """Calculate counterfactual coherence rate."""
        if self.counterfactual_tests == 0:
            return 0.5  # Neutral if untested
        return self.counterfactual_coherent / self.counterfactual_tests


@dataclass
class CausalChain:
    """Complete causal chain from root cause to final effect."""
    chain_id: str
    cause: str
    effect: str
    mechanisms: List[CausalMechanism] = field(default_factory=list)
    temporal_valid: bool = True
    compression_ratio: float = 1.0       # Higher = better compression
    
    def has_missing_links(self) -> bool:
        """Check if causal chain has gaps."""
        if len(self.mechanisms) == 0:
            return True
        
        # Check for weak mechanisms (< 0.3 strength)
        weak_mechanisms = [m for m in self.mechanisms if m.strength < 0.3]
        return len(weak_mechanisms) > 0
    
    def get_mechanistic_integrity(self) -> float:
        """
        Calculate mechanistic integrity score.
        
        Measures: Does the theory explain HOW, not just correlate?
        Checks: causal chain continuity, missing links, hidden jumps
        """
        if not self.mechanisms:
            return 0.0
        
        # Penalize missing links
        if self.has_missing_links():
            base_score = 0.3
        else:
            base_score = 0.7
        
        # Average mechanism strength
        avg_strength = sum(m.strength for m in self.mechanisms) / len(self.mechanisms)
        
        # Combine: integrity requires both completeness and strength
        integrity = base_score * 0.4 + avg_strength * 0.6
        
        return min(1.0, max(0.0, integrity))


@dataclass
class CausalDepthResult:
    """Output from causal depth evaluation."""
    theory_id: str
    causal_depth: float                  # Overall causal depth score (0.0-1.0)
    spurious_risk: float                 # Risk of spurious correlation (0.0-1.0)
    intervention_stability: float        # Survival under manipulation (0.0-1.0)
    counterfactual_coherence: float      # Counterfactual validity (0.0-1.0)
    mechanistic_integrity: float         # Explanation quality (0.0-1.0)
    temporal_validity: float             # Cause-before-effect (0.0-1.0)
    explanatory_compression: float       # Complexity reduction (0.0-1.0)
    
    def to_dict(self) -> Dict:
        return {
            'theory_id': self.theory_id,
            'causal_depth': self.causal_depth,
            'spurious_risk': self.spurious_risk,
            'intervention_stability': self.intervention_stability,
            'counterfactual_coherence': self.counterfactual_coherence,
            'mechanistic_integrity': self.mechanistic_integrity,
            'temporal_validity': self.temporal_validity,
            'explanatory_compression': self.explanatory_compression
        }


class CausalDepthEngine:
    """
    Structural causal evaluator.
    
    Evaluates whether mechanisms exist, interventions survive,
    counterfactuals remain coherent, and explanations compress reality causally.
    
    Key principle: Prediction quality ≠ causal validity
    
    A theory can predict well yet explain poorly.
    Example: Ice cream sales correlate with drowning deaths (predictive: yes, causal: no)
    """
    
    def __init__(self):
        # Stores causal chains for each theory
        self.causal_chains: Dict[str, List[CausalChain]] = {}
        
        # Tracks intervention test results
        self.intervention_results: Dict[str, List[Dict]] = {}
        
        # Tracks counterfactual test results
        self.counterfactual_results: Dict[str, List[Dict]] = {}
    
    def register_causal_chain(self, theory_id: str, chain: CausalChain):
        """Register a causal chain for a theory."""
        if theory_id not in self.causal_chains:
            self.causal_chains[theory_id] = []
        
        self.causal_chains[theory_id].append(chain)
    
    def record_intervention_test(
        self,
        theory_id: str,
        mechanism_id: str,
        manipulated_variable: str,
        expected_outcome: str,
        actual_outcome: str,
        success: bool
    ):
        """
        Record an intervention test result.
        
        Tests whether changing cause A alters effect B.
        Critical for distinguishing causation from correlation.
        """
        if theory_id not in self.intervention_results:
            self.intervention_results[theory_id] = []
        
        self.intervention_results[theory_id].append({
            'mechanism_id': mechanism_id,
            'manipulated_variable': manipulated_variable,
            'expected_outcome': expected_outcome,
            'actual_outcome': actual_outcome,
            'success': success,
            'timestamp': time.time()
        })
        
        # Update mechanism intervention stats
        for chain in self.causal_chains.get(theory_id, []):
            for mechanism in chain.mechanisms:
                if mechanism.mechanism_id == mechanism_id:
                    mechanism.intervention_tests += 1
                    if success:
                        mechanism.intervention_successes += 1
    
    def record_counterfactual_test(
        self,
        theory_id: str,
        mechanism_id: str,
        scenario: str,
        coherent: bool
    ):
        """
        Record a counterfactual test result.
        
        Tests: If cause never happened, would effect still occur?
        Separates causality from coincidence.
        """
        if theory_id not in self.counterfactual_results:
            self.counterfactual_results[theory_id] = []
        
        self.counterfactual_results[theory_id].append({
            'mechanism_id': mechanism_id,
            'scenario': scenario,
            'coherent': coherent,
            'timestamp': time.time()
        })
        
        # Update mechanism counterfactual stats
        for chain in self.causal_chains.get(theory_id, []):
            for mechanism in chain.mechanisms:
                if mechanism.mechanism_id == mechanism_id:
                    mechanism.counterfactual_tests += 1
                    if coherent:
                        mechanism.counterfactual_coherent += 1
    
    def evaluate_causal_depth(self, theory_id: str) -> CausalDepthResult:
        """
        Evaluate overall causal depth for a theory.
        
        Formula (from fixes.md):
        causal_depth = (
            mechanistic_integrity * 0.25 +
            intervention_stability * 0.25 +
            counterfactual_coherence * 0.20 +
            temporal_validity * 0.15 +
            explanatory_compression * 0.10 -
            spurious_risk * 0.15
        )
        
        Note: Predictive accuracy is INTENTIONALLY absent.
        """
        chains = self.causal_chains.get(theory_id, [])
        
        if not chains:
            # No causal structure = no causal depth
            return CausalDepthResult(
                theory_id=theory_id,
                causal_depth=0.0,
                spurious_risk=1.0,
                intervention_stability=0.0,
                counterfactual_coherence=0.0,
                mechanistic_integrity=0.0,
                temporal_validity=0.0,
                explanatory_compression=0.0
            )
        
        # Calculate each dimension
        mechanistic_integrity = self._calculate_mechanistic_integrity(chains)
        intervention_stability = self._calculate_intervention_stability(theory_id)
        counterfactual_coherence = self._calculate_counterfactual_coherence(theory_id)
        temporal_validity = self._calculate_temporal_validity(chains)
        explanatory_compression = self._calculate_explanatory_compression(chains)
        spurious_risk = self._calculate_spurious_risk(chains)
        
        # Apply formula
        causal_depth = (
            mechanistic_integrity * 0.25 +
            intervention_stability * 0.25 +
            counterfactual_coherence * 0.20 +
            temporal_validity * 0.15 +
            explanatory_compression * 0.10 -
            spurious_risk * 0.15
        )
        
        # Clamp to [0.0, 1.0]
        causal_depth = max(0.0, min(1.0, causal_depth))
        
        return CausalDepthResult(
            theory_id=theory_id,
            causal_depth=causal_depth,
            spurious_risk=spurious_risk,
            intervention_stability=intervention_stability,
            counterfactual_coherence=counterfactual_coherence,
            mechanistic_integrity=mechanistic_integrity,
            temporal_validity=temporal_validity,
            explanatory_compression=explanatory_compression
        )
    
    def _calculate_mechanistic_integrity(self, chains: List[CausalChain]) -> float:
        """
        Question: Does the theory explain HOW?
        
        Not: Does it merely correlate?
        
        Checks: causal chain continuity, missing links, hidden jumps, impossible transitions
        """
        if not chains:
            return 0.0
        
        # Average integrity across all chains
        integrities = [chain.get_mechanistic_integrity() for chain in chains]
        return sum(integrities) / len(integrities)
    
    def _calculate_intervention_stability(self, theory_id: str) -> float:
        """
        Question: Does the theory survive active manipulation?
        
        If A causes B, then changing A should alter B.
        If not: causal confidence drops.
        
        This is one of the most important modules.
        """
        interventions = self.intervention_results.get(theory_id, [])
        
        if not interventions:
            return 0.5  # Neutral if untested
        
        successes = sum(1 for test in interventions if test['success'])
        return successes / len(interventions)
    
    def _calculate_counterfactual_coherence(self, theory_id: str) -> float:
        """
        Question: If the cause never happened, would the effect still occur?
        
        This separates causality from coincidence.
        """
        tests = self.counterfactual_results.get(theory_id, [])
        
        if not tests:
            return 0.5  # Neutral if untested
        
        coherences = sum(1 for test in tests if test['coherent'])
        return coherences / len(tests)
    
    def _calculate_temporal_validity(self, chains: List[CausalChain]) -> float:
        """
        Question: Did the proposed cause occur before the effect?
        
        Simple. Critical. Many systems fail this implicitly.
        """
        if not chains:
            return 0.0
        
        valid_count = sum(1 for chain in chains if chain.temporal_valid)
        return valid_count / len(chains)
    
    def _calculate_explanatory_compression(self, chains: List[CausalChain]) -> float:
        """
        Question: Does the theory reduce complexity without losing predictive fidelity?
        
        Good causal theories compress reality elegantly.
        Bad ones memorize observations.
        
        This is where Tiannara starts becoming scientific instead of statistical.
        """
        if not chains:
            return 0.0
        
        # Average compression ratio across chains
        # Higher compression ratio = better explanation
        avg_compression = sum(chain.compression_ratio for chain in chains) / len(chains)
        
        # Normalize: compression_ratio of 1.0 = neutral, >1.0 = good, <1.0 = bad
        # Map to 0.0-1.0 scale
        if avg_compression >= 1.0:
            # Good compression: map [1.0, 2.0+] to [0.5, 1.0]
            return min(1.0, 0.5 + (avg_compression - 1.0) * 0.5)
        else:
            # Poor compression: map [0.0, 1.0) to [0.0, 0.5)
            return avg_compression * 0.5
    
    def _calculate_spurious_risk(self, chains: List[CausalChain]) -> float:
        """
        Question: Could both variables be caused by hidden factor C?
        
        This should actively penalize shallow pattern exploitation.
        """
        if not chains:
            return 1.0  # Maximum risk if no causal structure
        
        # Count spurious links
        spurious_count = 0
        total_links = 0
        
        for chain in chains:
            for mechanism in chain.mechanisms:
                total_links += 1
                if mechanism.link_type == CausalLinkType.SPURIOUS:
                    spurious_count += 1
        
        if total_links == 0:
            return 1.0  # Maximum risk if no mechanisms
        
        # Risk proportion
        spurious_proportion = spurious_count / total_links
        
        # Also consider weak mechanisms as potential spurious correlations
        weak_mechanisms = sum(
            1 for chain in chains
            for mechanism in chain.mechanisms
            if mechanism.strength < 0.3
        )
        
        weak_proportion = weak_mechanisms / total_links if total_links > 0 else 0.0
        
        # Combined risk: explicit spurious + weak mechanisms
        risk = spurious_proportion * 0.6 + weak_proportion * 0.4
        
        return min(1.0, risk)
    
    def detect_spurious_correlation(self, theory_id: str) -> List[Dict]:
        """
        Detect potential spurious correlations in a theory.
        
        Returns list of suspicious patterns that may indicate:
        - Both variables caused by hidden factor C
        - Shallow pattern exploitation
        - Statistical convenience over causal legitimacy
        """
        suspicious = []
        
        for chain in self.causal_chains.get(theory_id, []):
            for mechanism in chain.mechanisms:
                issues = []
                
                # Check for weak causal strength
                if mechanism.strength < 0.3:
                    issues.append("Weak causal strength")
                
                # Check for low intervention stability
                if mechanism.intervention_tests > 0:
                    stability = mechanism.get_intervention_stability()
                    if stability < 0.5:
                        issues.append(f"Low intervention stability ({stability:.2f})")
                
                # Check for poor counterfactual coherence
                if mechanism.counterfactual_tests > 0:
                    coherence = mechanism.get_counterfactual_coherence()
                    if coherence < 0.5:
                        issues.append(f"Poor counterfactual coherence ({coherence:.2f})")
                
                if issues:
                    suspicious.append({
                        'mechanism_id': mechanism.mechanism_id,
                        'link_type': mechanism.link_type.value,
                        'strength': mechanism.strength,
                        'issues': issues
                    })
        
        return suspicious


def combine_theory_score(
    predictive_score: float,
    causal_depth_result: CausalDepthResult,
    epistemic_resilience: float
) -> float:
    """
    Combine multiple dimensions into final theory score.
    
    From fixes.md:
    final_theory_score = (
        predictive_score * 0.45 +
        causal_depth * 0.40 +
        epistemic_resilience * 0.15
    )
    
    Now Tiannara balances:
    - utility (prediction),
    - explanation (causal depth),
    - robustness (epistemic resilience).
    
    That's far more advanced than standard AI architectures.
    """
    final_score = (
        predictive_score * 0.45 +
        causal_depth_result.causal_depth * 0.40 +
        epistemic_resilience * 0.15
    )
    
    return max(0.0, min(1.0, final_score))


if __name__ == "__main__":
    """Test the Causal Depth Engine."""
    print("="*80)
    print("CAUSAL DEPTH ENGINE - TEST")
    print("="*80)
    
    engine = CausalDepthEngine()
    
    # Test 1: Theory with strong causal structure
    print("\nTest 1: Strong Causal Theory")
    chain1 = CausalChain(
        chain_id="chain_1",
        cause="temperature",
        effect="ice_cream_sales",
        mechanisms=[
            CausalMechanism(
                mechanism_id="mech_1",
                description="Higher temperature increases desire for cold treats",
                link_type=CausalLinkType.DIRECT,
                strength=0.9,
                intervention_tests=10,
                intervention_successes=9,
                counterfactual_tests=5,
                counterfactual_coherent=5
            )
        ],
        temporal_valid=True,
        compression_ratio=1.5
    )
    engine.register_causal_chain("strong_causal_theory", chain1)
    
    result1 = engine.evaluate_causal_depth("strong_causal_theory")
    print(f"  Causal Depth: {result1.causal_depth:.3f}")
    print(f"  Mechanistic Integrity: {result1.mechanistic_integrity:.3f}")
    print(f"  Intervention Stability: {result1.intervention_stability:.3f}")
    print(f"  Spurious Risk: {result1.spurious_risk:.3f}")
    
    # Test 2: Theory with spurious correlation
    print("\nTest 2: Spurious Correlation (Ice Cream → Drowning)")
    chain2 = CausalChain(
        chain_id="chain_2",
        cause="ice_cream_sales",
        effect="drowning_deaths",
        mechanisms=[
            CausalMechanism(
                mechanism_id="mech_2",
                description="Unknown mechanism (likely spurious)",
                link_type=CausalLinkType.SPURIOUS,
                strength=0.2,  # Weak
                intervention_tests=5,
                intervention_successes=1,  # Low stability
                counterfactual_tests=3,
                counterfactual_coherent=0  # Poor coherence
            )
        ],
        temporal_valid=True,
        compression_ratio=0.8  # Poor compression
    )
    engine.register_causal_chain("spurious_theory", chain2)
    
    result2 = engine.evaluate_causal_depth("spurious_theory")
    print(f"  Causal Depth: {result2.causal_depth:.3f}")
    print(f"  Mechanistic Integrity: {result2.mechanistic_integrity:.3f}")
    print(f"  Intervention Stability: {result2.intervention_stability:.3f}")
    print(f"  Spurious Risk: {result2.spurious_risk:.3f}")
    
    # Detect spurious correlations
    suspicious = engine.detect_spurious_correlation("spurious_theory")
    print(f"\n  Detected {len(suspicious)} suspicious patterns:")
    for s in suspicious:
        print(f"    - {s['mechanism_id']}: {', '.join(s['issues'])}")
    
    # Test 3: Compare scores
    print("\nTest 3: Final Theory Score Comparison")
    strong_final = combine_theory_score(
        predictive_score=0.85,
        causal_depth_result=result1,
        epistemic_resilience=0.80
    )
    
    spurious_final = combine_theory_score(
        predictive_score=0.90,  # Higher prediction!
        causal_depth_result=result2,
        epistemic_resilience=0.70
    )
    
    print(f"  Strong Causal Theory: {strong_final:.3f}")
    print(f"  Spurious Theory: {spurious_final:.3f}")
    print(f"\n  Despite higher prediction (0.90 vs 0.85),")
    print(f"  spurious theory scores LOWER due to poor causal depth.")
    print(f"  This prevents shortcut intelligence!")
    
    print("\n" + "="*80)
    print("✅ CAUSAL DEPTH ENGINE TEST COMPLETE")
    print("="*80)
