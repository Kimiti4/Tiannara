"""Debug linear causal chain failures."""

import sys
from pathlib import Path

project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.evaluation.causal_system_domain import CausalSystemGenerator
from tiannara_core.evaluation.causal_system_evolver import CausalSystemEvolver

gen = CausalSystemGenerator(seed=45)
evolver = CausalSystemEvolver(seed=126)

print("Analyzing Linear Causal Chain Failures")
print("=" * 80)

chain_count = 0
fail_count = 0
for episode in range(1, 101):
    task = gen.generate_task(episode=episode)
    subtype = task.get("subtype", "unknown")
    
    if subtype == "linear_causal_chain":
        chain_count += 1
        
        # Create variant
        solution_func = evolver.create_variant(task, episode=episode)
        
        # Get prediction
        try:
            output = solution_func(**task["inputs"])
            expected = task.get("expected_output")
            
            # Verify
            success = gen.verify_solution(task, output)
            
            if not success:
                fail_count += 1
                error = abs(output - expected) if isinstance(output, (int, float)) else float('inf')
                
                if fail_count <= 5:
                    print(f"\nEpisode {episode}:")
                    print(f"  Expected: {expected}")
                    print(f"  Got: {output}")
                    print(f"  Error: {error:.4f}")
                    
                    # Check what strategy was used
                    observations = task["inputs"]["observations"]
                    intervention = task["inputs"]["intervention"]
                    mutation_type = evolver._select_causal_strategy(observations, intervention, task, "linear_causal_chain")
                    print(f"  Strategy: {mutation_type}")
                    
                    # Show observations
                    obs = task["inputs"]["observations"]
                    print(f"  Observations: {len(obs)} samples")
                    if len(obs) > 0:
                        vars_list = list(obs[0].keys())
                        print(f"  Variables: {vars_list}")
                        
        except Exception as e:
            fail_count += 1
            if fail_count <= 5:
                print(f"\nEpisode {episode}: ERROR - {e}")

print(f"\n{'='*80}")
print(f"Total linear_causal_chain tasks: {chain_count}")
print(f"Failed: {fail_count} ({fail_count/chain_count*100:.1f}%)")
print(f"Succeeded: {chain_count - fail_count} ({(chain_count-fail_count)/chain_count*100:.1f}%)")
