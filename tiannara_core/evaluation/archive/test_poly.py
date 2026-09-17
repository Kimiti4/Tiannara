"""Test polynomial fitting on a specific case."""

import sys
from pathlib import Path

project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.evaluation.reverse_engineering_evolver import ReverseEngineeringEvolver

# Test case from episode 4
inputs = [10, 2, 5, 6]  # After deduplication
outputs = [-293, -13, -73, -105]
x = 1
expected = -5

print("Testing polynomial fitting")
print(f"Inputs: {inputs}")
print(f"Outputs: {outputs}")
print(f"Test x: {x}")
print(f"Expected: {expected}")
print()

evolver = ReverseEngineeringEvolver(seed=125)
result = evolver._polynomial_fit(inputs, outputs, x)

print(f"Got: {result}")
print(f"Error: {abs(result - expected)}")
print()

# Try to understand what polynomial this should be
# With 4 points, we can fit a degree 3 polynomial exactly
import numpy as np

X = np.vander(inputs, 4)
y = np.array(outputs)
coeffs = np.linalg.lstsq(X, y, rcond=None)[0]

print(f"Fitted coefficients (degree 3): {coeffs}")
print(f"Coefficients rounded: {[round(c, 6) for c in coeffs]}")

# Evaluate at test point
test_result = np.polyval(coeffs, x)
print(f"NumPy result at x={x}: {test_result}")
