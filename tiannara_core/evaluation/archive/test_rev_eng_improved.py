"""Test improved Reverse Engineering Evolver."""

import sys
from pathlib import Path

project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.evaluation.reverse_engineering_domain import ReverseEngineeringGenerator
from tiannara_core.evaluation.reverse_engineering_evolver import ReverseEngineeringEvolver

def test_reverse_engineering():
    gen = ReverseEngineeringGenerator(seed=42)
    evolver = ReverseEngineeringEvolver(seed=125)
    
    successes = 0
    total = 50
    
    print("Testing Improved Reverse Engineering Evolver")
    print("=" * 60)
    
    for i in range(1, total + 1):
        task = gen.generate_task(i)
        variant = evolver.create_variant(task, i)
        
        try:
            output = variant(**task["inputs"])
            success = gen.verify_solution(task, output)
            
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
    print("=" * 60)
    print(f"FINAL RESULTS: {successes}/{total} = {final_rate:.1f}% success")
    print(f"Final quality level: {evolver.quality_level:.2f}")
    print(f"Skills stored: {len(evolver.skill_memory)}")
    
    return final_rate

if __name__ == "__main__":
    rate = test_reverse_engineering()
    
    if rate >= 50:
        print("\n✅ TARGET ACHIEVED! (>50% success)")
    elif rate >= 30:
        print("\n🟡 Good progress (30-50%), needs more improvement")
    else:
        print("\n⚠️ Below target (<30%), significant improvements needed")
