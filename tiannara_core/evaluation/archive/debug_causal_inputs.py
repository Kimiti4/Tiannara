"""Debug causal system task inputs structure."""

import sys
from pathlib import Path

project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.evaluation.causal_system_domain import CausalSystemGenerator

gen = CausalSystemGenerator(seed=45)

print("Causal Task Input Structure")
print("=" * 80)

for i in range(1, 4):
    task = gen.generate_task(i)
    print(f"\nTask {i}: {task['description']}")
    print(f"  Subtype: {task.get('subtype')}")
    print(f"  Inputs keys: {list(task['inputs'].keys())}")
    print(f"  Inputs: {task['inputs']}")
    print(f"  Expected output: {task['expected_output']}")
    print(f"  Hidden params: {task.get('hidden_params', {})}")
