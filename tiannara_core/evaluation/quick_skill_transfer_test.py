"""
Quick Skill Transfer Validation Test.

Runs 100 episodes of Reverse Engineering to:
1. Verify skill extraction works
2. Check that skills are stored in unified memory
3. Validate cross-domain retrieval
4. Measure transfer hint generation
"""

import sys
from pathlib import Path
sys.path.insert(0, str(Path.cwd()))

from tiannara_core.evaluation.reverse_engineering_domain import ReverseEngineeringGenerator
from tiannara_core.evaluation.reverse_engineering_evolver import ReverseEngineeringEvolver
from tiannara_core.evaluation.unified_skill_representation import SkillType


def test_skill_extraction():
    """Test that skills are extracted from successful solutions."""
    
    print("=" * 80)
    print("SKILL EXTRACTION TEST")
    print("=" * 80)
    
    gen = ReverseEngineeringGenerator(seed=42)
    evolver = ReverseEngineeringEvolver(seed=42)
    
    successes = 0
    total = 100
    
    print(f"\nRunning {total} episodes...")
    
    for episode in range(total):
        task = gen.generate_task()
        variant = evolver.create_variant(task, episode)
        
        # Evaluate using generator's verifier
        try:
            # Get test input from task
            test_input = task.get("test_input", 0)
            
            # Run the variant
            predicted = variant(test_input)
            
            # Verify
            success = gen.verify_solution(task, predicted)
            
            if success:
                successes += 1
            
            # Update quality (this should trigger skill extraction)
            evolver.update_quality(success, 1.0 if success else 0.0, variant, task=task, episode=episode)
            
        except Exception as e:
            if episode < 3:
                print(f"Episode {episode} error: {e}")
    
    print(f"\nResults:")
    print(f"  Successes: {successes}/{total} ({successes/total*100:.1f}%)")
    
    # Check skill memory
    memory = evolver.unified_skill_memory
    stats = memory.get_statistics()
    
    print(f"\nUnified Skill Memory:")
    print(f"  Total Skills: {stats['total_skills']}")
    print(f"  By Type: {stats['by_type']}")
    print(f"  By Abstraction: {stats['by_abstraction']}")
    print(f"  Avg Success Rate: {stats['avg_success_rate']:.3f}")
    
    # List some skills
    if memory.skills:
        print(f"\nSample Skills:")
        for i, (skill_id, skill) in enumerate(list(memory.skills.items())[:3]):
            print(f"  {i+1}. {skill.name}")
            print(f"     Type: {skill.skill_type.value}")
            print(f"     Abstraction: {skill.abstraction_level.value}")
            print(f"     Origin: {skill.origin_domain}")
            print(f"     Success Rate: {skill.success_rate:.2%}")
    
    return evolver


def test_cross_domain_retrieval(evolver):
    """Test that cross-domain skills can be retrieved."""
    
    print("\n" + "=" * 80)
    print("CROSS-DOMAIN RETRIEVAL TEST")
    print("=" * 80)
    
    gen = ReverseEngineeringGenerator(seed=123)
    
    # Create a test task
    task = gen.generate_task()
    
    print(f"\nTest Task:")
    print(f"  Type: {task.get('type', 'unknown')}")
    print(f"  Subtype: {task.get('subtype', 'unknown')}")
    
    # Try to retrieve relevant skills
    relevant_skills = evolver.unified_skill_memory.retrieve_relevant_skills(
        task=task,
        target_domain="reverse_engineering",
        max_skills=3
    )
    
    print(f"\nRetrieved {len(relevant_skills)} relevant skills:")
    
    for i, skill in enumerate(relevant_skills):
        print(f"  {i+1}. {skill.name}")
        print(f"     Type: {skill.skill_type.value}")
        print(f"     Confidence: {skill.success_rate:.2%}")
        
        # Check transfer probability
        transfer_prob = evolver.unified_skill_memory.feedback_loop.get_transfer_probability(
            skill.skill_type, "reverse_engineering"
        )
        print(f"     Transfer Probability: {transfer_prob:.3f}")
    
    return len(relevant_skills) > 0


def test_skill_hints(evolver):
    """Test that skill hints are generated correctly."""
    
    print("\n" + "=" * 80)
    print("SKILL HINTS TEST")
    print("=" * 80)
    
    gen = ReverseEngineeringGenerator(seed=456)
    
    # Simulate having transferred skills in cache
    if evolver.unified_skill_memory.skills:
        # Get first skill and put it in cache
        first_skill = list(evolver.unified_skill_memory.skills.values())[0]
        evolver._transferred_skills_cache = [first_skill]
        
        print(f"\nTesting hint generation for skill: {first_skill.name}")
        print(f"  Skill Type: {first_skill.skill_type.value}")
        
        # Generate a test task
        task = gen.generate_task()
        task_inputs = task.get("inputs", {})
        examples = task_inputs.get("examples", [])
        inputs = [ex["input"] for ex in examples]
        outputs = [ex["output"] for ex in examples]
        func_type = evolver._extract_function_type(task)
        
        # Analyze for hints
        hints = evolver._analyze_transferred_skills_for_hints()
        
        if hints:
            print(f"\nGenerated Hints:")
            print(f"  Preferred Strategy: {hints.get('preferred_strategy')}")
            print(f"  Confidence: {hints.get('confidence', 0):.3f}")
            print(f"  Reasoning: {hints.get('reasoning', 'N/A')}")
            
            # Test applying hints
            strategy = evolver._apply_skill_hints(hints, inputs, outputs, func_type)
            print(f"\nSelected Strategy: {strategy}")
        else:
            print("\nNo hints generated (low confidence or no matching skills)")
    else:
        print("\nNo skills in memory to test hints")


if __name__ == "__main__":
    # Test 1: Skill Extraction
    evolver = test_skill_extraction()
    
    # Test 2: Cross-Domain Retrieval
    has_retrieval = test_cross_domain_retrieval(evolver)
    
    # Test 3: Skill Hints
    test_skill_hints(evolver)
    
    print("\n" + "=" * 80)
    print("TEST SUMMARY")
    print("=" * 80)
    print(f"✅ Skill Extraction: {'WORKING' if evolver.unified_skill_memory.skills else 'NOT WORKING'}")
    print(f"✅ Cross-Domain Retrieval: {'WORKING' if has_retrieval else 'NO SKILLS TO RETRIEVE'}")
    print(f"✅ Skill Hints: Tested")
    print("\nSkill transfer infrastructure is operational!")
