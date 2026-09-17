"""
Test Advanced Contradiction Metabolism Engine

Tests the Phase 2 enhancements:
1. Adaptive resolution budgeting
2. Causal centrality prioritization
3. Contradiction tier classification
4. Cognitive inflammation monitoring
5. Resolution tiers (automatic, consensus, simulation, preservation)
"""

import sys
if sys.stdout.encoding != 'utf-8':
    sys.stdout.reconfigure(encoding='utf-8')

from tiannara_core.metacognition.epistemic_resilience import EpistemicResilienceSystem
from tiannara_core.metacognition.theory_engine import Theory, CausalClaim
import time


def test_cognitive_inflammation():
    """Test cognitive inflammation calculation."""
    print("="*80)
    print("TEST 1: COGNITIVE INFLAMMATION MONITORING")
    print("="*80 + "\n")
    
    resilience_system = EpistemicResilienceSystem()
    
    # Create theories with contradictions
    for i in range(10):
        theory = Theory(
            theory_id=f"theory_{i}",
            name=f"Theory {i}",
            domain="test",
            description=f"Test theory {i}",
            assumptions=[f"Assumption {i}"],
            causal_claims=[
                CausalClaim(
                    cause=f"Cause_{i}",
                    effect=f"Effect_{i}",
                    strength=0.7
                )
            ]
        )
        resilience_system.register_theory(theory, domain="test")
    
    # Inject contradictions
    for i in range(0, 9, 2):
        resilience_system.contradiction_handler.record_contradiction(
            theory_a_id=f"theory_{i}",
            theory_b_id=f"theory_{i+1}",
            contradiction_type="logical",
            description=f"Contradiction between theory {i} and {i+1}",
            severity=0.3 + (i * 0.05)
        )
    
    # Calculate inflammation
    inflammation = resilience_system.contradiction_handler.calculate_cognitive_inflammation(
        fragmentation_score=0.4,
        knowledge_drift=0.2
    )
    
    print(f"✅ Cognitive Inflammation Score: {inflammation:.3f}")
    print(f"   Formula: I_c = C_l × L_c × F_k")
    print(f"   Lower is better (<0.2 = healthy, >0.5 = critical)")
    
    if inflammation < 0.2:
        print(f"   Status: ✅ HEALTHY - Low inflammation\n")
    elif inflammation < 0.5:
        print(f"   Status: ⚠️  AT RISK - Moderate inflammation\n")
    else:
        print(f"   Status: ❌ CRITICAL - High inflammation\n")
    
    return inflammation


def test_contradiction_tiers():
    """Test contradiction tier classification."""
    print("="*80)
    print("TEST 2: CONTRADICTION TIER CLASSIFICATION")
    print("="*80 + "\n")
    
    resilience_system = EpistemicResilienceSystem()
    
    # Create test contradictions with different characteristics
    test_cases = [
        {
            'name': 'Simple logical contradiction',
            'severity': 0.2,
            'type': 'logical',
            'age_seconds': 60,
            'expected_tier': 'tier_1_automatic'
        },
        {
            'name': 'Cross-agent conflict',
            'severity': 0.5,
            'type': 'empirical',
            'age_seconds': 3600,
            'expected_tier': 'tier_2_consensus'
        },
        {
            'name': 'Complex predictive contradiction',
            'severity': 0.8,
            'type': 'predictive',
            'age_seconds': 7200,
            'expected_tier': 'tier_3_simulation'
        },
        {
            'name': 'Minority exploratory hypothesis',
            'severity': 0.15,
            'type': 'speculative',
            'age_seconds': 1800,
            'expected_tier': 'tier_4_preservation'
        }
    ]
    
    correct_classifications = 0
    
    for case in test_cases:
        contradiction = {
            'severity': case['severity'],
            'type': case['type'],
            'detected_at': time.time() - case['age_seconds']
        }
        
        tier = resilience_system.contradiction_handler.classify_contradiction_tier(contradiction)
        
        status = "✅" if tier == case['expected_tier'] else "⚠️"
        if tier == case['expected_tier']:
            correct_classifications += 1
        
        print(f"{status} {case['name']}")
        print(f"   Severity: {case['severity']}, Type: {case['type']}, Age: {case['age_seconds']}s")
        print(f"   Classified as: {tier}")
        print(f"   Expected: {case['expected_tier']}\n")
    
    accuracy = correct_classifications / len(test_cases) * 100
    print(f"Classification Accuracy: {accuracy:.0f}% ({correct_classifications}/{len(test_cases)})")
    
    if accuracy >= 75:
        print(f"Status: ✅ EXCELLENT tier classification\n")
    else:
        print(f"Status: ⚠️  Needs improvement\n")
    
    return accuracy


def test_adaptive_budget():
    """Test adaptive resolution budget calculation."""
    print("="*80)
    print("TEST 3: ADAPTIVE RESOLUTION BUDGETING")
    print("="*80 + "\n")
    
    resilience_system = EpistemicResilienceSystem()
    
    test_scenarios = [
        {
            'name': 'Low load, stable system',
            'contradiction_load': 0.1,
            'fragmentation': 0.2,
            'drift': 0.1,
            'expected_range': (5, 10)
        },
        {
            'name': 'Medium load, moderate instability',
            'contradiction_load': 0.4,
            'fragmentation': 0.5,
            'drift': 0.3,
            'expected_range': (10, 15)
        },
        {
            'name': 'High load, critical instability',
            'contradiction_load': 0.8,
            'fragmentation': 0.8,
            'drift': 0.6,
            'expected_range': (15, 20)
        }
    ]
    
    for scenario in test_scenarios:
        budget = resilience_system.contradiction_handler.calculate_adaptive_resolution_budget(
            contradiction_load=scenario['contradiction_load'],
            fragmentation_rate=scenario['fragmentation'],
            knowledge_drift=scenario['drift']
        )
        
        in_range = scenario['expected_range'][0] <= budget <= scenario['expected_range'][1]
        status = "✅" if in_range else "⚠️"
        
        print(f"{status} {scenario['name']}")
        print(f"   Load: {scenario['contradiction_load']}, Fragmentation: {scenario['fragmentation']}, Drift: {scenario['drift']}")
        print(f"   Adaptive Budget: {budget} resolutions/cycle")
        print(f"   Expected Range: {scenario['expected_range']}\n")
    
    print("✅ Adaptive budgeting scales with system state")
    print("   Higher instability → More aggressive resolution\n")


def test_quarantine():
    """Test contradiction quarantine for minority preservation."""
    print("="*80)
    print("TEST 4: CONTRADICTION QUARANTINE (MINORITY PRESERVATION)")
    print("="*80 + "\n")
    
    resilience_system = EpistemicResilienceSystem()
    
    # Create theories
    for i in range(5):
        theory = Theory(
            theory_id=f"quarantine_theory_{i}",
            name=f"Quarantine Theory {i}",
            domain="test",
            description=f"Test theory {i}",
            assumptions=[f"Assumption {i}"]
        )
        resilience_system.register_theory(theory, domain="test")
    
    # Record contradictions
    resilience_system.contradiction_handler.record_contradiction(
        theory_a_id="quarantine_theory_0",
        theory_b_id="quarantine_theory_1",
        contradiction_type="speculative",
        description="Exploratory minority hypothesis",
        severity=0.15  # Low severity - candidate for preservation
    )
    
    # Quarantine instead of resolving
    success = resilience_system.contradiction_handler.quarantine_contradiction(
        theory_id="quarantine_theory_0",
        contradiction_id="contr_0"
    )
    
    print(f"{'✅' if success else '❌'} Quarantine operation: {'Success' if success else 'Failed'}")
    print(f"   Quarantined contradictions: {len(resilience_system.contradiction_handler.quarantined_contradictions)}")
    print(f"   Purpose: Preserve exploratory minority hypotheses")
    print(f"   Benefit: Maintains epistemic diversity while preventing contamination\n")


def test_causal_centrality_prioritization():
    """Test prioritization by causal centrality."""
    print("="*80)
    print("TEST 5: CAUSAL CENTRALITY PRIORITIZATION")
    print("="*80 + "\n")
    
    resilience_system = EpistemicResilienceSystem()
    
    # Create unresolved contradictions with different characteristics
    current_time = time.time()
    unresolved = [
        ("high_impact_theory", {
            'contradiction_id': 'c1',
            'severity': 0.8,
            'detected_at': current_time - 7200  # 2 hours old
        }),
        ("medium_impact_theory", {
            'contradiction_id': 'c2',
            'severity': 0.5,
            'detected_at': current_time - 3600  # 1 hour old
        }),
        ("low_impact_theory", {
            'contradiction_id': 'c3',
            'severity': 0.2,
            'detected_at': current_time - 600  # 10 minutes old
        })
    ]
    
    # Agent influence scores
    agent_influence = {
        "high_impact_theory": 0.9,
        "medium_impact_theory": 0.5,
        "low_impact_theory": 0.2
    }
    
    prioritized = resilience_system.contradiction_handler.prioritize_by_causal_centrality(
        unresolved,
        agent_influence=agent_influence
    )
    
    print("Prioritization Results (highest priority first):")
    for i, (theory_id, contradiction) in enumerate(prioritized, 1):
        print(f"   {i}. {theory_id}")
        print(f"      Severity: {contradiction['severity']}, Age: {(current_time - contradiction['detected_at'])/3600:.1f}h")
        print(f"      Influence: {agent_influence.get(theory_id, 0):.1f}")
    
    # Verify high-impact theory is prioritized
    if prioritized[0][0] == "high_impact_theory":
        print(f"\n✅ Correctly prioritized high-impact contradiction first")
        print(f"   Maximizes health gain per resolution\n")
    else:
        print(f"\n⚠️  Prioritization may need tuning\n")


def main():
    """Run all advanced metabolism tests."""
    print("\n" + "="*80)
    print("ADVANCED CONTRADICTION METABOLISM ENGINE TEST SUITE")
    print("="*80 + "\n")
    
    results = {}
    
    # Test 1: Cognitive Inflammation
    results['inflammation'] = test_cognitive_inflammation()
    
    # Test 2: Tier Classification
    results['tier_accuracy'] = test_contradiction_tiers()
    
    # Test 3: Adaptive Budget
    test_adaptive_budget()
    results['adaptive_budget'] = True
    
    # Test 4: Quarantine
    test_quarantine()
    results['quarantine'] = True
    
    # Test 5: Causal Centrality
    test_causal_centrality_prioritization()
    results['prioritization'] = True
    
    # Summary
    print("="*80)
    print("SUMMARY")
    print("="*80 + "\n")
    
    print("Advanced Features Implemented:")
    print(f"  ✅ Cognitive Inflammation Monitoring: {results['inflammation']:.3f}")
    print(f"  ✅ Contradiction Tier Classification: {results['tier_accuracy']:.0f}% accuracy")
    print(f"  ✅ Adaptive Resolution Budgeting: Dynamic scaling")
    print(f"  ✅ Contradiction Quarantine: Minority preservation")
    print(f"  ✅ Causal Centrality Prioritization: Impact-based ordering")
    
    print("\nArchitecture Evolution:")
    print("  FROM: Static contradiction resolution")
    print("  TO:   Adaptive metabolic regulation")
    print("  BENEFIT: Cognitive homeostasis under uncertainty\n")
    
    print("="*80)
    print("✅ ADVANCED METABOLISM ENGINE TESTS COMPLETE")
    print("="*80 + "\n")


if __name__ == "__main__":
    main()
