"""Debug reverse engineering tasks to understand structure."""

import sys
from pathlib import Path

project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.evaluation.reverse_engineering_domain import ReverseEngineeringGenerator

gen = ReverseEngineeringGenerator(seed=42)

print("Sample Reverse Engineering Tasks")
print("=" * 80)

for i in range(1, 6):
    task = gen.generate_task(i)
    print(f"\nTask {i}:")
    print(f"  Type: {task.get('type')}")
    print(f"  Subtype: {task.get('subtype')}")
    print(f"  Description: {task.get('description')}")
    print(f"  Difficulty: {task.get('difficulty')}")
    print(f"  Expected Output: {task.get('expected_output')}")
    print(f"  Inputs keys: {list(task['inputs'].keys())}")
    
    examples = task['inputs'].get('examples', [])
    print(f"  Examples count: {len(examples)}")
    if examples:
        print(f"  First 3 examples: {examples[:3]}")
    
    test_input = task['inputs'].get('test_input')
    print(f"  Test input: {test_input}")
