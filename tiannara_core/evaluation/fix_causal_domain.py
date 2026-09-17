"""Fix Causal System Evolver - Simple but Effective Approach.

The key insight: For synthetic causal systems with confounders, we should use
MULTIPLE LINEAR REGRESSION on ALL observed variables to predict the target.

This works because even if x doesn't CAUSE y (they share a common cause u),
x and y will still be CORRELATED, so regression can predict y from x.
"""

import sys
from pathlib import Path

project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.evaluation.causal_system_domain import CausalSystemGenerator
from tiannara_core.evaluation.causal_system_evolver import CausalSystemEvolver

def test_simple_regression():
    """Test if simple linear regression works for causal tasks."""
    gen = CausalSystemGenerator(seed=45)
    
    print("Testing Simple Regression Approach for Causal Tasks")
    print("=" * 80)
    
    successes = 0
    total = 20
    
    for i in range(1, total + 1):
        task = gen.generate_task(i)
        
        # Extract data
        task_inputs = task.get("inputs", {})
        observations = task_inputs.get("observations", [])
        intervention = task_inputs.get("intervention", {})
        target_var = task_inputs.get("target_variable", "y")
        intervention_var = intervention.get("variable", "x")
        intervention_value = intervention.get("value", 0)
        
        print(f"\nTask {i}: {task['description']}")
        print(f"  Subtype: {task.get('subtype')}")
        print(f"  Target: {target_var}, Intervention: {intervention_var}={intervention_value}")
        print(f"  Observations: {len(observations)}")
        
        if not observations:
            print(f"  ❌ No observations!")
            continue
        
        # Try simple linear regression: y = b0 + b1*x
        x_vals = [obs.get(intervention_var, 0) for obs in observations]
        y_vals = [obs.get(target_var, 0) for obs in observations]
        
        # Calculate regression coefficients
        n = len(x_vals)
        if n < 2:
            print(f"  ❌ Not enough data points")
            continue
        
        mean_x = sum(x_vals) / n
        mean_y = sum(y_vals) / n
        
        numerator = sum((x - mean_x) * (y - mean_y) for x, y in zip(x_vals, y_vals))
        denominator = sum((x - mean_x) ** 2 for x in x_vals)
        
        if abs(denominator) < 1e-10:
            # All x values are the same, just predict mean of y
            predicted = mean_y
        else:
            b1 = numerator / denominator
            b0 = mean_y - b1 * mean_x
            
            # Predict for intervention value
            predicted = b0 + b1 * intervention_value
        
        print(f"  Regression: y = {b0:.3f} + {b1:.3f}*{intervention_var}")
        print(f"  Predicted: {predicted:.3f}")
        print(f"  Expected: {task['expected_output']:.3f}")
        
        # Check if prediction is close enough (within 20% tolerance)
        expected = task['expected_output']
        if isinstance(expected, dict):
            expected_val = expected.get(target_var, 0)
        else:
            expected_val = expected
        
        error = abs(predicted - expected_val)
        tolerance = max(abs(expected_val) * 0.2, 0.5)  # 20% or 0.5, whichever is larger
        
        success = error <= tolerance
        if success:
            successes += 1
            print(f"  ✅ SUCCESS (error={error:.3f}, tolerance={tolerance:.3f})")
        else:
            print(f"  ❌ FAIL (error={error:.3f}, tolerance={tolerance:.3f})")
    
    print("\n" + "=" * 80)
    print(f"RESULTS: {successes}/{total} = {successes/total*100:.1f}% success")
    
    return successes / total

if __name__ == "__main__":
    rate = test_simple_regression()
    
    if rate >= 0.3:
        print("\n✅ Good! Linear regression achieves >30% success")
    elif rate >= 0.15:
        print("\n🟡 Moderate - linear regression helps but needs improvement")
    else:
        print("\n⚠️ Poor - need different approach")
