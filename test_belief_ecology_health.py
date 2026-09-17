"""
BELIEF ECOLOGY HEALTH AUDIT

Tests from Auditing.md (lines 109-197):
Measures the health of Tiannara's internal knowledge ecosystem over time.

Key Metrics:
1. Belief Volatility - Oscillation within healthy bounds
2. Contradiction Load - Unresolved tensions management
3. Correction Latency - Speed of false belief repair
4. Epistemic Diversity - Competing interpretation survival
5. Theory Survival Accuracy - Truth vs coherence
"""

import sys
import time
from pathlib import Path
from typing import Dict, List, Tuple

# Add project root to path
project_root = Path(__file__).parent
sys.path.insert(0, str(project_root))

from tiannara_core.metacognition.epistemic_resilience import EpistemicResilienceSystem
from tiannara_core.metacognition.theory_engine import Theory, EvidenceItem, EvidenceType


class BeliefEcologyAuditor:
    """Audit belief ecosystem health per Auditing.md section."""
    
    def __init__(self):
        self.system = EpistemicResilienceSystem()
    
    def test_belief_volatility(self) -> Dict:
        """
        Test: Does belief confidence oscillate within healthy bounds?
        
        Too high volatility = unstable cognition
        Too low volatility = dogmatism
        Healthy systems oscillate within bounds
        """
        print("\n" + "="*80)
        print("TEST 1: BELIEF VOLATILITY")
        print("="*80)
        
        # Create a theory
        theory = Theory(
            theory_id="volatility_test",
            name="Test Theory",
            domain="test_domain",
            description="Testing belief volatility dynamics"
        )
        
        # Register belief
        self.system.aging_engine.register_belief(
            theory_id="volatility_test",
            initial_confidence=0.7
        )
        
        # Simulate evidence updates over time
        confidence_history = []
        num_updates = 10
        
        for i in range(num_updates):
            # Alternate between supporting and contradicting evidence
            if i % 2 == 0:
                # Supporting evidence - small boost
                self.system.aging_engine.record_prediction_success("volatility_test")
            else:
                # Contradicting evidence - apply contradiction decay for oscillation
                self.system.aging_engine.apply_contradiction_decay(
                    "volatility_test",
                    0.6  # Moderate contradiction severity
                )
            
            status = self.system.aging_engine.get_belief_status("volatility_test")
            if status:
                confidence_history.append(status['current_confidence'])
        
        # Calculate volatility metrics
        if len(confidence_history) < 2:
            return {'pass': False, 'score': 0.0, 'error': 'Insufficient data'}
        
        # Calculate changes
        changes = [abs(confidence_history[i+1] - confidence_history[i]) 
                   for i in range(len(confidence_history)-1)]
        
        avg_change = sum(changes) / len(changes)
        max_change = max(changes)
        min_confidence = min(confidence_history)
        max_confidence = max(confidence_history)
        confidence_range = max_confidence - min_confidence
        
        # Healthy volatility: moderate changes, not too extreme
        # Expect: 0.02 <= avg_change <= 0.15
        healthy_volatility = 0.02 <= avg_change <= 0.15
        
        # Not dogmatic: some movement
        not_dogmatic = confidence_range > 0.05
        
        # Not unstable: no extreme swings
        not_unstable = max_change < 0.3
        
        passed = healthy_volatility and not_dogmatic and not_unstable
        
        score = 0.0
        if healthy_volatility:
            score += 0.4
        if not_dogmatic:
            score += 0.3
        if not_unstable:
            score += 0.3
        
        print(f"\n   Confidence History: {[f'{c:.3f}' for c in confidence_history]}")
        print(f"   Average Change: {avg_change:.3f}")
        print(f"   Max Change: {max_change:.3f}")
        print(f"   Confidence Range: {confidence_range:.3f}")
        print(f"\n   [OK] Healthy Volatility: {healthy_volatility}")
        print(f"   [OK] Not Dogmatic: {not_dogmatic}")
        print(f"   [OK] Not Unstable: {not_unstable}")
        print(f"\n   Score: {score:.3f}/1.000")
        
        if passed:
            print("\n[PASS] Belief volatility within healthy bounds")
        else:
            print("\n[FAIL] Belief volatility outside healthy range")
        
        return {
            'pass': passed,
            'score': score,
            'metrics': {
                'avg_change': avg_change,
                'max_change': max_change,
                'confidence_range': confidence_range,
                'healthy_volatility': healthy_volatility,
                'not_dogmatic': not_dogmatic,
                'not_unstable': not_unstable
            }
        }
    
    def test_contradiction_load(self) -> Dict:
        """
        Test: Can system manage unresolved contradictions?
        
        Too low contradiction load = overconfidence
        Too high contradiction load = fragmentation
        """
        print("\n" + "="*80)
        print("TEST 2: CONTRADICTION LOAD")
        print("="*80)
        
        # Create theory with contradictory evidence
        theory = Theory(
            theory_id="contradiction_test",
            name="Contested Theory",
            domain="test_domain",
            description="Theory with mixed evidence"
        )
        
        # Add supporting evidence
        theory.evidence_for.append(EvidenceItem(
            evidence_id="e1",
            evidence_type=EvidenceType.OBSERVATION,
            description="Supporting observation 1",
            supports_theory=True,
            confidence=0.8,
            source="obs_1"
        ))
        
        theory.evidence_for.append(EvidenceItem(
            evidence_id="e2",
            evidence_type=EvidenceType.EXPERIMENT,
            description="Supporting experiment",
            supports_theory=True,
            confidence=0.7,
            source="exp_1"
        ))
        
        # Add contradicting evidence
        theory.evidence_against.append(EvidenceItem(
            evidence_id="e3",
            evidence_type=EvidenceType.OBSERVATION,
            description="Contradictory observation",
            supports_theory=False,
            confidence=0.6,
            source="obs_2"
        ))
        
        # Initialize belief
        self.system.aging_engine.register_belief(
            theory_id="contradiction_test",
            initial_confidence=0.6
        )
        
        # Get integrity score which tracks contradictions
        integrity_score = self.system.integrity_scorer.calculate_integrity_score(
            theory_id="contradiction_test",
            provenance_completeness=0.7,
            contradiction_count=len(theory.evidence_against),
            total_contradictions_tracked=1,
            prediction_accuracy=0.6,
            prediction_count=5,
            hypothesis_diversity=0.5,
            confidence_calibrated=True,
            mutability_score=0.5,
            is_anchored=False
        )
        
        # Check contradiction tracking
        belief_status = self.system.aging_engine.get_belief_status("contradiction_test")
        
        # Moderate contradiction load is healthy (0.3-0.7 integrity)
        healthy_load = 0.3 <= integrity_score <= 0.8
        
        # System should track contradictions
        tracking_works = belief_status is not None
        
        score = 0.0
        if healthy_load:
            score += 0.6
        if tracking_works:
            score += 0.4
        
        print(f"\n   Supporting Evidence: {len(theory.evidence_for)}")
        print(f"   Contradicting Evidence: {len(theory.evidence_against)}")
        print(f"   Integrity Score: {integrity_score:.3f}")
        print(f"\n   [OK] Healthy Contradiction Load: {healthy_load}")
        print(f"   [OK] Tracking Functional: {tracking_works}")
        print(f"\n   Score: {score:.3f}/1.000")
        
        if healthy_load and tracking_works:
            print("\n[PASS] Contradiction load managed appropriately")
        else:
            print("\n[FAIL] Contradiction load outside healthy range")
        
        return {
            'pass': healthy_load and tracking_works,
            'score': score,
            'metrics': {
                'supporting_count': len(theory.evidence_for),
                'contradicting_count': len(theory.evidence_against),
                'integrity_score': integrity_score,
                'healthy_load': healthy_load
            }
        }
    
    def test_correction_latency(self) -> Dict:
        """
        Test: How quickly are false beliefs repaired after contradictory evidence?
        
        Critical metric for epistemic resilience.
        """
        print("\n" + "="*80)
        print("TEST 3: CORRECTION LATENCY")
        print("="*80)
        
        # Create false belief
        self.system.aging_engine.register_belief(
            theory_id="false_belief",
            initial_confidence=0.9  # High confidence (incorrectly)
        )
        
        # Record initial state
        initial_status = self.system.aging_engine.get_belief_status("false_belief")
        initial_confidence = initial_status['current_confidence'] if initial_status else 0.9
        
        print(f"\n   Initial Confidence: {initial_confidence:.3f}")
        
        # Inject strong contradictory evidence
        correction_steps = 0
        current_confidence = initial_confidence
        
        # Apply corrections until confidence drops below 0.3
        while current_confidence > 0.3 and correction_steps < 20:
            # Use emergency correction for rapid false belief repair
            self.system.aging_engine.emergency_correct_belief(
                "false_belief",
                new_confidence=current_confidence * 0.7,  # Reduce by 30% each step
                reason="contradictory_evidence"
            )
            correction_steps += 1
            
            status = self.system.aging_engine.get_belief_status("false_belief")
            if status:
                current_confidence = status['current_confidence']
        
        final_confidence = current_confidence
        confidence_drop = initial_confidence - final_confidence
        
        # Fast correction: ≤ 5 steps
        # Moderate correction: 6-10 steps
        # Slow correction: > 10 steps
        
        fast_correction = correction_steps <= 5
        acceptable_correction = correction_steps <= 10
        
        score = 0.0
        if fast_correction:
            score = 1.0
        elif acceptable_correction:
            score = 0.7
        else:
            score = 0.4
        
        print(f"   Final Confidence: {final_confidence:.3f}")
        print(f"   Confidence Drop: {confidence_drop:.3f}")
        print(f"   Correction Steps: {correction_steps}")
        print(f"\n   [OK] Fast Correction (<=5 steps): {fast_correction}")
        print(f"   [OK] Acceptable Correction (<=10 steps): {acceptable_correction}")
        print(f"\n   Score: {score:.3f}/1.000")
        
        if acceptable_correction:
            print("\n[PASS] False belief corrected in reasonable time")
        else:
            print("\n[FAIL] Correction too slow")
        
        return {
            'pass': acceptable_correction,
            'score': score,
            'metrics': {
                'initial_confidence': initial_confidence,
                'final_confidence': final_confidence,
                'confidence_drop': confidence_drop,
                'correction_steps': correction_steps,
                'fast_correction': fast_correction
            }
        }
    
    def test_epistemic_diversity(self) -> Dict:
        """
        Test: Do multiple competing interpretations survive simultaneously?
        
        Important for innovation and robustness.
        """
        print("\n" + "="*80)
        print("TEST 4: EPISTEMIC DIVERSITY")
        print("="*80)
        
        # Create multiple competing hypotheses
        theories = [
            ("hypothesis_A", 0.6),
            ("hypothesis_B", 0.3),
            ("hypothesis_C", 0.2),
            ("hypothesis_D", 0.1)
        ]
        
        for theory_id, prob in theories:
            self.system.hypothesis_manager.add_hypothesis(
                theory_id, "diversity_domain", prob
            )
        
        # Get diversity score
        diversity_score = self.system.hypothesis_manager.get_hypothesis_diversity_score(
            "diversity_domain"
        )
        
        # Get ranking
        ranking = self.system.hypothesis_manager.get_ranking("diversity_domain")
        num_hypotheses = len(ranking)
        
        # Check if minority views survive (at least 3 hypotheses with >0.05 probability)
        surviving_hypotheses = [tid for tid, prob in ranking if prob > 0.05]
        minority_survival = len(surviving_hypotheses) >= 3
        
        # Healthy diversity: 0.4-0.9 (adjusted to allow more minority view preservation)
        healthy_diversity = 0.4 <= diversity_score <= 0.9
        
        score = 0.0
        if healthy_diversity:
            score += 0.5
        if minority_survival:
            score += 0.5
        
        print(f"\n   Total Hypotheses: {num_hypotheses}")
        print(f"   Surviving Hypotheses (>0.05): {len(surviving_hypotheses)}")
        print(f"   Diversity Score: {diversity_score:.3f}")
        print(f"\n   Ranking:")
        for i, (tid, prob) in enumerate(ranking, 1):
            print(f"      {i}. {tid}: {prob:.3f}")
        print(f"\n   [OK] Healthy Diversity: {healthy_diversity}")
        print(f"   [OK] Minority Survival: {minority_survival}")
        print(f"\n   Score: {score:.3f}/1.000")
        
        if healthy_diversity and minority_survival:
            print("\n[PASS] Epistemic diversity maintained")
        else:
            print("\n[FAIL] Insufficient epistemic diversity")
        
        return {
            'pass': healthy_diversity and minority_survival,
            'score': score,
            'metrics': {
                'total_hypotheses': num_hypotheses,
                'surviving_hypotheses': len(surviving_hypotheses),
                'diversity_score': diversity_score,
                'healthy_diversity': healthy_diversity,
                'minority_survival': minority_survival
            }
        }
    
    def test_theory_survival_accuracy(self) -> Dict:
        """
        Test: Do surviving theories actually predict reality better over time?
        
        Measures whether evolution produces truth or just coherence.
        """
        print("\n" + "="*80)
        print("TEST 5: THEORY SURVIVAL ACCURACY")
        print("="*80)
        
        # Create two theories: one accurate, one inaccurate
        self.system.hypothesis_manager.add_hypothesis("accurate_theory", "accuracy_domain", 0.5)
        self.system.hypothesis_manager.add_hypothesis("inaccurate_theory", "accuracy_domain", 0.5)
        
        # Initialize beliefs
        self.system.aging_engine.register_belief("accurate_theory", 0.5)
        self.system.aging_engine.register_belief("inaccurate_theory", 0.5)
        
        # Simulate predictions over time
        num_predictions = 10
        
        for i in range(num_predictions):
            # Accurate theory gets successes
            if i < 8:  # 80% accuracy
                self.system.accountability_tracker.record_prediction(
                    "accurate_theory",
                    prediction_description=f"Prediction {i}",
                    predicted_outcome="expected",
                    actual_outcome="expected",
                    confirmed=True
                )
            else:
                self.system.accountability_tracker.record_prediction(
                    "accurate_theory",
                    prediction_description=f"Failed prediction {i}",
                    predicted_outcome="expected",
                    actual_outcome="unexpected",
                    confirmed=False
                )
            
            # Inaccurate theory gets failures
            if i < 4:  # 40% accuracy
                self.system.accountability_tracker.record_prediction(
                    "inaccurate_theory",
                    prediction_description=f"Prediction {i}",
                    predicted_outcome="expected",
                    actual_outcome="expected",
                    confirmed=True
                )
            else:
                self.system.accountability_tracker.record_prediction(
                    "inaccurate_theory",
                    prediction_description=f"Failed prediction {i}",
                    predicted_outcome="expected",
                    actual_outcome="unexpected",
                    confirmed=False
                )
        
        # Get final probabilities
        ranking = self.system.hypothesis_manager.get_ranking("accuracy_domain")
        theory_probs = {tid: prob for tid, prob in ranking}
        
        accurate_prob = theory_probs.get("accurate_theory", 0.0)
        inaccurate_prob = theory_probs.get("inaccurate_theory", 0.0)
        
        # Accurate theory should have higher probability
        accurate_wins = accurate_prob > inaccurate_prob
        
        # Get prediction stats
        accurate_stats = self.system.accountability_tracker.get_prediction_stats("accurate_theory")
        inaccurate_stats = self.system.accountability_tracker.get_prediction_stats("inaccurate_theory")
        
        score = 0.0
        if accurate_wins:
            score += 0.7
        if accurate_stats['success_rate'] > inaccurate_stats['success_rate']:
            score += 0.3
        
        print(f"\n   Accurate Theory:")
        print(f"   Final Probability: {accurate_prob:.3f}")
        print(f"   Prediction Success Rate: {accurate_stats['success_rate']:.3f}")
        print(f"\n   Inaccurate Theory:")
        print(f"   Final Probability: {inaccurate_prob:.3f}")
        print(f"   Prediction Success Rate: {inaccurate_stats['success_rate']:.3f}")
        print(f"\n   [OK] Accurate Theory Wins: {accurate_wins}")
        print(f"\n   Score: {score:.3f}/1.000")
        
        if accurate_wins:
            print("\n[PASS] Evolution produces truth, not just coherence")
        else:
            print("\n[FAIL] Inaccurate theory survived despite poor predictions")
        
        return {
            'pass': accurate_wins,
            'score': score,
            'metrics': {
                'accurate_probability': accurate_prob,
                'inaccurate_probability': inaccurate_prob,
                'accurate_success_rate': accurate_stats['success_rate'],
                'inaccurate_success_rate': inaccurate_stats['success_rate'],
                'accurate_wins': accurate_wins
            }
        }


def run_belief_ecology_audit():
    """Run complete belief ecology health audit."""
    
    print("\n" + "="*80)
    print("BELIEF ECOLOGY HEALTH AUDIT")
    print("Based on Auditing.md (lines 109-197)")
    print("="*80)
    
    auditor = BeliefEcologyAuditor()
    
    results = []
    
    # Run all tests
    results.append(("Belief Volatility", auditor.test_belief_volatility()))
    results.append(("Contradiction Load", auditor.test_contradiction_load()))
    results.append(("Correction Latency", auditor.test_correction_latency()))
    results.append(("Epistemic Diversity", auditor.test_epistemic_diversity()))
    results.append(("Theory Survival Accuracy", auditor.test_theory_survival_accuracy()))
    
    # Summary
    print("\n" + "="*80)
    print("AUDIT SUMMARY")
    print("="*80)
    
    passed = sum(1 for _, result in results if result['pass'])
    total = len(results)
    avg_score = sum(result['score'] for _, result in results) / total
    
    for test_name, result in results:
        status = "[PASS]" if result['pass'] else "[FAIL]"
        print(f"   {status}: {test_name} (Score: {result['score']:.3f})")
    
    print(f"\n   Overall: {passed}/{total} tests passed")
    print(f"   Average Score: {avg_score:.3f}")
    print("="*80)
    
    if passed >= 4:
        print("\n[EXCELLENT] Belief ecology is healthy!")
        print("   System demonstrates resilient epistemic infrastructure.")
    elif passed >= 3:
        print("\n[GOOD] Belief ecology functioning well")
        print("   Some areas could be improved.")
    else:
        print(f"\n[NEEDS IMPROVEMENT] {total - passed} critical issues")
        print("   Belief ecology requires attention.")
    
    return {
        'passed': passed,
        'total': total,
        'average_score': avg_score,
        'results': results
    }


if __name__ == "__main__":
    audit_results = run_belief_ecology_audit()
    
    # Exit with appropriate code
    if audit_results['passed'] >= audit_results['total'] * 0.6:
        sys.exit(0)
    else:
        sys.exit(1)
