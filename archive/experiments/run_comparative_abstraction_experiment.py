"""Large-Scale Comparative Experiment with Skill Abstraction.

Compares baseline (4 domains, no abstraction) vs enhanced (6 domains + abstraction engine).

Tracks:
1. Cross-domain transfer success rates
2. Abstract pattern quality and applicability
3. Overall system capability across all domains
4. Learning curves with vs without abstraction

Usage:
    python tiannara_core/evaluation/run_comparative_abstraction_experiment.py --mode baseline --episodes 100
    python tiannara_core/evaluation/run_comparative_abstraction_experiment.py --mode enhanced --episodes 100
"""

import sys
from pathlib import Path
import argparse
import json
import time
from datetime import datetime
from typing import Dict, Any, List

# Add project root to path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.evaluation.algorithm_domain import AlgorithmTaskGenerator
from tiannara_core.evaluation.logic_domain import LogicPuzzleGenerator
from tiannara_core.evaluation.reverse_engineering_domain import ReverseEngineeringGenerator
from tiannara_core.evaluation.causal_system_domain import CausalSystemGenerator
from tiannara_core.evaluation.temporal_domain import TemporalTaskGenerator
from tiannara_core.evaluation.combinatorial_optimization_domain import CombinatorialOptimizationGenerator

from tiannara_core.evaluation.evolution_engine import AlgorithmEvolver
from tiannara_core.evaluation.logic_evolution_engine import LogicPuzzleEvolver
from tiannara_core.evaluation.reverse_engineering_evolver import ReverseEngineeringEvolver
from tiannara_core.evaluation.causal_system_evolver import CausalSystemEvolver
from tiannara_core.evaluation.temporal_evolution_engine import TemporalEvolver
from tiannara_core.evaluation.combinatorial_optimization_evolver import CombinatorialOptimizationEvolver

from tiannara_core.evaluation.evaluator import Evaluator
from tiannara_core.evaluation.episode_logger import EpisodeLogger
from tiannara_core.evaluation.skill_abstraction_engine import SkillAbstractionEngine


class EnhancedSkillMemory:
    """Enhanced skill memory with abstraction engine integration."""
    
    def __init__(self, enable_abstraction: bool = True):
        self.enable_abstraction = enable_abstraction
        
        # Domain-specific skills
        self.domain_skills: Dict[str, List[Dict[str, Any]]] = {
            "algorithm": [],
            "logic": [],
            "reverse_engineering": [],
            "causal": [],
            "temporal": [],
            "combinatorial": []
        }
        
        # Abstraction engine (if enabled)
        if enable_abstraction:
            self.abstraction_engine = SkillAbstractionEngine(
                min_cluster_size=5,
                similarity_threshold=0.6
            )
            self.extracted_patterns = []
            self.last_extraction_episode = 0
        else:
            self.abstraction_engine = None
            self.extracted_patterns = []
            self.last_extraction_episode = 0
        
        # Tracking
        self.total_skills_stored = 0
        self.transfer_attempts = 0
        self.transfer_successes = 0
    
    def add_skill(self, domain: str, skill_data: Dict[str, Any], episode: int):
        """Add a successful skill to memory."""
        self.domain_skills[domain].append(skill_data)
        self.total_skills_stored += 1
        
        # Add to abstraction engine if enabled
        if self.enable_abstraction and self.abstraction_engine:
            self.abstraction_engine.add_concrete_skill(
                skill_id=f"{domain}_{episode}",
                skill_data=skill_data
            )
    
    def get_applicable_skills(self, target_domain: str, max_skills: int = 10) -> List[Dict[str, Any]]:
        """Get skills applicable to target domain, using abstraction if available."""
        applicable = []
        
        if self.enable_abstraction and self.abstraction_engine:
            # Use abstract patterns for better generalization
            patterns = self.abstraction_engine.get_applicable_patterns(
                target_domain=target_domain,
                min_cross_domain_score=0.3
            )
            
            # Convert patterns back to concrete skills
            for pattern in patterns[:max_skills]:
                # Get source skills from this pattern
                for skill_id in pattern.source_skills[:3]:  # Top 3 from each pattern
                    for domain_skills in self.domain_skills.values():
                        for skill in domain_skills:
                            if skill.get("skill_id") == skill_id:
                                applicable.append(skill)
                                break
        else:
            # Fallback: use raw cross-domain skills
            for domain, skills in self.domain_skills.items():
                if domain != target_domain:
                    applicable.extend(skills[-5:])  # Last 5 skills from other domains
        
        return applicable[:max_skills]
    
    def extract_patterns_if_needed(self, episode: int, extraction_interval: int = 50):
        """Extract abstract patterns at regular intervals."""
        if not self.enable_abstraction or not self.abstraction_engine:
            return []
        
        if episode - self.last_extraction_episode >= extraction_interval:
            print(f"\n  [Abstraction Engine] Extracting patterns at episode {episode}...")
            new_patterns = self.abstraction_engine.extract_abstract_patterns()
            self.extracted_patterns.extend(new_patterns)
            self.last_extraction_episode = episode
            
            if new_patterns:
                print(f"  [Abstraction Engine] Extracted {len(new_patterns)} new patterns")
                print(f"  [Abstraction Engine] Total patterns: {len(self.extracted_patterns)}")
            
            return new_patterns
        
        return []
    
    def get_statistics(self) -> Dict[str, Any]:
        """Get comprehensive statistics."""
        stats = {
            "total_skills_stored": self.total_skills_stored,
            "transfer_attempts": self.transfer_attempts,
            "transfer_successes": self.transfer_successes,
            "transfer_success_rate": (
                self.transfer_successes / self.transfer_attempts 
                if self.transfer_attempts > 0 else 0.0
            ),
            "skills_per_domain": {
                domain: len(skills) for domain, skills in self.domain_skills.items()
            }
        }
        
        if self.enable_abstraction and self.abstraction_engine:
            stats["abstraction"] = self.abstraction_engine.get_statistics()
            stats["extracted_patterns_count"] = len(self.extracted_patterns)
        
        return stats


def run_experiment(
    mode: str = "baseline",
    episodes_per_domain: int = 100,
    enable_skill_transfer: bool = True,
    extraction_interval: int = 50
) -> Dict[str, Any]:
    """
    Run comparative experiment.
    
    Args:
        mode: "baseline" (4 domains, no abstraction) or "enhanced" (6 domains + abstraction)
        episodes_per_domain: Episodes per domain
        enable_skill_transfer: Enable cross-domain skill sharing
        extraction_interval: How often to extract abstract patterns (episodes)
    
    Returns:
        Experiment results dictionary
    """
    print("=" * 80)
    print(f"LARGE-SCALE COMPARATIVE EXPERIMENT - {mode.upper()} MODE")
    print("=" * 80)
    print(f"Mode: {mode}")
    print(f"Episodes per domain: {episodes_per_domain}")
    print(f"Skill transfer: {'Enabled' if enable_skill_transfer else 'Disabled'}")
    print(f"Abstraction engine: {'Enabled' if mode == 'enhanced' else 'Disabled'}")
    print(f"Start time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()
    
    # Initialize task generators based on mode
    if mode == "baseline":
        generators = {
            "algorithm": AlgorithmTaskGenerator(seed=42),
            "logic": LogicPuzzleGenerator(seed=43),
            "reverse_engineering": ReverseEngineeringGenerator(seed=44),
            "causal": CausalSystemGenerator(seed=45)
        }
        evolvers = {
            "algorithm": AlgorithmEvolver(seed=42),
            "logic": LogicPuzzleEvolver(seed=43),
            "reverse_engineering": ReverseEngineeringEvolver(seed=44),
            "causal": CausalSystemEvolver(seed=45)
        }
    else:  # enhanced
        generators = {
            "algorithm": AlgorithmTaskGenerator(seed=42),
            "logic": LogicPuzzleGenerator(seed=43),
            "reverse_engineering": ReverseEngineeringGenerator(seed=44),
            "causal": CausalSystemGenerator(seed=45),
            "temporal": TemporalTaskGenerator(seed=46),
            "combinatorial": CombinatorialOptimizationGenerator(seed=47)
        }
        evolvers = {
            "algorithm": AlgorithmEvolver(seed=42),
            "logic": LogicPuzzleEvolver(seed=43),
            "reverse_engineering": ReverseEngineeringEvolver(seed=44),
            "causal": CausalSystemEvolver(seed=45),
            "temporal": TemporalEvolver(seed=46),
            "combinatorial": CombinatorialOptimizationEvolver(seed=47)
        }
    
    # Initialize evaluator and logger
    evaluator = Evaluator()
    logger = EpisodeLogger(use_sqlite=True, batch_size=100)
    
    # Initialize enhanced skill memory
    enable_abstraction = (mode == "enhanced")
    skill_memory = EnhancedSkillMemory(enable_abstraction=enable_abstraction)
    
    # Results tracking
    domain_results = {domain: [] for domain in generators.keys()}
    total_episodes = 0
    total_successes = 0
    start_time = time.time()
    
    # Run experiments
    for domain_name, generator in generators.items():
        print(f"\n{'='*80}")
        print(f"DOMAIN: {domain_name.upper()}")
        print(f"{'='*80}")
        
        evolver = evolvers[domain_name]
        domain_successes = 0
        domain_correctness_sum = 0.0
        
        for episode in range(episodes_per_domain):
            total_episodes += 1
            
            # Generate task
            task = generator.generate_task(episode=total_episodes)
            
            # Get external skills for transfer
            external_skills = None
            if enable_skill_transfer and skill_memory.total_skills_stored > 0:
                external_skills = skill_memory.get_applicable_skills(
                    target_domain=domain_name,
                    max_skills=10
                )
                
                if external_skills:
                    skill_memory.transfer_attempts += len(external_skills)
            
            # Create variant
            try:
                variant = evolver.create_variant(
                    task, 
                    episode=total_episodes,
                    external_skills=external_skills
                )
            except Exception as e:
                print(f"  ERROR creating variant at episode {total_episodes}: {e}")
                import traceback
                traceback.print_exc()
                continue
            
            if not variant:
                print(f"  WARNING: No variant created at episode {total_episodes} (task type: {task.get('type', 'unknown')})")
                continue
            
            # Evaluate
            result = evaluator.evaluate(variant, task.get("inputs", {}))
            correctness = result.get("metrics", {}).get("correctness", 0.0)
            is_success = correctness > 0.6
            
            if is_success:
                domain_successes += 1
                total_successes += 1
                skill_memory.transfer_successes += 1
                
                # Store successful skill
                skill_data = {
                    "skill_id": f"{domain_name}_{total_episodes}",
                    "domain": domain_name,
                    "task_type": task.get("type", ""),
                    "subtype": task.get("subtype", ""),
                    "difficulty": task.get("difficulty", "medium"),
                    "score": correctness,
                    "performance": {
                        "accuracy": correctness,
                        "speed": result.get("metrics", {}).get("runtime", 0.0),
                        "robustness": correctness
                    },
                    "complexity": task.get("difficulty", "medium")
                }
                skill_memory.add_skill(domain_name, skill_data, total_episodes)
            
            domain_correctness_sum += correctness
            
            # Progress reporting
            if (episode + 1) % 20 == 0:
                current_success_rate = domain_successes / (episode + 1)
                print(f"  Episode {total_episodes}: Success rate = {current_success_rate:.2%}")
            
            # Extract abstract patterns at intervals
            if enable_abstraction:
                skill_memory.extract_patterns_if_needed(total_episodes, extraction_interval)
        
        # Domain summary
        domain_success_rate = domain_successes / episodes_per_domain
        avg_correctness = domain_correctness_sum / episodes_per_domain
        
        domain_results[domain_name] = {
            "success_rate": domain_success_rate,
            "avg_correctness": avg_correctness,
            "successes": domain_successes,
            "total_episodes": episodes_per_domain
        }
        
        print(f"\n  Domain Summary:")
        print(f"    Success Rate: {domain_success_rate:.2%}")
        print(f"    Avg Correctness: {avg_correctness:.4f}")
        print(f"    Successes: {domain_successes}/{episodes_per_domain}")
    
    # Final statistics
    elapsed_time = time.time() - start_time
    overall_success_rate = total_successes / total_episodes if total_episodes > 0 else 0.0
    
    results = {
        "timestamp": datetime.now().strftime("%Y%m%d_%H%M%S"),
        "mode": mode,
        "configuration": {
            "episodes_per_domain": episodes_per_domain,
            "skill_transfer_enabled": enable_skill_transfer,
            "abstraction_enabled": (mode == "enhanced"),
            "domains_tested": list(generators.keys()),
            "extraction_interval": extraction_interval
        },
        "overall": {
            "total_episodes": total_episodes,
            "total_successes": total_successes,
            "overall_success_rate": overall_success_rate,
            "elapsed_time_seconds": elapsed_time
        },
        "per_domain": domain_results,
        "skill_memory_stats": skill_memory.get_statistics()
    }
    
    # Print final summary
    print(f"\n{'='*80}")
    print("EXPERIMENT COMPLETE")
    print(f"{'='*80}")
    print(f"Overall Success Rate: {overall_success_rate:.2%}")
    print(f"Total Episodes: {total_episodes}")
    print(f"Total Successes: {total_successes}")
    print(f"Elapsed Time: {elapsed_time:.2f}s")
    
    if enable_abstraction:
        print(f"\nAbstraction Engine Statistics:")
        abs_stats = skill_memory.get_statistics().get("abstraction", {})
        for key, value in abs_stats.items():
            if isinstance(value, float):
                print(f"  {key}: {value:.4f}")
            else:
                print(f"  {key}: {value}")
    
    print(f"\nPer-Domain Results:")
    for domain, stats in domain_results.items():
        print(f"  {domain:25s}: {stats['success_rate']:6.2%} success, {stats['avg_correctness']:.4f} avg correctness")
    
    return results


def main():
    parser = argparse.ArgumentParser(description="Run comparative abstraction experiment")
    parser.add_argument("--mode", choices=["baseline", "enhanced"], default="baseline",
                       help="Experiment mode: baseline (4 domains) or enhanced (6 domains + abstraction)")
    parser.add_argument("--episodes", type=int, default=100,
                       help="Episodes per domain (default: 100)")
    parser.add_argument("--no-transfer", action="store_true",
                       help="Disable skill transfer")
    parser.add_argument("--extraction-interval", type=int, default=50,
                       help="Pattern extraction interval in episodes (default: 50)")
    parser.add_argument("--output", type=str, default=None,
                       help="Output JSON file path (default: auto-generated)")
    
    args = parser.parse_args()
    
    # Run experiment
    results = run_experiment(
        mode=args.mode,
        episodes_per_domain=args.episodes,
        enable_skill_transfer=not args.no_transfer,
        extraction_interval=args.extraction_interval
    )
    
    # Save results
    output_path = args.output or f"comparative_results_{args.mode}_{results['timestamp']}.json"
    with open(output_path, 'w') as f:
        json.dump(results, f, indent=2)
    
    print(f"\nResults saved to: {output_path}")
    
    return results


if __name__ == "__main__":
    main()
