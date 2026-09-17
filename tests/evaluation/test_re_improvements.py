"""Test Improved Reverse Engineering Domain - Validate improvements achieve >90% success rate.

Tests the following improvements:
1. Advanced polynomial fitting and pattern detection
2. Strategy selection based on data patterns
3. Piecewise function handling
4. Modulo/threshold detection
5. Nearest neighbor fallback

Target: >90% overall success rate across 100 episodes
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

from tiannara_core.evaluation.reverse_engineering_domain import ReverseEngineeringGenerator
from tiannara_core.evaluation.reverse_engineering_evolver import ReverseEngineeringEvolver


def run_re_improvement_test(num_episodes=100):
    """Run 100-episode experiment on improved RE domain."""
    
    print("\n" + "=" * 80)
    print("REVERSE ENGINEERING DOMAIN IMPROVEMENT TEST")
    print("=" * 80)
    print(f"Episodes: {num_episodes}")
    print(f"Target Success Rate: >90%")
    print("=" * 80)
    
    # Initialize components
    generator = ReverseEngineeringGenerator(seed=42)
    evolver = ReverseEngineeringEvolver(seed=42)
    
    # Track metrics
    results = {
        'episodes': [],
        'success_rates_by_type': {},
        'overall_success_rate': 0.0,
        'quality_trajectory': []
    }
    
    start_time = time.time()
    
    for episode in range(num_episodes):
        # Generate task
        task = generator.generate_task(episode=episode)
        
        # Get solution from evolver using create_variant
        solution_func = evolver.create_variant(task, episode=episode)
        
        try:
            # Execute solution on inputs
            task_inputs = task.get("inputs", {})
            output = solution_func(**task_inputs)
            
            # Extract predicted value
            if isinstance(output, dict):
                predicted_value = output.get("output", output)
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
        task_type = task.get('subtype', 'unknown')
        if task_type not in results['success_rates_by_type']:
            results['success_rates_by_type'][task_type] = {'successes': 0, 'total': 0}
        
        results['success_rates_by_type'][task_type]['total'] += 1
        if success:
            results['success_rates_by_type'][task_type]['successes'] += 1
        
        # Track overall
        results['episodes'].append({
            'episode': episode + 1,
            'task_type': task_type,
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
    
    # Calculate per-type success rates
    for func_type, stats in results['success_rates_by_type'].items():
        stats['success_rate'] = stats['successes'] / stats['total'] if stats['total'] > 0 else 0.0
    
    # Print results
    print("\n" + "=" * 80)
    print("RESULTS SUMMARY")
    print("=" * 80)
    print(f"\nOverall Success Rate: {results['overall_success_rate']:.1%} "
          f"({total_successes}/{num_episodes})")
    print(f"Target: >90%")
    print(f"Status: {'✅ PASSED' if results['overall_success_rate'] >= 0.9 else '❌ FAILED'}")
    
    print(f"\nSuccess Rate by Function Type:")
    for func_type, stats in sorted(results['success_rates_by_type'].items()):
        print(f"  {func_type:30s}: {stats['success_rate']:.1%} "
              f"({stats['successes']}/{stats['total']})")
    
    print(f"\nQuality Trajectory:")
    print(f"  Start: {results['quality_trajectory'][0]:.3f}")
    print(f"  End:   {results['quality_trajectory'][-1]:.3f}")
    print(f"  Mean:  {np.mean(results['quality_trajectory']):.3f}")
    
    print(f"\nExecution Time: {elapsed:.1f}s ({elapsed/60:.1f} min)")
    
    # Save results
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    output_file = f"re_improvement_test_{timestamp}.json"
    
    with open(output_file, 'w') as f:
        json.dump(results, f, indent=2, default=str)
    
    print(f"\nResults saved to: {output_file}")
    
    return results


def analyze_improvements(results):
    """Analyze which improvements contributed most to success."""
    
    print("\n" + "=" * 80)
    print("IMPROVEMENT ANALYSIS")
    print("=" * 80)
    
    # Analyze performance by task type
    type_improvements = {
        'linear_function': 'Linear Fitting',
        'polynomial': 'Polynomial Regression',
        'piecewise': 'Piecewise Detection',
        'modulo_pattern': 'Modulo/Threshold Detection'
    }
    
    print("\nImprovement Effectiveness:")
    for task_type, improvement in type_improvements.items():
        if task_type in results['success_rates_by_type']:
            stats = results['success_rates_by_type'][task_type]
            rate = stats['success_rate']
            status = "✅" if rate >= 0.9 else "⚠️" if rate >= 0.7 else "❌"
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
    
    if results['overall_success_rate'] >= 0.95:
        print("✅ OUTSTANDING: Near-perfect performance (>95%)")
    elif results['overall_success_rate'] >= 0.9:
        print("✅ EXCELLENT: Target achieved (>90%)")
    elif results['overall_success_rate'] >= 0.7:
        print("⚠️  GOOD: Strong performance, minor refinements needed (>70%)")
    elif results['overall_success_rate'] >= 0.5:
        print("⚠️  MODERATE: Some improvements working, others need work (>50%)")
    else:
        print("❌ NEEDS WORK: Significant improvements required (<50%)")
    
    print("=" * 80)


def main():
    """Run RE improvement test and analysis."""
    
    print("\nStarting Reverse Engineering Domain Improvement Test...")
    print("This will validate all implemented improvements on 100 episodes.\n")
    
    try:
        results = run_re_improvement_test(num_episodes=100)
        analyze_improvements(results)
        
        print("\n" + "=" * 80)
        print("TEST COMPLETE")
        print("=" * 80)
        
        return results['overall_success_rate'] >= 0.9
        
    except Exception as e:
        print(f"\n❌ ERROR: {e}")
        import traceback
        traceback.print_exc()
        return False


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
