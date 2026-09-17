"""
Test causal depth integration with hypothesis ranking system.

Validates that theories are now ranked by:
- Predictive accuracy (45%)
- Causal depth (40%) 
- Epistemic resilience (15%)

This prevents correlation dominance and promotes explanatory truthfulness.
"""

import sys
from pathlib import Path

# Add project root to path
project_root = Path(__file__).parent
sys.path.insert(0, str(project_root))

from tiannara_core.metacognition.epistemic_resilience import EpistemicResilienceSystem
from tiannara_core.metacognition.theory_engine import Theory, CausalClaim, EvidenceItem, EvidenceType


def test_causal_depth_integration():
    """Test that causal depth affects theory ranking."""
    
    print("=" * 80)
    print("CAUSAL DEPTH INTEGRATION TEST")
    print("=" * 80)
    
    # Initialize system
    system = EpistemicResilienceSystem(
        causal_weight=0.40,
        predictive_weight=0.45,
        resilience_weight=0.15
    )
    
    # Create two theories: one correlational, one causal
    correlational_theory = Theory(
        theory_id="correlation_only",
        name="Ice Cream-Drowning Correlation",
        domain="public_health",
        description="Ice cream sales correlate with drowning deaths"
    )
    correlational_theory.causal_claims.append(CausalClaim(
        cause="ice_cream_sales",
        effect="drowning_deaths",
        strength=0.9,
        direction="positive",
        mechanism=None,  # No mechanism - just correlation
        confidence=0.6
    ))
    correlational_theory.evidence_for.append(EvidenceItem(
        evidence_id="e1",
        evidence_type=EvidenceType.STATISTICAL_CORRELATION,
        description="Strong statistical correlation observed",
        supports_theory=True,
        confidence=0.9,
        source="statistical_analysis"
    ))
    
    causal_theory = Theory(
        theory_id="causal_mechanism",
        name="Temperature-Mediated Drowning Risk",
        domain="public_health",
        description="High temperature causes both increased ice cream sales AND swimming activity"
    )
    causal_theory.causal_claims.append(CausalClaim(
        cause="high_temperature",
        effect="increased_swimming",
        strength=0.85,
        direction="positive",
        mechanism="Heat increases recreational water activities",
        confidence=0.9
    ))
    causal_theory.causal_claims.append(CausalClaim(
        cause="increased_swimming",
        effect="drowning_risk",
        strength=0.8,
        direction="positive",
        mechanism="More swimmers increases absolute drowning count",
        confidence=0.85
    ))
    causal_theory.evidence_for.append(EvidenceItem(
        evidence_id="e2",
        evidence_type=EvidenceType.EXPERIMENT,
        description="Controlled studies show temperature drives both variables",
        supports_theory=True,
        confidence=0.95,
        source="controlled_experiment"
    ))
    
    theories = {
        "correlation_only": correlational_theory,
        "causal_mechanism": causal_theory
    }
    
    # Add hypotheses to competition
    system.hypothesis_manager.add_hypothesis("correlation_only", "public_health", 0.5)
    system.hypothesis_manager.add_hypothesis("causal_mechanism", "public_health", 0.5)
    
    # Register causal chains for evaluation
    from tiannara_core.causal.causal_depth_engine import CausalChain, CausalMechanism, CausalLinkType
    
    # Register correlational theory (weak causal structure)
    corr_mechanisms = []
    for claim in correlational_theory.causal_claims:
        mechanism = CausalMechanism(
            mechanism_id=f"{claim.cause}_to_{claim.effect}",
            description=claim.mechanism or f"{claim.cause} correlates with {claim.effect}",
            link_type=CausalLinkType.SPURIOUS,  # Mark as potentially spurious
            strength=claim.strength,
            evidence_count=len(correlational_theory.evidence_for),
            intervention_tests=0,  # No interventions tested
            intervention_successes=0,
            counterfactual_tests=0,
            counterfactual_coherent=0
        )
        corr_mechanisms.append(mechanism)
    
    corr_chain = CausalChain(
        chain_id="chain_correlation_only",
        cause=correlational_theory.causal_claims[0].cause if correlational_theory.causal_claims else "unknown",
        effect=correlational_theory.causal_claims[-1].effect if correlational_theory.causal_claims else "unknown",
        mechanisms=corr_mechanisms,
        temporal_valid=True,
        compression_ratio=0.3  # Low compression - just memorizes correlation
    )
    system.causal_depth_engine.register_causal_chain("correlation_only", corr_chain)
    
    # Register causal theory (strong causal structure)
    causal_mechanisms = []
    for claim in causal_theory.causal_claims:
        mechanism = CausalMechanism(
            mechanism_id=f"{claim.cause}_to_{claim.effect}",
            description=claim.mechanism or f"{claim.cause} causes {claim.effect}",
            link_type=CausalLinkType.DIRECT,
            strength=claim.strength,
            evidence_count=len(causal_theory.evidence_for),
            intervention_tests=2,  # Has intervention tests
            intervention_successes=2,  # All successful
            counterfactual_tests=2,
            counterfactual_coherent=2
        )
        causal_mechanisms.append(mechanism)
    
    causal_chain = CausalChain(
        chain_id="chain_causal_mechanism",
        cause=causal_theory.causal_claims[0].cause if causal_theory.causal_claims else "unknown",
        effect=causal_theory.causal_claims[-1].effect if causal_theory.causal_claims else "unknown",
        mechanisms=causal_mechanisms,
        temporal_valid=True,
        compression_ratio=0.8  # High compression - explains multiple phenomena
    )
    system.causal_depth_engine.register_causal_chain("causal_mechanism", causal_chain)
    
    # Simulate predictive scores (both predict well)
    predictive_scores = {
        "correlation_only": 0.90,  # High prediction from correlation
        "causal_mechanism": 0.85   # Slightly lower but still good
    }
    
    # Simulate resilience scores (similar)
    resilience_scores = {
        "correlation_only": 0.7,
        "causal_mechanism": 0.75
    }
    
    # Get traditional ranking (by probability only)
    traditional_ranking = system.hypothesis_manager.get_ranking("public_health")
    print("\n📊 TRADITIONAL RANKING (Probability Only):")
    for i, (tid, prob) in enumerate(traditional_ranking, 1):
        print(f"   {i}. {tid}: {prob:.3f}")
    
    # Get causal-enhanced ranking
    print("\nDebug: Checking registered causal chains...")
    print(f"   Registered theories: {list(system.causal_depth_engine.causal_chains.keys())}")
    
    enhanced_ranking = system.hypothesis_manager.get_causal_enhanced_ranking(
        domain="public_health",
        theories=theories,
        predictive_scores=predictive_scores,
        resilience_scores=resilience_scores,
        causal_weight=0.40,
        predictive_weight=0.45,
        resilience_weight=0.15
    )
    
    print("\n🔬 CAUSAL-ENHANCED RANKING (Predictive + Causal + Resilience):")
    for i, (tid, score) in enumerate(enhanced_ranking, 1):
        # Get individual components for display
        pred = predictive_scores.get(tid, 0.5)
        res = resilience_scores.get(tid, 0.5)
        
        # Calculate causal score
        theory = theories[tid]
        try:
            causal_eval = system.causal_depth_engine.evaluate_theory(theory, pred)
            causal = causal_eval.causal_depth
        except:
            causal = 0.5
        
        print(f"   {i}. {tid}: {score:.3f}")
        print(f"      ├─ Predictive: {pred:.3f} × 0.45 = {pred * 0.45:.3f}")
        print(f"      ├─ Causal:     {causal:.3f} × 0.40 = {causal * 0.40:.3f}")
        print(f"      └─ Resilience: {res:.3f} × 0.15 = {res * 0.15:.3f}")
    
    # Verify causal theory ranks higher
    top_theory = enhanced_ranking[0][0] if enhanced_ranking else None
    
    print("\n" + "=" * 80)
    if top_theory == "causal_mechanism":
        print("✅ SUCCESS: Causal theory ranks higher than correlational theory!")
        print("   This demonstrates prevention of shortcut intelligence.")
    else:
        print("⚠️  WARNING: Correlational theory still ranks higher")
        print("   May need to adjust weights or improve causal evaluation")
    print("=" * 80)
    
    return top_theory == "causal_mechanism"


def test_uncertainty_reserve():
    """Test that uncertainty mass is properly maintained."""
    
    print("\n" + "=" * 80)
    print("UNCERTAINTY RESERVE TEST")
    print("=" * 80)
    
    system = EpistemicResilienceSystem()
    
    # Add single theory
    system.hypothesis_manager.add_hypothesis("theory_a", "test_domain", 0.8)
    
    # Check uncertainty mass
    uncertainty = system.hypothesis_manager.get_uncertainty_mass("test_domain")
    
    print(f"\n📊 Uncertainty Reserve: {uncertainty:.3f}")
    print(f"   Expected: 0.150 (15% reserved for unknown explanations)")
    
    # Get ranking
    ranking = system.hypothesis_manager.get_ranking("test_domain")
    total_probability = sum(prob for _, prob in ranking)
    
    print(f"\n📊 Total Theory Probability: {total_probability:.3f}")
    print(f"   Expected: ≤ 0.850 (1.0 - 0.15)")
    
    success = abs(uncertainty - 0.15) < 0.01 and total_probability <= 0.85
    
    if success:
        print("\n✅ SUCCESS: Uncertainty reserve properly maintained!")
        print("   System can represent 'explanations not yet discovered'")
    else:
        print("\n⚠️  WARNING: Uncertainty reserve not working as expected")
    
    print("=" * 80)
    
    return success


def test_minimum_hypotheses():
    """Test that minimum competing hypotheses are enforced."""
    
    print("\n" + "=" * 80)
    print("MINIMUM HYPOTHESES ENFORCEMENT TEST")
    print("=" * 80)
    
    system = EpistemicResilienceSystem()
    
    # Add single theory
    system.hypothesis_manager.add_hypothesis("dominant_theory", "paradigm_domain", 0.9)
    
    print("\n📊 Before enforcement:")
    ranking = system.hypothesis_manager.get_ranking("paradigm_domain")
    print(f"   Number of hypotheses: {len(ranking)}")
    
    # Enforce minimum 2 hypotheses
    system.hypothesis_manager.ensure_minimum_hypotheses("paradigm_domain", min_count=2)
    
    print("\n📊 After enforcement:")
    ranking = system.hypothesis_manager.get_ranking("paradigm_domain")
    print(f"   Number of hypotheses: {len(ranking)}")
    for tid, prob in ranking:
        print(f"      - {tid}: {prob:.3f}")
    
    success = len(ranking) >= 2
    
    if success:
        print("\n✅ SUCCESS: Minimum hypotheses enforced!")
        print("   Prevents dogmatic single-theory dominance")
    else:
        print("\n⚠️  WARNING: Failed to enforce minimum hypotheses")
    
    print("=" * 80)
    
    return success


if __name__ == "__main__":
    print("\n" + "=" * 80)
    print("TESTING CAUSAL DEPTH INTEGRATION WITH HYPOTHESIS RANKING")
    print("=" * 80 + "\n")
    
    results = []
    
    # Test 1: Causal depth affects ranking
    results.append(("Causal Depth Integration", test_causal_depth_integration()))
    
    # Test 2: Uncertainty reserve
    results.append(("Uncertainty Reserve", test_uncertainty_reserve()))
    
    # Test 3: Minimum hypotheses
    results.append(("Minimum Hypotheses", test_minimum_hypotheses()))
    
    # Summary
    print("\n" + "=" * 80)
    print("TEST SUMMARY")
    print("=" * 80)
    
    passed = sum(1 for _, result in results if result)
    total = len(results)
    
    for test_name, result in results:
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"   {status}: {test_name}")
    
    print(f"\n   Overall: {passed}/{total} tests passed")
    print("=" * 80)
    
    if passed == total:
        print("\n🎉 ALL TESTS PASSED!")
        print("   Causal depth integration is working correctly.")
        sys.exit(0)
    else:
        print(f"\n⚠️  {total - passed} test(s) failed")
        sys.exit(1)
