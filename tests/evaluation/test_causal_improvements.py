"""Test Improved Causal Domain - Validate all improvements achieve >50% success rate.

Tests the following improvements:
1. Partial correlation for confounded systems
2. Relative tolerance evaluation
3. Ensemble prediction with meta-learning weights
4. PC algorithm for structure learning
5. Intervention prediction fixes

Target: >50% overall success rate across 100 episodes
"""

import sys
from pathlib import Path
import json
import time
import numpy as np
from datetime import datetime

# Add project root to path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.evaluation.causal_system_domain import CausalSystemGenerator
from tiannara_core.evaluation.causal_system_evolver import CausalSystemEvolver
from tiannara_core.evaluation.evaluator import Evaluator


def run_causal_improvement_test(num_episodes=100):
    """Run 100-episode experiment on improved causal domain."""
    
    print("\n" + "=" * 80)
    print("CAUSAL DOMAIN IMPROVEMENT TEST")
    print("=" * 80)
    print(f"Episodes: {num_episodes}")
    print(f"Target Success Rate: >50%")
    print("=" * 80)
    
    # Initialize components
    generator = CausalSystemGenerator(seed=42)
    evolver = CausalSystemEvolver(seed=42)
    evaluator = Evaluator()
    
    # Track metrics
    results = {
        'episodes': [],
        'success_rates_by_subtype': {},
        'overall_success_rate': 0.0,
        'quality_trajectory': [],
        'improvements_applied': []
    }
    
    start_time = time.time()
    
    for episode in range(num_episodes):
        # Generate task
        task = generator.generate_task(episode=episode)
        
        # Get solution from evolver using create_variant
        solution_func = evolver.create_variant(task, episode=episode)
        
        try:
            # Execute solution
            task_inputs = task.get("inputs", {})
            output = solution_func(**task_inputs)
            
            # Extract predicted value for target variable
            target_var = task_inputs.get("target_variable", "y")
            if isinstance(output, dict):
                predicted_value = output.get(target_var, 0)
            else:
                predicted_value = output
            
            # Verify using domain-specific verifier
            success = generator.verify_solution(task, predicted_value)
            correctness = 1.0 if success else 0.0
            
        except Exception as e:
            success = False
            correctness = 0.0
        
        # Update evolver quality
        if hasattr(evolver, 'update_quality'):
            evolver.update_quality(success, correctness, solution_func)
        
        # Track by subtype
        subtype = task.get('subtype', 'unknown')
        if subtype not in results['success_rates_by_subtype']:
            results['success_rates_by_subtype'][subtype] = {'successes': 0, 'total': 0}
        
        results['success_rates_by_subtype'][subtype]['total'] += 1
        if success:
            results['success_rates_by_subtype'][subtype]['successes'] += 1
        
        # Track overall
        results['episodes'].append({
            'episode': episode + 1,
            'subtype': subtype,
            'correctness': correctness,
            'success': success,
            'quality_level': evolver.quality_level
        })
        
        results['quality_trajectory'].append(evolver.quality_level)
        
        # Progress reporting
        if (episode + 1) % 10 == 0:
            recent_successes = sum(1 for e in results['episodes'][-10:] if e['success'])
            recent_rate = recent_successes / 10.0
            print(f"Episode {episode + 1}/{num_episodes} | "
                  f"Recent 10-ep success: {recent_rate:.1%} | "
                  f"Quality: {evolver.quality_level:.3f}")
    
    elapsed = time.time() - start_time
    
    # Calculate final metrics
    total_successes = sum(1 for e in results['episodes'] if e['success'])
    results['overall_success_rate'] = total_successes / num_episodes
    
    # Calculate per-subtype success rates
    for subtype, stats in results['success_rates_by_subtype'].items():
        stats['success_rate'] = stats['successes'] / stats['total'] if stats['total'] > 0 else 0.0
    
    # Print results
    print("\n" + "=" * 80)
    print("RESULTS SUMMARY")
    print("=" * 80)
    print(f"\nOverall Success Rate: {results['overall_success_rate']:.1%} "
          f"({total_successes}/{num_episodes})")
    print(f"Target: >50%")
    print(f"Status: {'✅ PASSED' if results['overall_success_rate'] > 0.5 else '❌ FAILED'}")
    
    print(f"\nSuccess Rate by Subtype:")
    for subtype, stats in sorted(results['success_rates_by_subtype'].items()):
        print(f"  {subtype:30s}: {stats['success_rate']:.1%} "
              f"({stats['successes']}/{stats['total']})")
    
    print(f"\nQuality Trajectory:")
    print(f"  Start: {results['quality_trajectory'][0]:.3f}")
    print(f"  End:   {results['quality_trajectory'][-1]:.3f}")
    print(f"  Mean:  {np.mean(results['quality_trajectory']):.3f}")
    
    print(f"\nExecution Time: {elapsed:.1f}s ({elapsed/60:.1f} min)")
    
    # Save results
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    output_file = f"causal_improvement_test_{timestamp}.json"
    
    with open(output_file, 'w') as f:
        json.dump(results, f, indent=2, default=str)
    
    print(f"\nResults saved to: {output_file}")
    
    return results


def analyze_improvements(results):
    """Analyze which improvements contributed most to success."""
    
    print("\n" + "=" * 80)
    print("IMPROVEMENT ANALYSIS")
    print("=" * 80)
    
    # Analyze performance by subtype (each uses different improvement)
    subtype_improvements = {
        'confounded_system': 'Partial Correlation',
        'linear_causal_chain': 'Full Chain Inference',
        'branching_causal': 'Regression Prediction',
        'intervention_prediction': 'Intervention Fixes',
        'ensemble': 'Ensemble Prediction'
    }
    
    print("\nImprovement Effectiveness:")
    for subtype, improvement in subtype_improvements.items():
        if subtype in results['success_rates_by_subtype']:
            stats = results['success_rates_by_subtype'][subtype]
            rate = stats['success_rate']
            status = "✅" if rate > 0.5 else "⚠️" if rate > 0.3 else "❌"
            print(f"  {status} {improvement:30s}: {rate:.1%} success rate")
    
    # Quality improvement analysis
    quality_start = results['quality_trajectory'][0]
    quality_end = results['quality_trajectory'][-1]
    quality_improvement = quality_end - quality_start
    
    print(f"\nQuality Level Evolution:")
    print(f"  Improvement: {quality_improvement:+.3f} "
          f"({'positive' if quality_improvement > 0 else 'negative'})")
    
    # Overall assessment
    print(f"\n" + "=" * 80)
    print("OVERALL ASSESSMENT")
    print("=" * 80)
    
    if results['overall_success_rate'] > 0.7:
        print("✅ EXCELLENT: All improvements working effectively (>70%)")
    elif results['overall_success_rate'] > 0.5:
        print("✅ GOOD: Target achieved, improvements validated (>50%)")
    elif results['overall_success_rate'] > 0.3:
        print("⚠️  PARTIAL: Some improvements working, others need refinement (>30%)")
    else:
        print("❌ NEEDS WORK: Improvements not achieving target (<30%)")
    
    print("=" * 80)


def main():
    """Run causal improvement test and analysis."""
    
    print("\nStarting Causal Domain Improvement Test...")
    print("This will validate all implemented improvements on 100 episodes.\n")
    
    try:
        results = run_causal_improvement_test(num_episodes=100)
        analyze_improvements(results)
        
        print("\n" + "=" * 80)
        print("TEST COMPLETE")
        print("=" * 80)
        
        return results['overall_success_rate'] > 0.5
        
    except Exception as e:
        print(f"\n❌ ERROR: {e}")
        import traceback
        traceback.print_exc()
        return False


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
