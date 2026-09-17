"""Test improved Causal System Evolver with PC algorithm."""

import sys
from pathlib import Path

project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.evaluation.causal_system_domain import CausalSystemGenerator
from tiannara_core.evaluation.causal_system_evolver import CausalSystemEvolver

def test_causal_system():
    gen = CausalSystemGenerator(seed=45)
    evolver = CausalSystemEvolver(seed=126)
    
    successes = 0
    total = 50
    
    print("Testing Improved Causal System Evolver (with PC Algorithm)")
    print("=" * 70)
    
    for i in range(1, total + 1):
        task = gen.generate_task(i)
        variant = evolver.create_variant(task, i)
        
        try:
            # Extract intervention from task inputs
            task_inputs = task.get("inputs", {})
            output = variant(**task_inputs)
            
            # Extract predicted value for target variable
            target_var = task_inputs.get("target_variable", "y")
            if isinstance(output, dict):
                predicted_value = output.get(target_var, 0)
            else:
                predicted_value = output
            
            success = gen.verify_solution(task, predicted_value)
            
            if success:
                successes += 1
                evolver.update_quality(True)
            else:
                evolver.update_quality(False)
                
        except Exception as e:
            evolver.update_quality(False)
        
        if i % 10 == 0:
            rate = successes / i * 100
            print(f"Episode {i:3d}: Success rate = {rate:5.1f}% ({successes}/{i}) | Quality: {evolver.quality_level:.2f}")
    
    final_rate = successes / total * 100
    print()
    print("=" * 70)
    print(f"FINAL RESULTS: {successes}/{total} = {final_rate:.1f}% success")
    print(f"Final quality level: {evolver.quality_level:.2f}")
    print(f"Skills stored: {len(evolver.skill_memory)}")
    
    return final_rate

if __name__ == "__main__":
    rate = test_causal_system()
    
    if rate >= 30:
        print("\n✅ TARGET ACHIEVED! (>30% success)")
    elif rate >= 15:
        print("\n🟡 Good progress (15-30%), moderate improvement needed")
    else:
        print("\n⚠️ Below target (<15%), significant improvements needed")
