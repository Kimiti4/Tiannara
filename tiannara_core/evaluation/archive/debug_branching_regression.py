"""Debug branching causal regression."""

import sys
from pathlib import Path

project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.evaluation.causal_system_domain import CausalSystemGenerator
from tiannara_core.evaluation.causal_system_evolver import CausalSystemEvolver

gen = CausalSystemGenerator(seed=45)
evolver = CausalSystemEvolver(seed=126)

# Get first branching task
for episode in range(1, 10):
    task = gen.generate_task(episode=episode)
    if task.get("subtype") == "branching_causal":
        break

print("Branching Causal Task Debug")
print("=" * 80)
print(f"Episode: {episode}")
hidden = task.get('hidden_params', {})
print(f"Hidden params structure: {type(hidden)}, keys: {list(hidden.keys()) if isinstance(hidden, dict) else 'N/A'}")
print()

observations = task["inputs"]["observations"]
intervention = task["inputs"]["intervention"]
target_var = task["inputs"]["target_variable"]

print(f"Target variable: {target_var}")
print(f"Intervention: {intervention}")
print(f"\nObservations:")
for i, obs in enumerate(observations):
    print(f"  {i+1}. x={obs['x']:.3f}, y={obs['y']:.3f}, z={obs['z']:.3f}")

# Manual regression calculation
x_vals = [obs["x"] for obs in observations]
y_vals = [obs[target_var] for obs in observations]

n = len(x_vals)
mean_x = sum(x_vals) / n
mean_y = sum(y_vals) / n

numerator = sum((x - mean_x) * (y - mean_y) for x, y in zip(x_vals, y_vals))
denominator = sum((x - mean_x) ** 2 for x in x_vals)

b1 = numerator / denominator
b0 = mean_y - b1 * mean_x

print(f"\nManual Regression ({target_var} ~ x):")
print(f"  b0 (intercept): {b0:.6f}")
print(f"  b1 (slope): {b1:.6f}")

intervention_value = intervention["value"]
predicted_manual = b0 + b1 * intervention_value
expected = task["expected_output"]

print(f"\nPrediction:")
print(f"  Intervention x = {intervention_value:.6f}")
print(f"  Predicted {target_var} = {predicted_manual:.6f}")
print(f"  Expected {target_var} = {expected:.6f}")
print(f"  Error = {abs(predicted_manual - expected):.6f}")

# Now test evolver
solution_func = evolver.create_variant(task, episode=episode)
output = solution_func(**task["inputs"])

print(f"\nEvolver prediction:")
print(f"  Got: {output}")
print(f"  Error: {abs(output - expected):.6f}")
