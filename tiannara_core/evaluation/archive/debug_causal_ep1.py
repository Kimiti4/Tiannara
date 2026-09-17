"""Debug Causal domain episode 1."""

import sys
from pathlib import Path

project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.evaluation.causal_system_domain import CausalSystemGenerator
from tiannara_core.evaluation.causal_system_evolver import CausalSystemEvolver

gen = CausalSystemGenerator(seed=45)
evolver = CausalSystemEvolver(seed=126)

# Get first task
task = gen.generate_task(episode=1)

print("Episode 1 Debug")
print("=" * 80)
print(f"Subtype: {task.get('subtype', 'unknown')}")
print(f"Description: {task.get('description', 'N/A')[:150]}")
print(f"\nInputs: {task['inputs']}")
print(f"Expected output: {task.get('expected_output')}")
print()

# Create variant
try:
    solution_func = evolver.create_variant(task, episode=1)
    print(f"Evolver quality: {evolver.quality_level}")
    
    # Call the solution
    output = solution_func(**task["inputs"])
    print(f"\nOutput type: {type(output)}")
    print(f"Output: {output}")
    
    # Try to verify
    try:
        success = gen.verify_solution(task, output)
        print(f"Verification: {'SUCCESS' if success else 'FAILED'}")
    except Exception as e:
        print(f"Verification ERROR: {e}")
        
except Exception as e:
    print(f"ERROR creating variant: {e}")
    import traceback
    traceback.print_exc()
