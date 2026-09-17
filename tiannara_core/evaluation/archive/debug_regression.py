"""Debug Regression - Check what's being fitted."""

import sys
from pathlib import Path

project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.evaluation.causal_system_domain import CausalSystemGenerator

def debug_regression():
    """Check regression fitting on specific tasks."""
    gen = CausalSystemGenerator(seed=42)
    
    print("Debugging Regression Fitting")
    print("=" * 80)
    
    # Test first 5 tasks
    for i in range(1, 6):
        task = gen.generate_task(i)
        
        print(f"\nTask {i}: {task.get('subtype')}")
        print(f"  Description: {task['description']}")
        
        task_inputs = task.get("inputs", {})
        observations = task_inputs.get("observations", [])
        counterfactual = task_inputs.get("counterfactual", {})
        intervention = task_inputs.get("intervention", {})
        target_var = task_inputs.get("target_variable", "y")
        
        print(f"  Target variable: {target_var}")
        print(f"  Expected output: {task['expected_output']:.3f}")
        
        # Show intervention/counterfactual
        if intervention:
            print(f"  Intervention: {intervention}")
        if counterfactual:
            print(f"  Counterfactual: {counterfactual}")
        
        # Extract x and y values
        x_vals = [obs.get("x", 0) for obs in observations]
        y_vals = [obs.get("y", 0) for obs in observations]
        
        print(f"  Observations:")
        for j, (x, y) in enumerate(zip(x_vals[:3], y_vals[:3])):
            print(f"    {j+1}. x={x:.3f}, y={y:.3f}")
        
        # Calculate simple linear regression
        n = len(x_vals)
        if n >= 2:
            mean_x = sum(x_vals) / n
            mean_y = sum(y_vals) / n
            
            numerator = sum((x - mean_x) * (y - mean_y) for x, y in zip(x_vals, y_vals))
            denominator = sum((x - mean_x) ** 2 for x in x_vals)
            
            if abs(denominator) > 1e-10:
                b1 = numerator / denominator
                b0 = mean_y - b1 * mean_x
                
                print(f"  Regression: y = {b0:.3f} + {b1:.3f}*x")
                
                # Determine what value to predict
                if counterfactual and "x" in counterfactual:
                    pred_x = counterfactual["x"]
                    print(f"  Predicting for counterfactual x={pred_x:.3f}")
                elif intervention:
                    if "value" in intervention:
                        pred_x = intervention["value"]
                    else:
                        # Old format
                        pred_x = list(intervention.values())[0] if intervention else 0
                    print(f"  Predicting for intervention x={pred_x:.3f}")
                else:
                    pred_x = 0
                    print(f"  No intervention/counterfactual, using x=0")
                
                predicted = b0 + b1 * pred_x
                print(f"  Predicted y: {predicted:.3f}")
                print(f"  Expected y: {task['expected_output']:.3f}")
                print(f"  Error: {abs(predicted - task['expected_output']):.3f}")

if __name__ == "__main__":
    debug_regression()
