"""Debug causal system tasks to understand structure."""

import sys
from pathlib import Path

project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.evaluation.causal_system_domain import CausalSystemGenerator

gen = CausalSystemGenerator(seed=45)

print("Sample Causal System Tasks")
print("=" * 80)

for i in range(1, 6):
    task = gen.generate_task(i)
    print(f"\nTask {i}:")
    print(f"  Type: {task.get('type')}")
    print(f"  Task Type: {task.get('task_type')}")
    print(f"  Description: {task.get('description')}")
    print(f"  Difficulty: {task.get('difficulty')}")
    print(f"  Keys: {list(task.keys())}")
    
    observations = task.get('observations', [])
    print(f"  Observations count: {len(observations)}")
    if observations:
        print(f"  First observation: {observations[0]}")
        print(f"  Variables: {list(observations[0].keys())}")
    
    intervention = task.get('intervention', {})
    print(f"  Intervention: {intervention}")
    
    expected = task.get('expected_outcome', {})
    print(f"  Expected outcome: {expected}")
