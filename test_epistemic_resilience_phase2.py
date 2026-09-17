"""
EPISTEMIC RESILIENCE SYSTEM - PHASE 2 TESTS

Tests the three critical Phase 2 systems:
1. Reality Anchor Layer - Immutable grounding constraints
2. Epistemic Integrity Scorer - Composite trustworthiness metric
3. Adversarial Red Team Agent - Permanent disproof agent

Based on strategic analysis from ADVERSARIAL_DEBATE_TEST_COMPLETE.md (lines 387-788)
"""

import sys
import time
from pathlib import Path

# Add project root to path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.metacognition.epistemic_resilience import (
    RealityAnchorLayer,
    EpistemicIntegrityScorer,
    AdversarialRedTeamAgent,
    EpistemicResilienceSystem
)
from tiannara_core.metacognition.theory_engine import Theory, CausalClaim, EvidenceItem, EvidenceType, Prediction


def test_reality_anchor_layer():
    """Test Reality Anchor Layer system."""
    print("\n" + "="*80)
    print("TEST 1: REALITY ANCHOR LAYER")
    print("="*80 + "\n")
    
    anchor_layer = RealityAnchorLayer()
    
    # Test 1: Classify different belief types
    print("Classifying beliefs by mutability level...")
    
    anchor_layer.classify_belief("theory_observed_fact", "observed_fact", evidence_strength=0.95)
    anchor_layer.classify_belief("theory_interpretation", "interpretation", evidence_strength=0.7)
    anchor_layer.classify_belief("theory_speculative", "speculative_theory", evidence_strength=0.5)
    anchor_layer.classify_belief("theory_emotional", "emotional_inference", evidence_strength=0.3)
    
    print("✅ Classified 4 belief types")
    
    # Test 2: Check mutability scores
    print("\nMutability scores:")
    observed_mutability = anchor_layer.get_mutability_score("theory_observed_fact")
    interpretation_mutability = anchor_layer.get_mutability_score("theory_interpretation")
    speculative_mutability = anchor_layer.get_mutability_score("theory_speculative")
    emotional_mutability = anchor_layer.get_mutability_score("theory_emotional")
    
    print(f"  Observed Fact: {observed_mutability:.2f} (should be ~0.1)")
    print(f"  Interpretation: {interpretation_mutability:.2f} (should be ~0.4)")
    print(f"  Speculative Theory: {speculative_mutability:.2f} (should be ~0.8)")
    print(f"  Emotional Inference: {emotional_mutability:.2f} (should be ~1.0)")
    
    assert observed_mutability == 0.1, f"Expected 0.1, got {observed_mutability}"
    assert interpretation_mutability == 0.4, f"Expected 0.4, got {interpretation_mutability}"
    assert speculative_mutability == 0.8, f"Expected 0.8, got {speculative_mutability}"
    assert emotional_mutability == 1.0, f"Expected 1.0, got {emotional_mutability}"
    
    print("✅ All mutability scores correct")
    
    # Test 3: Test modification restrictions
    print("\nTesting modification restrictions...")
    
    # Observed facts should be hard to change
    can_modify, reason = anchor_layer.can_modify_belief("theory_observed_fact", new_confidence=0.2)
    print(f"  Reduce observed fact to 0.2: {can_modify} - {reason}")
    assert not can_modify, "Should not allow reducing observed fact below 0.3"
    
    # Observed facts with moderate reduction should be allowed
    can_modify, reason = anchor_layer.can_modify_belief("theory_observed_fact", new_confidence=0.5)
    print(f"  Reduce observed fact to 0.5: {can_modify} - {reason}")
    assert can_modify, "Should allow moderate reduction of observed fact"
    
    # Speculative theories should be easy to change
    can_modify, reason = anchor_layer.can_modify_belief("theory_speculative", new_confidence=0.1)
    print(f"  Reduce speculative theory to 0.1: {can_modify} - {reason}")
    assert can_modify, "Should allow changing speculative theory"
    
    print("✅ Modification restrictions working correctly")
    
    # Test 4: Check anchor status
    print("\nChecking anchor status...")
    anchor_status = anchor_layer.get_anchor_status("theory_observed_fact")
    assert anchor_status is not None, "Observed fact should have anchor"
    assert anchor_status['type'] == 'observed_fact'
    assert anchor_status['locked'] == True
    print(f"  Anchor type: {anchor_status['type']}")
    print(f"  Locked: {anchor_status['locked']}")
    print(f"  Evidence strength: {anchor_status['evidence_strength']}")
    print(f"  Modification attempts: {anchor_status['modification_attempts']}")
    
    print("✅ Anchor status tracking working")
    
    print("\n" + "-"*80)
    print("REALITY ANCHOR LAYER TEST: PASSED ✅")
    print("-"*80)
    
    return True


def test_epistemic_integrity_scorer():
    """Test Epistemic Integrity Scorer system."""
    print("\n" + "="*80)
    print("TEST 2: EPISTEMIC INTEGRITY SCORER")
    print("="*80 + "\n")
    
    scorer = EpistemicIntegrityScorer()
    
    # Test 1: Calculate integrity score with excellent metrics
    print("Calculating integrity score for high-quality theory...")
    
    score_excellent = scorer.calculate_integrity_score(
        theory_id="theory_excellent",
        provenance_completeness=0.95,
        contradiction_count=2,
        total_contradictions_tracked=10,
        prediction_accuracy=0.9,
        prediction_count=10,
        hypothesis_diversity=0.85,
        confidence_calibrated=True,
        mutability_score=0.4,
        is_anchored=True
    )
    
    print(f"  Excellent theory integrity score: {score_excellent:.3f}")
    assert score_excellent >= 0.7, f"Expected >= 0.7, got {score_excellent}"
    print("✅ High-quality theory scored appropriately")
    
    # Test 2: Calculate integrity score with poor metrics
    print("\nCalculating integrity score for low-quality theory...")
    
    score_poor = scorer.calculate_integrity_score(
        theory_id="theory_poor",
        provenance_completeness=0.2,
        contradiction_count=0,
        total_contradictions_tracked=0,
        prediction_accuracy=0.3,
        prediction_count=1,
        hypothesis_diversity=0.1,
        confidence_calibrated=False,
        mutability_score=1.0,
        is_anchored=False
    )
    
    print(f"  Poor theory integrity score: {score_poor:.3f}")
    assert score_poor < 0.5, f"Expected < 0.5, got {score_poor}"
    print("✅ Low-quality theory scored appropriately")
    
    # Test 3: Verify score difference
    print(f"\nScore difference: {score_excellent - score_poor:.3f}")
    assert score_excellent > score_poor, "Excellent theory should score higher than poor theory"
    print("✅ Score differentiation working correctly")
    
    # Test 4: Track integrity trend
    print("\nTracking integrity trends...")
    
    # Simulate multiple measurements showing improvement
    base_time = time.time()
    improving_scores = []
    for i in range(5):
        score = 0.5 + (i * 0.1)  # Improving scores: 0.5, 0.6, 0.7, 0.8, 0.9
        improving_scores.append((base_time + i*3600, score))
    
    scorer.integrity_history["theory_trending"] = improving_scores
    
    trend = scorer.get_integrity_trend("theory_trending")
    print(f"  Trend for improving theory: {trend}")
    assert trend == 'improving', f"Expected 'improving', got '{trend}'"
    print("✅ Trend detection working")
    
    # Test 5: Get integrity report
    print("\nGenerating integrity report...")
    report = scorer.get_integrity_report("theory_excellent")
    assert report is not None
    print(f"  Current score: {report['current_integrity_score']:.3f}")
    print(f"  Integrity level: {report['integrity_level']}")
    print(f"  Measurement count: {report['measurement_count']}")
    print(f"  Trend: {report['trend']}")
    print("✅ Integrity report generation working")
    
    print("\n" + "-"*80)
    print("EPISTEMIC INTEGRITY SCORER TEST: PASSED ✅")
    print("-"*80)
    
    return True


def test_adversarial_red_team_agent():
    """Test Adversarial Red Team Agent system."""
    print("\n" + "="*80)
    print("TEST 3: ADVERSARIAL RED TEAM AGENT")
    print("="*80 + "\n")
    
    red_team = AdversarialRedTeamAgent(agent_id="red_team_alpha")
    
    # Test 1: Attack assumptions
    print("Attacking theory assumptions...")
    
    attack_result = red_team.attack_assumption(
        theory_id="theory_solar",
        assumption="Technology will continue improving at current rate"
    )
    
    print(f"  Attack ID: {attack_result['attack_id']}")
    print(f"  Weakness score: {attack_result['weakness_score']:.3f}")
    print(f"  Successful: {attack_result['successful']}")
    print("✅ Assumption attack executed")
    
    # Test 2: Challenge evidence quality
    print("\nChallenging evidence quality...")
    
    # Create weak evidence
    weak_evidence = EvidenceItem(
        evidence_id="weak_evid",
        evidence_type=EvidenceType.EXPERT_CONSENSUS,
        description="Anonymous expert opinion",
        supports_theory=True,
        confidence=0.98,  # Suspiciously high
        source="Anonymous Source"  # Unverifiable
    )
    
    challenge_result = red_team.challenge_evidence("theory_solar", weak_evidence)
    print(f"  Challenge ID: {challenge_result['challenge_id']}")
    print(f"  Weaknesses found: {len(challenge_result['weaknesses_found'])}")
    for weakness in challenge_result['weaknesses_found']:
        print(f"    - {weakness}")
    print(f"  Successful: {challenge_result['successful']}")
    
    assert len(challenge_result['weaknesses_found']) > 0, "Should find weaknesses in poor evidence"
    print("✅ Evidence challenge working")
    
    # Test 3: Test prediction accuracy
    print("\nTesting prediction accuracy...")
    
    failed_prediction = Prediction(
        prediction_id="pred_fail",
        description="Solar efficiency will reach 35% by 2025",
        conditions={"year": 2025},
        predicted_outcome="35% efficiency achieved",
        confidence=0.8
    )
    
    test_result = red_team.test_prediction(
        theory_id="theory_solar",
        prediction=failed_prediction,
        actual_outcome="28% efficiency achieved"
    )
    
    print(f"  Test ID: {test_result['test_id']}")
    print(f"  Prediction failed: {test_result['prediction_failed']}")
    print(f"  Successful disproof: {test_result['successful']}")
    
    assert test_result['prediction_failed'], "Prediction should fail when outcome doesn't match"
    print("✅ Prediction testing working")
    
    # Test 4: Get attack statistics
    print("\nGetting attack statistics...")
    stats = red_team.get_attack_statistics()
    print(f"  Total attacks: {stats['total_attacks']}")
    print(f"  Successful disproofs: {stats['successful_disproofs']}")
    print(f"  Success rate: {stats['success_rate']:.2%}")
    print(f"  Recent attacks logged: {len(stats['recent_attacks'])}")
    
    assert stats['total_attacks'] == 3, f"Expected 3 attacks, got {stats['total_attacks']}"
    print("✅ Attack statistics tracking working")
    
    print("\n" + "-"*80)
    print("ADVERSARIAL RED TEAM AGENT TEST: PASSED ✅")
    print("-"*80)
    
    return True


def test_phase2_integration():
    """Test integration of all Phase 2 systems."""
    print("\n" + "="*80)
    print("TEST 4: PHASE 2 INTEGRATION TEST")
    print("="*80 + "\n")
    
    resilience_system = EpistemicResilienceSystem()
    
    # Create test theories
    theory1 = Theory(
        theory_id="theory_fusion_energy",
        name="Nuclear Fusion Viability Theory",
        domain="energy",
        description="Commercial fusion energy will be viable by 2040",
        assumptions=["Plasma confinement technology improves"],
        causal_claims=[
            CausalClaim(cause="Increased funding", effect="Faster development", strength=0.7)
        ],
        evidence_for=[
            EvidenceItem(
                evidence_id="evid_fusion",
                evidence_type=EvidenceType.EXPERIMENT,
                description="ITER project shows promising results",
                supports_theory=True,
                confidence=0.75,
                source="ITER Organization, 2024"
            )
        ]
    )
    
    theory2 = Theory(
        theory_id="theory_hydrogen_economy",
        name="Hydrogen Economy Theory",
        domain="energy",
        description="Hydrogen will replace fossil fuels in transportation by 2050",
        assumptions=["Storage costs decrease significantly"],
        causal_claims=[
            CausalClaim(cause="Electrolysis efficiency", effect="Lower production cost", strength=0.8)
        ],
        evidence_for=[
            EvidenceItem(
                evidence_id="evid_hydrogen",
                evidence_type=EvidenceType.STATISTICAL_CORRELATION,
                description="Cost trends show 20% annual decrease",
                supports_theory=True,
                confidence=0.65,
                source="IEA Hydrogen Report 2024"
            )
        ]
    )
    
    print("Step 1: Registering theories with epistemic systems...")
    resilience_system.register_theory(theory1, domain="energy")
    resilience_system.register_theory(theory2, domain="energy")
    print("✅ Registered 2 theories")
    
    print("\nStep 2: Classifying beliefs with reality anchors...")
    resilience_system.reality_anchor.classify_belief("theory_fusion_energy", "speculative_theory", 0.75)
    resilience_system.reality_anchor.classify_belief("theory_hydrogen_economy", "interpretation", 0.65)
    print("✅ Classified both theories")
    
    print("\nStep 3: Recording predictions...")
    pred1 = Prediction(
        prediction_id="pred_fusion_2030",
        description="Fusion net energy gain achieved in lab by 2030",
        conditions={"year": 2030},
        predicted_outcome="Net energy gain demonstrated",
        confidence=0.7
    )
    
    pred2 = Prediction(
        prediction_id="pred_hydrogen_2035",
        description="Hydrogen vehicles reach 10% market share by 2035",
        conditions={"year": 2035},
        predicted_outcome="10% market penetration",
        confidence=0.6
    )
    
    resilience_system.record_prediction("theory_fusion_energy", pred1)
    resilience_system.record_prediction("theory_hydrogen_economy", pred2)
    print("✅ Recorded 2 predictions")
    
    print("\nStep 4: Verifying predictions...")
    resilience_system.verify_prediction("theory_fusion_energy", "pred_fusion_2030", success=True)
    resilience_system.verify_prediction("theory_hydrogen_economy", "pred_hydrogen_2035", success=False)
    print("✅ Verified predictions (1 success, 1 failure)")
    
    print("\nStep 5: Running adversarial attacks...")
    attack1 = resilience_system.red_team_agent.attack_assumption(
        "theory_fusion_energy",
        "Plasma confinement will scale linearly"
    )
    
    attack2 = resilience_system.red_team_agent.challenge_evidence(
        "theory_hydrogen_economy",
        theory2.evidence_for[0]
    )
    
    print(f"  Attacks executed: {resilience_system.red_team_agent.total_attacks}")
    print(f"  Successful disproofs: {resilience_system.red_team_agent.successful_disproofs}")
    print("✅ Adversarial attacks completed")
    
    print("\nStep 6: Calculating epistemic integrity scores...")
    
    # Get belief metadata
    fusion_metadata = resilience_system.aging_engine.belief_metadata.get("theory_fusion_energy")
    hydrogen_metadata = resilience_system.aging_engine.belief_metadata.get("theory_hydrogen_economy")
    
    if fusion_metadata:
        fusion_integrity = resilience_system.integrity_scorer.calculate_integrity_score(
            theory_id="theory_fusion_energy",
            provenance_completeness=0.85,
            contradiction_count=1,
            total_contradictions_tracked=5,
            prediction_accuracy=1.0,  # 1 success, 0 failures
            prediction_count=1,
            hypothesis_diversity=0.7,
            confidence_calibrated=True,
            mutability_score=resilience_system.reality_anchor.get_mutability_score("theory_fusion_energy"),
            is_anchored=False
        )
        print(f"  Fusion theory integrity: {fusion_integrity:.3f}")
    
    if hydrogen_metadata:
        hydrogen_integrity = resilience_system.integrity_scorer.calculate_integrity_score(
            theory_id="theory_hydrogen_economy",
            provenance_completeness=0.7,
            contradiction_count=0,
            total_contradictions_tracked=5,
            prediction_accuracy=0.0,  # 0 successes, 1 failure
            prediction_count=1,
            hypothesis_diversity=0.7,
            confidence_calibrated=False,
            mutability_score=resilience_system.reality_anchor.get_mutability_score("theory_hydrogen_economy"),
            is_anchored=False
        )
        print(f"  Hydrogen theory integrity: {hydrogen_integrity:.3f}")
    
    print("✅ Integrity scores calculated")
    
    print("\nStep 7: Getting comprehensive health reports...")
    fusion_report = resilience_system.get_epistemic_health_report("theory_fusion_energy")
    hydrogen_report = resilience_system.get_epistemic_health_report("theory_hydrogen_economy")
    
    print(f"\n  Fusion Theory:")
    print(f"    Confidence: {fusion_report['belief_status']['current_confidence']:.3f}")
    print(f"    Hypothesis rank: {fusion_report['hypothesis_rank']}")
    print(f"    Prediction success rate: {fusion_report['accountability']['statistics']['success_rate']:.2f}")
    
    print(f"\n  Hydrogen Theory:")
    print(f"    Confidence: {hydrogen_report['belief_status']['current_confidence']:.3f}")
    print(f"    Hypothesis rank: {hydrogen_report['hypothesis_rank']}")
    print(f"    Prediction success rate: {hydrogen_report['accountability']['statistics']['success_rate']:.2f}")
    
    print("✅ Health reports generated")
    
    print("\n" + "-"*80)
    print("PHASE 2 INTEGRATION TEST: PASSED ✅")
    print("-"*80)
    
    return True


def main():
    """Run all Phase 2 tests."""
    print("="*80)
    print("EPISTEMIC RESILIENCE SYSTEM - PHASE 2 TEST SUITE")
    print("="*80)
    print("\nTesting:")
    print("  1. Reality Anchor Layer")
    print("  2. Epistemic Integrity Scorer")
    print("  3. Adversarial Red Team Agent")
    print("  4. Full Phase 2 Integration")
    
    results = []
    
    try:
        results.append(("Reality Anchor Layer", test_reality_anchor_layer()))
    except Exception as e:
        print(f"\n❌ Reality Anchor Layer test FAILED: {e}")
        results.append(("Reality Anchor Layer", False))
    
    try:
        results.append(("Epistemic Integrity Scorer", test_epistemic_integrity_scorer()))
    except Exception as e:
        print(f"\n❌ Epistemic Integrity Scorer test FAILED: {e}")
        results.append(("Epistemic Integrity Scorer", False))
    
    try:
        results.append(("Adversarial Red Team Agent", test_adversarial_red_team_agent()))
    except Exception as e:
        print(f"\n❌ Adversarial Red Team Agent test FAILED: {e}")
        results.append(("Adversarial Red Team Agent", False))
    
    try:
        results.append(("Phase 2 Integration", test_phase2_integration()))
    except Exception as e:
        print(f"\n❌ Phase 2 Integration test FAILED: {e}")
        import traceback
        traceback.print_exc()
        results.append(("Phase 2 Integration", False))
    
    # Summary
    print("\n" + "="*80)
    print("PHASE 2 TEST SUMMARY")
    print("="*80 + "\n")
    
    passed = sum(1 for _, result in results if result)
    total = len(results)
    
    for test_name, result in results:
        status = "✅ PASSED" if result else "❌ FAILED"
        print(f"  {test_name}: {status}")
    
    print(f"\nTotal: {passed}/{total} tests passed")
    
    if passed == total:
        print("\n🎉 ALL PHASE 2 TESTS PASSED!")
        print("\nPhase 2 Systems Operational:")
        print("  ✅ Reality Anchor Layer - Immutable grounding constraints")
        print("  ✅ Epistemic Integrity Scorer - Trustworthiness metrics")
        print("  ✅ Adversarial Red Team Agent - Permanent disproof capability")
        return 0
    else:
        print(f"\n⚠️  {total - passed} test(s) failed")
        return 1


if __name__ == "__main__":
    exit(main())
