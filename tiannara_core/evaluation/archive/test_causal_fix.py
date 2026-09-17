"""Test Causal Domain After Fix - Run 100 episodes to verify improvement."""

import sys
from pathlib import Path

project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.evaluation.causal_system_domain import CausalSystemGenerator
from tiannara_core.evaluation.causal_system_evolver import CausalSystemEvolver

def test_causal_domain():
    """Run 100 episodes on causal domain with fixed evolver."""
    gen = CausalSystemGenerator(seed=42)
    evolver = CausalSystemEvolver()
    
    print("Testing Fixed Causal System Evolver")
    print("=" * 80)
    
    successes = 0
    total = 100
    
    for episode in range(1, total + 1):
        task = gen.generate_task(episode)
        
        # Generate variant using evolver
        variant_func = evolver.create_variant(task, episode)
        
        # Call the variant function to get prediction (passes kwargs)
        task_inputs = task.get("inputs", {})
        predicted = variant_func(**task_inputs)
        
        # Evaluate prediction
        expected = task["expected_output"]
        
        # Extract values for comparison
        target_var = task.get("inputs", {}).get("target_variable", "y")
        if isinstance(expected, dict):
            expected_val = expected.get(target_var, 0)
        else:
            expected_val = expected
        
        if isinstance(predicted, dict):
            predicted_val = predicted.get(target_var, 0)
        else:
            predicted_val = predicted
        
        # Check if prediction is close enough (within 20% tolerance)
        error = abs(predicted_val - expected_val)
        tolerance = max(abs(expected_val) * 0.2, 0.5)  # 20% or 0.5, whichever is larger
        
        success = error <= tolerance
        if success:
            successes += 1
        
        # Progress indicator every 10 episodes
        if episode % 10 == 0:
            rate = successes / episode
            print(f"Episode {episode:3d}: Success rate = {rate:.1%} ({successes}/{episode})")
    
    print("\n" + "=" * 80)
    final_rate = successes / total
    print(f"FINAL RESULTS: {successes}/{total} = {final_rate:.1%} success")
    
    if final_rate >= 0.30:
        print("✅ Excellent! Causal domain achieves >30% success rate")
    elif final_rate >= 0.20:
        print("🟡 Good progress - causal domain improving but needs more work")
    else:
        print("⚠️ Still struggling - need additional improvements")
    
    return final_rate

if __name__ == "__main__":
    test_causal_domain()
