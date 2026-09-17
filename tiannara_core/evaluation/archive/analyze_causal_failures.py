"""Analyze Causal Domain Failures."""

import sys
from pathlib import Path

project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.evaluation.causal_system_domain import CausalSystemGenerator
from tiannara_core.evaluation.causal_system_evolver import CausalSystemEvolver
from tiannara_core.evaluation.evaluator import Evaluator

def analyze_causal_failures():
    """Run 100 causal episodes and analyze failure patterns."""
    
    gen = CausalSystemGenerator(seed=45)
    evolver = CausalSystemEvolver(seed=126)
    evaluator = Evaluator()
    
    print("Analyzing Causal Domain Performance")
    print("=" * 80)
    
    # Track by subtype
    subtype_stats = {}
    total_success = 0
    total_count = 0
    
    for episode in range(1, 101):
        task = gen.generate_task(episode=episode)
        subtype = task.get("subtype", "unknown")
        
        if subtype not in subtype_stats:
            subtype_stats[subtype] = {"count": 0, "successes": 0, "errors": []}
        
        subtype_stats[subtype]["count"] += 1
        total_count += 1
        
        # Create variant
        solution_func = evolver.create_variant(task, episode=episode)
        
        # Evaluate
        try:
            result = evaluator.evaluate(solution_func, task["inputs"])
            correctness = result["metrics"]["correctness"]
            
            # Verify
            output = solution_func(**task["inputs"])
            if isinstance(output, dict):
                output_value = output.get("output", output)
            else:
                output_value = output
            
            success = gen.verify_solution(task, output_value)
            
            # Update evolver quality
            if hasattr(evolver, 'update_quality'):
                evolver.update_quality(success, correctness, solution_func)
            
            if success:
                subtype_stats[subtype]["successes"] += 1
                total_success += 1
            else:
                # Track error info
                expected = task.get("expected_output")
                error_info = {
                    "episode": episode,
                    "correctness": correctness,
                    "expected": expected,
                    "got": output_value
                }
                subtype_stats[subtype]["errors"].append(error_info)
                
        except Exception as e:
            error_info = {
                "episode": episode,
                "error": str(e),
                "exception": True
            }
            subtype_stats[subtype]["errors"].append(error_info)
    
    # Print results
    print(f"\nOverall Success Rate: {total_success}/{total_count} = {total_success/total_count*100:.1f}%\n")
    
    print("Performance by Subtype:")
    print("-" * 80)
    for subtype, stats in sorted(subtype_stats.items()):
        success_rate = stats["successes"] / stats["count"] * 100 if stats["count"] > 0 else 0
        print(f"{subtype.upper():30s}: {stats['successes']:3d}/{stats['count']:3d} = {success_rate:5.1f}%")
    
    print("\n" + "=" * 80)
    print("Key Insights:")
    print("-" * 80)
    
    # Find worst performing subtypes
    worst_subtypes = sorted(subtype_stats.items(), key=lambda x: x[1]["successes"]/x[1]["count"] if x[1]["count"] > 0 else 0)
    
    print("\nWORST PERFORMING SUBTYPES (need improvement):")
    for subtype, stats in worst_subtypes[:3]:
        success_rate = stats["successes"] / stats["count"] * 100 if stats["count"] > 0 else 0
        print(f"  {subtype:30s}: {success_rate:.1f}% success ({stats['count']} tasks)")
    
    print("\nBEST PERFORMING SUBTYPES:")
    for subtype, stats in reversed(worst_subtypes[-3:]):
        success_rate = stats["successes"] / stats["count"] * 100 if stats["count"] > 0 else 0
        print(f"  {subtype:30s}: {success_rate:.1f}% success ({stats['count']} tasks)")
    
    # Show sample errors for worst subtype
    if worst_subtypes:
        worst_subtype = worst_subtypes[0][0]
        worst_errors = subtype_stats[worst_subtype]["errors"]
        if worst_errors:
            print(f"\nSample Errors from {worst_subtype}:")
            print("-" * 80)
            for error in worst_errors[:5]:
                if error.get("exception"):
                    print(f"  Episode {error['episode']}: EXCEPTION - {error['error']}")
                else:
                    print(f"  Episode {error['episode']}: type={worst_subtype}, correctness={error['correctness']:.3f}")
                    print(f"      Expected: {error['expected']}")
                    print(f"      Got: {error['got']}")

if __name__ == "__main__":
    analyze_causal_failures()
