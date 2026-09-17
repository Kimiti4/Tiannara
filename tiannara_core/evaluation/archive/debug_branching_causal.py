"""Debug branching causal task failures."""

import sys
from pathlib import Path

project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.evaluation.causal_system_domain import CausalSystemGenerator
from tiannara_core.evaluation.causal_system_evolver import CausalSystemEvolver

gen = CausalSystemGenerator(seed=45)
evolver = CausalSystemEvolver(seed=126)

print("Analyzing Branching Causal Tasks")
print("=" * 80)

branching_count = 0
for episode in range(1, 101):
    task = gen.generate_task(episode=episode)
    subtype = task.get("subtype", "unknown")
    
    if subtype == "branching_causal":
        branching_count += 1
        
        # Create variant
        solution_func = evolver.create_variant(task, episode=episode)
        
        # Get prediction
        try:
            output = solution_func(**task["inputs"])
            expected = task.get("expected_output")
            success = gen.verify_solution(task, output)
            
            print(f"\nEpisode {episode}:")
            print(f"  Description: {task.get('description', 'N/A')[:100]}")
            observations = task["inputs"].get("observations", [])
            print(f"  Observations: {len(observations)} data points")
            if observations:
                print(f"  Variables: {list(observations[0].keys())}")
            intervention = task["inputs"].get("intervention", {})
            print(f"  Intervention: {intervention}")
            print(f"  Expected: {expected}")
            print(f"  Got: {output}")
            if isinstance(expected, (int, float)):
                print(f"  Error: {abs(output - expected):.3f}")
            print(f"  Success: {'YES' if success else 'NO'}")
            
            if branching_count >= 5:
                break
                
        except Exception as e:
            print(f"\nEpisode {episode}: EXCEPTION - {e}")
            if branching_count >= 5:
                break

print(f"\n{'=' * 80}")
print(f"Total branching tasks analyzed: {branching_count}")
