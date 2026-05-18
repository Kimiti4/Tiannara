#!/usr/bin/env python3
"""
Phase 2 Integration Test - Python Cortex Standalone Test

This script tests the Python simulation cortex without requiring Elixir runtime.
It simulates the NATS event flow locally to verify core logic works.

Run with: python test_cortex_standalone.py
"""

import asyncio
import json
from grcc_simulation_cortex import GRCCSimulationCortex


async def test_basic_simulation():
    """Test basic simulation step execution."""
    print("\n🧪 Test 1: Basic Simulation Step\n")
    
    cortex = GRCCSimulationCortex()
    
    # Run 5 simulation steps
    for i in range(1, 6):
        print(f"\n--- Step {i} ---")
        result = cortex.run_simulation_step({})
        
        print(f"  Entropy: {result['entropy']:.3f}")
        print(f"  Dominance: {result['dominance']:.3f}")
        print(f"  Lineages: {len(result['lineage_state'])}")
        print(f"  Niches: {len(result['niche_map'])}")
        print(f"  Anomalies: {len(result['anomalies'])}")
    
    print("\n✅ Test 1 passed: Basic simulation works\n")


async def test_intervention_application():
    """Test CIS intervention application."""
    print("\n🧪 Test 2: CIS Intervention Application\n")
    
    cortex = GRCCSimulationCortex()
    
    print(f"Initial mutation rate: {cortex.params['mutation_rate']}")
    
    # Apply heavy suppression intervention
    print("\nApplying heavy_suppression intervention...")
    cortex.apply_intervention("heavy_suppression", {
        'mutation_boost': 0.3
    })
    print(f"New mutation rate: {cortex.params['mutation_rate']}")
    
    # Apply entropy injection
    print("\nApplying entropy_injection intervention...")
    cortex.apply_intervention("entropy_injection", {})
    print(f"New mutation rate: {cortex.params['mutation_rate']}")
    print(f"New extinction pressure: {cortex.params['extinction_pressure']}")
    
    # Apply mild diversity boost
    print("\nApplying mild_diversity_boost intervention...")
    cortex.apply_intervention("mild_diversity_boost", {
        'mutation_rate_increase': 0.05
    })
    print(f"Final mutation rate: {cortex.params['mutation_rate']}")
    
    print("\n✅ Test 2 passed: Interventions apply correctly\n")


async def test_entropy_computation():
    """Test Shannon entropy calculation."""
    print("\n🧪 Test 3: Entropy Computation\n")
    
    cortex = GRCCSimulationCortex()
    
    # Test case 1: Single lineage (should have 0 entropy)
    cortex.simulation_state['lineage_population'] = {
        'lineage_1': {'population': 100, 'fitness': 0.5}
    }
    entropy = cortex._compute_entropy()
    print(f"Single lineage entropy: {entropy:.3f} (expected: 0.0)")
    assert entropy == 0.0, "Single lineage should have 0 entropy"
    
    # Test case 2: Two equal lineages (should have max entropy = 1.0)
    cortex.simulation_state['lineage_population'] = {
        'lineage_1': {'population': 50, 'fitness': 0.5},
        'lineage_2': {'population': 50, 'fitness': 0.5}
    }
    entropy = cortex._compute_entropy()
    print(f"Two equal lineages entropy: {entropy:.3f} (expected: 1.0)")
    assert abs(entropy - 1.0) < 0.01, "Equal lineages should have max entropy"
    
    # Test case 3: Unequal lineages (should have medium entropy)
    cortex.simulation_state['lineage_population'] = {
        'lineage_1': {'population': 80, 'fitness': 0.7},
        'lineage_2': {'population': 20, 'fitness': 0.3}
    }
    entropy = cortex._compute_entropy()
    print(f"Unequal lineages entropy: {entropy:.3f} (expected: ~0.5)")
    assert 0.3 < entropy < 0.8, "Unequal lineages should have medium entropy"
    
    print("\n✅ Test 3 passed: Entropy computation correct\n")


async def test_dominance_computation():
    """Test dominance calculation."""
    print("\n🧪 Test 4: Dominance Computation\n")
    
    cortex = GRCCSimulationCortex()
    
    # Test case 1: Single lineage (100% dominance)
    cortex.simulation_state['lineage_population'] = {
        'lineage_1': {'population': 100, 'fitness': 0.5}
    }
    dominance = cortex._compute_dominance()
    print(f"Single lineage dominance: {dominance:.3f} (expected: 1.0)")
    assert dominance == 1.0, "Single lineage should have 100% dominance"
    
    # Test case 2: Two equal lineages (50% dominance)
    cortex.simulation_state['lineage_population'] = {
        'lineage_1': {'population': 50, 'fitness': 0.5},
        'lineage_2': {'population': 50, 'fitness': 0.5}
    }
    dominance = cortex._compute_dominance()
    print(f"Two equal lineages dominance: {dominance:.3f} (expected: 0.5)")
    assert abs(dominance - 0.5) < 0.01, "Equal lineages should have 50% dominance"
    
    # Test case 3: Dominant lineage (80% dominance)
    cortex.simulation_state['lineage_population'] = {
        'lineage_1': {'population': 80, 'fitness': 0.7},
        'lineage_2': {'population': 20, 'fitness': 0.3}
    }
    dominance = cortex._compute_dominance()
    print(f"Dominant lineage dominance: {dominance:.3f} (expected: 0.8)")
    assert abs(dominance - 0.8) < 0.01, "Dominant lineage should have 80% dominance"
    
    print("\n✅ Test 4 passed: Dominance computation correct\n")


async def test_anomaly_detection():
    """Test anomaly detection logic."""
    print("\n🧪 Test 5: Anomaly Detection\n")
    
    cortex = GRCCSimulationCortex()
    
    # Test case 1: Normal state (no anomalies)
    cortex.simulation_state['dominance'] = 0.33
    cortex.simulation_state['entropy'] = 0.65
    anomalies = cortex._detect_anomalies()
    print(f"Normal state anomalies: {len(anomalies)} (expected: 0)")
    assert len(anomalies) == 0, "Normal state should have no anomalies"
    
    # Test case 2: Extreme dominance
    cortex.simulation_state['dominance'] = 0.95
    anomalies = cortex._detect_anomalies()
    print(f"Extreme dominance anomalies: {len(anomalies)} (expected: 1)")
    assert len(anomalies) == 1, "Extreme dominance should trigger anomaly"
    assert anomalies[0]['type'] == 'extreme_dominance'
    
    # Test case 3: Entropy collapse
    cortex.simulation_state['dominance'] = 0.33
    cortex.simulation_state['entropy'] = 0.05
    anomalies = cortex._detect_anomalies()
    print(f"Entropy collapse anomalies: {len(anomalies)} (expected: 1)")
    assert len(anomalies) == 1, "Entropy collapse should trigger anomaly"
    assert anomalies[0]['type'] == 'entropy_collapse'
    
    # Test case 4: Both anomalies
    cortex.simulation_state['dominance'] = 0.95
    cortex.simulation_state['entropy'] = 0.05
    anomalies = cortex._detect_anomalies()
    print(f"Both anomalies: {len(anomalies)} (expected: 2)")
    assert len(anomalies) == 2, "Both conditions should trigger 2 anomalies"
    
    print("\n✅ Test 5 passed: Anomaly detection correct\n")


async def main():
    """Run all tests."""
    print("=" * 60)
    print("🧪 Phase 2 Python Cortex - Standalone Tests")
    print("=" * 60)
    
    try:
        await test_basic_simulation()
        await test_intervention_application()
        await test_entropy_computation()
        await test_dominance_computation()
        await test_anomaly_detection()
        
        print("\n" + "=" * 60)
        print("✅ ALL TESTS PASSED!")
        print("=" * 60)
        print("\nPython cortex is ready for NATS integration.")
        print("Next step: Start NATS server and run full integration test.\n")
        
    except AssertionError as e:
        print(f"\n❌ TEST FAILED: {e}\n")
        raise
    except Exception as e:
        print(f"\n❌ ERROR: {e}\n")
        raise


if __name__ == "__main__":
    asyncio.run(main())
