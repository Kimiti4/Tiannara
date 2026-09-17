"""Debug specific Logic domain failures."""

import sys
from pathlib import Path

project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.evaluation.logic_domain import LogicPuzzleGenerator
from tiannara_core.evaluation.logic_evolution_engine import LogicPuzzleEvolver

def debug_failures():
    """Analyze specific failing tasks."""
    
    gen = LogicPuzzleGenerator(seed=42)
    evolver = LogicPuzzleEvolver(seed=124)
    
    print("Debugging Logic Domain Failures")
    print("=" * 80)
    
    fail_count = 0
    
    for episode in range(1, 101):
        task = gen.generate_task(episode=episode)
        
        # Create variant
        solution_func = evolver.create_variant(task, episode=episode)
        
        # Get prediction
        try:
            output = solution_func(**task["inputs"])
            if isinstance(output, dict):
                output_value = output.get("output", output)
            else:
                output_value = output
            
            expected = task.get("expected_output")
            success = gen.verify_solution(task, output_value)
            
            if not success:
                fail_count += 1
                
                if fail_count <= 10:  # Show first 10 failures
                    print(f"\nEpisode {episode}: {task['type']}")
                    print(f"  Task: {task.get('description', 'N/A')[:100]}")
                    print(f"  Inputs: {task['inputs']}")
                    print(f"  Expected: {expected}")
                    print(f"  Got: {output_value}")
                    print(f"  Error: {abs(output_value - expected) if isinstance(expected, (int, float)) else 'N/A'}")
                    
                    # Test what correct solver would give
                    seq = task["inputs"].get("sequence", [])
                    if seq and len(seq) >= 2:
                        diff = seq[1] - seq[0]
                        is_arithmetic = all(seq[i+1] - seq[i] == diff for i in range(len(seq)-1))
                        print(f"  Sequence: {seq}")
                        print(f"  Diff: {diff}, Is Arithmetic: {is_arithmetic}")
                        
                        if len(seq) >= 3:
                            ratio = seq[1] / seq[0] if seq[0] != 0 else None
                            is_geometric = ratio and all(abs(seq[i+1]/seq[i] - ratio) < 0.01 for i in range(len(seq)-1) if seq[i] != 0)
                            print(f"  Ratio: {ratio}, Is Geometric: {is_geometric}")
        
        except Exception as e:
            fail_count += 1
            print(f"\nEpisode {episode}: EXCEPTION - {e}")
    
    print(f"\n{'=' * 80}")
    print(f"Total failures: {fail_count}/100 = {fail_count}%")

if __name__ == "__main__":
    debug_failures()
