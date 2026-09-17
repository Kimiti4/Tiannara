"""Debug modulo episode 3 failure."""

import sys
from pathlib import Path

project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.evaluation.reverse_engineering_domain import ReverseEngineeringGenerator
from tiannara_core.evaluation.reverse_engineering_evolver import ReverseEngineeringEvolver

gen = ReverseEngineeringGenerator(seed=44)
evolver = ReverseEngineeringEvolver(seed=125)

task = gen.generate_task(episode=3)
print(f"Episode 3: {task['subtype']}")
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

print(f"Inputs: {inputs}")
print(f"Outputs: {outputs}")
print()

# Check what modulus works
print("Testing different moduli:")
for n in range(2, 10):
    matches = all(inp % n == out for inp, out in zip(inputs, outputs))
    print(f"  n={n}: {'MATCH' if matches else 'NO'} - {[inp % n for inp in inputs]}")

x_test = task["inputs"].get("x", task["inputs"].get("test_input"))
expected = task["expected_output"]
print(f"\nTest x: {x_test}")
print(f"Expected: {expected}")

# Test rule extraction
result = evolver._rule_extraction(inputs, outputs, x_test)
print(f"Rule extraction result: {result}")
print(f"Match: {result == expected}")
