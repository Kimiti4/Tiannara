"""Analyze Counterfactual Tasks - What do they expect?"""

import sys
from pathlib import Path

project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.evaluation.causal_system_domain import CausalSystemGenerator

def analyze_counterfactuals():
    """Check what counterfactual tasks expect."""
    gen = CausalSystemGenerator(seed=42)
    
    print("Analyzing Counterfactual Tasks")
    print("=" * 80)
    
    counterfactual_count = 0
    
    for i in range(1, 51):
        task = gen.generate_task(i)
        
        if task.get("subtype") == "intervention_prediction":
            counterfactual_count += 1
            
            task_inputs = task.get("inputs", {})
            observations = task_inputs.get("observations", [])
            intervention = task_inputs.get("intervention", {})
            target_var = task_inputs.get("target_variable", "y")
            
            print(f"\nTask {i}: {task['description']}")
            print(f"  Intervention: {intervention}")
            print(f"  Target variable: {target_var}")
            print(f"  Expected output: {task['expected_output']:.3f}")
            print(f"  Observations ({len(observations)}):")
            
            for j, obs in enumerate(observations[:3]):  # Show first 3
                print(f"    {j+1}. {obs}")
            
            # Check what y values look like when x=0 (if present)
            x_vals = [obs.get("x", None) for obs in observations]
            y_vals = [obs.get("y", None) for obs in observations]
            
            # Find observations where x is close to 0
            near_zero = [(x, y) for x, y in zip(x_vals, y_vals) if abs(x) < 0.1]
            if near_zero:
                print(f"  Observations with x≈0: {near_zero}")
            
            # Calculate mean of y
            if y_vals and all(y is not None for y in y_vals):
                mean_y = sum(y_vals) / len(y_vals)
                print(f"  Mean of y: {mean_y:.3f}")
    
    print(f"\n{'=' * 80}")
    print(f"Total counterfactual tasks: {counterfactual_count}/50")

if __name__ == "__main__":
    analyze_counterfactuals()
