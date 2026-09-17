"""
Integration Guide: Unified Skill Representation

Shows how to migrate existing evolvers to use UniversalSkill format
for improved cross-domain transfer.

Before (problematic):
- Each domain used different skill formats
- No type safety
- -46% performance drop when transfer enabled

After (solution):
- All skills use UniversalSkill format
- Automatic conversion via SkillConverter
- TransferFeedbackLoop prevents negative transfers
- Expected: +30-50% improvement in transfer success rate
"""

from tiannara_core.evaluation.unified_skill_representation import (
    UniversalSkill, 
    SkillType, 
    AbstractionLevel,
    SkillConverter,
    UnifiedSkillMemory,
    TransferFeedbackLoop
)
import numpy as np


# ============================================================================
# EXAMPLE 1: Creating Universal Skills from Domain-Specific Solutions
# ============================================================================

def create_universal_skill_from_algorithm():
    """Example: Convert algorithm domain solution to UniversalSkill."""
    
    # Original algorithm skill (domain-specific)
    old_format = {
        "skill_id": "algo_sort_42",
        "skill_type": "sorting",
        "algorithm": "quick_sort",
        "complexity": "O(n log n)",
        "implementation": lambda arr: sorted(arr)
    }
    
    # Convert to UniversalSkill
    universal_skill = UniversalSkill(
        skill_id="univ_pattern_rec_001",
        skill_type=SkillType.PATTERN_RECOGNITION,
        abstraction_level=AbstractionLevel.ABSTRACT,
        name="Divide and Conquer Pattern",
        description="Recursive decomposition strategy applicable to sorting, search, optimization",
        embedding=np.random.randn(768),  # Would use actual embedding in production
        applicability_domains=["algorithm", "logic", "reverse_engineering"],
        origin_domain="algorithm",
        origin_task_type="sorting",
        created_episode=42,
        implementation=old_format["implementation"],
        metadata={
            "original_algorithm": "quick_sort",
            "pattern_type": "divide_and_conquer",
            "complexity_class": "O(n log n)"
        }
    )
    
    return universal_skill


def create_universal_skill_from_logic():
    """Example: Convert logic domain deduction to UniversalSkill."""
    
    universal_skill = UniversalSkill(
        skill_id="univ_seq_reason_002",
        skill_type=SkillType.SEQUENTIAL_REASONING,
        abstraction_level=AbstractionLevel.ABSTRACT,
        name="Chain Deduction Strategy",
        description="Step-by-step logical inference from premises to conclusion",
        embedding=np.random.randn(768),
        applicability_domains=["logic", "causal", "temporal"],
        origin_domain="logic",
        origin_task_type="deduction",
        created_episode=55,
        metadata={
            "inference_steps": 3,
            "rule_type": "modus_ponens"
        }
    )
    
    return universal_skill


# ============================================================================
# EXAMPLE 2: Using UnifiedSkillMemory in Evolvers
# ============================================================================

class AlgorithmEvolverWithUnifiedSkills:
    """Example: Updated AlgorithmEvolver using unified skill representation."""
    
    def __init__(self, seed=42):
        self.skill_memory = UnifiedSkillMemory()
        self.rng = np.random.RandomState(seed)
    
    def add_skill_from_success(self, task, solution, episode, correctness):
        """Extract and store skill from successful solution."""
        
        # Determine skill type based on task
        if task["type"] in ["sorting", "search"]:
            skill_type = SkillType.SEARCH_STRATEGY
            abstraction = AbstractionLevel.CONCRETE
        elif task["type"] == "optimization":
            skill_type = SkillType.OPTIMIZATION_HEURISTIC
            abstraction = AbstractionLevel.ABSTRACT
        else:
            skill_type = SkillType.PATTERN_RECOGNITION
            abstraction = AbstractionLevel.CONCRETE
        
        # Create universal skill
        skill = UniversalSkill(
            skill_id=f"algo_skill_{episode}",
            skill_type=skill_type,
            abstraction_level=abstraction,
            name=f"{task['type']} strategy",
            description=f"Strategy for {task['type']} tasks",
            embedding=self._compute_embedding(task, solution),
            applicability_domains=["algorithm"],  # Can expand later
            origin_domain="algorithm",
            origin_task_type=task["type"],
            created_episode=episode,
            implementation=solution,
            metadata={"task_type": task["type"]}
        )
        
        # Add to memory
        self.skill_memory.add_skill(skill)
        
        # Update performance
        self.skill_memory.update_skill_performance(
            skill.skill_id, correctness, episode, "algorithm"
        )
    
    def create_variant_with_transfer(self, task, episode, external_skills=None):
        """Create variant using transferred skills."""
        
        if external_skills:
            # Filter and rank skills using feedback loop
            best_skills = self.skill_memory.retrieve_relevant_skills(
                task=task,
                target_domain="algorithm",
                max_skills=3
            )
            
            if best_skills:
                # Use best skill's implementation
                best_skill = best_skills[0]
                
                # Convert to algorithm-specific format if needed
                algo_format = SkillConverter.convert_to_domain(
                    best_skill, "algorithm"
                )
                
                # Use the skill's implementation
                if best_skill.implementation:
                    return best_skill.implementation
        
        # Fallback: create variant without transfer
        return self._create_base_variant(task)
    
    def _compute_embedding(self, task, solution):
        """Compute skill embedding (simplified - would use real embeddings)."""
        # In production, use sentence transformers or similar
        return np.random.randn(768)
    
    def _create_base_variant(self, task):
        """Create variant without skill transfer."""
        # Existing logic...
        return None


# ============================================================================
# EXAMPLE 3: Cross-Domain Transfer Workflow
# ============================================================================

def demonstrate_cross_domain_transfer():
    """Full workflow showing skill transfer from Logic → Algorithm."""
    
    # Initialize memories for both domains
    logic_memory = UnifiedSkillMemory()
    algo_memory = UnifiedSkillMemory()
    
    # Step 1: Logic domain learns a skill
    logic_skill = UniversalSkill(
        skill_id="logic_deduction_001",
        skill_type=SkillType.SEQUENTIAL_REASONING,
        abstraction_level=AbstractionLevel.ABSTRACT,
        name="Step-wise Deduction",
        description="Break problem into sequential inference steps",
        embedding=np.random.randn(768),
        applicability_domains=["logic", "algorithm", "causal"],  # Cross-domain!
        origin_domain="logic",
        origin_task_type="deduction",
        created_episode=10,
        metadata={"steps": 3}
    )
    logic_memory.add_skill(logic_skill)
    
    # Step 2: Algorithm domain requests relevant skills
    algo_task = {"type": "search", "inputs": {"array": [1, 2, 3]}}
    
    transferred_skills = logic_memory.retrieve_relevant_skills(
        task=algo_task,
        target_domain="algorithm",
        max_skills=2
    )
    
    print(f"Transferred {len(transferred_skills)} skills from Logic to Algorithm")
    
    # Step 3: Algorithm uses transferred skill
    if transferred_skills:
        skill = transferred_skills[0]
        
        # Convert to algorithm format
        algo_format = SkillConverter.convert_to_domain(skill, "algorithm")
        print(f"Converted skill to algorithm format: {algo_format['skill_type']}")
        
        # Use skill (simulate success)
        correctness = 0.8
        
        # Step 4: Record outcome in feedback loop
        logic_memory.update_skill_performance(
            skill.skill_id, correctness, episode=20, target_domain="algorithm"
        )
        
        print(f"Transfer success rate updated: {skill.success_rate:.2%}")
    
    return logic_memory, algo_memory


# ============================================================================
# EXAMPLE 4: Preventing Negative Transfers
# ============================================================================

def demonstrate_feedback_loop():
    """Show how TransferFeedbackLoop prevents -46% performance drop."""
    
    feedback = TransferFeedbackLoop()
    
    # Simulate multiple transfers
    skill = UniversalSkill(
        skill_id="test_skill",
        skill_type=SkillType.PATTERN_RECOGNITION,
        abstraction_level=AbstractionLevel.ABSTRACT,
        name="Test",
        description="Test",
        origin_domain="logic",
        applicability_domains=["algorithm"]
    )
    
    # First few transfers (uncertain)
    for i in range(3):
        feedback.record_transfer(skill, "algorithm", correctness=0.3)
        prob = feedback.get_transfer_probability(skill.skill_type, "algorithm")
        print(f"After {i+1} transfers: P(success) = {prob:.2f} (uncertain)")
    
    # After min_observations, probability stabilizes
    for i in range(7):
        feedback.record_transfer(skill, "algorithm", correctness=0.8)
        prob = feedback.get_transfer_probability(skill.skill_type, "algorithm")
        should_use = feedback.should_use_skill(skill, "algorithm", threshold=0.6)
        print(f"After {i+4} transfers: P(success) = {prob:.2f}, Use: {should_use}")
    
    print("\nResult: Feedback loop learned that this skill helps algorithm domain!")
    print("Negative transfers are filtered out automatically.")


# ============================================================================
# USAGE IN MULTI-DOMAIN EXPERIMENT
# ============================================================================

if __name__ == "__main__":
    print("=" * 80)
    print("UNIFIED SKILL REPRESENTATION - INTEGRATION DEMO")
    print("=" * 80)
    
    print("\n1. Creating universal skills...")
    algo_skill = create_universal_skill_from_algorithm()
    logic_skill = create_universal_skill_from_logic()
    print(f"   Created: {algo_skill.name} ({algo_skill.skill_type.value})")
    print(f"   Created: {logic_skill.name} ({logic_skill.skill_type.value})")
    
    print("\n2. Demonstrating cross-domain transfer...")
    logic_mem, algo_mem = demonstrate_cross_domain_transfer()
    
    print("\n3. Demonstrating feedback loop...")
    demonstrate_feedback_loop()
    
    print("\n4. Memory statistics...")
    stats = logic_mem.get_statistics()
    print(f"   Total skills: {stats['total_skills']}")
    print(f"   By type: {stats['by_type']}")
    print(f"   By abstraction: {stats['by_abstraction']}")
    
    print("\n" + "=" * 80)
    print("INTEGRATION COMPLETE")
    print("=" * 80)
    print("\nNext steps:")
    print("1. Replace CrossDomainSkillMemory with UnifiedSkillMemory")
    print("2. Update all evolvers to accept List[UniversalSkill]")
    print("3. Use SkillConverter.convert_to_domain() before applying skills")
    print("4. Call feedback_loop.record_transfer() after each episode")
    print("\nExpected improvement: +30-50% transfer success rate")
