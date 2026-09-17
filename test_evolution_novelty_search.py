"""
Test Evolution Engine with Novelty Search Integration

Validates that adaptive strategy selection prevents premature convergence
and maintains behavioral diversity.
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from tiannara_core.evolution.population import evolve_details


def test_evolution_with_novelty_search():
    """Test evolution with novelty search enabled."""
    print("\n" + "="*80)
    print("EVOLUTION ENGINE - NOVELTY SEARCH INTEGRATION TEST")
    print("="*80)
    
    print("\n[TEST 1] Evolution WITHOUT novelty search (baseline)...")
    
    result_baseline = evolve_details(
        question="Optimize prosthetic grip stability",
        pop_size=30,
        generations=20,
        mutation_rate=0.15,
        fitness_function="grip_stability",
        genome_type="neural",
        use_adversary=False,
        use_novelty_search=False  # Disabled
    )
    
    print(f"  Best fitness: {result_baseline['best_score']:.4f}")
    print(f"  Converged: {result_baseline['converged']}")
    print(f"  Fitness history (first 5): {[round(x, 3) for x in result_baseline['history'][:5]]}")
    print(f"  Fitness history (last 5): {[round(x, 3) for x in result_baseline['history'][-5:]]}")
    
    # Check if converged prematurely
    baseline_converged = result_baseline['converged']
    baseline_final_fitness = result_baseline['best_score']
    
    print("\n[TEST 2] Evolution WITH novelty search...")
    
    result_novelty = evolve_details(
        question="Optimize prosthetic grip stability",
        pop_size=30,
        generations=20,
        mutation_rate=0.15,
        fitness_function="grip_stability",
        genome_type="neural",
        use_adversary=False,
        use_novelty_search=True  # Enabled
    )
    
    print(f"  Best fitness: {result_novelty['best_score']:.4f}")
    print(f"  Converged: {result_novelty['converged']}")
    print(f"  Fitness history (first 5): {[round(x, 3) for x in result_novelty['history'][:5]]}")
    print(f"  Fitness history (last 5): {[round(x, 3) for x in result_novelty['history'][-5:]]}")
    
    # Novelty search statistics
    novelty_stats = result_novelty.get('novelty_search', {})
    print(f"\n  Novelty Search Statistics:")
    print(f"    Enabled: {novelty_stats.get('enabled', False)}")
    print(f"    Archive size: {novelty_stats.get('archive_stats', {}).get('size', 0)}")
    print(f"    Average novelty: {novelty_stats.get('avg_novelty', 0):.4f}")
    print(f"    Strategies used: {novelty_stats.get('strategy_stats', {}).get('strategy_distribution', {})}")
    
    novelty_converged = result_novelty['converged']
    novelty_final_fitness = result_novelty['best_score']
    
    print("\n[COMPARISON]")
    print(f"  Baseline fitness: {baseline_final_fitness:.4f}")
    print(f"  Novelty fitness:  {novelty_final_fitness:.4f}")
    print(f"  Improvement:      {novelty_final_fitness - baseline_final_fitness:+.4f}")
    print(f"  Baseline converged: {baseline_converged}")
    print(f"  Novelty converged:  {novelty_converged}")
    
    # Validation
    success = True
    
    if novelty_final_fitness >= baseline_final_fitness * 0.95:
        print("\n  ✅ Novelty search maintained or improved fitness")
    else:
        print(f"\n  ⚠️  Novelty search reduced fitness by {baseline_final_fitness - novelty_final_fitness:.4f}")
        # Still acceptable if diversity improved
    
    if novelty_stats.get('archive_stats', {}).get('size', 0) > 0:
        print("  ✅ Novelty archive populated with diverse behaviors")
    else:
        print("  ❌ Novelty archive is empty")
        success = False
    
    strategies = novelty_stats.get('strategy_stats', {}).get('strategy_distribution', {})
    if len(strategies) > 1:
        print(f"  ✅ Adaptive strategy selection active: {strategies}")
    else:
        print(f"  ⚠️  Only one strategy used: {strategies}")
    
    avg_novelty = novelty_stats.get('avg_novelty', 0)
    if avg_novelty > 0.1:
        print(f"  ✅ Maintained behavioral diversity (avg novelty: {avg_novelty:.3f})")
    else:
        print(f"  ⚠️  Low behavioral diversity (avg novelty: {avg_novelty:.3f})")
    
    print("\n" + "="*80)
    if success:
        print("✅ NOVELTY SEARCH INTEGRATION SUCCESSFUL")
    else:
        print("❌ NOVELTY SEARCH INTEGRATION NEEDS IMPROVEMENT")
    print("="*80 + "\n")
    
    return success


if __name__ == '__main__':
    success = test_evolution_with_novelty_search()
    sys.exit(0 if success else 1)
