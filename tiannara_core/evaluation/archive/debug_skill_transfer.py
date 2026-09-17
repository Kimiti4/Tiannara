"""Debug why skill transfer is failing."""

import sys
from pathlib import Path

project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.evaluation.algorithm_domain import AlgorithmTaskGenerator
from tiannara_core.evaluation.logic_domain import LogicPuzzleGenerator
from tiannara_core.evaluation.run_multi_domain_experiment import CrossDomainSkillMemory

# Create skill memory
skill_memory = CrossDomainSkillMemory()

# Generate some tasks
algo_gen = AlgorithmTaskGenerator(seed=42)
logic_gen = LogicPuzzleGenerator(seed=43)

print("Testing Skill Memory")
print("=" * 80)

# Store a skill from algorithm domain
algo_task = algo_gen.generate_task(episode=1)
print(f"\nAlgorithm task type: {algo_task.get('type')}")
print(f"Algorithm task subtype: {algo_task.get('subtype')}")

# Try to store skill (we'll use a dummy function)
def dummy_solution(**kwargs):
    return 42

skill_memory.store_skill("algorithm", algo_task, dummy_solution)

print(f"\nSkills stored in algorithm domain: {len(skill_memory.domain_skills['algorithm'])}")
print(f"Abstract skills populated:")
for category, skills in skill_memory.abstract_skills.items():
    print(f"  {category}: {len(skills)} skills")

# Now try to get relevant skills for a logic task
logic_task = logic_gen.generate_task(episode=1)
print(f"\nLogic task type: {logic_task.get('type')}")
print(f"Logic task subtype: {logic_task.get('subtype')}")

relevant_skills = skill_memory.get_relevant_skills(
    "algorithm",  # source domain
    logic_task.get("type", ""),
    current_task_data={
        "subtype": logic_task.get("subtype", ""),
        "difficulty": logic_task.get("difficulty", "medium")
    }
)

print(f"\nRelevant skills found: {len(relevant_skills)}")
for skill in relevant_skills:
    print(f"  - {skill}")

# Check what categories were checked
print(f"\nChecking categorization logic...")
task_type = logic_task.get("type", "").lower()
subtype = logic_task.get("subtype", "").lower()

print(f"Task type: '{task_type}'")
print(f"Subtype: '{subtype}'")

# Check which categories would match
categories = []
if "pattern" in task_type or "infer" in task_type:
    categories.append("pattern_recognition")
if any(keyword in task_type.lower() for keyword in ["sort", "search", "sequence", "chain", "order"]):
    categories.append("sequential_reasoning")
if any(keyword in subtype.lower() for keyword in ["linear", "polynomial", "arithmetic", "geometric"]):
    categories.append("sequential_reasoning")
    
print(f"Categories matched: {categories}")
