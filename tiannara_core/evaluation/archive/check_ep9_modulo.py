"""Check why episode 9 modulo detection failed."""

import sys
from pathlib import Path

project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.evaluation.reverse_engineering_domain import ReverseEngineeringGenerator
from tiannara_core.evaluation.reverse_engineering_evolver import ReverseEngineeringEvolver

gen = ReverseEngineeringGenerator(seed=44)
evolver = ReverseEngineeringEvolver(seed=125)

task = gen.generate_task(episode=9)
print(f"Episode 9 subtype: {task['subtype']}")

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

# Check modulo detection conditions
unique_outputs = len(set(outputs))
output_range = max(outputs) - min(outputs) if outputs else 0
all_small_ints = all(isinstance(o, (int, float)) and o >= 0 and o == int(o) and o <= 6 for o in outputs)

print(f"Unique outputs: {unique_outputs}")
print(f"Output range: {output_range}")
print(f"All small ints (0-6): {all_small_ints}")
print(f"Number of outputs: {len(outputs)}")
print()

# Check each output
print("Checking each output:")
for i, o in enumerate(outputs):
    is_int = isinstance(o, (int, float)) and o == int(o)
    is_nonneg = o >= 0
    is_le6 = o <= 6
    print(f"  Output {i}: {o} - is_int={is_int}, nonneg={is_nonneg}, <=6={is_le6}")

print()
print(f"Condition check:")
print(f"  len(outputs) >= 3: {len(outputs) >= 3}")
print(f"  all_small_ints: {all_small_ints}")
print(f"  output_range <= 6: {output_range <= 6}")
print(f"  unique_outputs <= 7: {unique_outputs <= 7}")
print()

strategy = evolver._select_best_strategy(inputs, outputs, "modulo_pattern")
print(f"Strategy selected: {strategy}")
