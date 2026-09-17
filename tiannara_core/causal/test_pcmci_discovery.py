"""
PCMCI Discovery Test Script

Demonstrates time-series causal discovery using PCMCI algorithm.

Usage:
    python tiannara_core/causal/test_pcmci_discovery.py
"""

import sys
from pathlib import Path
import numpy as np

# Add project root to path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

try:
    from tiannara_core.causal.pcmci_discovery import (
        PCMCIDiscovery,
        discover_temporal_causality
    )
    PCMCI_AVAILABLE = True
except ImportError as e:
    print(f"⚠️  PCMCI module not available: {e}")
    PCMCI_AVAILABLE = False


def generate_synthetic_temporal_data(n_samples=500):
    """
    Generate synthetic time-series data with known causal structure:
    
    X(t) → Y(t+1) → Z(t+2)
    X also directly affects Z at lag 2
    
    True causal effects:
    - X(t) → Y(t+1): 0.6
    - Y(t) → Z(t+1): 0.4
    - X(t) → Z(t+2): 0.3
    """
    T = n_samples
    X = np.zeros(T)
    Y = np.zeros(T)
    Z = np.zeros(T)
    
    # Initialize with random noise
    X[0] = np.random.randn()
    Y[0] = np.random.randn()
    Z[0] = np.random.randn()
    
    # Generate time series with causal dependencies
    for t in range(1, T):
        X[t] = 0.5 * X[t-1] + np.random.randn() * 0.3
        
        # Y depends on X with lag 1
        if t >= 1:
            Y[t] = 0.6 * X[t-1] + 0.4 * Y[t-1] + np.random.randn() * 0.2
        
        # Z depends on Y with lag 1 and X with lag 2
        if t >= 2:
            Z[t] = 0.4 * Y[t-1] + 0.3 * X[t-2] + 0.3 * Z[t-1] + np.random.randn() * 0.2
        elif t == 1:
            Z[t] = 0.4 * Y[t-1] + 0.3 * Z[t-1] + np.random.randn() * 0.2
    
    data = np.column_stack([X, Y, Z])
    variable_names = ['X', 'Y', 'Z']
    
    return data, variable_names


def test_pcmci_discovery():
    """Test PCMCI causal discovery on synthetic data."""
    print("=" * 80)
    print("PCMCI Time-Series Causal Discovery Test")
    print("=" * 80)
    
    # Generate synthetic data
    print("\n1. Generating synthetic temporal data...")
    data, var_names = generate_synthetic_temporal_data(n_samples=500)
    print(f"   Data shape: {data.shape}")
    print(f"   Variables: {var_names}")
    print(f"   True structure: X(t)→Y(t+1), Y(t)→Z(t+1), X(t)→Z(t+2)")
    
    # Run PCMCI discovery
    print("\n2. Running PCMCI discovery...")
    discovery = PCMCIDiscovery(tau_max=3, alpha=0.05)
    graph = discovery.discover_causal_graph(data, var_names)
    
    print(f"\n3. Discovered {len(graph.links)} causal links:")
    print("-" * 80)
    
    # Sort links by strength
    sorted_links = sorted(graph.links, key=lambda x: abs(x.strength), reverse=True)
    
    for link in sorted_links[:20]:  # Show top 20
        print(f"   {link}")
    
    # Check if true causal links were discovered
    print("\n4. Validation against ground truth:")
    print("-" * 80)
    
    true_links_found = 0
    total_true_links = 3
    
    # Check X→Y at lag 1
    xy_links = [l for l in graph.links if l.source == 'X' and l.target == 'Y' and l.lag == 1]
    if xy_links:
        print(f"   ✓ Found X(t)→Y(t+1): strength={xy_links[0].strength:.3f}, p={xy_links[0].p_value:.4f}")
        true_links_found += 1
    else:
        print(f"   ✗ Missing X(t)→Y(t+1)")
    
    # Check Y→Z at lag 1
    yz_links = [l for l in graph.links if l.source == 'Y' and l.target == 'Z' and l.lag == 1]
    if yz_links:
        print(f"   ✓ Found Y(t)→Z(t+1): strength={yz_links[0].strength:.3f}, p={yz_links[0].p_value:.4f}")
        true_links_found += 1
    else:
        print(f"   ✗ Missing Y(t)→Z(t+1)")
    
    # Check X→Z at lag 2
    xz_links = [l for l in graph.links if l.source == 'X' and l.target == 'Z' and l.lag == 2]
    if xz_links:
        print(f"   ✓ Found X(t)→Z(t+2): strength={xz_links[0].strength:.3f}, p={xz_links[0].p_value:.4f}")
        true_links_found += 1
    else:
        print(f"   ✗ Missing X(t)→Z(t+2)")
    
    print(f"\n   Recovery rate: {true_links_found}/{total_true_links} ({100*true_links_found/total_true_links:.0f}%)")
    
    # Estimate temporal effects
    print("\n5. Estimating temporal causal effects:")
    print("-" * 80)
    
    effects_xy = discovery.estimate_temporal_effects(data, graph, 'X', 'Y')
    print(f"   X → Y:")
    print(f"      Total effect: {effects_xy['total_effect']:.3f}")
    print(f"      Significant paths: {effects_xy['n_significant_paths']}")
    
    effects_yz = discovery.estimate_temporal_effects(data, graph, 'Y', 'Z')
    print(f"   Y → Z:")
    print(f"      Total effect: {effects_yz['total_effect']:.3f}")
    print(f"      Significant paths: {effects_yz['n_significant_paths']}")
    
    effects_xz = discovery.estimate_temporal_effects(data, graph, 'X', 'Z')
    print(f"   X → Z:")
    print(f"      Total effect: {effects_xz['total_effect']:.3f}")
    print(f"      Significant paths: {effects_xz['n_significant_paths']}")
    
    # Adjacency matrix
    print("\n6. Adjacency matrix representation:")
    print("-" * 80)
    adj = graph.to_adjacency_matrix()
    print(f"   Shape: {adj.shape} (source × target × lag)")
    
    for lag in range(graph.max_lag + 1):
        print(f"\n   Lag {lag}:")
        for i, src in enumerate(var_names):
            for j, tgt in enumerate(var_names):
                if adj[i, j, lag] > 0:
                    print(f"      {src} → {tgt}: {adj[i, j, lag]:.3f}")
    
    print("\n" + "=" * 80)
    print("Test completed successfully!")
    print("=" * 80)


def test_convenience_function():
    """Test the convenience function for quick discovery."""
    print("\n" + "=" * 80)
    print("Testing Convenience Function")
    print("=" * 80)
    
    # Generate simple data
    data, var_names = generate_synthetic_temporal_data(n_samples=300)
    
    # Use convenience function
    print("\nRunning discover_temporal_causality()...")
    graph = discover_temporal_causality(data, var_names, tau_max=2, alpha=0.05)
    
    print(f"Discovered {len(graph.links)} links")
    
    for link in sorted(graph.links, key=lambda x: abs(x.strength), reverse=True)[:5]:
        print(f"   {link}")
    
    print("\nConvenience function test passed!")


if __name__ == "__main__":
    if not PCMCI_AVAILABLE:
        print("⚠️  Cannot run tests - PCMCI module not available")
        print("Install dependencies: pip install tigramite numpy scipy")
        sys.exit(1)
    
    try:
        test_pcmci_discovery()
        test_convenience_function()
    except Exception as e:
        print(f"\n❌ Test failed with error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
