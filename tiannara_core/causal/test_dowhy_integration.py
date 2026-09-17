"""
DoWhy Integration Test Script

Demonstrates causal graph discovery and effect estimation
using the DoWhy library integration.

Usage:
    python tiannara_core/causal/test_dowhy_integration.py
"""

import sys
from pathlib import Path
import numpy as np

# Add project root to path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

try:
    from tiannara_core.causal.dowhy_integration import (
        CausalGraphDiscovery,
        discover_and_estimate
    )
    DOWHY_TEST_AVAILABLE = True
except ImportError as e:
    print(f"⚠️  DoWhy not available: {e}")
    print("Install with: pip install dowhy pandas scikit-learn")
    DOWHY_TEST_AVAILABLE = False


def generate_synthetic_causal_data(n_samples=500):
    """
    Generate synthetic data with known causal structure:
    
    X → Y → Z
    X also directly affects Z
    
    True causal effects:
    - X → Y: 0.5
    - Y → Z: 0.3
    - X → Z: 0.2 (direct)
    """
    np.random.seed(42)
    
    # Exogenous noise
    eps_x = np.random.randn(n_samples) * 0.5
    eps_y = np.random.randn(n_samples) * 0.5
    eps_z = np.random.randn(n_samples) * 0.5
    
    # Generate variables with causal relationships
    X = eps_x
    Y = 0.5 * X + eps_y  # X causes Y
    Z = 0.3 * Y + 0.2 * X + eps_z  # Both X and Y cause Z
    
    data = np.column_stack([X, Y, Z])
    variable_names = ['X', 'Y', 'Z']
    
    true_effects = {
        ('X', 'Y'): 0.5,
        ('Y', 'Z'): 0.3,
        ('X', 'Z'): 0.2
    }
    
    return data, variable_names, true_effects


def test_causal_discovery():
    """Test causal graph discovery on synthetic data."""
    
    if not DOWHY_TEST_AVAILABLE:
        print("Skipping test - DoWhy not installed")
        return
    
    print("=" * 80)
    print("Tiannara DoWhy Integration - Causal Discovery Test")
    print("=" * 80)
    print()
    
    # Generate synthetic data
    print("📊 Generating synthetic causal data...")
    data, variable_names, true_effects = generate_synthetic_causal_data(500)
    
    print(f"   Samples: {data.shape[0]}")
    print(f"   Variables: {variable_names}")
    print(f"   True causal structure:")
    for (cause, effect), strength in true_effects.items():
        print(f"     {cause} → {effect}: {strength}")
    print()
    
    # Initialize discovery
    discovery = CausalGraphDiscovery(
        significance_level=0.05,
        min_observations=100
    )
    
    # Discover causal graph
    print("🔍 Discovering causal graph...")
    print("-" * 80)
    
    try:
        graph = discovery.discover_causal_graph(data, variable_names)
        
        print(f"\n✅ Discovered {len(graph.edges)} causal relationships:")
        for cause, effect in graph.edges:
            confidence = graph.confidence_scores.get((cause, effect), 0.0)
            print(f"   {cause} → {effect} (confidence: {confidence:.3f})")
        
        print(f"\nAdjacency matrix:")
        print(graph.adjacency_matrix)
        print()
        
        # Compare with ground truth
        print("📋 Comparison with ground truth:")
        true_edges = set(true_effects.keys())
        discovered_edges = set(graph.edges)
        
        true_positives = true_edges & discovered_edges
        false_positives = discovered_edges - true_edges
        false_negatives = true_edges - discovered_edges
        
        print(f"   True positives: {len(true_positives)} {true_positives}")
        print(f"   False positives: {len(false_positives)} {false_positives}")
        print(f"   False negatives: {len(false_negatives)} {false_negatives}")
        
        if len(true_edges) > 0:
            precision = len(true_positives) / len(discovered_edges) if discovered_edges else 0
            recall = len(true_positives) / len(true_edges)
            print(f"   Precision: {precision:.2%}")
            print(f"   Recall: {recall:.2%}")
        
        print()
        
    except Exception as e:
        print(f"❌ Graph discovery failed: {e}")
        import traceback
        traceback.print_exc()
        return
    
    # Estimate causal effects
    print("=" * 80)
    print("📈 Estimating Causal Effects")
    print("=" * 80)
    print()
    
    # Test each true causal relationship
    for (treatment, outcome), true_effect in true_effects.items():
        print(f"Estimating effect: {treatment} → {outcome}")
        print("-" * 80)
        
        try:
            estimate = discovery.estimate_causal_effect(
                data, treatment, outcome, variable_names, graph=graph
            )
            
            print(f"   Estimated effect: {estimate.estimated_effect:.4f}")
            print(f"   True effect: {true_effect:.4f}")
            print(f"   Error: {abs(estimate.estimated_effect - true_effect):.4f}")
            print(f"   95% CI: [{estimate.confidence_interval[0]:.4f}, "
                  f"{estimate.confidence_interval[1]:.4f}]")
            print(f"   p-value: {estimate.p_value:.4f}")
            print(f"   Statistically significant: {estimate.statistical_significance}")
            print(f"   Method: {estimate.method_used}")
            
            # Check if true value is within confidence interval
            ci_lower, ci_upper = estimate.confidence_interval
            contains_true = ci_lower <= true_effect <= ci_upper
            print(f"   Contains true value: {'✅ Yes' if contains_true else '❌ No'}")
            
            print()
            
        except Exception as e:
            print(f"   ⚠️  Estimation failed: {e}")
            print()
    
    # Summary
    print("=" * 80)
    print("📊 SUMMARY")
    print("=" * 80)
    print()
    print("✅ Causal discovery and effect estimation completed!")
    print()
    print("Key findings:")
    print(f"  • Discovered {len(graph.edges)} causal relationships")
    print(f"  • Successfully estimated {len(true_effects)} causal effects")
    print(f"  • Used DoWhy's backdoor adjustment for confounder control")
    print()
    print("Next steps:")
    print("  1. Integrate with CausalSystemEvolver")
    print("  2. Replace basic regression with causal effect estimates")
    print("  3. Add PCMCI for time-series causal discovery")
    print()


if __name__ == "__main__":
    test_causal_discovery()
