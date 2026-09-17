"""
Skill Abstraction Engine - Integration Example

Demonstrates how to integrate the SkillAbstractionEngine with existing
multi-domain experiments for automatic pattern extraction and transfer.

Usage:
    python tiannara_core/evaluation/skill_abstraction_integration.py
"""

import sys
sys.path.insert(0, '.')

from tiannara_core.evaluation.skill_abstraction_engine import SkillAbstractionEngine, AbstractPattern
from tiannara_core.evaluation.unified_skill_representation import UniversalSkill, SkillType, AbstractionLevel
import numpy as np


def simulate_multi_domain_experiment():
    """Simulate a multi-domain experiment with skill collection."""
    
    print("=" * 80)
    print("SKILL ABSTRACTION ENGINE - INTEGRATION EXAMPLE")
    print("=" * 80)
    print()
    
    # Initialize abstraction engine
    engine = SkillAbstractionEngine(min_cluster_size=2, similarity_threshold=0.5)
    
    # Simulate collecting skills from multiple domains
    print("Phase 1: Collecting concrete skills from 5 domains...")
    print("-" * 80)
    
    # Algorithm domain skills - add more similar ones for clustering
    algorithm_skills = [
        {
            "skill_id": "algo_sort_001",
            "domain": "algorithm",
            "strategy": {
                "type": "greedy_sorting",
                "requires": ["sorting", "comparison"],
                "operators": ["swap", "compare"]
            },
            "complexity": "medium",
            "performance": {"accuracy": 0.92, "speed": 0.85, "robustness": 0.88}
        },
        {
            "skill_id": "algo_search_002",
            "domain": "algorithm",
            "strategy": {
                "type": "binary_search",
                "requires": ["sorting", "comparison"],
                "operators": ["divide", "compare"]
            },
            "complexity": "low",
            "performance": {"accuracy": 0.95, "speed": 0.95, "robustness": 0.90}
        },
        {
            "skill_id": "algo_optimize_003",
            "domain": "algorithm",
            "strategy": {
                "type": "greedy_optimization",
                "requires": ["optimization", "iteration"],
                "operators": ["select_best", "update"]
            },
            "complexity": "high",
            "performance": {"accuracy": 0.78, "speed": 0.70, "robustness": 0.75}
        },
        {
            "skill_id": "algo_merge_sort_004",
            "domain": "algorithm",
            "strategy": {
                "type": "recursive_sorting",
                "requires": ["sorting", "comparison", "recursion"],
                "operators": ["split", "merge", "compare"]
            },
            "complexity": "medium",
            "performance": {"accuracy": 0.94, "speed": 0.82, "robustness": 0.90}
        }
    ]
    
    # Logic domain skills
    logic_skills = [
        {
            "skill_id": "logic_deduction_001",
            "domain": "logic",
            "strategy": {
                "type": "constraint_satisfaction",
                "requires": ["constraint_propagation", "backtracking"],
                "operators": ["deduce", "eliminate"]
            },
            "complexity": "medium",
            "performance": {"accuracy": 0.88, "speed": 0.75, "robustness": 0.82}
        },
        {
            "skill_id": "logic_truth_002",
            "domain": "logic",
            "strategy": {
                "type": "truth_table_analysis",
                "requires": ["enumeration", "comparison"],
                "operators": ["evaluate", "compare"]
            },
            "complexity": "low",
            "performance": {"accuracy": 0.98, "speed": 0.60, "robustness": 0.95}
        }
    ]
    
    # Temporal domain skills
    temporal_skills = [
        {
            "skill_id": "temporal_pattern_001",
            "domain": "temporal",
            "strategy": {
                "type": "pattern_recognition",
                "requires": ["sequence_analysis", "trend_detection"],
                "operators": ["fit", "extrapolate"]
            },
            "complexity": "medium",
            "performance": {"accuracy": 0.85, "speed": 0.80, "robustness": 0.78}
        },
        {
            "skill_id": "temporal_forecast_002",
            "domain": "temporal",
            "strategy": {
                "type": "ensemble_prediction",
                "requires": ["pattern_recognition", "averaging"],
                "operators": ["blend", "weight"]
            },
            "complexity": "high",
            "performance": {"accuracy": 0.90, "speed": 0.65, "robustness": 0.88}
        }
    ]
    
    # Causal domain skills
    causal_skills = [
        {
            "skill_id": "causal_inference_001",
            "domain": "causal",
            "strategy": {
                "type": "dependency_analysis",
                "requires": ["correlation", "conditioning"],
                "operators": ["regress", "test_independence"]
            },
            "complexity": "high",
            "performance": {"accuracy": 0.82, "speed": 0.60, "robustness": 0.75}
        },
        {
            "skill_id": "causal_intervention_002",
            "domain": "causal",
            "strategy": {
                "type": "counterfactual_reasoning",
                "requires": ["model_fitting", "simulation"],
                "operators": ["intervene", "predict"]
            },
            "complexity": "high",
            "performance": {"accuracy": 0.79, "speed": 0.55, "robustness": 0.72}
        }
    ]
    
    # Combinatorial optimization skills
    combo_skills = [
        {
            "skill_id": "combo_tsp_001",
            "domain": "combinatorial",
            "strategy": {
                "type": "greedy_heuristic",
                "requires": ["optimization", "iteration"],
                "operators": ["select_nearest", "update_path"]
            },
            "complexity": "medium",
            "performance": {"accuracy": 0.75, "speed": 0.90, "robustness": 0.70}
        },
        {
            "skill_id": "combo_knapsack_002",
            "domain": "combinatorial",
            "strategy": {
                "type": "dynamic_programming",
                "requires": ["optimization", "memoization"],
                "operators": ["subproblem_solve", "combine"]
            },
            "complexity": "high",
            "performance": {"accuracy": 0.95, "speed": 0.50, "robustness": 0.92}
        }
    ]
    
    # Add all skills to engine
    all_skills = algorithm_skills + logic_skills + temporal_skills + causal_skills + combo_skills
    
    for skill in all_skills:
        engine.add_concrete_skill(skill["skill_id"], skill)
        print(f"  Added: {skill['skill_id']} ({skill['domain']})")
    
    print(f"\nTotal skills collected: {len(all_skills)}")
    print()
    
    # Phase 2: Extract abstract patterns
    print("Phase 2: Extracting abstract patterns...")
    print("-" * 80)
    
    patterns = engine.extract_abstract_patterns()
    
    print()
    print(f"Extracted {len(patterns)} new patterns:")
    for pattern in patterns:
        print(f"  - {pattern.name}")
        print(f"    ID: {pattern.pattern_id}")
        print(f"    Level: {pattern.abstraction_level}")
        print(f"    Source skills: {len(pattern.source_skills)}")
        print(f"    Domains: {', '.join(pattern.domains_observed)}")
        print(f"    Success rate: {pattern.success_rate:.2%}")
        print(f"    Cross-domain score: {pattern.cross_domain_score:.2f}")
        print()
    
    # Phase 3: Get applicable patterns for a target domain
    print("Phase 3: Finding patterns applicable to 'temporal' domain...")
    print("-" * 80)
    
    applicable = engine.get_applicable_patterns(target_domain="temporal", min_cross_domain_score=0.3)
    
    if applicable:
        print(f"Found {len(applicable)} applicable patterns:\n")
        for i, pattern in enumerate(applicable[:5], 1):  # Show top 5
            print(f"{i}. {pattern.name}")
            print(f"   Relevance score: {pattern.cross_domain_score * pattern.success_rate:.3f}")
            print(f"   Domains observed: {', '.join(pattern.domains_observed)}")
            print()
    else:
        print("No applicable patterns found.")
    
    print()
    
    # Phase 4: Get statistics
    print("Phase 4: Abstraction engine statistics...")
    print("-" * 80)
    
    stats = engine.get_statistics()
    for key, value in stats.items():
        if isinstance(value, float):
            print(f"  {key}: {value:.4f}")
        else:
            print(f"  {key}: {value}")
    
    print()
    
    # Phase 5: Export patterns
    print("Phase 5: Exporting patterns for persistence...")
    print("-" * 80)
    
    exported = engine.export_patterns()
    print(f"Exported {len(exported['abstract_patterns'])} abstract patterns")
    print(f"Exported {len(exported['meta_patterns'])} meta patterns")
    print()
    
    print("=" * 80)
    print("INTEGRATION COMPLETE")
    print("=" * 80)
    print()
    print("Next steps:")
    print("1. Integrate with run_multi_domain_experiment.py")
    print("2. Call engine.add_concrete_skill() after each successful episode")
    print("3. Run engine.extract_abstract_patterns() every 50 episodes")
    print("4. Use engine.get_applicable_patterns() to retrieve transferable skills")
    print()
    
    return engine


if __name__ == "__main__":
    engine = simulate_multi_domain_experiment()
