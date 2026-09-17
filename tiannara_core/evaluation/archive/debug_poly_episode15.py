"""Debug polynomial fitting for episode 15."""

import sys
from pathlib import Path

project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.evaluation.reverse_engineering_evolver import ReverseEngineeringEvolver

# Episode 15 data (after deduplication)
inputs = [8, 7, 6, 2]
outputs = [-206, -159, -118, -14]
x = 5
expected = -83

print("Episode 15 Polynomial Debug")
print(f"Inputs: {inputs}")
print(f"Outputs: {outputs}")
print(f"Test x: {x}")
print(f"Expected: {expected}")
print()

evolver = ReverseEngineeringEvolver(seed=125)

# Test polynomial fit
result = evolver._polynomial_fit(inputs, outputs, x)
print(f"Polynomial fit result: {result}")
print(f"Error: {abs(result - expected)}")
print()

# Try different degrees manually
import numpy as np

for degree in range(1, 5):
    if len(inputs) > degree:
        try:
            X = np.vander(inputs, degree + 1)
            y = np.array(outputs)
            coeffs = np.linalg.lstsq(X, y, rcond=None)[0]
            
            # Calculate training error
            train_preds = [np.polyval(coeffs, xi) for xi in inputs]
            train_error = sum((p - o)**2 for p, o in zip(train_preds, outputs))
            
            # Predict at test point
            test_pred = np.polyval(coeffs, x)
            test_error = abs(test_pred - expected)
            
            print(f"Degree {degree}:")
            print(f"  Coefficients: {[round(c, 4) for c in coeffs]}")
            print(f"  Train error: {train_error:.6f}")
            print(f"  Test prediction: {test_pred:.2f}, error: {test_error:.2f}")
            print()
        except Exception as e:
            print(f"Degree {degree}: Error - {e}")
