"""Test rule extraction for episode 9."""

import sys
from pathlib import Path

project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.evaluation.reverse_engineering_domain import ReverseEngineeringGenerator
from tiannara_core.evaluation.reverse_engineering_evolver import ReverseEngineeringEvolver

gen = ReverseEngineeringGenerator(seed=44)
evolver = ReverseEngineeringEvolver(seed=125)

task = gen.generate_task(episode=9)

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
x = task["inputs"]["test_input"]

print(f"Inputs: {inputs}")
print(f"Outputs: {outputs}")
print(f"Test x: {x}")
print(f"Expected: {task['expected_output']}")
print()

# Test rule extraction
result = evolver._rule_extraction(inputs, outputs, x)
print(f"Rule extraction result: {result}")
print(f"Expected: {task['expected_output']}")
print(f"Match: {result == task['expected_output']}")

# Now test the full variant
solution_func = evolver.create_variant(task, episode=9)
output = solution_func(**task["inputs"])
print(f"\nFull variant output: {output}")
print(f"Expected: {task['expected_output']}")
print(f"Match: {output == task['expected_output']}")
