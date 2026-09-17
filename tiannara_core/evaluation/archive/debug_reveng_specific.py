"""Debug specific Reverse Engineering domain failures."""

import sys
from pathlib import Path

project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.evaluation.reverse_engineering_domain import ReverseEngineeringGenerator
from tiannara_core.evaluation.reverse_engineering_evolver import ReverseEngineeringEvolver

def debug_failures():
    """Analyze specific failing tasks."""
    
    gen = ReverseEngineeringGenerator(seed=44)
    evolver = ReverseEngineeringEvolver(seed=125)
    
    print("Debugging Reverse Engineering Domain Failures")
    print("=" * 80)
    
    fail_count = 0
    subtype_fails = {}
    
    for episode in range(1, 101):
        task = gen.generate_task(episode=episode)
        subtype = task.get("subtype", "unknown")
        
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
                subtype_fails[subtype] = subtype_fails.get(subtype, 0) + 1
                
                if fail_count <= 15:  # Show first 15 failures
                    print(f"\nEpisode {episode}: {task['type']} (subtype: {subtype})")
                    print(f"  Task: {task.get('description', 'N/A')[:120]}")
                    examples = task["inputs"].get("examples", [])
                    print(f"  Examples: {examples[:5]}")  # Show first 5 examples
                    test_input = task["inputs"].get("test_input", "N/A")
                    print(f"  Test input: {test_input}")
                    print(f"  Expected: {expected}")
                    print(f"  Got: {output_value}")
                    if isinstance(expected, (int, float)):
                        print(f"  Error: {abs(output_value - expected):.6f}")
                    
                    # Check quality level
                    print(f"  Evolver quality: {evolver.quality_level:.3f}")
                    
                    # Try to determine which strategy was used
                    unique_outputs = len(set([ex["output"] for ex in examples]))
                    print(f"  Unique outputs: {unique_outputs}")
                    if unique_outputs <= 3 and len(examples) >= 5:
                        print(f"  → Should use rule_extraction (modulo/threshold)")
                    elif evolver._is_linear(inputs=[ex["input"] for ex in examples], outputs=[ex["output"] for ex in examples]):
                        print(f"  → Should use linear_fit")
            
            # Update quality
            evolver.update_quality(success)
                    
        except Exception as e:
            fail_count += 1
            subtype_fails[subtype] = subtype_fails.get(subtype, 0) + 1
            print(f"\nEpisode {episode}: EXCEPTION - {e}")
    
    print(f"\n{'=' * 80}")
    print(f"Total failures: {fail_count}/100 = {fail_count}%")
    print(f"\nFailures by subtype:")
    for subtype, count in sorted(subtype_fails.items(), key=lambda x: -x[1]):
        print(f"  {subtype}: {count}")

if __name__ == "__main__":
    debug_failures()
