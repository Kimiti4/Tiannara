"""
Extended Cross-Domain Skill Transfer Experiment.

Runs 500 episodes across all domains to:
1. Populate unified skill memory with diverse skills
2. Track which skill types transfer successfully
3. Measure transfer success rates over time
4. Identify optimal confidence thresholds
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


def run_extended_experiment(episodes=500, seed=42):
    """Run extended experiment across all domains."""
    
    print("=" * 80)
    print("EXTENDED CROSS-DOMAIN SKILL TRANSFER EXPERIMENT")
    print("=" * 80)
    print(f"Episodes per domain: {episodes}")
    print(f"Started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()
    
    # Initialize generators and evolvers
    domains = {
        "Algorithm": (AlgorithmTaskGenerator(seed=seed), AlgorithmEvolver(seed=seed)),
        "Logic": (LogicPuzzleGenerator(seed=seed), LogicPuzzleEvolver(seed=seed)),
        "Reverse Engineering": (ReverseEngineeringGenerator(seed=seed), ReverseEngineeringEvolver(seed=seed)),
        "Causal": (CausalSystemGenerator(seed=seed), CausalSystemEvolver(seed=seed))
    }
    
    results = {}
    transfer_stats = {
        "skills_extracted": {},
        "transfer_attempts": 0,
        "successful_transfers": 0,
        "failed_transfers": 0,
        "by_skill_type": {},
        "by_domain_pair": {}
    }
    
    for domain_name, (generator, evolver) in domains.items():
        print(f"\n>>> Starting {domain_name} Domain ({episodes} episodes)...")
        
        successes = 0
        total_correctness = 0.0
        
        # Track skill extraction for RE domain
        if domain_name == "Reverse Engineering":
            transfer_stats["skills_extracted"][domain_name] = 0
        
        for episode in range(episodes):
            try:
                # Generate task
                task = generator.generate_task()
                
                # Create variant
                variant_func = evolver.create_variant(task, episode)
                
                # Evaluate
                start_time = time.time()
                solution_func = variant_func
                correctness = evaluate_solution(solution_func, task)
                elapsed = time.time() - start_time
                
                success = correctness > 0.99
                
                # Update quality with task and episode info
                if hasattr(evolver, 'update_quality'):
                    import inspect
                    sig = inspect.signature(evolver.update_quality)
                    params = list(sig.parameters.keys())
                    
                    if 'task' in params and 'episode' in params:
                        evolver.update_quality(success, correctness, solution_func, task=task, episode=episode)
                        
                        # Track skill extraction for RE
                        if domain_name == "Reverse Engineering" and success:
                            if hasattr(evolver, 'unified_skill_memory'):
                                current_skills = len(evolver.unified_skill_memory.skills)
                                prev_count = transfer_stats["skills_extracted"].get(domain_name, 0)
                                if current_skills > prev_count:
                                    transfer_stats["skills_extracted"][domain_name] = current_skills
                    else:
                        evolver.update_quality(success, correctness, solution_func)
                
                if success:
                    successes += 1
                total_correctness += correctness
                
            except Exception as e:
                if episode < 5:
                    print(f"  Episode {episode} ERROR: {type(e).__name__}: {e}")
        
        success_rate = successes / episodes if episodes > 0 else 0.0
        avg_correctness = total_correctness / episodes if episodes > 0 else 0.0
        
        results[domain_name] = {
            "success_rate": success_rate,
            "avg_correctness": avg_correctness,
            "episodes": episodes
        }
        
        print(f"  Success Rate: {success_rate*100:.1f}% ({successes}/{episodes})")
        print(f"  Avg Correctness: {avg_correctness:.3f}")
        
        # Print skill memory stats for RE
        if domain_name == "Reverse Engineering" and hasattr(evolver, 'unified_skill_memory'):
            stats = evolver.unified_skill_memory.get_statistics()
            print(f"  Skills in Memory: {stats['total_skills']}")
            print(f"  By Type: {stats['by_type']}")
            print(f"  By Abstraction: {stats['by_abstraction']}")
    
    # Analyze transfer statistics
    print("\n" + "=" * 80)
    print("SKILL TRANSFER ANALYSIS")
    print("=" * 80)
    
    # Check RE evolver's unified memory
    re_evolver = domains["Reverse Engineering"][1]
    if hasattr(re_evolver, 'unified_skill_memory'):
        memory = re_evolver.unified_skill_memory
        
        print(f"\nTotal Skills Stored: {len(memory.skills)}")
        print(f"Average Success Rate: {memory.get_statistics()['avg_success_rate']:.3f}")
        
        # Analyze feedback loop data
        if hasattr(memory, 'feedback_loop'):
            feedback = memory.feedback_loop
            
            print(f"\nTransfer History Entries: {len(feedback.transfer_history)}")
            print(f"Success Rate Estimates: {len(feedback.success_rates)}")
            
            # Show top transfer pairs
            if feedback.success_rates:
                print("\nTop Transfer Combinations:")
                sorted_rates = sorted(feedback.success_rates.items(), key=lambda x: x[1], reverse=True)[:5]
                for (skill_type, target_domain), rate in sorted_rates:
                    print(f"  {skill_type.value} → {target_domain}: {rate:.3f}")
    
    # Summary
    print("\n" + "=" * 80)
    print("EXPERIMENT SUMMARY")
    print("=" * 80)
    
    for domain_name, stats in results.items():
        print(f"{domain_name:25s}: {stats['success_rate']*100:6.1f}% success, {stats['avg_correctness']:.3f} avg correctness")
    
    overall_success = sum(r['success_rate'] for r in results.values()) / len(results)
    print(f"\nOverall Average Success Rate: {overall_success*100:.1f}%")
    
    # Save results
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    output_file = f"extended_transfer_experiment_{timestamp}.json"
    
    output_data = {
        "timestamp": datetime.now().isoformat(),
        "episodes_per_domain": episodes,
        "results": results,
        "overall_average": overall_success,
        "transfer_stats": {
            "skills_extracted": transfer_stats["skills_extracted"]
        }
    }
    
    with open(output_file, 'w') as f:
        json.dump(output_data, f, indent=2, default=str)
    
    print(f"\nResults saved to: {output_file}")
    print(f"Completed at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    return results


def evaluate_solution(solution_func, task):
    """Evaluate solution correctness."""
    try:
        test_input = task.get("test_input", 0)
        expected_output = task.get("expected_output", None)
        
        if expected_output is None:
            return 0.0
        
        predicted = solution_func(test_input)
        
        # Handle different output types
        if isinstance(expected_output, (int, float)):
            if isinstance(predicted, (int, float)):
                error = abs(predicted - expected_output)
                return 1.0 if error < 0.01 else 0.0
        
        return 0.0
    
    except Exception:
        return 0.0


if __name__ == "__main__":
    results = run_extended_experiment(episodes=500, seed=42)
