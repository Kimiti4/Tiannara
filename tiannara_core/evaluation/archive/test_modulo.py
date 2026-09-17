"""Test modulo detection."""

import sys
from pathlib import Path

project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

# Test case from episode 1
inputs = [9, 2, 3, 7, 4]
outputs = [3, 2, 3, 1, 4]
x = 5

print("Testing modulo detection")
print(f"Inputs: {inputs}")
print(f"Outputs: {outputs}")
print(f"Test x: {x}")
print()

unique_outputs = sorted(set(outputs))
print(f"Unique outputs: {unique_outputs}")
print(f"Number of unique outputs: {len(unique_outputs)}")
print(f"Max output: {max(unique_outputs)}")
print(f"Min output: {min(unique_outputs)}")
print()

# Check if all are integers
all_ints = all(isinstance(o, (int, float)) and o == int(o) for o in unique_outputs)
print(f"All outputs are integers: {all_ints}")
print()

if len(unique_outputs) <= 7 and all_ints:
    max_output = max(unique_outputs)
    min_output = min(unique_outputs)
    
    print(f"Checking moduli from 2 to 7...")
    for n in range(2, 8):
        matches = all(abs(out - (inp % n)) < 1e-6 for inp, out in zip(inputs, outputs))
        print(f"  n={n}: {matches} - {[inp % n for inp in inputs]}")
        
        if matches:
            print(f"  ✓ Found! f({x}) = {x % n}")
            break
