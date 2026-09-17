"""Test polynomial evaluation."""

import numpy as np

# Coefficients from degree 2 fit for episode 15
coeffs = [-3.0, -2.0, 2.0]  # From numpy output

print("Testing polynomial evaluation")
print(f"Coefficients: {coeffs}")
print()

# Test at x=5
x = 5

# Method 1: NumPy polyval (expects descending order)
result_np = np.polyval(coeffs, x)
print(f"NumPy polyval result: {result_np}")

# Method 2: Horner's method with reversed coefficients (ascending order)
result_horner_asc = 0.0
for coeff in coeffs:  # Ascending order
    result_horner_asc = result_horner_asc * x + coeff
print(f"Horner (ascending): {result_horner_asc}")

# Method 3: Horner's method with original coefficients (descending order)  
result_horner_desc = 0.0
for coeff in reversed(coeffs):  # Descending to ascending
    result_horner_desc = result_horner_desc * x + coeff
print(f"Horner (reversed/descending): {result_horner_desc}")

# Method 4: Direct evaluation
result_direct = coeffs[0] * x**2 + coeffs[1] * x + coeffs[2]
print(f"Direct (a*x² + b*x + c): {result_direct}")

print()
print("Expected: -83")
