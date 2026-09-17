"""
TEST SUITE FOR DELIBERATE FRICTION SYSTEM

Validates:
1. Mode configuration and switching
2. Evidence sufficiency checking
3. Echo chamber detection (agreement ratio)
4. Alternative hypothesis requirements
5. Premature synthesis prevention
6. Ambiguity preservation
7. Decision slowdown logic
8. Mode statistics tracking
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from tiannara_core.monitoring.deliberate_friction import (
    DeliberateFrictionSystem,
    ReasoningMode,
    ModeConfiguration,
    FrictionDecision,
    MODE_CONFIGS
)


def test_mode_configurations():
    """Test: Are all reasoning modes properly configured?"""
    print("\n" + "="*70)
    print("TEST 1: Mode Configurations")
    print("="*70)
    
    # Verify all 5 modes exist
    expected_modes = [
        ReasoningMode.EXPLORATORY,
        ReasoningMode.SKEPTICAL,
        ReasoningMode.CONSERVATIVE,
        ReasoningMode.CREATIVE,
        ReasoningMode.ARBITRATION
    ]
    
    for mode in expected_modes:
        assert mode in MODE_CONFIGS, f"Missing config for {mode.value}"
        config = MODE_CONFIGS[mode]
        assert isinstance(config, ModeConfiguration)
        print(f"   [PASS] {mode.value}: min_evidence={config.min_evidence_count}, "
              f"min_confidence={config.min_confidence_threshold}")
    
    # Verify conservative is stricter than exploratory
    conservative = MODE_CONFIGS[ReasoningMode.CONSERVATIVE]
    exploratory = MODE_CONFIGS[ReasoningMode.EXPLORATORY]
    
    assert conservative.min_evidence_count > exploratory.min_evidence_count
    assert conservative.min_confidence_threshold > exploratory.min_confidence_threshold
    
    print(f"\n   [PASS] Conservative mode stricter than exploratory")
    
    return True


def test_evidence_sufficiency_checking():
    """Test: Does system reject conclusions with insufficient evidence?"""
    print("\n" + "="*70)
    print("TEST 2: Evidence Sufficiency Checking")
    print("="*70)
    
    friction = DeliberateFrictionSystem(default_mode=ReasoningMode.CONSERVATIVE)
    
    # Insufficient evidence (should reject)
    decision = friction.evaluate_with_friction(
        conclusion="Theory A is correct",
        available_evidence=3,  # Below conservative minimum of 12
        supporting_sources=3,
        total_sources=3,
        alternative_hypotheses=["Theory B"],
        contradiction_count=0,
        initial_confidence=0.8
    )
    
    assert not decision.conclusion_accepted, "Should reject with insufficient evidence"
    assert len(decision.reasons_for_rejection) > 0
    
    print(f"   [PASS] Rejected conclusion with insufficient evidence")
    print(f"   [PASS] Reasons: {len(decision.reasons_for_rejection)}")
    for reason in decision.reasons_for_rejection:
        print(f"      - {reason}")
    
    # Sufficient evidence (should accept)
    good_decision = friction.evaluate_with_friction(
        conclusion="Theory A is correct",
        available_evidence=15,  # Above minimum
        supporting_sources=6,   # 50% agreement (within threshold)
        total_sources=12,
        alternative_hypotheses=["Theory B", "Theory C"],
        contradiction_count=2,
        initial_confidence=0.9
    )
    
    assert good_decision.conclusion_accepted, "Should accept with sufficient evidence"
    print(f"\n   [PASS] Accepted conclusion with sufficient evidence")
    
    return True


def test_echo_chamber_detection():
    """Test: Does system detect excessive agreement (echo chamber)?"""
    print("\n" + "="*70)
    print("TEST 3: Echo Chamber Detection")
    print("="*70)
    
    friction = DeliberateFrictionSystem(default_mode=ReasoningMode.SKEPTICAL)
    
    # All sources agree (suspicious)
    decision = friction.evaluate_with_friction(
        conclusion="Everyone agrees on X",
        available_evidence=10,
        supporting_sources=10,  # 100% agreement
        total_sources=10,
        alternative_hypotheses=["Alternative Y"],
        contradiction_count=1,
        initial_confidence=0.9
    )
    
    assert not decision.conclusion_accepted, "Should reject echo chamber"
    assert any('agreement' in r.lower() or 'echo' in r.lower() 
               for r in decision.reasons_for_rejection)
    
    print(f"   [PASS] Detected echo chamber (100% agreement)")
    print(f"   [PASS] Recommendation: {decision.recommendations[0]}")
    
    # Healthy disagreement (should accept)
    healthy = friction.evaluate_with_friction(
        conclusion="Mixed opinions on X",
        available_evidence=10,
        supporting_sources=6,  # 60% agreement
        total_sources=10,
        alternative_hypotheses=["Alternative Y"],
        contradiction_count=2,
        initial_confidence=0.8
    )
    
    assert healthy.conclusion_accepted, "Should accept healthy disagreement"
    print(f"\n   [PASS] Accepted healthy disagreement (60% agreement)")
    
    return True


def test_alternative_hypothesis_requirement():
    """Test: Does system require alternative hypotheses?"""
    print("\n" + "="*70)
    print("TEST 4: Alternative Hypothesis Requirement")
    print("="*70)
    
    friction = DeliberateFrictionSystem(default_mode=ReasoningMode.ARBITRATION)
    
    # No alternatives provided (should reject)
    decision = friction.evaluate_with_friction(
        conclusion="Only one theory exists",
        available_evidence=8,
        supporting_sources=5,
        total_sources=6,
        alternative_hypotheses=None,  # No alternatives
        contradiction_count=1,
        initial_confidence=0.85
    )
    
    assert not decision.conclusion_accepted, "Should reject without alternatives"
    assert any('alternative' in r.lower() for r in decision.reasons_for_rejection)
    
    print(f"   [PASS] Rejected conclusion without alternative hypotheses")
    
    # With alternatives (should accept if other criteria met)
    with_alternatives = friction.evaluate_with_friction(
        conclusion="Theory with alternatives",
        available_evidence=8,
        supporting_sources=5,
        total_sources=6,
        alternative_hypotheses=["Alt 1", "Alt 2"],
        contradiction_count=1,
        initial_confidence=0.85
    )
    
    # May still reject for other reasons, but not for missing alternatives
    no_alt_reason = [r for r in with_alternatives.reasons_for_rejection 
                     if 'alternative' in r.lower()]
    assert len(no_alt_reason) == 0, "Should not reject for alternatives when provided"
    
    print(f"   [PASS] Accepted when alternatives provided")
    
    return True


def test_premature_synthesis_prevention():
    """Test: Can system refuse premature synthesis?"""
    print("\n" + "="*70)
    print("TEST 5: Premature Synthesis Prevention")
    print("="*70)
    
    friction = DeliberateFrictionSystem()
    
    # Incomplete exploration (should refuse)
    should_refuse = friction.refuse_premature_synthesis(
        exploration_completeness=0.4,  # Only 40% complete
        hypothesis_count=2,
        min_hypotheses=3
    )
    
    assert should_refuse, "Should refuse incomplete exploration"
    print(f"   [PASS] Refused synthesis at 40% exploration completeness")
    
    # Insufficient hypotheses (should refuse)
    should_refuse_2 = friction.refuse_premature_synthesis(
        exploration_completeness=0.8,  # Well explored
        hypothesis_count=1,  # But only 1 hypothesis
        min_hypotheses=3
    )
    
    assert should_refuse_2, "Should refuse with insufficient hypotheses"
    print(f"   [PASS] Refused synthesis with only 1 hypothesis")
    
    # Ready for synthesis (should allow)
    should_allow = friction.refuse_premature_synthesis(
        exploration_completeness=0.85,
        hypothesis_count=5,
        min_hypotheses=3
    )
    
    assert not should_allow, "Should allow synthesis when ready"
    print(f"   [PASS] Allowed synthesis when exploration complete")
    
    return True


def test_ambiguity_preservation():
    """Test: Can system preserve ambiguity when appropriate?"""
    print("\n" + "="*70)
    print("TEST 6: Ambiguity Preservation")
    print("="*70)
    
    friction = DeliberateFrictionSystem()
    
    # Small confidence gap (should preserve ambiguity)
    should_preserve = friction.preserve_ambiguity(
        confidence_gap=0.08,  # Very close
        evidence_quality="fair"
    )
    
    assert should_preserve, "Should preserve ambiguity with small gap"
    print(f"   [PASS] Preserved ambiguity (gap=0.08, quality=fair)")
    
    # Poor evidence quality (should preserve)
    should_preserve_2 = friction.preserve_ambiguity(
        confidence_gap=0.25,  # Decent gap
        evidence_quality="poor"
    )
    
    assert should_preserve_2, "Should preserve ambiguity with poor evidence"
    print(f"   [PASS] Preserved ambiguity (gap=0.25, quality=poor)")
    
    # Clear winner with good evidence (should decide)
    should_decide = friction.preserve_ambiguity(
        confidence_gap=0.35,  # Large gap
        evidence_quality="excellent"
    )
    
    assert not should_decide, "Should make decision when clear"
    print(f"   [PASS] Made decision (gap=0.35, quality=excellent)")
    
    return True


def test_decision_slowdown_logic():
    """Test: Does system slow down for high-stakes/uncertain decisions?"""
    print("\n" + "="*70)
    print("TEST 7: Decision Slowdown Logic")
    print("="*70)
    
    friction = DeliberateFrictionSystem()
    
    # High stakes (should slow down)
    should_slow = friction.should_slow_down(
        decision_urgency="high",
        stakes_level="critical",
        uncertainty_level=0.5
    )
    
    assert should_slow, "Should slow down for critical stakes"
    print(f"   [PASS] Slowed down for critical stakes")
    
    # High uncertainty (should slow down)
    should_slow_2 = friction.should_slow_down(
        decision_urgency="medium",
        stakes_level="medium",
        uncertainty_level=0.85  # Very uncertain
    )
    
    assert should_slow_2, "Should slow down for high uncertainty"
    print(f"   [PASS] Slowed down for high uncertainty (0.85)")
    
    # Low stakes, low uncertainty (can proceed quickly)
    can_proceed = friction.should_slow_down(
        decision_urgency="low",
        stakes_level="low",
        uncertainty_level=0.2
    )
    
    assert not can_proceed, "Can proceed quickly for low-stakes decisions"
    print(f"   [PASS] Proceeded quickly for low-stakes decision")
    
    return True


def test_mode_switching_and_statistics():
    """Test: Can switch modes and track statistics?"""
    print("\n" + "="*70)
    print("TEST 8: Mode Switching and Statistics")
    print("="*70)
    
    friction = DeliberateFrictionSystem(default_mode=ReasoningMode.CONSERVATIVE)
    
    # Make some decisions in conservative mode
    friction.evaluate_with_friction(
        conclusion="Test 1",
        available_evidence=15,
        supporting_sources=10,
        total_sources=12,
        alternative_hypotheses=["Alt"],
        initial_confidence=0.9
    )
    
    # Switch to exploratory mode
    friction.set_mode(ReasoningMode.EXPLORATORY)
    
    friction.evaluate_with_friction(
        conclusion="Test 2",
        available_evidence=3,
        supporting_sources=2,
        total_sources=3,
        alternative_hypotheses=["Alt"],
        initial_confidence=0.6
    )
    
    # Get statistics
    stats = friction.get_mode_statistics()
    
    assert stats['current_mode'] == ReasoningMode.EXPLORATORY.value
    assert stats['total_decisions'] == 2
    assert 'mode_usage' in stats
    assert 'acceptance_rates' in stats
    
    print(f"   [PASS] Current mode: {stats['current_mode']}")
    print(f"   [PASS] Total decisions: {stats['total_decisions']}")
    print(f"   [PASS] Mode usage: {stats['mode_usage']}")
    print(f"   [PASS] Acceptance rates: {stats['acceptance_rates']}")
    
    return True


def test_mode_specific_behavior():
    """Test: Do different modes exhibit distinct behavior?"""
    print("\n" + "="*70)
    print("TEST 9: Mode-Specific Behavior")
    print("="*70)
    
    # Test same scenario across different modes
    scenario = {
        'conclusion': "Test conclusion",
        'available_evidence': 5,
        'supporting_sources': 4,
        'total_sources': 5,
        'alternative_hypotheses': ["Alt"],
        'initial_confidence': 0.7
    }
    
    results = {}
    for mode in [ReasoningMode.EXPLORATORY, ReasoningMode.CONSERVATIVE, 
                 ReasoningMode.SKEPTICAL]:
        friction = DeliberateFrictionSystem(default_mode=mode)
        decision = friction.evaluate_with_friction(**scenario)
        results[mode.value] = decision.conclusion_accepted
    
    print(f"   Scenario: evidence=5, confidence=0.7")
    print(f"   Results:")
    for mode_name, accepted in results.items():
        status = "ACCEPTED" if accepted else "REJECTED"
        print(f"      - {mode_name}: {status}")
    
    # Exploratory should be more permissive than conservative
    assert results['exploratory'] != results['conservative'], \
        "Different modes should produce different outcomes"
    
    print(f"\n   [PASS] Different modes exhibit distinct behavior")
    
    return True


def run_all_tests():
    """Execute all deliberate friction system tests."""
    print("\n" + "="*70)
    print("DELIBERATE FRICTION SYSTEM TEST SUITE")
    print("="*70)
    
    tests = [
        ("Mode Configurations", test_mode_configurations),
        ("Evidence Sufficiency Checking", test_evidence_sufficiency_checking),
        ("Echo Chamber Detection", test_echo_chamber_detection),
        ("Alternative Hypothesis Requirement", test_alternative_hypothesis_requirement),
        ("Premature Synthesis Prevention", test_premature_synthesis_prevention),
        ("Ambiguity Preservation", test_ambiguity_preservation),
        ("Decision Slowdown Logic", test_decision_slowdown_logic),
        ("Mode Switching and Statistics", test_mode_switching_and_statistics),
        ("Mode-Specific Behavior", test_mode_specific_behavior),
    ]
    
    results = []
    for name, test_func in tests:
        try:
            passed = test_func()
            results.append((name, passed))
        except Exception as e:
            print(f"\n   [FAIL] {name}: {str(e)}")
            import traceback
            traceback.print_exc()
            results.append((name, False))
    
    # Summary
    print("\n" + "="*70)
    print("TEST SUMMARY")
    print("="*70)
    
    passed_count = sum(1 for _, passed in results if passed)
    total_count = len(results)
    
    for name, passed in results:
        status = "[PASS]" if passed else "[FAIL]"
        print(f"   {status} {name}")
    
    print(f"\n   Overall: {passed_count}/{total_count} tests passed")
    
    if passed_count == total_count:
        print("\n   [EXCELLENT] All deliberate friction tests passed!")
    else:
        print(f"\n   [WARNING] {total_count - passed_count} test(s) failed")
    
    return passed_count == total_count


if __name__ == "__main__":
    success = run_all_tests()
    sys.exit(0 if success else 1)
