"""
Validate Skill Transfer Effectiveness

Runs controlled A/B experiments to measure whether cross-domain skill transfer
actually improves performance compared to isolated domain learning.

This validates the core architectural assumption of the system.
"""

import sys
from pathlib import Path
from datetime import datetime
import json

project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.evaluation.algorithm_domain import AlgorithmTaskGenerator
from tiannara_core.evaluation.logic_domain import LogicPuzzleGenerator
from tiannara_core.evaluation.reverse_engineering_domain import ReverseEngineeringGenerator
from tiannara_core.evaluation.causal_system_domain import CausalSystemGenerator
from tiannara_core.evaluation.evolution_engine import AlgorithmEvolver
from tiannara_core.evaluation.logic_evolution_engine import LogicPuzzleEvolver
from tiannara_core.evaluation.reverse_engineering_evolver import ReverseEngineeringEvolver
from tiannara_core.evaluation.causal_system_evolver import CausalSystemEvolver


class SkillTransferValidator:
    """Measures the impact of skill transfer on domain performance."""
    
    def __init__(self, num_episodes=50, seed=42):
        self.num_episodes = num_episodes
        self.seed = seed
        
        # Initialize domains
        self.domains = {
            "algorithm": AlgorithmTaskGenerator(seed=seed),
            "logic": LogicPuzzleGenerator(seed=seed+1),
            "reverse_engineering": ReverseEngineeringGenerator(seed=seed+2),
            "causal": CausalSystemGenerator(seed=seed+3)
        }
        
        # Initialize evolvers
        self.evolvers = {
            "algorithm": AlgorithmEvolver(seed=seed+10),
            "logic": LogicPuzzleEvolver(seed=seed+11),
            "reverse_engineering": ReverseEngineeringEvolver(seed=seed+12),
            "causal": CausalSystemEvolver(seed=seed+13)
        }
        
        self.results = {
            "with_transfer": [],
            "without_transfer": []
        }
    
    def run_experiment_with_transfer(self):
        """Run experiment WITH skill transfer enabled."""
        print("\n" + "="*80)
        print("EXPERIMENT A: WITH SKILL TRANSFER")
        print("="*80)
        
        # Create shared skill memory
        from tiannara_core.evaluation.run_multi_domain_experiment import CrossDomainSkillMemory
        skill_memory = CrossDomainSkillMemory()
        
        domain_list = list(self.domains.keys())
        total_success = 0
        total_count = 0
        domain_stats = {d: {"success": 0, "count": 0} for d in domain_list}
        transfer_count = 0
        
        for episode in range(1, self.num_episodes + 1):
            # Round-robin across domains
            domain_name = domain_list[(episode - 1) % len(domain_list)]
            domain = self.domains[domain_name]
            evolver = self.evolvers[domain_name]
            
            task = domain.generate_task(episode=episode)
            
            # Get transferred skills from other domains
            other_domains = [d for d in domain_list if d != domain_name]
            transferred_skills = []
            for other_domain in other_domains:
                skills = skill_memory.get_relevant_skills(
                    other_domain,
                    task.get("type", ""),
                    current_task_data={
                        "subtype": task.get("subtype", ""),
                        "difficulty": task.get("difficulty", "medium")
                    }
                )
                transferred_skills.extend(skills[:2])  # Top 2 from each domain
            
            if transferred_skills:
                transfer_count += 1
            
            # Create solution WITH transferred skills
            solution_func = evolver.create_variant(task, episode=episode, external_skills=transferred_skills)
            
            # Evaluate
            try:
                output = solution_func(**task["inputs"])
                success = domain.verify_solution(task, output)
                
                # Update evolver quality
                evolver.update_quality(success, None, solution_func)
                
                # Store skill if successful
                if success:
                    # Categorize the skill
                    skill_categories = skill_memory.categorize_skill(
                        domain_name,
                        task.get("type", ""),
                        task.get("subtype", "")
                    )
                    
                    skill_data = {
                        "task_type": task.get("type", ""),
                        "subtype": task.get("subtype", ""),
                        "difficulty": task.get("difficulty", "medium"),
                        "score": 1.0,  # Successful
                        "domain": domain_name
                    }
                    
                    skill_memory.add_skill(domain_name, skill_categories, skill_data)
                
                total_success += 1 if success else 0
                total_count += 1
                domain_stats[domain_name]["success"] += 1 if success else 0
                domain_stats[domain_name]["count"] += 1
                
            except Exception as e:
                total_count += 1
                domain_stats[domain_name]["count"] += 1
        
        overall_rate = total_success / total_count if total_count > 0 else 0
        
        print(f"\nOverall Success Rate: {total_success}/{total_count} = {overall_rate:.1%}")
        print(f"\nPerformance by Domain:")
        for domain_name in sorted(domain_stats.keys()):
            stats = domain_stats[domain_name]
            rate = stats["success"] / stats["count"] if stats["count"] > 0 else 0
            print(f"  {domain_name:25s}: {stats['success']:3d}/{stats['count']:3d} = {rate:5.1%}")
        
        print(f"\nSkill Transfers Attempted: {transfer_count}")
        
        return {
            "overall_rate": overall_rate,
            "domain_stats": domain_stats,
            "transfer_count": transfer_count,
            "total_episodes": total_count
        }
    
    def run_experiment_without_transfer(self):
        """Run experiment WITHOUT skill transfer (isolated domains)."""
        print("\n" + "="*80)
        print("EXPERIMENT B: WITHOUT SKILL TRANSFER (ISOLATED)")
        print("="*80)
        
        # Use fresh evolvers (no shared memory)
        isolated_evolvers = {
            "algorithm": AlgorithmEvolver(seed=self.seed+20),
            "logic": LogicPuzzleEvolver(seed=self.seed+21),
            "reverse_engineering": ReverseEngineeringEvolver(seed=self.seed+22),
            "causal": CausalSystemEvolver(seed=self.seed+23)
        }
        
        domain_list = list(self.domains.keys())
        total_success = 0
        total_count = 0
        domain_stats = {d: {"success": 0, "count": 0} for d in domain_list}
        
        for episode in range(1, self.num_episodes + 1):
            # Round-robin across domains
            domain_name = domain_list[(episode - 1) % len(domain_list)]
            domain = self.domains[domain_name]
            evolver = isolated_evolvers[domain_name]
            
            task = domain.generate_task(episode=episode)
            
            # Create solution (NO skill transfer)
            solution_func = evolver.create_variant(task, episode=episode)
            
            # Evaluate
            try:
                output = solution_func(**task["inputs"])
                success = domain.verify_solution(task, output)
                
                # Update evolver quality
                evolver.update_quality(success, None, solution_func)
                
                total_success += 1 if success else 0
                total_count += 1
                domain_stats[domain_name]["success"] += 1 if success else 0
                domain_stats[domain_name]["count"] += 1
                
            except Exception as e:
                total_count += 1
                domain_stats[domain_name]["count"] += 1
        
        overall_rate = total_success / total_count if total_count > 0 else 0
        
        print(f"\nOverall Success Rate: {total_success}/{total_count} = {overall_rate:.1%}")
        print(f"\nPerformance by Domain:")
        for domain_name in sorted(domain_stats.keys()):
            stats = domain_stats[domain_name]
            rate = stats["success"] / stats["count"] if stats["count"] > 0 else 0
            print(f"  {domain_name:25s}: {stats['success']:3d}/{stats['count']:3d} = {rate:5.1%}")
        
        return {
            "overall_rate": overall_rate,
            "domain_stats": domain_stats,
            "transfer_count": 0,
            "total_episodes": total_count
        }
    
    def analyze_results(self, results_with, results_without):
        """Compare results and calculate transfer impact."""
        print("\n" + "="*80)
        print("SKILL TRANSFER IMPACT ANALYSIS")
        print("="*80)
        
        improvement = results_with["overall_rate"] - results_without["overall_rate"]
        relative_improvement = (improvement / results_without["overall_rate"] * 100) if results_without["overall_rate"] > 0 else 0
        
        print(f"\nOverall Performance:")
        print(f"  With Transfer:    {results_with['overall_rate']:.1%}")
        print(f"  Without Transfer: {results_without['overall_rate']:.1%}")
        print(f"  Absolute Improvement:  {improvement:+.1%}")
        print(f"  Relative Improvement:  {relative_improvement:+.1f}%")
        
        print(f"\nDomain-by-Domain Comparison:")
        print(f"{'Domain':25s} {'With':>8s} {'Without':>8s} {'Diff':>8s}")
        print("-" * 60)
        
        for domain_name in sorted(results_with["domain_stats"].keys()):
            with_stats = results_with["domain_stats"][domain_name]
            without_stats = results_without["domain_stats"][domain_name]
            
            with_rate = with_stats["success"] / with_stats["count"] if with_stats["count"] > 0 else 0
            without_rate = without_stats["success"] / without_stats["count"] if without_stats["count"] > 0 else 0
            diff = with_rate - without_rate
            
            print(f"{domain_name:25s} {with_rate:7.1%} {without_rate:7.1%} {diff:+7.1%}")
        
        print(f"\nSkill Transfer Statistics:")
        print(f"  Total Transfers Attempted: {results_with['transfer_count']}")
        print(f"  Episodes with Transfer: {results_with['transfer_count']}")
        print(f"  Episodes without Transfer: {results_with['total_episodes'] - results_with['transfer_count']}")
        
        # Statistical significance (simple test)
        n = results_with["total_episodes"]
        p_with = results_with["overall_rate"]
        p_without = results_without["overall_rate"]
        
        # Standard error for difference in proportions
        se = ((p_with * (1 - p_with) + p_without * (1 - p_without)) / n) ** 0.5
        z_score = improvement / se if se > 0 else 0
        
        print(f"\nStatistical Significance:")
        print(f"  Z-score: {z_score:.2f}")
        if abs(z_score) > 1.96:
            print(f"  Result: SIGNIFICANT (p < 0.05)")
        elif abs(z_score) > 1.645:
            print(f"  Result: MARGINALLY SIGNIFICANT (p < 0.10)")
        else:
            print(f"  Result: NOT SIGNIFICANT (p >= 0.10)")
        
        # Conclusion
        print(f"\n{'='*80}")
        print("CONCLUSION:")
        print("="*80)
        
        if improvement > 0.05:
            print(f"[PASS] Skill transfer provides SIGNIFICANT benefit (+{improvement:.1%})")
            print(f"   The architectural assumption is VALIDATED.")
        elif improvement > 0:
            print(f"[WARN] Skill transfer provides modest benefit (+{improvement:.1%})")
            print(f"   May need refinement to maximize impact.")
        elif improvement == 0:
            print(f"[FAIL] Skill transfer provides NO benefit (0.0%)")
            print(f"   Architectural assumption may be INVALID.")
        else:
            print(f"[FAIL] Skill transfer HURTS performance ({improvement:.1%})")
            print(f"   Critical issue - transfer mechanism needs redesign.")
        
        return {
            "improvement": improvement,
            "relative_improvement": relative_improvement,
            "z_score": z_score,
            "significant": abs(z_score) > 1.96
        }
    
    def save_results(self, results_with, results_without, analysis):
        """Save results to file for later analysis."""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"skill_transfer_validation_{timestamp}.json"
        filepath = Path(__file__).parent / filename
        
        report = {
            "timestamp": datetime.now().isoformat(),
            "num_episodes": self.num_episodes,
            "seed": self.seed,
            "results_with_transfer": results_with,
            "results_without_transfer": results_without,
            "analysis": analysis,
            "conclusion": "validated" if analysis["improvement"] > 0.05 else 
                         "needs_refinement" if analysis["improvement"] > 0 else
                         "invalid" if analysis["improvement"] <= 0 else "unknown"
        }
        
        with open(filepath, 'w') as f:
            json.dump(report, f, indent=2)
        
        print(f"\nResults saved to: {filepath}")
        return filepath


def main():
    """Run skill transfer validation experiment."""
    print("="*80)
    print("SKILL TRANSFER VALIDATION EXPERIMENT")
    print("="*80)
    print(f"\nThis experiment validates whether cross-domain skill transfer")
    print(f"actually improves performance compared to isolated learning.")
    print(f"\nConfiguration:")
    print(f"  Episodes per condition: 50")
    print(f"  Domains: algorithm, logic, reverse_engineering, causal")
    print(f"  Method: A/B testing (with vs without transfer)")
    
    validator = SkillTransferValidator(num_episodes=50, seed=42)
    
    # Run Experiment A: With transfer
    results_with = validator.run_experiment_with_transfer()
    
    # Run Experiment B: Without transfer
    results_without = validator.run_experiment_without_transfer()
    
    # Analyze results
    analysis = validator.analyze_results(results_with, results_without)
    
    # Save results
    validator.save_results(results_with, results_without, analysis)
    
    print("\n" + "="*80)
    print("VALIDATION COMPLETE")
    print("="*80)


if __name__ == "__main__":
    main()
