"""
Test script for Advanced Evaluation System.

Demonstrates usage and verifies all components work correctly.
Run this to validate the evaluation system before integrating with orchestrators.
"""

import sys
import os

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from tiannara_core.evaluation import Evaluator


def test_basic_evaluation():
    """Test basic evaluation with a simple function."""
    print("=" * 60)
    print("TEST 1: Basic Evaluation")
    print("=" * 60)
    
    evaluator = Evaluator()
    
    # Define a simple successful function
    def add_numbers(x, y):
        return {"output": x + y, "success": True}
    
    # Evaluate it
    result = evaluator.evaluate(add_numbers, {"x": 5, "y": 3}, runs=3)
    
    print(f"Score: {result['score']:.4f}")
    print(f"Correctness: {result['metrics']['correctness']:.4f}")
    print(f"Runtime: {result['metrics']['runtime']:.6f}s")
    print(f"Error rate: {result['metrics']['error']:.4f}")
    print(f"Stability: {result['metrics']['stability']:.4f}")
    print(f"Novelty: {result['metrics']['novelty']:.4f}")
    print(f"Outputs: {len(result['outputs'])} runs")
    print()
    
    assert result['score'] > 0, "Score should be positive for successful function"
    assert result['metrics']['correctness'] == 1.0, "Should be fully correct"
    assert result['metrics']['error'] == 0.0, "Should have no errors"
    print("✓ Basic evaluation test passed\n")


def test_error_handling():
    """Test evaluation with functions that raise exceptions."""
    print("=" * 60)
    print("TEST 2: Error Handling")
    print("=" * 60)
    
    evaluator = Evaluator()
    
    # Define a function that always fails
    def failing_function(x):
        raise ValueError("Intentional error")
    
    result = evaluator.evaluate(failing_function, {"x": 10}, runs=3)
    
    print(f"Score: {result['score']:.4f}")
    print(f"Correctness: {result['metrics']['correctness']:.4f}")
    print(f"Error rate: {result['metrics']['error']:.4f}")
    print(f"Stability: {result['metrics']['stability']:.4f}")
    print()
    
    assert result['metrics']['error'] == 1.0, "Should detect all errors"
    assert result['metrics']['correctness'] == 0.0, "Should have zero correctness"
    print("✓ Error handling test passed\n")


def test_stability_analysis():
    """Test stability measurement across consistent vs inconsistent outputs."""
    print("=" * 60)
    print("TEST 3: Stability Analysis")
    print("=" * 60)
    
    evaluator = Evaluator()
    
    # Consistent function (same output every time)
    def consistent_func(x):
        return {"output": 42, "success": True}
    
    result1 = evaluator.evaluate(consistent_func, {"x": 1}, runs=5)
    print(f"Consistent function stability: {result1['metrics']['stability']:.4f}")
    
    # Inconsistent function (different output each time)
    counter = [0]
    def inconsistent_func(x):
        counter[0] += 1
        return {"output": counter[0], "success": True}
    
    result2 = evaluator.evaluate(inconsistent_func, {"x": 1}, runs=5)
    print(f"Inconsistent function stability: {result2['metrics']['stability']:.4f}")
    print()
    
    assert result1['metrics']['stability'] > result2['metrics']['stability'], \
        "Consistent function should have higher stability"
    print("✓ Stability analysis test passed\n")


def test_novelty_tracking():
    """Test novelty detection across multiple evaluations."""
    print("=" * 60)
    print("TEST 4: Novelty Tracking")
    print("=" * 60)
    
    evaluator = Evaluator()
    
    def simple_func(x):
        return {"output": x * 2, "success": True}
    
    # First evaluation - should be maximally novel
    result1 = evaluator.evaluate(simple_func, {"x": 1}, runs=1)
    print(f"First evaluation novelty: {result1['metrics']['novelty']:.4f}")
    
    # Second evaluation with different input - should still be somewhat novel
    result2 = evaluator.evaluate(simple_func, {"x": 2}, runs=1)
    print(f"Second evaluation novelty: {result2['metrics']['novelty']:.4f}")
    
    # Third evaluation similar to second - novelty should decrease
    result3 = evaluator.evaluate(simple_func, {"x": 2}, runs=1)
    print(f"Third evaluation novelty: {result3['metrics']['novelty']:.4f}")
    print()
    
    assert result1['metrics']['novelty'] > 0, "First evaluation should have novelty"
    print("✓ Novelty tracking test passed\n")


def test_history_and_statistics():
    """Test history logging and statistical analysis."""
    print("=" * 60)
    print("TEST 5: History and Statistics")
    print("=" * 60)
    
    evaluator = Evaluator()
    
    def test_func(x):
        return {"output": x ** 2, "success": True}
    
    # Run multiple evaluations
    for i in range(10):
        evaluator.evaluate(test_func, {"x": i}, runs=2)
    
    # Get statistics
    stats = evaluator.get_history_statistics()
    print(f"Total records: {stats['total_records']}")
    print(f"Average score: {stats['average_score']:.4f}")
    print(f"Best score: {stats['best_score']:.4f}")
    print(f"Worst score: {stats['worst_score']:.4f}")
    print(f"Trend: {stats['trend']}")
    print()
    
    assert stats['total_records'] == 10, "Should have 10 records"
    assert stats['best_score'] >= stats['average_score'], "Best should be >= average"
    print("✓ History and statistics test passed\n")


def test_weighted_scoring():
    """Test custom weight configuration."""
    print("=" * 60)
    print("TEST 6: Weighted Scoring")
    print("=" * 60)
    
    # Create evaluator with custom weights emphasizing correctness
    custom_weights = {
        "correctness": 0.60,
        "efficiency": 0.10,
        "stability": 0.10,
        "novelty": 0.10,
        "error_penalty": 0.10,
    }
    
    evaluator = Evaluator(weights=custom_weights)
    
    def good_func(x):
        return {"output": x + 1, "success": True}
    
    result = evaluator.evaluate(good_func, {"x": 5}, runs=3)
    print(f"Score with custom weights: {result['score']:.4f}")
    print(f"Weights: {evaluator.scorer.get_weight_breakdown()}")
    print()
    
    assert abs(evaluator.scorer.weights['correctness'] - 0.60) < 0.01, \
        "Custom weight should be applied"
    print("✓ Weighted scoring test passed\n")


def test_integration_scenario():
    """Test complete integration scenario simulating evolution loop."""
    print("=" * 60)
    print("TEST 7: Integration Scenario (Evolution Loop Simulation)")
    print("=" * 60)
    
    evaluator = Evaluator()
    
    # Simulate evolution improving over time
    def evolving_function(x, quality=0.5):
        # Higher quality = more likely to succeed
        import random
        success = random.random() < quality
        return {
            "output": x * 2 if success else None,
            "success": success
        }
    
    scores = []
    for episode in range(20):
        # Simulate improving quality over episodes
        quality = 0.3 + (episode / 20) * 0.7  # Improves from 0.3 to 1.0
        
        result = evaluator.evaluate(
            lambda x, q=quality: evolving_function(x, q),
            {"x": 10},
            runs=3
        )
        scores.append(result['score'])
        
        if (episode + 1) % 5 == 0:
            avg_recent = sum(scores[-5:]) / 5
            print(f"Episode {episode + 1:2d}: Score={result['score']:.4f}, "
                  f"Avg(last 5)={avg_recent:.4f}")
    
    # Check for improvement trend
    first_half_avg = sum(scores[:10]) / 10
    second_half_avg = sum(scores[10:]) / 10
    
    print(f"\nFirst half average: {first_half_avg:.4f}")
    print(f"Second half average: {second_half_avg:.4f}")
    print(f"Improvement: {second_half_avg - first_half_avg:.4f}")
    
    stats = evaluator.get_history_statistics()
    print(f"Overall trend: {stats['trend']}")
    print()
    
    assert second_half_avg >= first_half_avg, \
        "System should show improvement or stability (not degradation)"
    print("✓ Integration scenario test passed\n")


if __name__ == "__main__":
    print("\n" + "=" * 60)
    print("ADVANCED EVALUATION SYSTEM - TEST SUITE")
    print("=" * 60 + "\n")
    
    try:
        test_basic_evaluation()
        test_error_handling()
        test_stability_analysis()
        test_novelty_tracking()
        test_history_and_statistics()
        test_weighted_scoring()
        test_integration_scenario()
        
        print("=" * 60)
        print("ALL TESTS PASSED ✓")
        print("=" * 60)
        print("\nThe evaluation system is ready for integration!")
        print("\nNext steps:")
        print("1. Integrate with your orchestrator/evolution loop")
        print("2. Feed metrics into causal engine")
        print("3. Use scores to guide mutation/evolution decisions")
        print("4. Run 50-100 episodes on a single domain")
        print("5. Monitor trends: score ↑, stability ↑, novelty ↓ (convergence)")
        
    except Exception as e:
        print(f"\n❌ TEST FAILED: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
