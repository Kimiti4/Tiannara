defmodule Tiannara.OS.InstitutionalMemoryTest do
  @moduledoc """
  Test suite for Institutional Memory System.
  
  Validates that:
  1. Wisdom is correctly extracted from graveyard
  2. Failed traits are identified
  3. Successful traits are recognized
  4. Mutation is guided by wisdom
  5. Offspring avoid ancestral mistakes
  """
  
  use ExUnit.Case, async: false
  
  alias TiannaraOS.InstitutionalMemory
  alias TiannaraOS.State
  alias TiannaraOS.ResearchProgram
  
  # ============================================================================
  # Test 1: Extract Wisdom from Graveyard
  # ============================================================================
  
  test "extract_wisdom returns empty wisdom with insufficient data" do
    state = %State{
      program_graveyard: %{
        death_1: %{world_id: :w1, cause_of_death: :resource_exhaustion}
      },
      economy: %{tick: 1000}
    }
    
    wisdom = InstitutionalMemory.extract_wisdom(state, :w1)
    
    assert wisdom.lesson_count == 1
    assert wisdom.confidence == 0.0  # Below minimum threshold
    assert map_size(wisdom.failed_traits) == 0
  end
  
  test "extract_wisdom identifies failed traits from resource deaths" do
    # Create death records with high exploration + low validation
    death_records = Enum.map(1..10, fn i ->
      %{
        world_id: :w1,
        cause_of_death: :resource_exhaustion,
        lifespan_ticks: 500 + i * 100,
        genome: %{
          exploration_rate: 0.8 + :rand.uniform() * 0.1,  # High exploration
          validation_priority: 0.1 + :rand.uniform() * 0.1,  # Low validation
          cross_domain_synthesis: 0.5,
          anomaly_sensitivity: 0.5,
          risk_tolerance: 0.5
        },
        assets_at_death: []
      }
    end)
    
    graveyard = Enum.reduce(Enum.with_index(death_records), %{}, fn {record, idx}, acc ->
      Map.put(acc, :"death_#{idx}", record)
    end)
    
    state = %State{
      program_graveyard: graveyard,
      economy: %{tick: 5000}
    }
    
    wisdom = InstitutionalMemory.extract_wisdom(state, :w1)
    
    assert wisdom.lesson_count == 10
    assert wisdom.confidence > 0.0
    
    # Debug: print failed traits
    IO.inspect(wisdom.failed_traits, label: "Failed Traits")
    
    assert Map.get(wisdom.failed_traits, :high_exploration_low_validation_fatal) == true
  end
  
  test "extract_wisdom identifies successful traits" do
    # Mix of short-lived and long-lived programs
    death_records = [
      # Short-lived (should not influence success patterns)
      %{world_id: :w1, cause_of_death: :resource_exhaustion, lifespan_ticks: 200,
        genome: %{exploration_rate: 0.9, validation_priority: 0.1, cross_domain_synthesis: 0.2,
                  anomaly_sensitivity: 0.3, risk_tolerance: 0.2},
        assets_at_death: []},
      %{world_id: :w1, cause_of_death: :stagnation, lifespan_ticks: 300,
        genome: %{exploration_rate: 0.1, validation_priority: 0.9, cross_domain_synthesis: 0.1,
                  anomaly_sensitivity: 0.2, risk_tolerance: 0.1},
        assets_at_death: []},
      
      # Long-lived (should influence success patterns)
      %{world_id: :w1, cause_of_death: :competitive_displacement, lifespan_ticks: 5000,
        genome: %{exploration_rate: 0.5, validation_priority: 0.6, cross_domain_synthesis: 0.7,
                  anomaly_sensitivity: 0.6, risk_tolerance: 0.6},
        assets_at_death: [:asset1, :asset2]},
      %{world_id: :w1, cause_of_death: :resource_exhaustion, lifespan_ticks: 6000,
        genome: %{exploration_rate: 0.4, validation_priority: 0.7, cross_domain_synthesis: 0.6,
                  anomaly_sensitivity: 0.5, risk_tolerance: 0.7},
        assets_at_death: [:asset3, :asset4, :asset5]},
      %{world_id: :w1, cause_of_death: :stagnation, lifespan_ticks: 4500,
        genome: %{exploration_rate: 0.6, validation_priority: 0.5, cross_domain_synthesis: 0.8,
                  anomaly_sensitivity: 0.7, risk_tolerance: 0.5},
        assets_at_death: [:asset6]}
    ]
    
    graveyard = Enum.reduce(Enum.with_index(death_records), %{}, fn {record, idx}, acc ->
      Map.put(acc, :"death_#{idx}", record)
    end)
    
    state = %State{
      program_graveyard: graveyard,
      economy: %{tick: 10000}
    }
    
    wisdom = InstitutionalMemory.extract_wisdom(state, :w1)
    
    assert wisdom.lesson_count == 5
    assert map_size(wisdom.successful_traits) > 0
    
    survival_genome = Map.get(wisdom.successful_traits, :survival_genome)
    assert survival_genome != nil
    assert survival_genome.cross_domain_synthesis > 0.5  # Long-lived had high synthesis
  end
  
  # ============================================================================
  # Test 2: Apply Wisdom to Mutation
  # ============================================================================
  
  test "apply_wisdom_to_mutation adjusts away from fatal strategies" do
    # Parent has fatal combination: high exploration + low validation
    parent_genome = %{
      exploration_rate: 0.85,
      validation_priority: 0.15,
      cross_domain_synthesis: 0.5,
      anomaly_sensitivity: 0.5,
      risk_tolerance: 0.5
    }
    
    # Wisdom says this combination is fatal
    wisdom = %{
      failed_traits: %{high_exploration_low_validation_fatal: true},
      successful_traits: %{},
      confidence: 0.8
    }
    
    # Run multiple times to account for Gaussian randomness
    results = Enum.map(1..50, fn _ ->
      InstitutionalMemory.apply_wisdom_to_mutation(parent_genome, wisdom, 0.2)
    end)
    
    # On average, exploration should decrease and validation should increase
    avg_exploration = Enum.sum(Enum.map(results, & &1.exploration_rate)) / length(results)
    avg_validation = Enum.sum(Enum.map(results, & &1.validation_priority)) / length(results)
    
    assert avg_exploration < parent_genome.exploration_rate, 
           "Expected avg exploration #{avg_exploration} < #{parent_genome.exploration_rate}"
    assert avg_validation > parent_genome.validation_priority,
           "Expected avg validation #{avg_validation} > #{parent_genome.validation_priority}"
    
    # All values should be bounded
    Enum.each(results, fn mutated ->
      assert mutated.exploration_rate >= 0.0 and mutated.exploration_rate <= 1.0
      assert mutated.validation_priority >= 0.0 and mutated.validation_priority <= 1.0
    end)
  end
  
  test "apply_wisdom_to_mutation moves toward successful traits" do
    parent_genome = %{
      exploration_rate: 0.3,
      validation_priority: 0.3,
      cross_domain_synthesis: 0.3,
      anomaly_sensitivity: 0.3,
      risk_tolerance: 0.3
    }
    
    # Wisdom shows successful pattern
    wisdom = %{
      failed_traits: %{},
      successful_traits: %{
        survival_genome: %{
          exploration_rate: 0.6,
          validation_priority: 0.6,
          cross_domain_synthesis: 0.7,
          anomaly_sensitivity: 0.6,
          risk_tolerance: 0.6
        }
      },
      confidence: 0.9
    }
    
    # Run multiple times to account for Gaussian randomness
    results = Enum.map(1..50, fn _ ->
      InstitutionalMemory.apply_wisdom_to_mutation(parent_genome, wisdom, 0.2)
    end)
    
    # On average, traits should move toward successful pattern
    avg_exploration = Enum.sum(Enum.map(results, & &1.exploration_rate)) / length(results)
    avg_synthesis = Enum.sum(Enum.map(results, & &1.cross_domain_synthesis)) / length(results)
    
    assert avg_exploration > parent_genome.exploration_rate,
           "Expected avg exploration #{avg_exploration} > #{parent_genome.exploration_rate}"
    assert avg_synthesis > parent_genome.cross_domain_synthesis,
           "Expected avg synthesis #{avg_synthesis} > #{parent_genome.cross_domain_synthesis}"
  end
  
  test "apply_wisdom_to_mutation respects confidence level" do
    parent_genome = %{
      exploration_rate: 0.9,
      validation_priority: 0.1,
      cross_domain_synthesis: 0.5,
      anomaly_sensitivity: 0.5,
      risk_tolerance: 0.5
    }
    
    wisdom_low_confidence = %{
      failed_traits: %{high_exploration_low_validation_fatal: true},
      successful_traits: %{},
      confidence: 0.1  # Low confidence
    }
    
    wisdom_high_confidence = %{
      failed_traits: %{high_exploration_low_validation_fatal: true},
      successful_traits: %{},
      confidence: 0.9  # High confidence
    }
    
    # Run multiple times to account for Gaussian randomness
    low_results = Enum.map(1..50, fn _ ->
      InstitutionalMemory.apply_wisdom_to_mutation(parent_genome, wisdom_low_confidence, 0.2)
    end)
    
    high_results = Enum.map(1..50, fn _ ->
      InstitutionalMemory.apply_wisdom_to_mutation(parent_genome, wisdom_high_confidence, 0.2)
    end)
    
    # Calculate average adjustments
    avg_low_adjustment = Enum.sum(Enum.map(low_results, & abs(&1.exploration_rate - parent_genome.exploration_rate))) / length(low_results)
    avg_high_adjustment = Enum.sum(Enum.map(high_results, & abs(&1.exploration_rate - parent_genome.exploration_rate))) / length(high_results)
    
    # High confidence should produce stronger adjustment ON AVERAGE
    assert avg_high_adjustment > avg_low_adjustment,
           "Expected high confidence avg adjustment #{avg_high_adjustment} > low confidence #{avg_low_adjustment}"
  end
  
  test "apply_wisdom_to_mutation bounds values to [0, 1]" do
    parent_genome = %{
      exploration_rate: 0.0,
      validation_priority: 1.0,
      cross_domain_synthesis: 0.5,
      anomaly_sensitivity: 0.5,
      risk_tolerance: 0.5
    }
    
    wisdom = %{
      failed_traits: %{},
      successful_traits: %{
        survival_genome: %{
          exploration_rate: 0.8,
          validation_priority: 0.2,
          cross_domain_synthesis: 0.6,
          anomaly_sensitivity: 0.6,
          risk_tolerance: 0.6
        }
      },
      confidence: 1.0
    }
    
    mutated = InstitutionalMemory.apply_wisdom_to_mutation(parent_genome, wisdom, 0.3)
    
    # All values should be bounded
    assert mutated.exploration_rate >= 0.0 and mutated.exploration_rate <= 1.0
    assert mutated.validation_priority >= 0.0 and mutated.validation_priority <= 1.0
    assert mutated.cross_domain_synthesis >= 0.0 and mutated.cross_domain_synthesis <= 1.0
  end
  
  # ============================================================================
  # Test 3: Domain Saturation Analysis
  # ============================================================================
  
  test "analyze_domain_saturation identifies oversaturated domains" do
    discoveries = %{
      disc_1: %{world_id: :w1, domain_vector: %{energy: 0.9, materials: 0.1}},
      disc_2: %{world_id: :w1, domain_vector: %{energy: 0.8, materials: 0.2}},
      disc_3: %{world_id: :w1, domain_vector: %{energy: 0.85, materials: 0.15}},
      disc_4: %{world_id: :w1, domain_vector: %{materials: 0.9, energy: 0.1}}
    }
    
    state = %State{
      discoveries: discoveries,
      program_graveyard: %{},
      economy: %{tick: 2000}
    }
    
    wisdom = InstitutionalMemory.extract_wisdom(state, :w1)
    
    # Check that domain saturation was analyzed
    assert map_size(wisdom.domain_saturation) > 0, "Expected domain saturation, got: #{inspect(wisdom.domain_saturation)}"
    
    energy_info = Map.get(wisdom.domain_saturation, :energy)
    materials_info = Map.get(wisdom.domain_saturation, :materials)
    
    # Energy should be more saturated than materials (3 vs 1 discoveries)
    assert energy_info.count > materials_info.count
    assert energy_info.status == :oversaturated  # 75% of discoveries (>30%)
    assert materials_info.status == :balanced  # 25% of discoveries (10-30% range)
  end
  
  # ============================================================================
  # Test 4: Integration Test - Full Reproduction Cycle
  # ============================================================================
  
  test "institutional memory guides reproduction decisions" do
    # Setup: Create state with graveyard showing clear failure pattern
    death_records = Enum.map(1..15, fn _ ->
      %{
        world_id: :w1,
        cause_of_death: :resource_exhaustion,
        lifespan_ticks: 400,
        genome: %{
          exploration_rate: 0.85,
          validation_priority: 0.15,
          cross_domain_synthesis: 0.3,
          anomaly_sensitivity: 0.4,
          risk_tolerance: 0.3
        },
        assets_at_death: []
      }
    end)
    
    graveyard = Enum.reduce(Enum.with_index(death_records), %{}, fn {record, idx}, acc ->
      Map.put(acc, :"death_#{idx}", record)
    end)
    
    # Parent program with risky strategy
    parent = %ResearchProgram{
      id: :parent_prog,
      world_id: :w1,
      strategy_genome: %{
        exploration_rate: 0.8,
        validation_priority: 0.2,
        cross_domain_synthesis: 0.4,
        anomaly_sensitivity: 0.5,
        risk_tolerance: 0.4
      },
      budget: %{credits: 1000, compute: 200, attention: 100, curiosity_budget: 50},
      status: :active,
      generation: 1,
      metadata: %{
        epistemic_physics: nil,
        created_at_tick: 0,
        current_tick: 500
      }
    }
    
    state = %State{
      research_programs: %{parent.id => parent},
      program_graveyard: graveyard,
      discovery_assets: %{},
      discoveries: %{},
      economy: %{tick: 500}
    }
    
    # Extract wisdom
    wisdom = InstitutionalMemory.extract_wisdom(state, :w1)
    
    assert wisdom.lesson_count == 15
    assert wisdom.confidence > 0.2
    assert Map.get(wisdom.failed_traits, :high_exploration_low_validation_fatal) == true
    
    # Apply wisdom to mutation
    results = Enum.map(1..50, fn _ ->
      InstitutionalMemory.apply_wisdom_to_mutation(
        parent.strategy_genome,
        wisdom,
        0.2
      )
    end)
    
    # On average, child should have adjusted traits
    avg_exploration = Enum.sum(Enum.map(results, & &1.exploration_rate)) / length(results)
    avg_validation = Enum.sum(Enum.map(results, & &1.validation_priority)) / length(results)
    
    assert avg_exploration < parent.strategy_genome.exploration_rate,
           "Expected avg exploration #{avg_exploration} < #{parent.strategy_genome.exploration_rate}"
    assert avg_validation > parent.strategy_genome.validation_priority,
           "Expected avg validation #{avg_validation} > #{parent.strategy_genome.validation_priority}"
    
    IO.puts("\n✅ Institutional memory successfully guided mutation away from fatal strategy")
    IO.puts("   Parent: exploration=#{parent.strategy_genome.exploration_rate}, validation=#{parent.strategy_genome.validation_priority}")
    IO.puts("   Child (avg): exploration=#{Float.round(avg_exploration, 2)}, validation=#{Float.round(avg_validation, 2)}")
  end
  
  # ============================================================================
  # Test 5: Wisdom Summary
  # ============================================================================
  
  test "summarize_wisdom produces readable output" do
    wisdom = %{
      lesson_count: 47,
      confidence: 0.94,
      failed_traits: %{
        high_exploration_low_validation_fatal: true,
        low_risk_tolerance_slow_death: true
      },
      successful_traits: %{
        survival_genome: %{
          exploration_rate: 0.5,
          validation_priority: 0.6,
          cross_domain_synthesis: 0.7,
          anomaly_sensitivity: 0.6,
          risk_tolerance: 0.6
        },
        avg_lifespan: 5234
      },
      domain_saturation: %{
        energy: %{count: 45, proportion: 0.45, status: :oversaturated},
        medicine: %{count: 12, proportion: 0.12, status: :balanced}
      }
    }
    
    summary = InstitutionalMemory.summarize_wisdom(wisdom)
    
    assert String.contains?(summary, "Institutional Memory Summary")
    assert String.contains?(summary, "Lessons learned: 47")
    assert String.contains?(summary, "Confidence: 94.0%")
    assert String.contains?(summary, "high_exploration_low_validation_fatal")
    
    IO.puts("\n=== Wisdom Summary Example ===\n#{summary}\n")
  end
end
