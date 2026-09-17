"""Check episode 9 expected output."""

import sys
from pathlib import Path

project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.evaluation.reverse_engineering_domain import ReverseEngineeringGenerator

gen = ReverseEngineeringGenerator(seed=44)

task = gen.generate_task(episode=9)
print(f"Episode 9:")
print(f"  Subtype: {task['subtype']}")
print(f"  Description: {task.get('description', 'N/A')}")
print(f"  Inputs: {task['inputs']}")
print(f"  Expected output: {task.get('expected_output')}")
print()

# Check if it's really modulo 6
examples = task["inputs"].get("examples", [])
print("Examples:")
for ex in examples:
    inp = ex["input"]
    out = ex["output"]
    print(f"  f({inp}) = {out}, {inp} % 6 = {inp % 6}")

x = task["inputs"].get("x", task["inputs"].get("test_input"))
print(f"\nTest input: {x}")
print(f"Expected: {task['expected_output']}")
print(f"x % 6 = {x % 6}")
