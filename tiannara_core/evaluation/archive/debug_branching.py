"""Debug Branching Causal Tasks."""

import sys
from pathlib import Path

project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.evaluation.causal_system_domain import CausalSystemGenerator

def debug_branching_tasks():
    """Analyze branching causal task structure."""
    gen = CausalSystemGenerator(seed=42)
    
    print("Analyzing Branching Causal Tasks")
    print("=" * 80)
    
    count = 0
    
    for i in range(1, 101):
        task = gen.generate_task(i)
        
        if task.get("subtype") == "branching_causal":
            count += 1
            
            if count <= 3:  # Show first 3 examples
                print(f"\nTask {i}: {task['description']}")
                
                task_inputs = task.get("inputs", {})
                observations = task_inputs.get("observations", [])
                intervention = task_inputs.get("intervention", {})
                target_var = task_inputs.get("target_variable", "y")
                
                print(f"  Target variable: {target_var}")
                print(f"  Intervention: {intervention}")
                print(f"  Expected output: {task['expected_output']:.3f}")
                print(f"  Observations ({len(observations)}):")
                
                for j, obs in enumerate(observations[:3]):
                    print(f"    {j+1}. {obs}")
                
                # Try multivariate regression
                if len(observations) >= 2:
                    import numpy as np
                    
                    all_vars = list(observations[0].keys())
                    predictor_vars = [v for v in all_vars if v != target_var]
                    
                    print(f"  Predictor variables: {predictor_vars}")
                    
                    # Build design matrix
                    n = len(observations)
                    k = len(predictor_vars)
                    
                    X = np.ones((n, k + 1))  # intercept
                    for j_idx, var in enumerate(predictor_vars):
                        X[:, j_idx + 1] = [obs.get(var, 0) for obs in observations]
                    
                    y = np.array([obs.get(target_var, 0) for obs in observations])
                    
                    try:
                        beta = np.linalg.lstsq(X, y, rcond=None)[0]
                        
                        # Predict for intervention
                        x_new = np.ones(k + 1)
                        for j_idx, var in enumerate(predictor_vars):
                            if var == intervention.get("variable", ""):
                                x_new[j_idx + 1] = intervention.get("value", 0)
                            else:
                                mean_val = np.mean([obs.get(var, 0) for obs in observations])
                                x_new[j_idx + 1] = mean_val
                        
                        predicted = np.dot(beta, x_new)
                        print(f"  Multivariate prediction: {predicted:.3f}")
                        print(f"  Error: {abs(predicted - task['expected_output']):.3f}")
                    except Exception as e:
                        print(f"  Regression failed: {e}")
    
    print(f"\n{'=' * 80}")
    print(f"Total branching causal tasks: {count}")

if __name__ == "__main__":
    debug_branching_tasks()
