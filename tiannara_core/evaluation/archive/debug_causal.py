"""Debug Causal Domain - Check which strategies are being used."""

import sys
from pathlib import Path

project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.evaluation.causal_system_domain import CausalSystemGenerator
from tiannara_core.evaluation.causal_system_evolver import CausalSystemEvolver

def debug_causal_strategies():
    """Check which mutation strategies are selected."""
    gen = CausalSystemGenerator(seed=42)
    evolver = CausalSystemEvolver()
    
    print("Debugging Causal Strategy Selection")
    print("=" * 80)
    
    strategy_counts = {}
    successes_by_strategy = {}
    
    for episode in range(1, 51):  # First 50 episodes
        task = gen.generate_task(episode)
        
        # Get the selected strategy (we need to peek at it)
        task_type = evolver._extract_task_type(task)
        task_inputs = task.get("inputs", {})
        observations = task_inputs.get("observations", [])
        intervention = task_inputs.get("intervention", task_inputs.get("counterfactual", {}))
        
        strategy = evolver._select_causal_strategy(observations, intervention, task, task_type)
        
        # Track strategy usage
        if strategy not in strategy_counts:
            strategy_counts[strategy] = 0
            successes_by_strategy[strategy] = 0
        strategy_counts[strategy] += 1
        
        # Generate variant and test
        variant_func = evolver.create_variant(task, episode)
        predicted = variant_func(**task_inputs)
        
        # Evaluate
        expected = task["expected_output"]
        target_var = task_inputs.get("target_variable", "y")
        
        if isinstance(expected, dict):
            expected_val = expected.get(target_var, 0)
        else:
            expected_val = expected
        
        if isinstance(predicted, dict):
            predicted_val = predicted.get(target_var, 0)
        else:
            predicted_val = predicted
        
        error = abs(predicted_val - expected_val)
        tolerance = max(abs(expected_val) * 0.2, 0.5)
        
        if error <= tolerance:
            successes_by_strategy[strategy] += 1
        
        # Print details for first 10 episodes
        if episode <= 10:
            print(f"\nEpisode {episode}:")
            print(f"  Subtype: {task.get('subtype')}")
            print(f"  Strategy: {strategy}")
            print(f"  Predicted: {predicted_val:.3f}, Expected: {expected_val:.3f}")
            print(f"  Error: {error:.3f}, Tolerance: {tolerance:.3f}")
            status = "SUCCESS" if error <= tolerance else "FAIL"
            print(f"  [{status}]")
    
    print("\n" + "=" * 80)
    print("STRATEGY USAGE SUMMARY:")
    print("-" * 80)
    for strategy, count in sorted(strategy_counts.items(), key=lambda x: -x[1]):
        success_rate = successes_by_strategy[strategy] / count if count > 0 else 0
        print(f"{strategy:30s}: {count:3d} uses, {successes_by_strategy[strategy]:3d} successes ({success_rate:.1%})")
    
    total_successes = sum(successes_by_strategy.values())
    total_episodes = sum(strategy_counts.values())
    print(f"\nOverall: {total_successes}/{total_episodes} = {total_successes/total_episodes:.1%}")

if __name__ == "__main__":
    debug_causal_strategies()
