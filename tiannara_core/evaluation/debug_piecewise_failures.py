"""Debug Piecewise Task Failures."""

import sys
from pathlib import Path

project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.evaluation.reverse_engineering_domain import ReverseEngineeringGenerator
from tiannara_core.evaluation.reverse_engineering_evolver import ReverseEngineeringEvolver

def debug_piecewise_failures():
    """Debug why piecewise tasks are failing."""
    
    gen = ReverseEngineeringGenerator(seed=42)
    evolver = ReverseEngineeringEvolver(seed=42)
    
    print("=" * 80)
    print("PIECEWISE TASK DEBUGGING")
    print("=" * 80)
    
    successes = []
    failures = []
    
    for i in range(100):
        task = gen.generate_task(episode=i)
        subtype = task.get("subtype", "unknown")
        
        if subtype != "piecewise":
            continue
        
        # Extract data
        examples = task["inputs"]["examples"]
        inputs = [ex["input"] for ex in examples]
        outputs = [ex["output"] for ex in examples]
        test_input = task["inputs"]["test_input"]
        expected = task["expected_output"]
        
        # Get strategy
        strategy = evolver._select_best_strategy(inputs, outputs, subtype)
        
        # Create variant and test
        variant = evolver.create_variant(task, episode=i)
        predicted = variant(test_input=test_input)
        
        success = abs(predicted - expected) < 0.01
        
        status = 'PASS' if success else 'FAIL'
        print(f"\nTask {i}: {status}")
        print(f"  Examples: {list(zip(inputs, outputs))}")
        print(f"  Test input: {test_input}, Expected: {expected}, Predicted: {predicted:.2f}")
        print(f"  Strategy: {strategy}")
        print(f"  Error: {abs(predicted - expected):.4f}")
        
        if success:
            successes.append({
                'task_id': i,
                'inputs': inputs,
                'outputs': outputs,
                'test_input': test_input,
                'expected': expected,
                'predicted': predicted,
                'strategy': strategy
            })
        else:
            failures.append({
                'task_id': i,
                'inputs': inputs,
                'outputs': outputs,
                'test_input': test_input,
                'expected': expected,
                'predicted': predicted,
                'strategy': strategy,
                'error': abs(predicted - expected)
            })
    
    print("\n" + "=" * 80)
    total = len(successes) + len(failures)
    print(f"SUMMARY: {len(successes)} successes, {len(failures)} failures out of {total} piecewise tasks")
    print(f"Success Rate: {len(successes)/total*100:.1f}%")
    print("=" * 80)
    
    # Analyze common failure patterns
    if failures:
        print("\nCommon Issues:")
        strategies_used = {}
        for f in failures:
            strategies_used[f['strategy']] = strategies_used.get(f['strategy'], 0) + 1
        
        for strategy, count in sorted(strategies_used.items(), key=lambda x: -x[1]):
            print(f"  {strategy}: {count} failures")
        
        # Show first few detailed failures
        print("\nDetailed Failure Analysis (first 3):")
        for f in failures[:3]:
            print(f"\n  Task {f['task_id']}:")
            print(f"    Data points: {len(f['inputs'])}")
            print(f"    Input range: [{min(f['inputs'])}, {max(f['inputs'])}]")
            print(f"    Output range: [{min(f['outputs'])}, {max(f['outputs'])}]")
            print(f"    Test point: {f['test_input']} (in range: {min(f['inputs']) <= f['test_input'] <= max(f['inputs'])})")
            print(f"    Strategy used: {f['strategy']}")
            print(f"    Prediction error: {f['error']:.4f}")
            
            # Try to understand the piecewise structure
            sorted_pairs = sorted(zip(f['inputs'], f['outputs']))
            print(f"    Sorted data: {sorted_pairs}")
            
            # Check slopes in different regions
            if len(sorted_pairs) >= 4:
                mid = len(sorted_pairs) // 2
                first_half = sorted_pairs[:mid]
                second_half = sorted_pairs[mid:]
                
                if len(first_half) >= 2 and len(second_half) >= 2:
                    slope1 = (first_half[-1][1] - first_half[0][1]) / (first_half[-1][0] - first_half[0][0]) if first_half[-1][0] != first_half[0][0] else 0
                    slope2 = (second_half[-1][1] - second_half[0][1]) / (second_half[-1][0] - second_half[0][0]) if second_half[-1][0] != second_half[0][0] else 0
                    print(f"    First half slope: {slope1:.2f}")
                    print(f"    Second half slope: {slope2:.2f}")
                    print(f"    Slope difference: {abs(slope1 - slope2):.2f}")

if __name__ == "__main__":
    debug_piecewise_failures()
