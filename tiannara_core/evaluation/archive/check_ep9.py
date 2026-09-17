"""Check episode 9 piecewise task."""

import sys
from pathlib import Path

project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.evaluation.reverse_engineering_domain import ReverseEngineeringGenerator
from tiannara_core.evaluation.reverse_engineering_evolver import ReverseEngineeringEvolver

gen = ReverseEngineeringGenerator(seed=44)
evolver = ReverseEngineeringEvolver(seed=125)

# Get episode 9 task
for episode in range(1, 10):
    task = gen.generate_task(episode=episode)

task = gen.generate_task(episode=9)
print(f"Episode 9: {task['subtype']}")
print(f"Description: {task.get('description', 'N/A')}")

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

print(f"\nExamples: {len(examples)} total, {len(unique_examples)} unique")
print(f"Inputs: {inputs}")
print(f"Outputs: {outputs}")
print(f"Unique outputs: {len(set(outputs))}")
print(f"Output range: {max(outputs) - min(outputs)}")

strategy = evolver._select_best_strategy(inputs, outputs, "piecewise")
print(f"\nStrategy selected: {strategy}")

# Test the prediction
solution_func = evolver.create_variant(task, episode=9)
output = solution_func(**task["inputs"])
print(f"\nPrediction: {output}")
print(f"Expected: {task['expected_output']}")
