"""Analyze Logic Domain Failures."""

import sys
from pathlib import Path

project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.evaluation.logic_domain import LogicPuzzleGenerator
from tiannara_core.evaluation.logic_evolution_engine import LogicPuzzleEvolver
from tiannara_core.evaluation.evaluator import Evaluator

def analyze_logic_failures():
    """Run 100 logic episodes and analyze failure patterns."""
    
    gen = LogicPuzzleGenerator(seed=42)
    evolver = LogicPuzzleEvolver(seed=124)
    evaluator = Evaluator()
    
    print("Analyzing Logic Domain Performance")
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
    print(f"\nOverall Success Rate: {total_success}/{total_count} = {total_success/total_count*100:.1f}%")
    print("\n" + "-" * 80)
    print("Performance by Subtype:")
    print("-" * 80)
    
    for subtype, stats in sorted(subtype_stats.items()):
        rate = stats["successes"] / stats["count"] * 100 if stats["count"] > 0 else 0
        print(f"\n{subtype.upper():30s}: {stats['successes']:3d}/{stats['count']:3d} = {rate:5.1f}%")
        
        # Show sample errors
        if stats["errors"] and len(stats["errors"]) > 0:
            print(f"  Sample failures ({len(stats['errors'])} total):")
            for err in stats["errors"][:3]:  # Show first 3
                if err.get("exception"):
                    print(f"    Episode {err['episode']}: EXCEPTION - {err['error']}")
                else:
                    print(f"    Episode {err['episode']}: correctness={err['correctness']:.3f}, expected={err['expected']}, got={err['got']}")
    
    print("\n" + "=" * 80)
    print("Key Insights:")
    print("-" * 80)
    
    # Identify worst performing subtypes
    worst_subtypes = sorted(subtype_stats.items(), key=lambda x: x[1]["successes"]/x[1]["count"] if x[1]["count"] > 0 else 0)
    
    print(f"\nWORST PERFORMING SUBTYPES (need improvement):")
    for subtype, stats in worst_subtypes[:3]:
        rate = stats["successes"] / stats["count"] * 100 if stats["count"] > 0 else 0
        print(f"  {subtype:30s}: {rate:.1f}% success ({stats['count']} tasks)")
    
    print(f"\nBEST PERFORMING SUBTYPES:")
    for subtype, stats in worst_subtypes[-3:]:
        rate = stats["successes"] / stats["count"] * 100 if stats["count"] > 0 else 0
        print(f"  {subtype:30s}: {rate:.1f}% success ({stats['count']} tasks)")

if __name__ == "__main__":
    analyze_logic_failures()
