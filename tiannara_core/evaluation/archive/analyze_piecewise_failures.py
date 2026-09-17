"""Analyze piecewise function failures in detail."""

import sys
from pathlib import Path

project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.evaluation.reverse_engineering_domain import ReverseEngineeringGenerator
from tiannara_core.evaluation.reverse_engineering_evolver import ReverseEngineeringEvolver

gen = ReverseEngineeringGenerator(seed=44)
evolver = ReverseEngineeringEvolver(seed=125)

print("Analyzing Piecewise Function Failures")
print("=" * 80)

piecewise_count = 0
fail_count = 0
for episode in range(1, 101):
    task = gen.generate_task(episode=episode)
    subtype = task.get("subtype", "unknown")
    
    if subtype == "piecewise":
        piecewise_count += 1
        
        # Extract examples
        examples = task["inputs"].get("examples", [])
        
        # Deduplicate
        seen = set()
        unique_examples = []
        for ex in examples:
            key = (ex["input"], ex["output"])
            if key not in seen:
                seen.add(key)
                unique_examples.append(ex)
        
        inputs = [ex["input"] for ex in unique_examples]
        outputs = [ex["output"] for ex in unique_examples]
        
        # Check strategy selection
        strategy = evolver._select_best_strategy(inputs, outputs, "piecewise")
        
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
                
                print(f"\nEpisode {episode}:")
                print(f"  Examples: {len(examples)} total, {len(unique_examples)} unique")
                print(f"  Inputs: {inputs}")
                print(f"  Outputs: {outputs}")
                print(f"  Expected: {expected}")
                print(f"  Got: {output}")
                print(f"  Error: {error:.4f}")
                print(f"  Strategy selected: {strategy}")
                
                # Test piecewise detection
                is_pw = evolver._is_piecewise(inputs, outputs)
                print(f"  Is detected as piecewise: {is_pw}")
                
        except Exception as e:
            fail_count += 1
            print(f"\nEpisode {episode}: ERROR - {e}")

print(f"\n{'='*80}")
print(f"Total piecewise tasks: {piecewise_count}")
print(f"Failed: {fail_count} ({fail_count/piecewise_count*100:.1f}%)")
print(f"Succeeded: {piecewise_count - fail_count} ({(piecewise_count-fail_count)/piecewise_count*100:.1f}%)")
