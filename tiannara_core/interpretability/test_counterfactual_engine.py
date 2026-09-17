"""
Counterfactual Engine Test Script

Demonstrates counterfactual reasoning capabilities including:
- What-if intervention simulation
- Minimal change optimization
- Contrastive explanations

Usage:
    python tiannara_core/interpretability/test_counterfactual_engine.py
"""

import sys
from pathlib import Path
import numpy as np

# Add project root to path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

try:
    from tiannara_core.interpretability.counterfactual_engine import (
        CounterfactualEngine,
        CounterfactualQuery,
        answer_what_if
    )
    COUNTERFACTUAL_AVAILABLE = True
except ImportError as e:
    print(f"WARNING: Counterfactual module not available: {e}")
    COUNTERFACTUAL_AVAILABLE = False


def create_sample_ecm_graph():
    """Create a sample ECM graph for testing."""
    graph = {
        'nodes': [
            'skill_memory',
            'pattern_recognition', 
            'cross_domain_transfer',
            'solution_quality',
            'adaptation_speed',
            'final_outcome'
        ],
        'edges': [
            ('skill_memory', 'pattern_recognition', 0.8),
            ('skill_memory', 'cross_domain_transfer', 0.6),
            ('pattern_recognition', 'solution_quality', 0.9),
            ('cross_domain_transfer', 'adaptation_speed', 0.7),
            ('solution_quality', 'final_outcome', 0.85),
            ('adaptation_speed', 'final_outcome', 0.75)
        ],
        'node_values': {
            'skill_memory': 0.5,
            'pattern_recognition': 0.5,
            'cross_domain_transfer': 0.5,
            'solution_quality': 0.5,
            'adaptation_speed': 0.5,
            'final_outcome': 0.5
        },
        'outcome_node': 'final_outcome'
    }
    
    return graph


def test_intervention_simulation():
    """Test what-if intervention simulation."""
    print("=" * 80)
    print("Intervention Simulation Test")
    print("=" * 80)
    
    graph = create_sample_ecm_graph()
    engine = CounterfactualEngine()
    
    # Compute original outcome
    original_outcome = engine._compute_outcome(graph)
    print(f"\n1. Original outcome: {original_outcome:.3f}")
    
    # Test 1: Increase skill_memory
    print("\n2. What if skill_memory increases by 0.3?")
    query1 = CounterfactualQuery(
        query_type='intervention',
        target_variable='final_outcome',
        intervention={'skill_memory': 0.8}
    )
    
    result1 = engine.answer_counterfactual(graph, query1)
    print(result1.summary())
    
    # Test 2: Decrease multiple nodes
    print("\n3. What if pattern_recognition decreases and cross_domain_transfer increases?")
    query2 = CounterfactualQuery(
        query_type='intervention',
        target_variable='final_outcome',
        intervention={
            'pattern_recognition': 0.3,
            'cross_domain_transfer': 0.9
        }
    )
    
    result2 = engine.answer_counterfactual(graph, query2)
    print(result2.summary())
    
    # Test 3: Use convenience function
    print("\n4. Using convenience function answer_what_if()...")
    result3 = answer_what_if(graph, {'solution_quality': 0.9})
    print(result3.summary())
    
    print("\n" + "=" * 80)
    print("Intervention Simulation Test Completed!")
    print("=" * 80)


def test_minimal_change():
    """Test minimal change optimization."""
    print("\n" + "=" * 80)
    print("Minimal Change Optimization Test")
    print("=" * 80)
    
    graph = create_sample_ecm_graph()
    engine = CounterfactualEngine()
    
    current_outcome = engine._compute_outcome(graph)
    desired_outcome = 0.8
    
    print(f"\n1. Current outcome: {current_outcome:.3f}")
    print(f"   Desired outcome: {desired_outcome:.3f}")
    print(f"   Target change: {desired_outcome - current_outcome:+.3f}")
    
    # Find minimal intervention
    print("\n2. Finding minimal intervention...")
    minimal = engine.find_minimal_intervention(
        graph,
        current_outcome=current_outcome,
        desired_outcome=desired_outcome
    )
    
    if minimal:
        print(f"\n3. Minimal Intervention Found:")
        print("-" * 80)
        print(f"   {minimal}")
        print(f"   Total magnitude: {minimal.total_magnitude:.3f}")
        print(f"   Feasibility: {minimal.feasibility_score:.2f}/1.00")
        print(f"   Affected nodes: {len(minimal.affected_nodes)}")
        
        # Verify by applying
        intervened_graph = engine._apply_intervention(graph, minimal.changes)
        verified_outcome = engine._compute_outcome(intervened_graph)
        print(f"\n4. Verification:")
        print(f"   Predicted outcome: {minimal.predicted_outcome:.3f}")
        print(f"   Verified outcome: {verified_outcome:.3f}")
        print(f"   Error: {abs(verified_outcome - desired_outcome):.4f}")
    else:
        print("   No feasible intervention found")
    
    print("\n" + "=" * 80)
    print("Minimal Change Test Completed!")
    print("=" * 80)


def test_contrastive_explanation():
    """Test contrastive explanations."""
    print("\n" + "=" * 80)
    print("Contrastive Explanation Test")
    print("=" * 80)
    
    graph = create_sample_ecm_graph()
    engine = CounterfactualEngine()
    
    current_outcome = engine._compute_outcome(graph)
    contrast_outcome = 0.3  # Lower outcome
    
    print(f"\n1. Why was outcome {current_outcome:.3f} instead of {contrast_outcome:.3f}?")
    
    query = CounterfactualQuery(
        query_type='contrastive',
        target_variable='final_outcome',
        desired_outcome=current_outcome,
        contrast_outcome=contrast_outcome
    )
    
    result = engine.answer_counterfactual(graph, query)
    
    print(f"\n2. Contrastive Explanation:")
    print("-" * 80)
    print(result.explanation)
    print(f"\n   Required changes: {result.interventions_applied}")
    print(f"   Confidence: {result.confidence:.2f}")
    
    print("\n" + "=" * 80)
    print("Contrastive Explanation Test Completed!")
    print("=" * 80)


def test_complex_scenario():
    """Test with more complex scenario."""
    print("\n" + "=" * 80)
    print("Complex Scenario Test")
    print("=" * 80)
    
    # Create ML pipeline graph
    ml_graph = {
        'nodes': [
            'data_quality',
            'feature_engineering',
            'model_complexity',
            'training_epochs',
            'validation_accuracy',
            'test_performance'
        ],
        'edges': [
            ('data_quality', 'feature_engineering', 0.9),
            ('data_quality', 'model_complexity', 0.3),
            ('feature_engineering', 'validation_accuracy', 0.8),
            ('model_complexity', 'validation_accuracy', 0.6),
            ('training_epochs', 'validation_accuracy', 0.7),
            ('validation_accuracy', 'test_performance', 0.85)
        ],
        'node_values': {
            'data_quality': 0.6,
            'feature_engineering': 0.5,
            'model_complexity': 0.5,
            'training_epochs': 0.5,
            'validation_accuracy': 0.5,
            'test_performance': 0.5
        },
        'outcome_node': 'test_performance'
    }
    
    engine = CounterfactualEngine()
    
    current = engine._compute_outcome(ml_graph)
    print(f"\n1. ML Pipeline - Current test performance: {current:.3f}")
    
    # What if we improve data quality?
    print("\n2. What if data_quality improves from 0.6 to 0.9?")
    result = answer_what_if(ml_graph, {'data_quality': 0.9})
    print(result.summary())
    
    # Find minimal changes to achieve 0.8 performance
    print(f"\n3. How to achieve 0.8 test performance?")
    minimal = engine.find_minimal_intervention(
        ml_graph,
        current_outcome=current,
        desired_outcome=0.8
    )
    
    if minimal:
        print(f"   {minimal}")
    
    print("\n" + "=" * 80)
    print("Complex Scenario Test Completed!")
    print("=" * 80)


if __name__ == "__main__":
    if not COUNTERFACTUAL_AVAILABLE:
        print("WARNING: Cannot run tests - Counterfactual module not available")
        sys.exit(1)
    
    try:
        test_intervention_simulation()
        test_minimal_change()
        test_contrastive_explanation()
        test_complex_scenario()
        
        print("\n" + "=" * 80)
        print("ALL TESTS PASSED!")
        print("=" * 80)
        
    except Exception as e:
        print(f"\nERROR: Test failed with error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
