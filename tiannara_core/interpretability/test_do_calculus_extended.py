"""
Test Extended Do-Calculus with Counterfactual Reasoning

Validates Pearl's three rules, backdoor/frontdoor criteria, and counterfactual integration.
"""

import sys
from pathlib import Path
import numpy as np

# Add project root to path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.interpretability.do_calculus_extended import (
    DoCalculusEngine,
    DoCalculusResult,
    CounterfactualDoQuery,
    apply_do_calculus
)


def create_simple_confounder_graph():
    """Create graph: Z → X → Y, Z → Y (confounded relationship)."""
    return {
        'nodes': ['Z', 'X', 'Y'],
        'edges': [
            ('Z', 'X', 0.7),
            ('Z', 'Y', 0.5),
            ('X', 'Y', 0.8)
        ],
        'node_values': {'Z': 0.5, 'X': 0.5, 'Y': 0.5}
    }


def create_chain_graph():
    """Create graph: X → M → Y (mediation chain)."""
    return {
        'nodes': ['X', 'M', 'Y'],
        'edges': [
            ('X', 'M', 0.9),
            ('M', 'Y', 0.85)
        ],
        'node_values': {'X': 0.5, 'M': 0.5, 'Y': 0.5}
    }


def create_fork_graph():
    """Create graph: X ← Z → Y (pure confounding, no causal effect)."""
    return {
        'nodes': ['X', 'Z', 'Y'],
        'edges': [
            ('Z', 'X', 0.7),
            ('Z', 'Y', 0.6)
        ],
        'node_values': {'X': 0.5, 'Z': 0.5, 'Y': 0.5}
    }


def generate_observational_data(graph: dict, n_samples: int = 100, seed: int = 42) -> list:
    """Generate synthetic observational data from causal graph."""
    rng = np.random.RandomState(seed)
    nodes = graph['nodes']
    edges = graph['edges']
    
    # Build parent relationships
    parents = {node: [] for node in nodes}
    weights = {}
    for src, tgt, w in edges:
        parents[tgt].append((src, w))
    
    data = []
    for _ in range(n_samples):
        obs = {}
        
        # Generate values in topological order
        for node in nodes:
            if not parents[node]:
                # Root node - sample from normal
                obs[node] = rng.normal(0.5, 0.2)
            else:
                # Child node - weighted sum of parents + noise
                value = 0.5  # intercept
                for parent, weight in parents[node]:
                    value += weight * obs[parent]
                value += rng.normal(0, 0.1)  # noise
                obs[node] = value
        
        data.append(obs)
    
    return data


def test_backdoor_criterion():
    """Test 1: Backdoor adjustment for confounded relationship."""
    print("\n" + "=" * 80)
    print("TEST 1: Backdoor Criterion - Confounded Relationship")
    print("=" * 80)
    
    graph = create_simple_confounder_graph()
    engine = DoCalculusEngine()
    
    # Find adjustment set
    adjustment_set = engine.find_backdoor_adjustment_set(graph, 'X', 'Y')
    
    print(f"\nGraph: Z → X → Y, Z → Y")
    print(f"Backdoor adjustment set for X → Y: {adjustment_set}")
    
    assert adjustment_set is not None, "Should find valid adjustment set"
    assert 'Z' in adjustment_set, "Should adjust for confounder Z"
    
    print("✓ PASSED: Found correct adjustment set")
    
    # Generate data and estimate effect
    observations = generate_observational_data(graph, n_samples=200)
    result = engine.estimate_causal_effect_backdoor(observations, 'X', 'Y', adjustment_set)
    
    print(f"\nCausal effect estimate: {result.causal_effect:.4f}")
    print(f"Confidence: {result.confidence:.2f}")
    print(f"Rule applied: {result.rule_applied}")
    print(f"Formula: {result.formula}")
    
    assert result.identifiable, "Effect should be identifiable"
    assert abs(result.causal_effect) > 0.1, "Should detect non-zero effect"
    
    print("✓ PASSED: Successfully estimated causal effect via backdoor adjustment")
    return True


def test_frontdoor_criterion():
    """Test 2: Front-door criterion for mediation."""
    print("\n" + "=" * 80)
    print("TEST 2: Front-Door Criterion - Mediation Chain")
    print("=" * 80)
    
    graph = create_chain_graph()
    engine = DoCalculusEngine()
    
    # Find mediator
    mediator = engine.find_frontdoor_mediator(graph, 'X', 'Y')
    
    print(f"\nGraph: X → M → Y")
    print(f"Front-door mediator for X → Y: {mediator}")
    
    assert mediator == 'M', "Should identify M as mediator"
    
    print("✓ PASSED: Correctly identified front-door mediator")
    
    # Estimate effect
    observations = generate_observational_data(graph, n_samples=200)
    result = engine.estimate_causal_effect_frontdoor(observations, 'X', 'Y', mediator)
    
    print(f"\nCausal effect estimate: {result.causal_effect:.4f}")
    print(f"Confidence: {result.confidence:.2f}")
    print(f"Rule applied: {result.rule_applied}")
    
    assert result.identifiable, "Effect should be identifiable"
    assert result.causal_effect > 0, "Should detect positive mediated effect"
    
    print("✓ PASSED: Successfully estimated causal effect via front-door criterion")
    return True


def test_no_confounding():
    """Test 3: No adjustment needed when no confounding."""
    print("\n" + "=" * 80)
    print("TEST 3: No Confounding - Direct Causal Effect")
    print("=" * 80)
    
    graph = {
        'nodes': ['X', 'Y'],
        'edges': [('X', 'Y', 0.8)],
        'node_values': {'X': 0.5, 'Y': 0.5}
    }
    
    engine = DoCalculusEngine()
    adjustment_set = engine.find_backdoor_adjustment_set(graph, 'X', 'Y')
    
    print(f"\nGraph: X → Y (no confounders)")
    print(f"Adjustment set: {adjustment_set}")
    
    assert adjustment_set == [], "No adjustment needed for unconfounded relationship"
    
    print("✓ PASSED: Correctly identified no adjustment needed")
    
    # Estimate simple effect
    observations = generate_observational_data(graph, n_samples=200)
    result = engine.estimate_causal_effect_backdoor(observations, 'X', 'Y', [])
    
    print(f"Causal effect: {result.causal_effect:.4f}")
    assert result.identifiable, "Effect should be identifiable"
    
    print("✓ PASSED: Successfully estimated direct causal effect")
    return True


def test_counterfactual_with_do_calculus():
    """Test 4: Counterfactual query using do-calculus."""
    print("\n" + "=" * 80)
    print("TEST 4: Counterfactual Query with Do-Calculus")
    print("=" * 80)
    
    graph = create_simple_confounder_graph()
    engine = DoCalculusEngine()
    
    # Create counterfactual query
    query = CounterfactualDoQuery(
        treatment='X',
        outcome='Y',
        intervention_value=0.8,
        evidence={'Z': 0.6}
    )
    
    print(f"\nQuery: {query}")
    
    # Generate data
    observations = generate_observational_data(graph, n_samples=200)
    
    # Answer counterfactual
    result = engine.answer_counterfactual_with_do_calculus(graph, observations, query)
    
    print(f"\nIdentifiable: {result.identifiable}")
    print(f"Causal effect: {result.causal_effect:.4f}")
    print(f"Rule applied: {result.rule_applied}")
    print(f"Explanation: {result.explanation[:100]}...")
    
    assert result.identifiable, "Counterfactual should be identifiable"
    assert 'backdoor' in result.rule_applied or 'frontdoor' in result.rule_applied
    
    print("✓ PASSED: Successfully answered counterfactual using do-calculus")
    return True


def test_pearl_rule_1():
    """Test 5: Pearl's Rule 1 - Insertion/deletion of observations."""
    print("\n" + "=" * 80)
    print("TEST 5: Pearl's Rule 1 - Observation Deletion")
    print("=" * 80)
    
    # Graph where Z is independent of Y given X
    graph = {
        'nodes': ['X', 'Y', 'Z'],
        'edges': [('X', 'Y', 0.8)],  # Z is disconnected from Y
        'node_values': {'X': 0.5, 'Y': 0.5, 'Z': 0.5}
    }
    
    engine = DoCalculusEngine()
    
    # Test if we can ignore Z
    can_ignore = engine.rule_1_insertion_deletion_of_observations(
        graph, y='Y', z='Z', w='', x='X'
    )
    
    print(f"\nCan ignore observation Z? {can_ignore}")
    
    assert can_ignore, "Z should be ignorable (independent of Y given X)"
    
    print("✓ PASSED: Rule 1 correctly identifies ignorable observations")
    return True


def test_convenience_function():
    """Test 6: Convenience function apply_do_calculus."""
    print("\n" + "=" * 80)
    print("TEST 6: Convenience Function - apply_do_calculus")
    print("=" * 80)
    
    graph = create_simple_confounder_graph()
    observations = generate_observational_data(graph, n_samples=200)
    
    result = apply_do_calculus(graph, observations, 'X', 'Y')
    
    print(f"\nIdentifiable: {result.identifiable}")
    print(f"Causal effect: {result.causal_effect:.4f}")
    print(f"Rule applied: {result.rule_applied}")
    print(f"Adjustment set: {result.adjustment_set}")
    
    assert result.identifiable, "Effect should be identifiable"
    assert len(result.adjustment_set) > 0, "Should have adjustment variables"
    
    print("✓ PASSED: Convenience function works correctly")
    return True


def run_all_tests():
    """Run all do-calculus tests."""
    print("\n" + "=" * 80)
    print("EXTENDED DO-CALCULUS TEST SUITE")
    print("=" * 80)
    
    tests = [
        ("Backdoor Criterion", test_backdoor_criterion),
        ("Front-Door Criterion", test_frontdoor_criterion),
        ("No Confounding", test_no_confounding),
        ("Counterfactual with Do-Calculus", test_counterfactual_with_do_calculus),
        ("Pearl's Rule 1", test_pearl_rule_1),
        ("Convenience Function", test_convenience_function),
    ]
    
    results = []
    for name, test_func in tests:
        try:
            passed = test_func()
            results.append((name, passed))
        except Exception as e:
            print(f"\n✗ FAILED: {name}")
            print(f"Error: {e}")
            import traceback
            traceback.print_exc()
            results.append((name, False))
    
    # Summary
    print("\n" + "=" * 80)
    print("TEST SUMMARY")
    print("=" * 80)
    
    passed_count = sum(1 for _, passed in results if passed)
    total_count = len(results)
    
    for name, passed in results:
        status = "✓ PASSED" if passed else "✗ FAILED"
        print(f"{status}: {name}")
    
    print(f"\nTotal: {passed_count}/{total_count} tests passing ({passed_count/total_count*100:.0f}% success rate)")
    
    if passed_count == total_count:
        print("\n🎉 ALL TESTS PASSED! Extended do-calculus implementation validated.")
    else:
        print(f"\n⚠️  {total_count - passed_count} test(s) failed. Review implementation.")
    
    return passed_count == total_count


if __name__ == "__main__":
    success = run_all_tests()
    sys.exit(0 if success else 1)
