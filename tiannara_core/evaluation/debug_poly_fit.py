"""Debug Polynomial Fitting in RE Evolver."""

import sys
from pathlib import Path
import numpy as np

project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.evaluation.reverse_engineering_evolver import ReverseEngineeringEvolver

def test_polynomial_fitting():
    """Test polynomial fitting on known quadratic function."""
    
    evolver = ReverseEngineeringEvolver(seed=42)
    
    # Test 1: Simple quadratic f(x) = x² + 2x + 1
    print("Test 1: Quadratic f(x) = x² + 2x + 1")
    inputs = [1, 2, 3, 4, 5]
    outputs = [4, 9, 16, 25, 36]  # (x+1)²
    
    print(f"  Inputs: {inputs}")
    print(f"  Outputs: {outputs}")
    
    # Try polynomial fit at x=6 (should be 49)
    result = evolver._polynomial_fit(inputs, outputs, 6)
    expected = 49
    
    print(f"  Predicted f(6): {result:.2f}")
    print(f"  Expected: {expected}")
    print(f"  Error: {abs(result - expected):.4f}")
    print(f"  Status: {'✅ PASS' if abs(result - expected) < 0.01 else '❌ FAIL'}\n")
    
    # Test 2: Cubic f(x) = x³ - x
    print("Test 2: Cubic f(x) = x³ - x")
    inputs = [0, 1, 2, 3, 4]
    outputs = [0, 0, 6, 24, 60]
    
    print(f"  Inputs: {inputs}")
    print(f"  Outputs: {outputs}")
    
    result = evolver._polynomial_fit(inputs, outputs, 5)
    expected = 120  # 5³ - 5 = 125 - 5 = 120
    
    print(f"  Predicted f(5): {result:.2f}")
    print(f"  Expected: {expected}")
    print(f"  Error: {abs(result - expected):.4f}")
    print(f"  Status: {'✅ PASS' if abs(result - expected) < 0.01 else '❌ FAIL'}\n")
    
    # Test 3: Check R² calculation
    print("Test 3: R² Calculation for Quadratic")
    r_squared = evolver._check_polynomial_fit([1, 2, 3, 4, 5], [4, 9, 16, 25, 36])
    print(f"  R²: {r_squared:.4f}")
    print(f"  Status: {'✅ PASS (R² > 0.95)' if r_squared > 0.95 else '❌ FAIL'}\n")
    
    # Test 4: Strategy selection
    print("Test 4: Strategy Selection for Polynomial Data")
    strategy = evolver._select_best_strategy([1, 2, 3, 4, 5], [4, 9, 16, 25, 36], "polynomial")
    print(f"  Selected strategy: {strategy}")
    print(f"  Status: {'✅ PASS' if strategy == 'polynomial_fit' else '❌ FAIL'}\n")

if __name__ == "__main__":
    test_polynomial_fitting()
