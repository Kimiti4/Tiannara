"""
EPISTEMIC RESILIENCE SYSTEM - PHASE 3 TESTS

Tests the three critical Phase 3 systems:
1. Provenance Chains - Full source traceability
2. Delayed Contradiction Handling - Store contradictions without immediate resolution
3. Consensus Corruption Resistance - Anti-echo-chamber mechanisms

Based on strategic analysis from ADVERSARIAL_DEBATE_TEST_COMPLETE.md (lines 387-788)
"""

import sys
import time
import random
from pathlib import Path

# Add project root to path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.metacognition.epistemic_resilience import (
    ProvenanceChainTracker,
    DelayedContradictionHandler,
    ConsensusCorruptionResistance,
    EpistemicResilienceSystem
)


def test_provenance_chain_tracker():
    """Test Provenance Chain Tracker system."""
    print("\n" + "="*80)
    print("TEST 1: PROVENANCE CHAIN TRACKER")
    print("="*80 + "\n")
    
    tracker = ProvenanceChainTracker()
    
    # Test 1: Record provenance steps
    print("Recording provenance chain for theory...")
    
    tracker.record_provenance_step(
        theory_id="theory_solar",
        step_type="observation",
        source="NREL Experiment 2024",
        transformation="Raw data collection",
        confidence_before=0.0,
        confidence_after=0.6
    )
    
    tracker.record_provenance_step(
        theory_id="theory_solar",
        step_type="inference",
        source="Statistical analysis",
        transformation="Trend extrapolation",
        confidence_before=0.6,
        confidence_after=0.75
    )
    
    tracker.record_provenance_step(
        theory_id="theory_solar",
        step_type="synthesis",
        source="Expert review",
        transformation="Peer validation",
        confidence_before=0.75,
        confidence_after=0.85
    )
    
    print(f"✅ Recorded {len(tracker.provenance_chains['theory_solar'])} provenance steps")
    
    # Test 2: Verify provenance chain
    print("\nVerifying provenance chain completeness...")
    is_complete, issues = tracker.verify_provenance_chain("theory_solar")
    print(f"  Is complete: {is_complete}")
    if issues:
        print(f"  Issues found: {len(issues)}")
        for issue in issues:
            print(f"    - {issue}")
    else:
        print("  No issues found ✅")
    
    # Test 3: Calculate completeness score
    print("\nCalculating completeness score...")
    score = tracker.get_provenance_completeness_score("theory_solar")
    print(f"  Completeness score: {score:.3f}")
    assert score > 0.5, f"Expected > 0.5, got {score}"
    print("✅ Completeness score reasonable")
    
    # Test 4: Get full report
    print("\nGenerating provenance report...")
    report = tracker.get_full_provenance_report("theory_solar")
    assert report is not None
    print(f"  Chain length: {report['chain_length']}")
    print(f"  Is complete: {report['is_complete']}")
    print(f"  Completeness score: {report['completeness_score']:.3f}")
    print(f"  Issues: {len(report['issues'])}")
    print("✅ Report generation working")
    
    # Test 5: Test incomplete chain
    print("\nTesting incomplete chain detection...")
    tracker.record_provenance_step(
        theory_id="theory_incomplete",
        step_type="inference",  # Should start with observation
        source="",  # Missing source
        transformation="Unknown",
        confidence_before=0.0,
        confidence_after=0.9  # Large unjustified jump
    )
    
    is_complete, issues = tracker.verify_provenance_chain("theory_incomplete")
    print(f"  Is complete: {is_complete}")
    print(f"  Issues found: {len(issues)}")
    for issue in issues:
        print(f"    - {issue}")
    
    assert not is_complete, "Incomplete chain should be detected"
    assert len(issues) > 0, "Should detect issues"
    print("✅ Incomplete chain detection working")
    
    print("\n" + "-"*80)
    print("PROVENANCE CHAIN TRACKER TEST: PASSED ✅")
    print("-"*80)
    
    return True


def test_delayed_contradiction_handler():
    """Test Delayed Contradiction Handler system."""
    print("\n" + "="*80)
    print("TEST 2: DELAYED CONTRADICTION HANDLER")
    print("="*80 + "\n")
    
    handler = DelayedContradictionHandler()
    
    # Test 1: Record contradictions
    print("Recording contradictions between theories...")
    
    handler.record_contradiction(
        theory_a_id="theory_fusion",
        theory_b_id="theory_renewables",
        contradiction_type="resource_allocation",
        description="Funding for fusion reduces renewable energy research budget",
        severity=0.7
    )
    
    handler.record_contradiction(
        theory_a_id="theory_fusion",
        theory_b_id="theory_efficiency",
        contradiction_type="logical",
        description="Fusion timeline conflicts with efficiency improvement projections",
        severity=0.5
    )
    
    print(f"✅ Recorded 2 contradictions for theory_fusion")
    
    # Test 2: Get unresolved contradictions
    print("\nGetting unresolved contradictions...")
    unresolved = handler.get_unresolved_contradictions("theory_fusion")
    print(f"  Unresolved count: {len(unresolved)}")
    assert len(unresolved) == 2, f"Expected 2, got {len(unresolved)}"
    print("✅ Unresolved tracking working")
    
    # Test 3: Get contradiction statistics
    print("\nGetting contradiction statistics...")
    stats = handler.get_contradiction_statistics("theory_fusion")
    print(f"  Total contradictions: {stats['total']}")
    print(f"  Unresolved: {stats['unresolved']}")
    print(f"  Resolved: {stats['resolved']}")
    print(f"  Average severity: {stats['avg_severity']:.3f}")
    print(f"  Types: {stats['types']}")
    
    assert stats['total'] == 2
    assert stats['unresolved'] == 2
    assert stats['resolved'] == 0
    print("✅ Statistics accurate")
    
    # Test 4: Calculate uncertainty level
    print("\nCalculating uncertainty level...")
    uncertainty = handler.get_uncertainty_level("theory_fusion")
    print(f"  Uncertainty level: {uncertainty:.3f}")
    assert uncertainty > 0.0, "Should have some uncertainty with unresolved contradictions"
    print("✅ Uncertainty calculation working")
    
    # Test 5: Resolve a contradiction
    print("\nResolving a contradiction...")
    contradiction_id = unresolved[0]['contradiction_id']
    resolved = handler.resolve_contradiction(
        theory_a_id="theory_fusion",
        contradiction_id=contradiction_id,
        resolution="Budget allocation adjusted to support both",
        resolution_type="policy_adjustment"
    )
    
    assert resolved, "Resolution should succeed"
    print(f"  Resolved: {resolved}")
    
    # Check updated stats
    stats_after = handler.get_contradiction_statistics("theory_fusion")
    print(f"  After resolution:")
    print(f"    Unresolved: {stats_after['unresolved']}")
    print(f"    Resolved: {stats_after['resolved']}")
    
    assert stats_after['unresolved'] == 1
    assert stats_after['resolved'] == 1
    print("✅ Resolution working correctly")
    
    # Test 6: Create uncertainty cluster
    print("\nCreating uncertainty cluster...")
    handler.create_uncertainty_cluster(
        cluster_id="energy_debate",
        theory_ids=["theory_fusion", "theory_renewables", "theory_efficiency"]
    )
    
    assert "energy_debate" in handler.uncertainty_clusters
    print(f"  Cluster created with {len(handler.uncertainty_clusters['energy_debate'])} theories")
    print("✅ Uncertainty cluster creation working")
    
    print("\n" + "-"*80)
    print("DELAYED CONTRADICTION HANDLER TEST: PASSED ✅")
    print("-"*80)
    
    return True


def test_consensus_corruption_resistance():
    """Test Consensus Corruption Resistance system."""
    print("\n" + "="*80)
    print("TEST 3: CONSENSUS CORRUPTION RESISTANCE")
    print("="*80 + "\n")
    
    resistance = ConsensusCorruptionResistance()
    
    # Test 1: Record agent beliefs
    print("Recording agent beliefs...")
    
    # TRUE echo chamber: everyone agrees very closely (low variance)
    for i in range(10):
        resistance.record_agent_belief(f"agent_{i}", "belief_climate", random.uniform(0.85, 0.92))
    
    print(f"✅ Recorded beliefs for 10 agents (all agreeing closely)")
    
    # Test 2: Detect echo chamber
    print("\nDetecting echo chamber...")
    detection = resistance.detect_echo_chamber("belief_climate", threshold=0.8)
    
    print(f"  Is echo chamber: {detection['is_echo_chamber']}")
    print(f"  Total agents: {detection['total_agents']}")
    print(f"  Agreeing agents: {detection['agreeing_agents']}")
    print(f"  Consensus ratio: {detection['consensus_ratio']:.2f}")
    print(f"  Diversity score: {detection['diversity_score']:.3f}")
    
    assert detection['is_echo_chamber'], "Should detect echo chamber with 80% agreement and low diversity"
    print("✅ Echo chamber detection working")
    
    # Test 3: Amplify minority voice
    print("\nAmplifying minority voices...")
    
    # First, add some minority agents
    resistance.record_agent_belief(f"minority_1", "belief_climate", 0.2)
    resistance.record_agent_belief(f"minority_2", "belief_climate", 0.25)
    
    minority_agents = resistance.amplify_minority_voice("belief_climate", minority_threshold=0.3)
    print(f"  Minority agents found: {len(minority_agents)}")
    print(f"  Agent IDs: {minority_agents}")
    
    assert len(minority_agents) == 2, f"Expected 2 minority agents, got {len(minority_agents)}"
    print("✅ Minority amplification working")
    
    # Test 4: Test consensus corruption resistance
    print("\nTesting consensus corruption resistance scenario...")
    test_result = resistance.test_consensus_corruption_resistance(
        belief_id="belief_test",
        false_majority_ratio=0.8,
        truthful_minority_count=2
    )
    
    print(f"  Scenario: {test_result['scenario']}")
    print(f"  False majority agents: {test_result['false_majority_agents']}")
    print(f"  Truthful minority agents: {test_result['truthful_minority_agents']}")
    print(f"  Echo chamber detected: {test_result['echo_chamber_detected']}")
    print(f"  Recovery possible: {test_result['recovery_possible']}")
    print(f"  Recommendation: {test_result['recommendation']}")
    
    assert test_result['false_majority_agents'] == 8
    assert test_result['truthful_minority_agents'] == 2
    print("✅ Consensus corruption test working")
    
    # Test 5: Get consensus health report
    print("\nGetting consensus health report...")
    health_report = resistance.get_consensus_health_report()
    print(f"  Total beliefs tracked: {health_report['total_beliefs_tracked']}")
    print(f"  Echo chambers detected: {health_report['echo_chambers_detected']}")
    print(f"  Average diversity: {health_report['avg_diversity']:.3f}")
    print(f"  Health status: {health_report['health_status']}")
    print(f"  Total warnings: {health_report['total_warnings']}")
    
    assert health_report['total_beliefs_tracked'] > 0
    assert health_report['echo_chambers_detected'] > 0
    print("✅ Health report generation working")
    
    print("\n" + "-"*80)
    print("CONSENSUS CORRUPTION RESISTANCE TEST: PASSED ✅")
    print("-"*80)
    
    return True


def test_phase3_integration():
    """Test integration of all Phase 3 systems."""
    print("\n" + "="*80)
    print("TEST 4: PHASE 3 INTEGRATION TEST")
    print("="*80 + "\n")
    
    resilience_system = EpistemicResilienceSystem()
    
    # Test 1: Record provenance with integrated system
    print("Step 1: Recording provenance chain through integrated system...")
    
    resilience_system.record_provenance_step(
        theory_id="theory_integrated",
        step_type="observation",
        source="Experimental data",
        transformation="Data collection",
        confidence_before=0.0,
        confidence_after=0.5
    )
    
    resilience_system.record_provenance_step(
        theory_id="theory_integrated",
        step_type="analysis",
        source="Statistical model",
        transformation="Regression analysis",
        confidence_before=0.5,
        confidence_after=0.7
    )
    
    print("✅ Recorded 2 provenance steps")
    
    # Test 2: Verify provenance
    print("\nStep 2: Verifying provenance...")
    is_complete, issues = resilience_system.verify_provenance("theory_integrated")
    print(f"  Is complete: {is_complete}")
    if issues:
        print(f"  Issues: {len(issues)}")
    print("✅ Provenance verification working")
    
    # Test 3: Record contradiction
    print("\nStep 3: Recording contradiction...")
    resilience_system.record_contradiction(
        theory_a_id="theory_A",
        theory_b_id="theory_B",
        contradiction_type="empirical",
        description="Conflicting experimental results",
        severity=0.6
    )
    
    unresolved = resilience_system.contradiction_handler.get_unresolved_contradictions("theory_A")
    print(f"  Unresolved contradictions: {len(unresolved)}")
    assert len(unresolved) == 1
    print("✅ Contradiction recording working")
    
    # Test 4: Resolve contradiction
    print("\nStep 4: Resolving contradiction...")
    contradiction_id = unresolved[0]['contradiction_id']
    resolved = resilience_system.resolve_contradiction(
        theory_id="theory_A",
        contradiction_id=contradiction_id,
        resolution="Additional experiment confirmed theory A",
        resolution_type="experimental_validation"
    )
    
    assert resolved, "Resolution should succeed"
    print(f"  Resolved: {resolved}")
    
    stats = resilience_system.contradiction_handler.get_contradiction_statistics("theory_A")
    print(f"  Resolved count: {stats['resolved']}")
    assert stats['resolved'] == 1
    print("✅ Contradiction resolution working")
    
    # Test 5: Detect echo chamber
    print("\nStep 5: Testing echo chamber detection...")
    
    # Create TRUE echo chamber scenario (all agents agree closely)
    for i in range(10):
        resilience_system.consensus_resistance.record_agent_belief(
            f"echo_agent_{i}", "belief_echo", random.uniform(0.85, 0.92)
        )
    
    detection = resilience_system.detect_echo_chamber("belief_echo")
    print(f"  Echo chamber detected: {detection['is_echo_chamber']}")
    print(f"  Consensus ratio: {detection['consensus_ratio']:.2f}")
    print(f"  Diversity score: {detection['diversity_score']:.3f}")
    
    assert detection['is_echo_chamber'], "Should detect echo chamber"
    print("✅ Echo chamber detection working")
    
    # Test 6: Test consensus resistance
    print("\nStep 6: Testing consensus corruption resistance...")
    test_result = resilience_system.test_consensus_resistance(
        belief_id="belief_corruption_test",
        false_majority_ratio=0.8,
        truthful_minority_count=2
    )
    
    print(f"  Scenario: {test_result['scenario']}")
    print(f"  Recovery possible: {test_result['recovery_possible']}")
    print(f"  Recommendation: {test_result['recommendation']}")
    print("✅ Consensus resistance testing working")
    
    # Test 7: Get enhanced health report with Phase 3 data
    print("\nStep 7: Getting enhanced health report...")
    
    # First register a theory
    from tiannara_core.metacognition.theory_engine import Theory, CausalClaim, EvidenceItem, EvidenceType
    
    theory = Theory(
        theory_id="theory_health_test",
        name="Test Theory",
        domain="test",
        description="Theory for health report testing",
        assumptions=["Test assumption"],
        causal_claims=[
            CausalClaim(cause="A", effect="B", strength=0.7)
        ],
        evidence_for=[
            EvidenceItem(
                evidence_id="evid_test",
                evidence_type=EvidenceType.EXPERIMENT,
                description="Test evidence",
                supports_theory=True,
                confidence=0.8,
                source="Test Source"
            )
        ]
    )
    
    resilience_system.register_theory(theory, domain="test")
    
    # Record some provenance
    resilience_system.record_provenance_step(
        theory_id="theory_health_test",
        step_type="observation",
        source="Initial observation",
        transformation="Data collection",
        confidence_before=0.0,
        confidence_after=0.6
    )
    
    # Record a contradiction
    resilience_system.record_contradiction(
        theory_a_id="theory_health_test",
        theory_b_id="theory_other",
        contradiction_type="logical",
        description="Test contradiction",
        severity=0.4
    )
    
    # Get report
    report = resilience_system.get_epistemic_health_report("theory_health_test")
    
    print(f"  Theory ID: {report['theory_id']}")
    print(f"  Domain: {report['domain']}")
    print(f"  Has provenance data: {'provenance' in report}")
    print(f"  Has contradiction data: {'contradictions' in report}")
    print(f"  Uncertainty level: {report['uncertainty_level']:.3f}")
    
    assert 'provenance' in report, "Report should include provenance"
    assert 'contradictions' in report, "Report should include contradictions"
    assert 'uncertainty_level' in report, "Report should include uncertainty level"
    print("✅ Enhanced health report working")
    
    print("\n" + "-"*80)
    print("PHASE 3 INTEGRATION TEST: PASSED ✅")
    print("-"*80)
    
    return True


def main():
    """Run all Phase 3 tests."""
    print("="*80)
    print("EPISTEMIC RESILIENCE SYSTEM - PHASE 3 TEST SUITE")
    print("="*80)
    print("\nTesting:")
    print("  1. Provenance Chain Tracker")
    print("  2. Delayed Contradiction Handler")
    print("  3. Consensus Corruption Resistance")
    print("  4. Full Phase 3 Integration")
    
    results = []
    
    try:
        results.append(("Provenance Chain Tracker", test_provenance_chain_tracker()))
    except Exception as e:
        print(f"\n❌ Provenance Chain Tracker test FAILED: {e}")
        import traceback
        traceback.print_exc()
        results.append(("Provenance Chain Tracker", False))
    
    try:
        results.append(("Delayed Contradiction Handler", test_delayed_contradiction_handler()))
    except Exception as e:
        print(f"\n❌ Delayed Contradiction Handler test FAILED: {e}")
        import traceback
        traceback.print_exc()
        results.append(("Delayed Contradiction Handler", False))
    
    try:
        results.append(("Consensus Corruption Resistance", test_consensus_corruption_resistance()))
    except Exception as e:
        print(f"\n❌ Consensus Corruption Resistance test FAILED: {e}")
        import traceback
        traceback.print_exc()
        results.append(("Consensus Corruption Resistance", False))
    
    try:
        results.append(("Phase 3 Integration", test_phase3_integration()))
    except Exception as e:
        print(f"\n❌ Phase 3 Integration test FAILED: {e}")
        import traceback
        traceback.print_exc()
        results.append(("Phase 3 Integration", False))
    
    # Summary
    print("\n" + "="*80)
    print("PHASE 3 TEST SUMMARY")
    print("="*80 + "\n")
    
    passed = sum(1 for _, result in results if result)
    total = len(results)
    
    for test_name, result in results:
        status = "✅ PASSED" if result else "❌ FAILED"
        print(f"  {test_name}: {status}")
    
    print(f"\nTotal: {passed}/{total} tests passed")
    
    if passed == total:
        print("\n🎉 ALL PHASE 3 TESTS PASSED!")
        print("\nPhase 3 Systems Operational:")
        print("  ✅ Provenance Chains - Full source traceability")
        print("  ✅ Delayed Contradiction Handling - Preserved uncertainty")
        print("  ✅ Consensus Corruption Resistance - Anti-echo-chamber mechanisms")
        return 0
    else:
        print(f"\n⚠️  {total - passed} test(s) failed")
        return 1


if __name__ == "__main__":
    exit(main())
