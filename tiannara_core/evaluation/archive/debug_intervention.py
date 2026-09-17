"""Debug Intervention Prediction Tasks."""

import sys
from pathlib import Path

project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.evaluation.causal_system_domain import CausalSystemGenerator

def debug_intervention_tasks():
    """Analyze intervention prediction task structure."""
    gen = CausalSystemGenerator(seed=42)
    
    print("Analyzing Intervention Prediction Tasks")
    print("=" * 80)
    
    count = 0
    
    for i in range(1, 101):
        task = gen.generate_task(i)
        
        if task.get("subtype") == "intervention_prediction":
            count += 1
            
            if count <= 5:  # Show first 5 examples
                print(f"\nTask {i}: {task['description']}")
                
                task_inputs = task.get("inputs", {})
                observations = task_inputs.get("observations", [])
                counterfactual = task_inputs.get("counterfactual", {})
                observed = task_inputs.get("observed", {})
                
                print(f"  Observed: {observed}")
                print(f"  Counterfactual query: {counterfactual}")
                print(f"  Expected output: {task['expected_output']:.3f}")
                print(f"  Observations ({len(observations)}):")
                
                for j, obs in enumerate(observations[:3]):
                    print(f"    {j+1}. {obs}")
                
                # Calculate what regression would predict
                if len(observations) >= 2:
                    x_vals = [obs.get("x", 0) for obs in observations]
                    y_vals = [obs.get("y", 0) for obs in observations]
                    
                    mean_x = sum(x_vals) / len(x_vals)
                    mean_y = sum(y_vals) / len(y_vals)
                    
                    numerator = sum((x - mean_x) * (y - mean_y) for x, y in zip(x_vals, y_vals))
                    denominator = sum((x - mean_x) ** 2 for x in x_vals)
                    
                    if abs(denominator) > 1e-10:
                        b1 = numerator / denominator
                        b0 = mean_y - b1 * mean_x
                        
                        # What value should we predict for?
                        if counterfactual and "x" in counterfactual:
                            pred_x = counterfactual["x"]
                            predicted = b0 + b1 * pred_x
                            print(f"  Regression prediction for x={pred_x:.3f}: {predicted:.3f}")
                            print(f"  Error: {abs(predicted - task['expected_output']):.3f}")
    
    print(f"\n{'=' * 80}")
    print(f"Total intervention prediction tasks: {count}")

if __name__ == "__main__":
    debug_intervention_tasks()
