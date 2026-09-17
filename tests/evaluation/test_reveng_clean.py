"""Clean test of reverse engineering domain."""

import sys
from pathlib import Path

project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.evaluation.reverse_engineering_domain import ReverseEngineeringGenerator
from tiannara_core.evaluation.reverse_engineering_evolver import ReverseEngineeringEvolver

gen = ReverseEngineeringGenerator(seed=44)
evolver = ReverseEngineeringEvolver(seed=125)

print("Testing Reverse Engineering Domain - Clean Run")
print("=" * 80)

total_success = 0
total_count = 0
subtype_stats = {}

for episode in range(1, 101):
    task = gen.generate_task(episode=episode)
    subtype = task.get("subtype", "unknown")
    
    if subtype not in subtype_stats:
        subtype_stats[subtype] = {"count": 0, "successes": 0}
    
    subtype_stats[subtype]["count"] += 1
    total_count += 1
    
    # Create variant
    solution_func = evolver.create_variant(task, episode=episode)
    
    # Get prediction
    try:
        output = solution_func(**task["inputs"])
        
        # Verify
        success = gen.verify_solution(task, output)
        
        if success:
            subtype_stats[subtype]["successes"] += 1
            total_success += 1
            
    except Exception as e:
        pass

print(f"\nOverall Success Rate: {total_success}/{total_count} = {total_success/total_count*100:.1f}%\n")
print("Performance by Subtype:")
print("-" * 80)

for subtype in sorted(subtype_stats.keys()):
    stats = subtype_stats[subtype]
    pct = stats["successes"] / stats["count"] * 100 if stats["count"] > 0 else 0
    print(f"{subtype:30s}: {stats['successes']:3d}/{stats['count']:3d} = {pct:5.1f}%")
