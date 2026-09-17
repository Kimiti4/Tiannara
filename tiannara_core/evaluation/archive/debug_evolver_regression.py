"""Debug evolver regression prediction."""

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

print(f"Episode {episode}: {task['subtype']}")
print("=" * 80)

observations = task["inputs"]["observations"]
intervention = task["inputs"]["intervention"]
target_var = task["inputs"]["target_variable"]

print(f"Observations count: {len(observations)}")
print(f"Intervention: {intervention}")
print(f"Target: {target_var}")
print()

# Check what mutation type would be selected
mutation_type = evolver._select_causal_strategy(observations, intervention, task, task.get("subtype", "unknown"))
print(f"Selected mutation: {mutation_type}")
print()

# Now manually call _regression_prediction to see what happens
result = evolver._regression_prediction(observations, intervention)
print(f"_regression_prediction result: {result}")
print(f"Result type: {type(result)}")
print()

# Extract x and y values for manual check
x_vals = [obs["x"] for obs in observations]
y_vals = [obs[target_var] for obs in observations]

print(f"x values: {[round(x, 3) for x in x_vals]}")
print(f"y values: {[round(y, 3) for y in y_vals]}")
print(f"Number of predictors: 1 (just x)")
print(f"Number of observations: {len(observations)}")
print()

# The issue might be that it's trying multivariate when it shouldn't
# Check if z is being included as a predictor
if len(observations) >= 5:
    print("WARNING: Has 5+ observations, might try multivariate regression")
    print("But we only have 1 predictor variable (x), so should use simple regression")
