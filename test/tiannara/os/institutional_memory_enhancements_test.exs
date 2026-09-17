defmodule Tiannara.OS.InstitutionalMemoryEnhancementsTest do
  @moduledoc """
  Test suite for Institutional Memory Enhancements.
  
  Validates:
  1. Cross-world wisdom sharing
  2. Temporal wisdom decay
  3. Contrarian mutation strategies
  4. Meta-learning tracking
  """
  
  use ExUnit.Case, async: false
  
  alias TiannaraOS.InstitutionalMemoryEnhancements
  alias TiannaraOS.State
  
  # ============================================================================
  # Test 1: Cross-World Wisdom Sharing
  # ============================================================================
  
  test "extract_cross_world_wisdom aggregates from multiple worlds" do
    # Create state with deaths in multiple worlds
    graveyard = %{
      death1: %{world_id: :w1, cause_of_death: :resource_exhaustion, strategy_genome: %{exploration_rate: 0.9}, assets_at_death: []},
      death2: %{world_id: :w1, cause_of_death: :stagnation, strategy_genome: %{exploration_rate: 0.1}, assets_at_death: []},
      death3: %{world_id: :w2, cause_of_death: :competition, strategy_genome: %{risk_tolerance: 0.2}, assets_at_death: []}
    }
    
    state = %State{
      program_graveyard: graveyard,
      economy: %{tick: 5000},
      discoveries: %{},
      research_programs: %{}
    }
    
    wisdom = InstitutionalMemoryEnhancements.extract_cross_world_wisdom(state, [:w1, :w2])
    
    assert wisdom.lesson_count >= 3  # All deaths counted
    assert wisdom.source_worlds == [:w1, :w2]
    assert map_size(wisdom.failed_traits) > 0
    assert wisdom.confidence > 0.0
  end
  
  # ============================================================================
  # Test 2: Temporal Wisdom Decay
  # ============================================================================
  
  test "apply_temporal_decay reduces confidence based on age" do
    wisdom = %{
      failed_traits: %{high_exploration_fatal: true},
      successful_traits: %{},
      domain_saturation: %{},
      lesson_count: 50,
      last_updated_tick: 0,
      confidence: 1.0
    }
    
    # After 1000 ticks with default decay rate (0.001)
    decayed = InstitutionalMemoryEnhancements.apply_temporal_decay(wisdom, 1000)
    
    assert decayed.confidence < wisdom.confidence
    assert decayed.aged_ticks == 1000
    
    # Should still have some confidence (not fully decayed)
    assert decayed.confidence > 0.0
    
    # After very long time, should approach zero
    very_old = InstitutionalMemoryEnhancements.apply_temporal_decay(wisdom, 10000)
    assert very_old.confidence < decayed.confidence
  end
  
  test "apply_temporal_decay with custom decay rate" do
    wisdom = %{
      failed_traits: %{},
      successful_traits: %{},
      domain_saturation: %{},
      lesson_count: 50,
      last_updated_tick: 0,
      confidence: 1.0
    }
    
    # Fast decay rate
    fast_decayed = InstitutionalMemoryEnhancements.apply_temporal_decay(wisdom, 1000, 0.01)
    
    # Slow decay rate
    slow_decayed = InstitutionalMemoryEnhancements.apply_temporal_decay(wisdom, 1000, 0.0001)
    
    # Fast decay should reduce confidence more
    assert fast_decayed.confidence < slow_decayed.confidence
  end
  
  # ============================================================================
  # Test 3: Contrarian Mutation Strategies
  # ============================================================================
  
  test "mutate_against_wisdom moves toward dangerous trait regions" do
    parent_genome = %{
      exploration_rate: 0.5,
      validation_priority: 0.5,
      cross_domain_synthesis: 0.5,
      anomaly_sensitivity: 0.5,
      risk_tolerance: 0.5
    }
    
    wisdom = %{
      failed_traits: %{
        high_exploration_low_validation_fatal: true
      },
      successful_traits: %{},
      confidence: 0.8
    }
    
    # Run multiple times to account for randomness
    results = Enum.map(1..50, fn _ ->
      InstitutionalMemoryEnhancements.mutate_against_wisdom(parent_genome, wisdom, 0.1)
    end)
    
    # On average, exploration should increase and validation should decrease
    avg_exploration = Enum.sum(Enum.map(results, & &1.exploration_rate)) / length(results)
    avg_validation = Enum.sum(Enum.map(results, & &1.validation_priority)) / length(results)
    
    assert avg_exploration > parent_genome.exploration_rate,
           "Expected avg exploration #{avg_exploration} > #{parent_genome.exploration_rate}"
    assert avg_validation < parent_genome.validation_priority,
           "Expected avg validation #{avg_validation} < #{parent_genome.validation_priority}"
  end
  
  test "mutate_against_wisdom handles empty failed traits" do
    parent_genome = %{
      exploration_rate: 0.5,
      validation_priority: 0.5,
      cross_domain_synthesis: 0.5,
      anomaly_sensitivity: 0.5,
      risk_tolerance: 0.5
    }
    
    wisdom = %{
      failed_traits: %{},
      successful_traits: %{},
      confidence: 0.0
    }
    
    result = InstitutionalMemoryEnhancements.mutate_against_wisdom(parent_genome, wisdom, 0.1)
    
    # Should just apply base mutation, not crash
    assert result.exploration_rate >= 0.0
    assert result.exploration_rate <= 1.0
  end
  
  # ============================================================================
  # Test 4: Meta-Learning Tracking
  # ============================================================================
  
  test "calculate_meta_wisdom tracks warning accuracy" do
    wisdom_history = [
      %{confidence: 0.8, failed_traits: %{trait1: true}},
      %{confidence: 0.6, failed_traits: %{trait2: true}},
      %{confidence: 0.3, failed_traits: %{}},  # Low confidence
      %{confidence: 0.9, failed_traits: %{trait3: true}}
    ]
    
    outcome_data = [%{tick: 1000}, %{tick: 2000}]
    
    meta = InstitutionalMemoryEnhancements.calculate_meta_wisdom(wisdom_history, outcome_data)
    
    assert meta.total_warnings_issued == 4
    assert meta.accurate_warnings >= 2  # At least the high-confidence ones
    assert meta.warning_accuracy > 0.0
    assert meta.warning_accuracy <= 1.0
  end
  
  test "calculate_meta_wisdom handles empty history" do
    meta = InstitutionalMemoryEnhancements.calculate_meta_wisdom([], [])
    
    assert meta.total_warnings_issued == 0
    assert meta.accurate_warnings == 0
    assert meta.warning_accuracy == 0.0
  end
  
  # ============================================================================
  # Test 5: Value Bounding in Contrarian Mutation
  # ============================================================================
  
  test "mutate_against_wisdom bounds all values to [0, 1]" do
    parent_genome = %{
      exploration_rate: 0.95,  # Already high
      validation_priority: 0.05,  # Already low
      cross_domain_synthesis: 0.5,
      anomaly_sensitivity: 0.5,
      risk_tolerance: 0.5
    }
    
    wisdom = %{
      failed_traits: %{
        high_exploration_low_validation_fatal: true
      },
      successful_traits: %{},
      confidence: 0.8
    }
    
    result = InstitutionalMemoryEnhancements.mutate_against_wisdom(parent_genome, wisdom, 0.2)
    
    # All values should be bounded
    assert result.exploration_rate <= 1.0
    assert result.validation_priority >= 0.0
    assert result.cross_domain_synthesis >= 0.0
    assert result.cross_domain_synthesis <= 1.0
  end
  
  # ============================================================================
  # Test 6: Integration - Cross-World + Temporal Decay
  # ============================================================================
  
  test "cross-world wisdom can be temporally decayed" do
    graveyard = %{
      death1: %{world_id: :w1, cause_of_death: :resource_exhaustion, strategy_genome: %{exploration_rate: 0.9}, assets_at_death: []}
    }
    
    state = %State{
      program_graveyard: graveyard,
      economy: %{tick: 0},
      discoveries: %{},
      research_programs: %{}
    }
    
    # Extract cross-world wisdom
    wisdom = InstitutionalMemoryEnhancements.extract_cross_world_wisdom(state, [:w1])
    
    # Simulate time passing
    future_state = %{state | economy: %{tick: 5000}}
    
    # Apply temporal decay
    decayed = InstitutionalMemoryEnhancements.apply_temporal_decay(wisdom, 5000)
    
    assert decayed.confidence < wisdom.confidence
    assert decayed.aged_ticks == 5000
  end
end
