"""Debug piecewise task episode 5."""

import sys
from pathlib import Path

project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.evaluation.reverse_engineering_evolver import ReverseEngineeringEvolver

# Episode 5 data (after deduplication)
inputs = [2, 8, 4]
outputs = [5, 5, 9]
x = 3
expected = 7

print("Episode 5 Piecewise Debug")
print(f"Inputs: {inputs}")
print(f"Outputs: {outputs}")
print(f"Test x: {x}")
print(f"Expected: {expected}")
print()

evolver = ReverseEngineeringEvolver(seed=125)

# Check if detected as piecewise
is_pw = evolver._is_piecewise(inputs, outputs)
print(f"Is piecewise: {is_pw}")

# Test piecewise inference
result = evolver._piecewise_infer(inputs, outputs, x)
print(f"Piecewise result: {result}")
print(f"Error: {abs(result - expected)}")
print()

# Show sorted pairs
sorted_pairs = sorted(zip(inputs, outputs))
print(f"Sorted pairs: {sorted_pairs}")

# Manual calculation for 3-point case
if len(sorted_pairs) == 3:
    x0, y0 = sorted_pairs[0]
    x1, y1 = sorted_pairs[1]
    x2, y2 = sorted_pairs[2]
    
    print(f"\nPoint 0: ({x0}, {y0})")
    print(f"Point 1: ({x1}, {y1})")
    print(f"Point 2: ({x2}, {y2})")
    
    # Expected y at x1 if linear
    if x2 != x0:
        expected_y1 = y0 + (y2 - y0) * (x1 - x0) / (x2 - x0)
        print(f"Expected y1 if linear: {expected_y1:.2f}")
        print(f"Actual y1: {y1}")
        print(f"Difference: {abs(y1 - expected_y1):.2f}")
        
        output_range = max(outputs) - min(outputs)
        print(f"Output range: {output_range}")
        print(f"Threshold (0.3 * range): {0.3 * output_range:.2f}")
