"""Multi-Domain Experiment with Temporal Reasoning.

Tests system capability across 5 domains:
1. Algorithm (sorting, search, optimization)
2. Logic (patterns, deduction)
3. Reverse Engineering (function inference)
4. Causal (causal structure learning)
5. Temporal (time series, event sequences) [NEW]

With cross-domain skill transfer and unified evaluation.
"""

import sys
from pathlib import Path

# Add project root to path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.evaluation.algorithm_domain import AlgorithmTaskGenerator
from tiannara_core.evaluation.logic_domain import LogicPuzzleGenerator
from tiannara_core.evaluation.reverse_engineering_domain import ReverseEngineeringGenerator
from tiannara_core.evaluation.causal_system_domain import CausalSystemGenerator
from tiannara_core.evaluation.temporal_domain import TemporalTaskGenerator

from tiannara_core.evaluation.evolution_engine import AlgorithmEvolver
from tiannara_core.evaluation.logic_evolution_engine import LogicPuzzleEvolver
from tiannara_core.evaluation.reverse_engineering_evolver import ReverseEngineeringEvolver
from tiannara_core.evaluation.causal_system_evolver import CausalSystemEvolver
from tiannara_core.evaluation.temporal_evolution_engine import TemporalEvolver

from tiannara_core.evaluation.evaluator import Evaluator
from tiannara_core.evaluation.episode_logger import EpisodeLogger

import json
import time
from datetime import datetime


def run_5_domain_experiment(num_episodes_per_domain=50, enable_skill_transfer=True):
    """
    Run multi-domain experiment with temporal reasoning.
    
    Args:
        num_episodes_per_domain: Episodes to run per domain
        enable_skill_transfer: Enable cross-domain skill sharing
    """
    print("=" * 80)
    print("5-DOMAIN EXPERIMENT WITH TEMPORAL REASONING")
    print("=" * 80)
    print(f"Episodes per domain: {num_episodes_per_domain}")
    print(f"Skill transfer: {'Enabled' if enable_skill_transfer else 'Disabled'}")
    print(f"Start time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()
    
    # Initialize task generators
    generators = {
        "algorithm": AlgorithmTaskGenerator(seed=42),
        "logic": LogicPuzzleGenerator(seed=43),
        "reverse_engineering": ReverseEngineeringGenerator(seed=44),
        "causal": CausalSystemGenerator(seed=45),
        "temporal": TemporalTaskGenerator(seed=46)
    }
    
    # Initialize evolvers
    evolvers = {
        "algorithm": AlgorithmEvolver(seed=42),
        "logic": LogicPuzzleEvolver(seed=43),
        "reverse_engineering": ReverseEngineeringEvolver(seed=44),
        "causal": CausalSystemEvolver(seed=45),
        "temporal": TemporalEvolver(seed=46)
    }
    
    # Initialize evaluator
    evaluator = Evaluator()
    
    # Initialize logger
    logger = EpisodeLogger(use_sqlite=True, batch_size=100)
    
    # Shared skill memory (simple dict-based for this experiment)
    skill_memory = {}
    
    # Results tracking
    domain_results = {domain: [] for domain in generators.keys()}
    total_episodes = 0
    
    # Run experiments
    for domain_name, generator in generators.items():
        print(f"\n{'='*80}")
        print(f"DOMAIN: {domain_name.upper()}")
        print(f"{'='*80}")
        
        evolver = evolvers[domain_name]
        domain_successes = 0
        
        for episode in range(num_episodes_per_domain):
            total_episodes += 1
            
            # Generate task
            task = generator.generate_task(episode=total_episodes)
            
            # Get external skills for transfer
            external_skills = None
            if enable_skill_transfer and skill_memory:
                # Collect skills from other domains
                external_skills = []
                for other_domain, skills in skill_memory.items():
                    if other_domain != domain_name:
                        external_skills.extend(skills[:5])  # Top 5 skills from each domain
                
                if external_skills:
                    print(f"  Episode {total_episodes}: Using {len(external_skills)} external skills")
            
            # Create variant
            variant = evolver.create_variant(task, episode=total_episodes, 
                                           external_skills=external_skills)
            
            if not variant:
                print(f"  Episode {total_episodes}: FAILED to create variant")
                continue
            
            # Evaluate
            try:
                result = variant(**task.get("inputs", {}))
                
                # Verify solution
                correctness = generator.verify_solution(task, result)
                
                # Track results
                domain_results[domain_name].append({
                    "episode": total_episodes,
                    "correctness": correctness,
                    "success": correctness > 0.5
                })
                
                if correctness > 0.5:
                    domain_successes += 1
                    
                    # Store successful skill
                    if domain_name not in skill_memory:
                        skill_memory[domain_name] = []
                    
                    skill_memory[domain_name].append({
                        "skill_id": f"{domain_name}_{total_episodes}",
                        "task_type": task["type"],
                        "solution_pattern": str(result)[:100],
                        "correctness": correctness,
                        "episode": total_episodes
                    })
                
                # Log episode
                logger.log_episode({
                    "episode": total_episodes,
                    "domain": domain_name,
                    "task_type": task["type"],
                    "correctness": correctness,
                    "runtime_ms": 0,  # Simplified
                    "difficulty": task.get("difficulty", "unknown")
                })
                
                # Progress update
                if (episode + 1) % 10 == 0:
                    current_rate = domain_successes / (episode + 1)
                    print(f"  Episode {total_episodes}: Success rate = {current_rate:.2%} ({domain_successes}/{episode+1})")
                
            except Exception as e:
                print(f"  Episode {total_episodes}: ERROR - {str(e)[:100]}")
                domain_results[domain_name].append({
                    "episode": total_episodes,
                    "correctness": 0.0,
                    "success": False,
                    "error": str(e)
                })
        
        # Domain summary
        domain_total = len(domain_results[domain_name])
        domain_rate = domain_successes / domain_total if domain_total > 0 else 0
        print(f"\n{domain_name.upper()} SUMMARY:")
        print(f"  Total episodes: {domain_total}")
        print(f"  Successes: {domain_successes}")
        print(f"  Success rate: {domain_rate:.2%}")
        print(f"  Skills stored: {len(skill_memory.get(domain_name, []))}")
    
    # Overall summary
    print(f"\n{'='*80}")
    print("OVERALL RESULTS")
    print(f"{'='*80}")
    
    total_successes = sum(
        sum(1 for r in results if r["success"])
        for results in domain_results.values()
    )
    total_tasks = sum(len(results) for results in domain_results.values())
    overall_rate = total_successes / total_tasks if total_tasks > 0 else 0
    
    print(f"\nTotal episodes: {total_tasks}")
    print(f"Total successes: {total_successes}")
    print(f"Overall success rate: {overall_rate:.2%}")
    print()
    
    print("Per-domain breakdown:")
    for domain, results in domain_results.items():
        successes = sum(1 for r in results if r["success"])
        rate = successes / len(results) if results else 0
        print(f"  {domain:25s}: {rate:.2%} ({successes}/{len(results)})")
    
    print(f"\nSkill memory size: {sum(len(skills) for skills in skill_memory.values())} skills")
    print(f"  ", end="")
    for domain, skills in skill_memory.items():
        print(f"{domain}: {len(skills)}  ", end="")
    print()
    
    # Close logger
    logger.close()
    
    # Save results
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    results_file = f"tiannara_core/evaluation/5domain_results_{timestamp}.json"
    
    results_data = {
        "timestamp": timestamp,
        "config": {
            "episodes_per_domain": num_episodes_per_domain,
            "skill_transfer": enable_skill_transfer,
            "domains": list(generators.keys())
        },
        "overall": {
            "total_episodes": total_tasks,
            "total_successes": total_successes,
            "overall_success_rate": overall_rate
        },
        "per_domain": {
            domain: {
                "total": len(results),
                "successes": sum(1 for r in results if r["success"]),
                "success_rate": sum(1 for r in results if r["success"]) / len(results) if results else 0,
                "avg_correctness": sum(r["correctness"] for r in results) / len(results) if results else 0
            }
            for domain, results in domain_results.items()
        }
    }
    
    with open(results_file, "w") as f:
        json.dump(results_data, f, indent=2)
    
    print(f"\nResults saved to: {results_file}")
    print(f"End time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    return results_data


if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Run 5-domain experiment with temporal reasoning")
    parser.add_argument("--episodes", type=int, default=50, help="Episodes per domain")
    parser.add_argument("--no-transfer", action="store_true", help="Disable skill transfer")
    
    args = parser.parse_args()
    
    results = run_5_domain_experiment(
        num_episodes_per_domain=args.episodes,
        enable_skill_transfer=not args.no_transfer
    )
