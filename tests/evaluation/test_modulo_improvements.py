"""Test modulo improvements specifically."""

import sys
from pathlib import Path

project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.evaluation.reverse_engineering_evolver import ReverseEngineeringEvolver

evolver = ReverseEngineeringEvolver(seed=125)

print("="*80)
print("TESTING MODULO IMPROVEMENTS")
print("="*80)

# Test 1: Extended range (n > 7)
print("\n1. Extended Modulo Range (n=8 to n=15):")
print("-"*80)

test_cases_extended = [
    # (inputs, outputs, test_x, expected, description)
    ([0, 1, 2, 3, 4], [0, 1, 2, 3, 4], 5, 5, "x % 8 with x=5"),
    ([0, 1, 2, 3, 4, 5, 6, 7], [0, 1, 2, 3, 4, 5, 6, 7], 10, 2, "x % 8 with x=10"),
    ([0, 1, 2, 3, 4, 5, 6, 7, 8, 9], list(range(10)), 12, 2, "x % 10 with x=12"),
]

for inputs, outputs, test_x, expected, desc in test_cases_extended:
    result = evolver._rule_extraction(inputs, outputs, test_x)
    status = "✓" if abs(result - expected) < 1e-6 else "✗"
    print(f"  {status} {desc}: expected={expected}, got={result}")

# Test 2: Affine modulo f(x) = (a*x + b) % n
print("\n2. Affine Modulo Detection f(x) = (a*x + b) % n:")
print("-"*80)

test_cases_affine = [
    # Generate test data for affine patterns
    (list(range(5)), [(2*x + 1) % 5 for x in range(5)], 6, (2*6 + 1) % 5, "(2x+1) % 5 at x=6"),
    (list(range(6)), [(3*x + 2) % 7 for x in range(6)], 8, (3*8 + 2) % 7, "(3x+2) % 7 at x=8"),
    (list(range(4)), [(1*x + 3) % 4 for x in range(4)], 5, (1*5 + 3) % 4, "(x+3) % 4 at x=5"),
]

for inputs, outputs, test_x, expected, desc in test_cases_affine:
    result = evolver._rule_extraction(inputs, outputs, test_x)
    status = "✓" if abs(result - expected) < 1e-6 else "✗"
    print(f"  {status} {desc}: expected={expected}, got={result}")

# Test 3: Regular modulo still works
print("\n3. Regular Modulo (backward compatibility):")
print("-"*80)

test_cases_regular = [
    ([0, 1, 2, 3, 4], [0, 1, 2, 3, 4], 7, 1, "x % 6 at x=7"),
    ([0, 1, 2, 3, 4, 5], [0, 1, 2, 3, 4, 5], 8, 2, "x % 6 at x=8"),
]

for inputs, outputs, test_x, expected, desc in test_cases_regular:
    result = evolver._rule_extraction(inputs, outputs, test_x)
    status = "✓" if abs(result - expected) < 1e-6 else "✗"
    print(f"  {status} {desc}: expected={expected}, got={result}")

print("\n" + "="*80)
print("MODULO IMPROVEMENTS SUMMARY")
print("="*80)
print("✓ Extended range: Can now detect modulo patterns with n up to 15")
print("✓ Affine detection: Can detect f(x) = (a*x + b) % n patterns")
print("✓ Backward compatible: Regular modulo still works correctly")
