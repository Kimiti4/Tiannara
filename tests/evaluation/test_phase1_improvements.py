"""Test Phase 1 improvements on reverse engineering domain."""

import sys
from pathlib import Path

project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.evaluation.reverse_engineering_domain import ReverseEngineeringGenerator
from tiannara_core.evaluation.reverse_engineering_evolver import ReverseEngineeringEvolver

print("="*80)
print("PHASE 1 IMPROVEMENTS TEST")
print("="*80)

# Test multiple seeds to get better statistical sample
seeds = [44, 50, 60, 70, 80]
total_success = 0
total_count = 0
subtype_stats = {}

for seed in seeds:
    gen = ReverseEngineeringGenerator(seed=seed)
    evolver = ReverseEngineeringEvolver(seed=seed+100)
    
    for episode in range(1, 21):  # 20 episodes per seed
        task = gen.generate_task(episode=episode)
        subtype = task.get("subtype", "unknown")
        
        if subtype not in subtype_stats:
            subtype_stats[subtype] = {"count": 0, "successes": 0}
        
        subtype_stats[subtype]["count"] += 1
        total_count += 1
        
        try:
            solution_func = evolver.create_variant(task, episode=episode)
            output = solution_func(**task["inputs"])
            success = gen.verify_solution(task, output)
            
            if success:
                subtype_stats[subtype]["successes"] += 1
                total_success += 1
        except Exception as e:
            pass

print(f"\nOverall Success Rate: {total_success}/{total_count} = {total_success/total_count*100:.1f}%\n")
print("Performance by Subtype:")
print("-"*80)

for subtype in sorted(subtype_stats.keys()):
    stats = subtype_stats[subtype]
    pct = stats["successes"] / stats["count"] * 100 if stats["count"] > 0 else 0
    print(f"{subtype:30s}: {stats['successes']:3d}/{stats['count']:3d} = {pct:5.1f}%")

print("\n" + "="*80)
print("COMPARISON WITH BASELINE (86% overall)")
print("="*80)
improvement = (total_success/total_count*100) - 86.0
if improvement > 0:
    print(f"✅ IMPROVEMENT: +{improvement:.1f}% (now at {total_success/total_count*100:.1f}%)")
elif improvement == 0:
    print(f"✓ NO CHANGE: Same as baseline (86.0%)")
else:
    print(f"⚠️  REGRESSION: {improvement:.1f}% (now at {total_success/total_count*100:.1f}%)")
