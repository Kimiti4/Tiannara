"""
Analyze why reverse engineering performance drops with skill transfer.

Tests whether transferred skills from other domains help or hurt RE tasks.
"""

import sys
from pathlib import Path

project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.evaluation.reverse_engineering_domain import ReverseEngineeringGenerator
from tiannara_core.evaluation.algorithm_domain import AlgorithmTaskGenerator
from tiannara_core.evaluation.logic_domain import LogicPuzzleGenerator
from tiannara_core.evaluation.causal_system_domain import CausalSystemGenerator
from tiannara_core.evaluation.reverse_engineering_evolver import ReverseEngineeringEvolver
from tiannara_core.evaluation.run_multi_domain_experiment import CrossDomainSkillMemory

# Initialize components
re_gen = ReverseEngineeringGenerator(seed=44)
algo_gen = AlgorithmTaskGenerator(seed=42)
logic_gen = LogicPuzzleGenerator(seed=43)
causal_gen = CausalSystemGenerator(seed=45)

re_evolver = ReverseEngineeringEvolver(seed=125)
skill_memory = CrossDomainSkillMemory()

print("="*80)
print("REVERSE ENGINEERING SKILL TRANSFER ANALYSIS")
print("="*80)

# First, populate skill memory with some successful skills from other domains
print("\nStep 1: Populating skill memory with skills from other domains...")

# Generate and store algorithm skills
for ep in range(1, 11):
    task = algo_gen.generate_task(episode=ep)
    
    # Create a simple solution (we'll just simulate success for testing)
    def algo_solution(**kwargs):
        return 42
    
    skill_categories = skill_memory.categorize_skill(
        "algorithm",
        task.get("type", ""),
        task.get("subtype", "")
    )
    
    skill_data = {
        "task_type": task.get("type", ""),
        "subtype": task.get("subtype", ""),
        "difficulty": task.get("difficulty", "medium"),
        "score": 1.0,
        "domain": "algorithm"
    }
    
    skill_memory.add_skill("algorithm", skill_categories, skill_data)

print(f"  Algorithm skills stored: {len(skill_memory.domain_skills['algorithm'])}")

# Generate and store logic skills
for ep in range(1, 11):
    task = logic_gen.generate_task(episode=ep)
    
    skill_categories = skill_memory.categorize_skill(
        "logic",
        task.get("type", ""),
        task.get("subtype", "")
    )
    
    skill_data = {
        "task_type": task.get("type", ""),
        "subtype": task.get("subtype", ""),
        "difficulty": task.get("difficulty", "medium"),
        "score": 1.0,
        "domain": "logic"
    }
    
    skill_memory.add_skill("logic", skill_categories, skill_data)

print(f"  Logic skills stored: {len(skill_memory.domain_skills['logic'])}")

# Generate and store causal skills
for ep in range(1, 11):
    task = causal_gen.generate_task(episode=ep)
    
    skill_categories = skill_memory.categorize_skill(
        "causal",
        task.get("type", ""),
        task.get("subtype", "")
    )
    
    skill_data = {
        "task_type": task.get("type", ""),
        "subtype": task.get("subtype", ""),
        "difficulty": task.get("difficulty", "medium"),
        "score": 1.0,
        "domain": "causal"
    }
    
    skill_memory.add_skill("causal", skill_categories, skill_data)

print(f"  Causal skills stored: {len(skill_memory.domain_skills['causal'])}")

# Now test RE tasks with and without transferred skills
print("\nStep 2: Testing RE tasks with vs without transferred skills...")

test_episodes = list(range(1, 21))  # Test 20 episodes
results_with_transfer = []
results_without_transfer = []

for episode in test_episodes:
    task = re_gen.generate_task(episode=episode)
    task_type = task.get("type", "")
    subtype = task.get("subtype", "")
    
    # Get transferred skills
    other_domains = ["algorithm", "logic", "causal"]
    transferred_skills = []
    for other_domain in other_domains:
        skills = skill_memory.get_relevant_skills(
            other_domain,
            task_type,
            current_task_data={
                "subtype": subtype,
                "difficulty": task.get("difficulty", "medium")
            }
        )
        transferred_skills.extend(skills[:2])
    
    # Test WITHOUT transfer
    evolver_no_transfer = ReverseEngineeringEvolver(seed=125 + episode)
    solution_no = evolver_no_transfer.create_variant(task, episode=episode)
    
    try:
        output_no = solution_no(**task["inputs"])
        success_no = re_gen.verify_solution(task, output_no)
    except Exception as e:
        success_no = False
    
    results_without_transfer.append(success_no)
    
    # Test WITH transfer
    evolver_with_transfer = ReverseEngineeringEvolver(seed=125 + episode)
    solution_with = evolver_with_transfer.create_variant(
        task, 
        episode=episode,
        external_skills=transferred_skills if transferred_skills else None
    )
    
    try:
        output_with = solution_with(**task["inputs"])
        success_with = re_gen.verify_solution(task, output_with)
    except Exception as e:
        success_with = False
    
    results_with_transfer.append(success_with)
    
    # Log details for mismatched cases
    if success_no != success_with:
        print(f"\n  Episode {episode} ({subtype}):")
        print(f"    Without transfer: {'✓' if success_no else '✗'}")
        print(f"    With transfer:    {'✓' if success_with else '✗'}")
        print(f"    Transferred skills: {len(transferred_skills)}")
        if transferred_skills:
            for skill in transferred_skills[:2]:
                skill_info = skill.get("skill", {})
                print(f"      - {skill_info.get('domain', '?')}: {skill_info.get('task_type', '?')}")

# Calculate statistics
success_no_count = sum(results_without_transfer)
success_with_count = sum(results_with_transfer)
total = len(test_episodes)

print("\n" + "="*80)
print("RESULTS SUMMARY")
print("="*80)
print(f"\nTotal episodes tested: {total}")
print(f"Without transfer: {success_no_count}/{total} = {success_no_count/total*100:.1f}%")
print(f"With transfer:    {success_with_count}/{total} = {success_with_count/total*100:.1f}%")
print(f"Difference:       {success_with_count - success_no_count:+d} ({(success_with_count - success_no_count)/total*100:+.1f}%)")

# Analyze by subtype
print("\nBreakdown by Subtype:")
print("-"*80)

subtype_stats = {}
for i, episode in enumerate(test_episodes):
    task = re_gen.generate_task(episode=episode)
    subtype = task.get("subtype", "unknown")
    
    if subtype not in subtype_stats:
        subtype_stats[subtype] = {"no_transfer": 0, "with_transfer": 0, "count": 0}
    
    subtype_stats[subtype]["count"] += 1
    if results_without_transfer[i]:
        subtype_stats[subtype]["no_transfer"] += 1
    if results_with_transfer[i]:
        subtype_stats[subtype]["with_transfer"] += 1

for subtype in sorted(subtype_stats.keys()):
    stats = subtype_stats[subtype]
    no_rate = stats["no_transfer"] / stats["count"] * 100
    with_rate = stats["with_transfer"] / stats["count"] * 100
    diff = with_rate - no_rate
    
    print(f"{subtype:25s}: No transfer {no_rate:5.1f}% | With transfer {with_rate:5.1f}% | Diff {diff:+5.1f}%")

print("\n" + "="*80)
print("CONCLUSION")
print("="*80)

if success_with_count < success_no_count:
    print(f"WARNING: Skill transfer HURTS RE performance by {success_no_count - success_with_count} episodes")
    print("   Possible causes:")
    print("   - Incompatible skills from other domains interfering with RE strategies")
    print("   - Wrong strategy selection due to misleading skill information")
    print("   - Need domain-specific filtering for skill transfer")
elif success_with_count > success_no_count:
    print(f"GOOD: Skill transfer HELPS RE performance by {success_with_count - success_no_count} episodes")
else:
    print("OK: Skill transfer has NO effect on RE performance")
