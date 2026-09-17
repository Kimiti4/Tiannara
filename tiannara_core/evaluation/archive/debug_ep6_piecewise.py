"""Debug episode 6 piecewise failure."""

import sys
from pathlib import Path

project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.evaluation.reverse_engineering_domain import ReverseEngineeringGenerator
from tiannara_core.evaluation.reverse_engineering_evolver import ReverseEngineeringEvolver

gen = ReverseEngineeringGenerator(seed=44)
evolver = ReverseEngineeringEvolver(seed=125)

task = gen.generate_task(episode=6)
print(f"Episode 6: {task['subtype']}")
print(f"Description: {task.get('description', 'N/A')}")
print()

examples = task["inputs"].get("examples", [])
seen = set()
unique_examples = []
for ex in examples:
    key = (ex["input"], ex["output"])
    if key not in seen:
        seen.add(key)
        unique_examples.append(ex)

inputs = [ex["input"] for ex in unique_examples]
outputs = [ex["output"] for ex in unique_examples]

print(f"Examples: {len(examples)} total, {len(unique_examples)} unique")
print(f"Inputs: {inputs}")
print(f"Outputs: {outputs}")
print()

# Sort by input
sorted_pairs = sorted(zip(inputs, outputs))
print("Sorted pairs:")
for x, y in sorted_pairs:
    print(f"  ({x}, {y})")

# Check slopes
print("\nSlopes between consecutive points:")
for i in range(len(sorted_pairs) - 1):
    x0, y0 = sorted_pairs[i]
    x1, y1 = sorted_pairs[i+1]
    if x1 != x0:
        slope = (y1 - y0) / (x1 - x0)
        print(f"  ({x0},{y0}) -> ({x1},{y1}): slope = {slope:.3f}")

# Test prediction
x_test = task["inputs"].get("x", task["inputs"].get("test_input"))
expected = task["expected_output"]

print(f"\nTest x: {x_test}")
print(f"Expected: {expected}")

# Test piecewise inference
pw_result = evolver._piecewise_infer(inputs, outputs, x_test)
print(f"\nPiecewise result: {pw_result}")
print(f"Error: {abs(pw_result - expected):.4f}")

# What strategy is selected?
strategy = evolver._select_best_strategy(inputs, outputs, "piecewise")
print(f"\nStrategy selected: {strategy}")
