"""Test Lagrange Interpolation Directly."""

import sys
from pathlib import Path

project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.evaluation.reverse_engineering_evolver import ReverseEngineeringEvolver

def test_lagrange():
    """Test Lagrange interpolation on failing polynomial task."""
    
    evolver = ReverseEngineeringEvolver(seed=42)
    
    # Task 8 from debug output
    inputs = [3, 8, 7, 5, 9]
    outputs = [-11, -111, -83, -39, -143]
    test_x = 4
    expected = -23
    
    print("Testing Lagrange Interpolation")
    print("=" * 60)
    print(f"Inputs: {inputs}")
    print(f"Outputs: {outputs}")
    print(f"Test point: x={test_x}")
    print(f"Expected: {expected}")
    
    # Try Lagrange interpolation
    result = evolver._lagrange_interpolation(inputs, outputs, test_x)
    print(f"\nLagrange result: {result:.2f}")
    print(f"Error: {abs(result - expected):.2f}")
    print(f"Success: {abs(result - expected) < 0.01}")
    
    # Also try polynomial_fit (which should use Lagrange for <= 5 points)
    result2 = evolver._polynomial_fit(inputs, outputs, test_x)
    print(f"\n_polynomial_fit result: {result2:.2f}")
    print(f"Error: {abs(result2 - expected):.2f}")
    
    # Check how many unique points we have
    unique_pairs = list(set(zip(inputs, outputs)))
    print(f"\nUnique data points: {len(unique_pairs)}")
    print(f"Unique pairs: {unique_pairs}")

if __name__ == "__main__":
    test_lagrange()
