"""
Run Refined Experiments - Compare Learning Trajectories Across All Domains

Runs 100-episode experiments on all refined domains and compares performance:
- Algorithm domain (with improved mutations)
- Logic domain (with harder puzzle types)
- Reverse Engineering domain (improved)
- Causal domain (improved with PC algorithm, do-calculus)

Target: Validate that refinements improve overall system capability
"""

import sys
from pathlib import Path
import json
import time
from datetime import datetime
import numpy as np

# Add project root to path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.evaluation.algorithm_domain import AlgorithmTaskGenerator
from tiannara_core.evaluation.evolution_engine import AlgorithmEvolver
from tiannara_core.evaluation.logic_domain import LogicPuzzleGenerator
from tiannara_core.evaluation.logic_evolution_engine import LogicPuzzleEvolver
from tiannara_core.evaluation.reverse_engineering_domain import ReverseEngineeringGenerator
from tiannara_core.evaluation.reverse_engineering_evolver import ReverseEngineeringEvolver
from tiannara_core.evaluation.causal_system_domain import CausalSystemGenerator
from tiannara_core.evaluation.causal_system_evolver import CausalSystemEvolver
from tiannara_core.evaluation.evaluator import Evaluator


def run_domain_experiment(domain_name: str, generator, evolver, num_episodes: int = 100):
    """Run experiment on a single domain."""
    print(f"\n{'='*80}")
    print(f"RUNNING {domain_name.upper()} DOMAIN EXPERIMENT")
    print(f"{'='*80}\n")
    
    results = {
        'domain': domain_name,
        'episodes': [],
        'success_rate': 0.0,
        'avg_quality': 0.0,
        'learning_curve': []
    }
    
    # Create evaluator for proper solution execution
    evaluator = Evaluator()
    
    successes = 0
    
    for episode in range(num_episodes):
        start_time = time.time()
        
        # Generate task
        task = generator.generate_task(episode=episode)
        
        # Get solution from evolver
        solution_func = evolver.create_variant(task, episode=episode)
        
        try:
            # Use evaluator to properly execute solution (handles dict outputs)
            evaluation = evaluator.evaluate(solution_func, task.get("inputs", {}), runs=3)
            
            # Extract actual output from evaluation results
            outputs = evaluation.get("outputs", [])
            if outputs:
                first_output = outputs[0]
                actual_output = first_output.get("output") if isinstance(first_output, dict) else first_output
            else:
                actual_output = None
            
            # Verify using domain-specific verifier
            if actual_output is not None:
                success = generator.verify_solution(task, actual_output)
                correctness = 1.0 if success else 0.0
            else:
                success = False
                correctness = 0.0
            
        except Exception as e:
            success = False
            correctness = 0.0
            # Log first few errors for debugging
            if episode < 3:
                print(f"  Episode {episode} ERROR: {type(e).__name__}: {e}")
                print(f"    Task type: {task.get('type', 'unknown')}")
                print(f"    Task inputs keys: {list(task.get('inputs', {}).keys())[:5]}")
        
        elapsed = time.time() - start_time
        
        # Update evolver quality
        if hasattr(evolver, 'update_quality'):
            import inspect
            sig = inspect.signature(evolver.update_quality)
            params = list(sig.parameters.keys())
            
            # Check if evolver supports task and episode parameters
            if 'task' in params and 'episode' in params:
                evolver.update_quality(success, correctness, solution_func, task=task, episode=episode)
            else:
                # Backward compatibility for evolvers without new signature
                evolver.update_quality(success, correctness, solution_func)
        
        # Track results
        if success:
            successes += 1
        
        episode_result = {
            'episode': episode,
            'success': success,
            'correctness': correctness,
            'quality_level': evolver.quality_level if hasattr(evolver, 'quality_level') else 0.0,
            'execution_time': elapsed
        }
        
        results['episodes'].append(episode_result)
        results['learning_curve'].append(correctness)
    
    # Calculate summary statistics
    results['success_rate'] = successes / num_episodes * 100
    results['avg_quality'] = np.mean([e['quality_level'] for e in results['episodes']])
    
    # Print summary
    print(f"\n{domain_name.upper()} Domain Results:")
    print(f"  Success Rate: {results['success_rate']:.1f}% ({successes}/{num_episodes})")
    print(f"  Average Quality: {results['avg_quality']:.3f}")
    print(f"  Final Quality: {results['episodes'][-1]['quality_level']:.3f}")
    
    return results


def compare_domains(all_results: list):
    """Compare performance across all domains."""
    print(f"\n{'='*80}")
    print("DOMAIN COMPARISON SUMMARY")
    print(f"{'='*80}\n")
    
    print(f"{'Domain':<25} {'Success Rate':<15} {'Avg Quality':<15} {'Final Quality':<15}")
    print("-" * 70)
    
    for results in all_results:
        domain = results['domain']
        success_rate = results['success_rate']
        avg_quality = results['avg_quality']
        final_quality = results['episodes'][-1]['quality_level']
        
        print(f"{domain:<25} {success_rate:>6.1f}%      {avg_quality:>8.3f}     {final_quality:>8.3f}")
    
    # Overall statistics
    avg_success = np.mean([r['success_rate'] for r in all_results])
    avg_final_quality = np.mean([r['episodes'][-1]['quality_level'] for r in all_results])
    
    print(f"\nOverall Statistics:")
    print(f"  Average Success Rate: {avg_success:.1f}%")
    print(f"  Average Final Quality: {avg_final_quality:.3f}")
    
    # Identify best/worst performing domains
    best_domain = max(all_results, key=lambda r: r['success_rate'])
    worst_domain = min(all_results, key=lambda r: r['success_rate'])
    
    print(f"\nBest Performing Domain: {best_domain['domain']} ({best_domain['success_rate']:.1f}%)")
    print(f"Worst Performing Domain: {worst_domain['domain']} ({worst_domain['success_rate']:.1f}%)")
    
    return {
        'avg_success_rate': avg_success,
        'avg_final_quality': avg_final_quality,
        'best_domain': best_domain['domain'],
        'worst_domain': worst_domain['domain']
    }


def analyze_learning_trajectories(all_results: list):
    """Analyze learning curves across domains."""
    print(f"\n{'='*80}")
    print("LEARNING TRAJECTORY ANALYSIS")
    print(f"{'='*80}\n")
    
    for results in all_results:
        domain = results['domain']
        curve = results['learning_curve']
        
        # Calculate phases
        early = np.mean(curve[:20])  # First 20 episodes
        mid = np.mean(curve[40:60])  # Middle 20 episodes
        late = np.mean(curve[80:])   # Last 20 episodes
        
        improvement = late - early
        
        print(f"{domain}:")
        print(f"  Early Phase (0-20):   {early:.3f}")
        print(f"  Mid Phase (40-60):    {mid:.3f}")
        print(f"  Late Phase (80-100):  {late:.3f}")
        print(f"  Improvement:          {improvement:+.3f}")
        print()


def main():
    """Run refined experiments on all domains."""
    print("\n" + "=" * 80)
    print("REFINED EXPERIMENTS - CROSS-DOMAIN COMPARISON")
    print("=" * 80)
    print(f"Started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"Episodes per domain: 100")
    print(f"Domains: Algorithm, Logic, Reverse Engineering, Causal")
    
    all_results = []
    
    # 1. Algorithm Domain
    print("\n\n>>> Starting Algorithm Domain...")
    algo_generator = AlgorithmTaskGenerator(seed=42)
    algo_evolver = AlgorithmEvolver(seed=42)
    algo_results = run_domain_experiment("Algorithm", algo_generator, algo_evolver, 100)
    all_results.append(algo_results)
    
    # 2. Logic Domain (with harder puzzle types)
    print("\n\n>>> Starting Logic Domain...")
    logic_generator = LogicPuzzleGenerator(seed=123)
    logic_evolver = LogicPuzzleEvolver(seed=123)
    logic_results = run_domain_experiment("Logic", logic_generator, logic_evolver, 100)
    all_results.append(logic_results)
    
    # 3. Reverse Engineering Domain (improved)
    print("\n\n>>> Starting Reverse Engineering Domain...")
    re_generator = ReverseEngineeringGenerator(seed=456)
    re_evolver = ReverseEngineeringEvolver(seed=456)
    re_results = run_domain_experiment("Reverse Engineering", re_generator, re_evolver, 100)
    all_results.append(re_results)
    
    # 4. Causal Domain (improved with PC algorithm, do-calculus)
    print("\n\n>>> Starting Causal Domain...")
    causal_generator = CausalSystemGenerator(seed=789)
    causal_evolver = CausalSystemEvolver(seed=789)
    causal_results = run_domain_experiment("Causal", causal_generator, causal_evolver, 100)
    all_results.append(causal_results)
    
    # Compare domains
    comparison = compare_domains(all_results)
    
    # Analyze learning trajectories
    analyze_learning_trajectories(all_results)
    
    # Save results
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    output_file = f"refined_experiments_{timestamp}.json"
    
    with open(output_file, 'w') as f:
        json.dump({
            'timestamp': datetime.now().isoformat(),
            'comparison': comparison,
            'domains': all_results
        }, f, indent=2)
    
    print(f"\n{'='*80}")
    print(f"RESULTS SAVED TO: {output_file}")
    print(f"{'='*80}")
    
    # Final assessment
    print(f"\n{'='*80}")
    print("FINAL ASSESSMENT")
    print(f"{'='*80}\n")
    
    if comparison['avg_success_rate'] > 70:
        print("✅ EXCELLENT: System shows strong capability across all domains!")
    elif comparison['avg_success_rate'] > 50:
        print("✓ GOOD: System demonstrates solid multi-domain competence.")
    elif comparison['avg_success_rate'] > 30:
        print("⚠️  MODERATE: Some domains need further refinement.")
    else:
        print("❌ NEEDS WORK: Significant improvements required.")
    
    print(f"\nKey Insights:")
    print(f"  • Best domain ({comparison['best_domain']}) shows system strengths")
    print(f"  • Worst domain ({comparison['worst_domain']}) identifies areas for improvement")
    print(f"  • Overall success rate of {comparison['avg_success_rate']:.1f}% indicates {'robust' if comparison['avg_success_rate'] > 60 else 'developing'} cross-domain capability")
    
    print(f"\nCompleted at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    return comparison


if __name__ == "__main__":
    try:
        results = main()
        sys.exit(0)
    except Exception as e:
        print(f"\n❌ Experiment failed with error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
