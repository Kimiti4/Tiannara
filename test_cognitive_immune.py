"""
TEST SUITE FOR COGNITIVE IMMUNE SYSTEM

Validates detection of:
1. Overconfidence spikes
2. Confidence-evidence mismatch
3. Self-confirming loops
4. Contradiction suppression
5. Reward hacking
6. Hallucinated causality
7. Full audit integration
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from tiannara_core.monitoring.cognitive_immune import (
    CognitiveImmuneSystem,
    CognitiveAnomaly,
    AnomalyType
)


def test_overconfidence_spike_detection():
    """Test: Can detect when confidence increases without evidence?"""
    print("\n" + "="*70)
    print("TEST 1: Overconfidence Spike Detection")
    print("="*70)
    
    immune = CognitiveImmuneSystem()
    
    # Simulate confidence spike without evidence
    anomaly = immune.check_overconfidence_spike(
        theory_id="theory_001",
        old_confidence=0.3,
        new_confidence=0.8,  # 2.67x increase
        evidence_added=0
    )
    
    assert anomaly is not None, "Should detect overconfidence spike"
    assert anomaly.anomaly_type == AnomalyType.OVERCONFIDENCE_SPIKE
    assert anomaly.severity > 0.5, f"Severity {anomaly.severity} should be high"
    
    print(f"   [PASS] Detected overconfidence spike")
    print(f"   [PASS] Severity: {anomaly.severity:.2f}")
    print(f"   [PASS] Description: {anomaly.description}")
    
    # Test normal confidence increase with evidence (should NOT trigger)
    normal = immune.check_overconfidence_spike(
        theory_id="theory_002",
        old_confidence=0.3,
        new_confidence=0.5,
        evidence_added=5
    )
    
    assert normal is None, "Should NOT flag normal increase with evidence"
    print(f"   [PASS] Normal increase with evidence not flagged")
    
    return True


def test_confidence_evidence_mismatch():
    """Test: Can detect high confidence with insufficient evidence?"""
    print("\n" + "="*70)
    print("TEST 2: Confidence-Evidence Mismatch")
    print("="*70)
    
    immune = CognitiveImmuneSystem()
    
    # High confidence, low evidence
    anomaly = immune.check_confidence_evidence_mismatch(
        theory_id="theory_003",
        confidence=0.9,
        evidence_count=2  # Below minimum of 5
    )
    
    assert anomaly is not None, "Should detect mismatch"
    assert anomaly.anomaly_type == AnomalyType.CONFIDENCE_EVIDENCE_MISMATCH
    
    print(f"   [PASS] Detected confidence-evidence mismatch")
    print(f"   [PASS] Confidence: {anomaly.confidence_after:.2f}")
    print(f"   [PASS] Evidence: {anomaly.evidence_count_after}")
    print(f"   [PASS] Recommendation: {anomaly.recommended_action}")
    
    # Adequate evidence (should NOT trigger)
    normal = immune.check_confidence_evidence_mismatch(
        theory_id="theory_004",
        confidence=0.9,
        evidence_count=8  # Above minimum
    )
    
    assert normal is None, "Should NOT flag adequate evidence"
    print(f"   [PASS] Adequate evidence not flagged")
    
    return True


def test_self_confirming_loop_detection():
    """Test: Can detect suspiciously perfect prediction records?"""
    print("\n" + "="*70)
    print("TEST 3: Self-Confirming Loop Detection")
    print("="*70)
    
    immune = CognitiveImmuneSystem()
    
    # Perfect success rate (suspicious)
    perfect_predictions = [True] * 10  # 10/10 successes
    
    anomaly = immune.check_self_confirming_loop(
        theory_id="theory_005",
        recent_predictions=perfect_predictions
    )
    
    assert anomaly is not None, "Should detect self-confirming loop"
    assert anomaly.anomaly_type == AnomalyType.SELF_CONFIRMING_LOOP
    
    print(f"   [PASS] Detected self-confirming loop")
    print(f"   [PASS] Severity: {anomaly.severity:.2f}")
    print(f"   [PASS] Description: {anomaly.description}")
    
    # Normal success rate with some failures (should NOT trigger)
    normal_predictions = [True, True, False, True, True, True, False, True, True, True]
    
    normal = immune.check_self_confirming_loop(
        theory_id="theory_006",
        recent_predictions=normal_predictions
    )
    
    assert normal is None, "Should NOT flag normal success rate"
    print(f"   [PASS] Normal success rate not flagged")
    
    return True


def test_contradiction_suppression_detection():
    """Test: Can detect when contradictions are being ignored?"""
    print("\n" + "="*70)
    print("TEST 4: Contradiction Suppression Detection")
    print("="*70)
    
    immune = CognitiveImmuneSystem()
    
    # Suppressing most contradictions
    anomaly = immune.check_contradiction_suppression(
        theory_id="theory_007",
        total_contradictions=10,
        acknowledged_contradictions=2  # Only 20% acknowledged
    )
    
    assert anomaly is not None, "Should detect contradiction suppression"
    assert anomaly.anomaly_type == AnomalyType.CONTRADICTION_SUPPRESSION
    assert anomaly.severity > 0.5, "Severity should reflect suppression ratio"
    
    print(f"   [PASS] Detected contradiction suppression")
    print(f"   [PASS] Suppression ratio: {anomaly.severity:.2f}")
    print(f"   [PASS] Ignored: {10 - 2}/{10} contradictions")
    
    # Properly addressing contradictions (should NOT trigger)
    normal = immune.check_contradiction_suppression(
        theory_id="theory_008",
        total_contradictions=10,
        acknowledged_contradictions=9  # 90% acknowledged
    )
    
    assert normal is None, "Should NOT flag proper contradiction handling"
    print(f"   [PASS] Proper contradiction handling not flagged")
    
    return True


def test_reward_hacking_detection():
    """Test: Can detect reward exploitation without causal understanding?"""
    print("\n" + "="*70)
    print("TEST 5: Reward Hacking Detection")
    print("="*70)
    
    immune = CognitiveImmuneSystem()
    
    # High reward correlation, low causal depth (suspicious)
    anomaly = immune.check_reward_hacking(
        theory_id="theory_009",
        reward_correlation=0.98,  # Very high
        causal_depth=0.3          # Low
    )
    
    assert anomaly is not None, "Should detect reward hacking"
    assert anomaly.anomaly_type == AnomalyType.REWARD_HACKING
    
    print(f"   [PASS] Detected reward hacking")
    print(f"   [PASS] Severity: {anomaly.severity:.2f}")
    print(f"   [PASS] Reward correlation: 0.98")
    print(f"   [PASS] Causal depth: 0.3")
    print(f"   [PASS] Recommendation: {anomaly.recommended_action}")
    
    # Legitimate high performance (should NOT trigger)
    normal = immune.check_reward_hacking(
        theory_id="theory_010",
        reward_correlation=0.98,
        causal_depth=0.85  # High causal depth
    )
    
    assert normal is None, "Should NOT flag legitimate high performance"
    print(f"   [PASS] Legitimate high performance not flagged")
    
    return True


def test_hallucinated_causality_detection():
    """Test: Can detect unverified causal claims?"""
    print("\n" + "="*70)
    print("TEST 6: Hallucinated Causality Detection")
    print("="*70)
    
    immune = CognitiveImmuneSystem()
    
    # Many claims, few verified
    anomaly = immune.check_hallucinated_causality(
        theory_id="theory_011",
        causal_claims=10,
        verified_causal_links=2  # Only 20% verified
    )
    
    assert anomaly is not None, "Should detect hallucinated causality"
    assert anomaly.anomaly_type == AnomalyType.HALLUCINATED_CAUSALITY
    
    print(f"   [PASS] Detected hallucinated causality")
    print(f"   [PASS] Severity: {anomaly.severity:.2f}")
    print(f"   [PASS] Claims: {10}, Verified: {2}")
    print(f"   [PASS] Verification ratio: 20%")
    
    # Well-verified causality (should NOT trigger)
    normal = immune.check_hallucinated_causality(
        theory_id="theory_012",
        causal_claims=10,
        verified_causal_links=8  # 80% verified
    )
    
    assert normal is None, "Should NOT flag well-verified causality"
    print(f"   [PASS] Well-verified causality not flagged")
    
    return True


def test_full_audit_integration():
    """Test: Does full audit detect multiple anomalies simultaneously?"""
    print("\n" + "="*70)
    print("TEST 7: Full Audit Integration")
    print("="*70)
    
    immune = CognitiveImmuneSystem()
    
    # Create theory data with multiple issues
    problematic_theory = {
        'theory_id': 'problematic_001',
        'confidence': 0.95,
        'evidence_count': 2,  # Too low for high confidence
        'recent_predictions': [True] * 10,  # Suspiciously perfect
        'total_contradictions': 8,
        'acknowledged_contradictions': 1,  # Suppressing most
        'reward_correlation': 0.97,
        'causal_depth': 0.25,
        'causal_claims': 12,
        'verified_causal_links': 2
    }
    
    anomalies = immune.run_full_audit(problematic_theory)
    
    assert len(anomalies) >= 4, f"Should detect multiple anomalies, got {len(anomalies)}"
    
    anomaly_types = [a.anomaly_type for a in anomalies]
    
    print(f"   [PASS] Detected {len(anomalies)} anomalies:")
    for anomaly in anomalies:
        print(f"      - {anomaly.anomaly_type.value}: severity {anomaly.severity:.2f}")
    
    # Verify specific detections
    assert AnomalyType.CONFIDENCE_EVIDENCE_MISMATCH in anomaly_types
    assert AnomalyType.SELF_CONFIRMING_LOOP in anomaly_types
    assert AnomalyType.CONTRADICTION_SUPPRESSION in anomaly_types
    assert AnomalyType.REWARD_HACKING in anomaly_types
    
    print(f"\n   [PASS] All expected anomaly types detected")
    
    return True


def test_health_report_generation():
    """Test: Does health report provide comprehensive assessment?"""
    print("\n" + "="*70)
    print("TEST 8: Health Report Generation")
    print("="*70)
    
    immune = CognitiveImmuneSystem()
    
    # Generate some anomalies
    immune.check_overconfidence_spike("t1", 0.3, 0.8, 0)
    immune.check_confidence_evidence_mismatch("t2", 0.9, 2)
    immune.check_reward_hacking("t3", 0.98, 0.3)
    
    # Get health report
    report = immune.get_health_report()
    
    assert report['status'] in ['HEALTHY', 'MONITORING', 'WARNING', 'CRITICAL']
    assert report['total_anomalies'] == 3
    assert 'by_type' in report
    assert 'recent_anomalies' in report
    
    print(f"   [PASS] Health report status: {report['status']}")
    print(f"   [PASS] Total anomalies: {report['total_anomalies']}")
    print(f"   [PASS] Anomaly types: {list(report['by_type'].keys())}")
    print(f"   [PASS] Recent anomalies: {len(report['recent_anomalies'])}")
    
    # Test healthy system report
    healthy_immune = CognitiveImmuneSystem()
    healthy_report = healthy_immune.get_health_report()
    
    assert healthy_report['status'] == 'HEALTHY'
    assert healthy_report['total_anomalies'] == 0
    
    print(f"   [PASS] Healthy system correctly reports HEALTHY status")
    
    return True


def run_all_tests():
    """Execute all cognitive immune system tests."""
    print("\n" + "="*70)
    print("COGNITIVE IMMUNE SYSTEM TEST SUITE")
    print("="*70)
    
    tests = [
        ("Overconfidence Spike Detection", test_overconfidence_spike_detection),
        ("Confidence-Evidence Mismatch", test_confidence_evidence_mismatch),
        ("Self-Confirming Loop Detection", test_self_confirming_loop_detection),
        ("Contradiction Suppression Detection", test_contradiction_suppression_detection),
        ("Reward Hacking Detection", test_reward_hacking_detection),
        ("Hallucinated Causality Detection", test_hallucinated_causality_detection),
        ("Full Audit Integration", test_full_audit_integration),
        ("Health Report Generation", test_health_report_generation),
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
        print("\n   [EXCELLENT] All cognitive immune system tests passed!")
    else:
        print(f"\n   [WARNING] {total_count - passed_count} test(s) failed")
    
    return passed_count == total_count


if __name__ == "__main__":
    success = run_all_tests()
    sys.exit(0 if success else 1)
