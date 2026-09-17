"""
Skill Memory Population Experiment.

Runs extended experiments across all domains to populate unified skill memory.
Tracks skill accumulation, transfer rates, and performance over time.
"""

import sys
from pathlib import Path
sys.path.insert(0, str(Path.cwd()))

import time
import json
from datetime import datetime
from tiannara_core.evaluation.algorithm_domain import AlgorithmTaskGenerator
from tiannara_core.evaluation.logic_domain import LogicPuzzleGenerator
from tiannara_core.evaluation.reverse_engineering_domain import ReverseEngineeringGenerator
from tiannara_core.evaluation.causal_system_domain import CausalSystemGenerator
from tiannara_core.evaluation.evolution_engine import AlgorithmEvolver
from tiannara_core.evaluation.logic_evolution_engine import LogicPuzzleEvolver
from tiannara_core.evaluation.reverse_engineering_evolver import ReverseEngineeringEvolver
from tiannara_core.evaluation.causal_system_evolver import CausalSystemEvolver


def run_population_experiment(episodes_per_domain=200, seed=42):
    """Run experiments to populate skill memory across all domains."""
    
    print("=" * 80)
    print("SKILL MEMORY POPULATION EXPERIMENT")
    print("=" * 80)
    print(f"Episodes per domain: {episodes_per_domain}")
    print(f"Started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()
    
    # Initialize generators and evolvers
    domains_config = [
        ("Algorithm", AlgorithmTaskGenerator(seed=seed), AlgorithmEvolver(seed=seed)),
        ("Logic", LogicPuzzleGenerator(seed=seed), LogicPuzzleEvolver(seed=seed)),
        ("Reverse Engineering", ReverseEngineeringGenerator(seed=seed), ReverseEngineeringEvolver(seed=seed)),
        ("Causal", CausalSystemGenerator(seed=seed), CausalSystemEvolver(seed=seed))
    ]
    
    results = {}
    skill_accumulation = []
    
    for domain_name, generator, evolver in domains_config:
        print(f"\n>>> Running {domain_name} ({episodes_per_domain} episodes)...")
        
        successes = 0
        total_correctness = 0.0
        
        for episode in range(episodes_per_domain):
            try:
                # Generate task
                task = generator.generate_task()
                
                # Create variant (pass external_skills if available)
                variant_func = evolver.create_variant(task, episode)
                
                # Evaluate using generator's verifier
                task_inputs = task.get("inputs", {})
                try:
                    predicted = variant_func(**task_inputs) if callable(variant_func) else None
                except (TypeError, Exception) as e:
                    if episode < 3:
                        print(f"  Episode {episode} call error: {type(e).__name__}: {e}")
                    predicted = None
                
                if predicted is not None:
                    success = generator.verify_solution(task, predicted)
                    correctness = 1.0 if success else 0.0
                else:
                    success = False
                    correctness = 0.0
                
                # Update quality with task and episode info
                if hasattr(evolver, 'update_quality'):
                    import inspect
                    sig = inspect.signature(evolver.update_quality)
                    params = list(sig.parameters.keys())
                    
                    if 'task' in params and 'episode' in params:
                        evolver.update_quality(success, correctness, variant_func, task=task, episode=episode)
                    else:
                        evolver.update_quality(success, correctness, variant_func)
                
                if success:
                    successes += 1
                total_correctness += correctness
                
            except Exception as e:
                if episode < 3:
                    print(f"  Episode {episode} ERROR: {type(e).__name__}: {e}")
        
        success_rate = successes / episodes_per_domain if episodes_per_domain > 0 else 0.0
        avg_correctness = total_correctness / episodes_per_domain if episodes_per_domain > 0 else 0.0
        
        results[domain_name] = {
            "success_rate": success_rate,
            "avg_correctness": avg_correctness,
            "episodes": episodes_per_domain
        }
        
        print(f"  Success Rate: {success_rate*100:.1f}% ({successes}/{episodes_per_domain})")
        print(f"  Avg Correctness: {avg_correctness:.3f}")
        
        # Track skill accumulation for RE domain
        if domain_name == "Reverse Engineering" and hasattr(evolver, 'unified_skill_memory'):
            stats = evolver.unified_skill_memory.get_statistics()
            skill_accumulation.append({
                "domain": domain_name,
                "total_skills": stats['total_skills'],
                "by_type": stats['by_type'],
                "by_abstraction": stats['by_abstraction']
            })
            
            print(f"  Skills in Memory: {stats['total_skills']}")
            print(f"  By Type: {stats['by_type']}")
    
    # Analyze final skill memory state
    print("\n" + "=" * 80)
    print("FINAL SKILL MEMORY STATE")
    print("=" * 80)
    
    re_evolver = domains_config[2][2]  # Reverse Engineering evolver
    if hasattr(re_evolver, 'unified_skill_memory'):
        memory = re_evolver.unified_skill_memory
        stats = memory.get_statistics()
        
        print(f"\nTotal Skills Stored: {stats['total_skills']}")
        print(f"Average Success Rate: {stats['avg_success_rate']:.3f}")
        print(f"By Type: {json.dumps(stats['by_type'], indent=2)}")
        print(f"By Abstraction: {json.dumps(stats['by_abstraction'], indent=2)}")
        
        # Show sample skills
        if memory.skills:
            print(f"\nSample Skills (first 5):")
            for i, (skill_id, skill) in enumerate(list(memory.skills.items())[:5]):
                print(f"  {i+1}. {skill.name}")
                print(f"     Type: {skill.skill_type.value}")
                print(f"     Level: {skill.abstraction_level.value}")
                print(f"     Origin: {skill.origin_domain}")
                print(f"     Uses: {skill.total_uses}, Success Rate: {skill.success_rate:.2%}")
        
        # Analyze feedback loop
        if hasattr(memory, 'feedback_loop'):
            feedback = memory.feedback_loop
            print(f"\nTransfer Feedback Loop:")
            print(f"  History Entries: {len(feedback.transfer_history)}")
            print(f"  Success Rate Estimates: {len(feedback.success_rates)}")
            
            if feedback.success_rates:
                print(f"\nTop Transfer Combinations:")
                sorted_rates = sorted(feedback.success_rates.items(), key=lambda x: x[1], reverse=True)[:5]
                for (skill_type, target_domain), rate in sorted_rates:
                    print(f"  {skill_type.value} -> {target_domain}: {rate:.3f}")
    
    # Summary
    print("\n" + "=" * 80)
    print("EXPERIMENT SUMMARY")
    print("=" * 80)
    
    for domain_name, stats in results.items():
        print(f"{domain_name:25s}: {stats['success_rate']*100:6.1f}% success, {stats['avg_correctness']:.3f} avg")
    
    overall_success = sum(r['success_rate'] for r in results.values()) / len(results)
    print(f"\nOverall Average Success Rate: {overall_success*100:.1f}%")
    
    # Save results
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    output_file = f"skill_population_{timestamp}.json"
    
    output_data = {
        "timestamp": datetime.now().isoformat(),
        "episodes_per_domain": episodes_per_domain,
        "results": results,
        "overall_average": overall_success,
        "skill_accumulation": skill_accumulation,
        "final_skill_stats": stats if hasattr(re_evolver, 'unified_skill_memory') else None
    }
    
    with open(output_file, 'w') as f:
        json.dump(output_data, f, indent=2, default=str)
    
    print(f"\nResults saved to: {output_file}")
    print(f"Completed at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    return results, re_evolver if hasattr(re_evolver, 'unified_skill_memory') else None


if __name__ == "__main__":
    results, evolver = run_population_experiment(episodes_per_domain=200, seed=42)
