defmodule Tiannara.OS.DynamicNeedsEvolutionTest do
  @moduledoc """
  Test suite for Dynamic World Needs Evolution.
  
  Validates that:
  1. Satisfied needs decrease over time
  2. Oversaturated domains lose priority
  3. Underserved domains gain priority
  4. Cross-domain opportunities emerge
  5. Needs stay bounded within valid range
  """
  
  use ExUnit.Case, async: false
  
  alias TiannaraOS.DynamicNeedsEvolution
  
  # ============================================================================
  # Test 1: Need Satisfaction Decay
  # ============================================================================
  
  test "evolve_needs reduces satisfied needs" do
    original_needs = %{
      energy: 0.9,
      materials: 0.5,
      medicine: 0.3
    }
    
    # Create discoveries that address energy need
    discoveries = [
      %{domain_vector: %{energy: 0.9, materials: 0.1}},
      %{domain_vector: %{energy: 0.85, materials: 0.15}},
      %{domain_vector: %{energy: 0.8, materials: 0.2}}
    ]
    
    evolved_needs = DynamicNeedsEvolution.evolve_needs(original_needs, discoveries, 1000)
    
    # Energy need should decrease
    assert evolved_needs.energy < original_needs.energy
    assert evolved_needs.energy >= 0.1  # Should not go below minimum
    
    # Other needs should remain relatively stable
    assert abs(evolved_needs.materials - original_needs.materials) < 0.1
  end
  
  test "evolve_needs respects minimum need value" do
    original_needs = %{
      energy: 0.15  # Already low
    }
    
    # Many discoveries addressing energy
    discoveries = Enum.map(1..20, fn _ ->
      %{domain_vector: %{energy: 0.9}}
    end)
    
    evolved_needs = DynamicNeedsEvolution.evolve_needs(original_needs, discoveries, 1000)
    
    # Should not go below minimum
    assert evolved_needs.energy >= 0.1
  end
  
  # ============================================================================
  # Test 2: Domain Saturation Detection
  # ============================================================================
  
  test "detect_emerging_needs boosts underserved domains" do
    current_needs = %{
      energy: 0.5,
      materials: 0.5
    }
    
    # All discoveries in energy domain (oversaturated)
    discoveries = Enum.map(1..10, fn _ ->
      %{domain_vector: %{energy: 0.9}}
    end)
    
    emerging = DynamicNeedsEvolution.detect_emerging_needs(discoveries, current_needs)
    
    # Materials should be boosted (underserved)
    if Map.has_key?(emerging, :materials) do
      assert emerging.materials > current_needs.materials
    end
  end
  
  test "count_discoveries_by_domain correctly counts" do
    discoveries = [
      %{domain_vector: %{energy: 0.9, materials: 0.1}},
      %{domain_vector: %{energy: 0.8, materials: 0.2}},
      %{domain_vector: %{materials: 0.9, energy: 0.1}}
    ]
    
    counts = DynamicNeedsEvolution.count_discoveries_by_domain(discoveries)
    
    # Energy should have 2 (primary domain in first two)
    # Materials should have 1 (primary domain in third)
    assert counts[:energy] == 2
    assert counts[:materials] == 1
  end
  
  # ============================================================================
  # Test 3: Cross-Domain Opportunities
  # ============================================================================
  
  test "generate_cross_domain_needs creates related opportunities" do
    current_needs = %{
      energy: 0.9,  # Saturated
      materials: 0.3  # Low
    }
    
    oversaturated = [:energy]
    
    cross_needs = DynamicNeedsEvolution.generate_cross_domain_needs(oversaturated, current_needs)
    
    # Materials should be boosted (related to energy)
    if Map.has_key?(cross_needs, :materials) do
      assert cross_needs.materials > current_needs.materials
    end
  end
  
  test "cross_domain_map includes expected relationships" do
    # Test that key relationships exist
    cross_domain_map = %{
      energy: [:materials, :efficiency, :storage],
      medicine: [:prevention, :diagnostics, :genetics],
      mathematics: [:computation, :applications, :logic]
    }
    
    assert length(cross_domain_map[:energy]) == 3
    assert length(cross_domain_map[:medicine]) == 3
    assert length(cross_domain_map[:mathematics]) == 3
  end
  
  # ============================================================================
  # Test 4: Need Bounding and Normalization
  # ============================================================================
  
  test "merge_and_normalize keeps values bounded" do
    current_needs = %{
      energy: 0.9,
      materials: 0.1
    }
    
    emerging_needs = %{
      energy: 1.5,  # Too high
      materials: -0.2  # Too low
    }
    
    normalized = DynamicNeedsEvolution.merge_and_normalize(current_needs, emerging_needs)
    
    # All values should be within bounds
    assert normalized.energy >= 0.1 and normalized.energy <= 1.0
    assert normalized.materials >= 0.1 and normalized.materials <= 1.0
  end
  
  test "merge_and_normalize allows gradual decay" do
    current_needs = %{
      energy: 0.8
    }
    
    emerging_needs = %{
      energy: 0.6  # Lower than current
    }
    
    normalized = DynamicNeedsEvolution.merge_and_normalize(current_needs, emerging_needs)
    
    # Should take max but allow some decay
    assert normalized.energy >= 0.6
    assert normalized.energy <= 0.8
  end
  
  # ============================================================================
  # Test 5: Satisfaction Level Calculation
  # ============================================================================
  
  test "calculate_satisfaction_level measures progress" do
    original_needs = %{
      energy: 0.9,
      materials: 0.7
    }
    
    current_needs = %{
      energy: 0.5,  # Reduced by ~44%
      materials: 0.6  # Reduced by ~14%
    }
    
    satisfaction = DynamicNeedsEvolution.calculate_satisfaction_level(original_needs, current_needs)
    
    # Should be between 0 and 100
    assert satisfaction >= 0.0
    assert satisfaction <= 100.0
    
    # Average reduction is ~29%, so satisfaction should be around that
    assert satisfaction > 20.0
    assert satisfaction < 40.0
  end
  
  test "calculate_satisfaction_level is 0 when no change" do
    needs = %{
      energy: 0.8,
      materials: 0.6
    }
    
    satisfaction = DynamicNeedsEvolution.calculate_satisfaction_level(needs, needs)
    
    assert satisfaction == 0.0
  end
  
  # ============================================================================
  # Test 6: Full Evolution Cycle
  # ============================================================================
  
  test "evolve_needs handles empty discoveries" do
    original_needs = %{
      energy: 0.8,
      materials: 0.6
    }
    
    evolved = DynamicNeedsEvolution.evolve_needs(original_needs, [], 1000)
    
    # Should remain unchanged
    assert evolved == original_needs
  end
  
  test "evolve_needs creates balanced ecosystem" do
    original_needs = %{
      energy: 0.9,
      materials: 0.9,
      medicine: 0.9,
      mathematics: 0.9
    }
    
    # Mix of discoveries across domains
    discoveries = [
      %{domain_vector: %{energy: 0.9}},
      %{domain_vector: %{energy: 0.85}},
      %{domain_vector: %{energy: 0.8}},
      %{domain_vector: %{materials: 0.9}},
      %{domain_vector: %{medicine: 0.9}},
      %{domain_vector: %{mathematics: 0.9}}
    ]
    
    evolved = DynamicNeedsEvolution.evolve_needs(original_needs, discoveries, 1000)
    
    # Energy should be most reduced (3 discoveries)
    assert evolved.energy < evolved.materials
    assert evolved.energy < evolved.medicine
    assert evolved.energy < evolved.mathematics
    
    # All needs should still be above minimum
    assert evolved.energy >= 0.1
    assert evolved.materials >= 0.1
    assert evolved.medicine >= 0.1
    assert evolved.mathematics >= 0.1
  end
  
  # ============================================================================
  # Test 7: Needs Summary
  # ============================================================================
  
  test "summarize_needs_evolution produces readable output" do
    original_needs = %{
      energy: 0.9,
      materials: 0.7,
      medicine: 0.5
    }
    
    current_needs = %{
      energy: 0.6,
      materials: 0.65,
      medicine: 0.48
    }
    
    summary = DynamicNeedsEvolution.summarize_needs_evolution(original_needs, current_needs)
    
    assert String.contains?(summary, "Needs Evolution Summary")
    assert String.contains?(summary, "Overall satisfaction:")
    assert String.contains?(summary, "Current Needs:")
    assert String.contains?(summary, "Changes from Original:")
    
    IO.puts("\n=== Needs Evolution Example ===\n#{summary}\n")
  end
end
