"""Debug causal evolver to see what's happening."""

import sys
from pathlib import Path

project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.evaluation.causal_system_domain import CausalSystemGenerator
from tiannara_core.evaluation.causal_system_evolver import CausalSystemEvolver

gen = CausalSystemGenerator(seed=45)
evolver = CausalSystemEvolver(seed=126)

print("Debugging Causal Evolver")
print("=" * 80)

for i in range(1, 4):
    task = gen.generate_task(i)
    print(f"\nTask {i}: {task['description']}")
    print(f"  Subtype: {task.get('subtype')}")
    print(f"  Inputs: {list(task['inputs'].keys())}")
    
    variant = evolver.create_variant(task, i)
    
    try:
        task_inputs = task.get("inputs", {})
        print(f"  Calling variant with inputs...")
        output = variant(**task_inputs)
        print(f"  Output: {output}")
        
        target_var = task_inputs.get("target_variable", "y")
        if isinstance(output, dict):
            predicted_value = output.get(target_var, 0)
        else:
            predicted_value = output
        
        print(f"  Predicted value for '{target_var}': {predicted_value}")
        print(f"  Expected output: {task['expected_output']}")
        
        success = gen.verify_solution(task, predicted_value)
        print(f"  Success: {success}")
        
    except Exception as e:
        print(f"  ERROR: {e}")
        import traceback
        traceback.print_exc()
