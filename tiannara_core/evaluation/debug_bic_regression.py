"""Debug why BIC is causing polynomial regression."""

import sys
from pathlib import Path
import math

project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.evaluation.reverse_engineering_domain import ReverseEngineeringGenerator
from tiannara_core.evaluation.reverse_engineering_evolver import ReverseEngineeringEvolver

# Test a specific polynomial task
gen = ReverseEngineeringGenerator(seed=60)
evolver = ReverseEngineeringEvolver(seed=160)

# Find a polynomial task
for ep in range(1, 21):
    task = gen.generate_task(episode=ep)
    if task.get("subtype") == "polynomial":
        print(f"Episode {ep}: Polynomial task")
        print(f"  Inputs: {task['inputs']}")
        
        # Manually test polynomial fitting with both methods
        examples = task["inputs"]["examples"]
        inputs = [ex["input"] for ex in examples]
        outputs = [float(ex["output"]) for ex in examples]
        x_test = task["inputs"]["test_input"]
        
        print(f"\nTesting polynomial fitting...")
        
        # Try different degrees
        for degree in range(1, 6):
            coeffs = evolver._fit_polynomial(inputs, outputs, degree)
            if coeffs is not None:
                # Calculate RSS
                rss = sum((evolver._eval_poly(coeffs, inp) - out)**2 for inp, out in zip(inputs, outputs))
                
                # Calculate BIC
                n = len(inputs)
                k = degree + 1
                
                if rss < 1e-10:
                    bic = float('-inf')
                    print(f"  Degree {degree}: PERFECT FIT (RSS < 1e-10)")
                else:
                    bic = n * math.log(rss / n) + k * math.log(n)
                    print(f"  Degree {degree}: RSS={rss:.6f}, BIC={bic:.2f}, k={k}")
                
                # Test prediction
                pred = evolver._eval_poly(coeffs, x_test)
                print(f"           Prediction at x={x_test}: {pred:.4f}")
        
        break
