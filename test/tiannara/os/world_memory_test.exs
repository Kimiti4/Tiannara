defmodule Tiannara.OS.WorldMemoryTest do
  @moduledoc """
  Test suite for World Memory system.
  
  Validates that:
  1. World memory accumulates successful/failed domains
  2. Recurring bottlenecks are detected
  3. Genome biasing works toward successful strategies
  4. Performance metrics calculate correctly
  """
  
  use ExUnit.Case, async: false
  
  alias TiannaraOS.WorldMemory
  alias TiannaraOS.State
  alias TiannaraOS.ResearchProgram
  
  # ============================================================================
  # Test 1: Update World Memory - Successful Domains
  # ============================================================================
  
  test "update_world_memory tracks successful domains" do
    active_programs = %{
      prog1: %ResearchProgram{
        id: :prog1,
        world_id: :w1,
        status: :active,
        strategy_genome: %{
          exploration_rate: 0.8,
          validation_priority: 0.3,
          cross_domain_synthesis: 0.5,
          anomaly_sensitivity: 0.4,
          risk_tolerance: 0.6
        }
      },
      prog2: %ResearchProgram{
        id: :prog2,
        world_id: :w1,
        status: :active,
        strategy_genome: %{
          exploration_rate: 0.75,
          validation_priority: 0.4,
          cross_domain_synthesis: 0.5,
          anomaly_sensitivity: 0.5,
          risk_tolerance: 0.5
        }
      }
    }
    
    world = %{
      id: :w1,
      name: "Test World",
      needs_vector: %{energy: 0.5},
      memory: %{
        successful_domains: %{},
        failed_domains: %{},
        recurring_bottlenecks: [],
        adaptation_history: [],
        last_updated_tick: 0
      }
    }
    
    state = %State{
      worlds: %{w1: world},
      research_programs: active_programs,
      program_graveyard: %{},
      economy: %{tick: 5000}
    }
    
    updated_state = WorldMemory.update_world_memory(state, :w1)
    updated_world = Map.get(updated_state.worlds, :w1)
    
    # Should have recorded some successful domains
    assert map_size(updated_world.memory.successful_domains) > 0
    
    # Exploration should be counted (both programs have high exploration)
    assert Map.get(updated_world.memory.successful_domains, :exploration, 0) >= 1
  end
  
  # ============================================================================
  # Test 2: Detect Recurring Bottlenecks
  # ============================================================================
  
  test "detect_recurring_bottlenecks identifies persistent unsatisfied needs" do
    world = %{
      id: :w1,
      name: "Test World",
      needs_vector: %{
        energy: 0.8,      # High need - bottleneck
        materials: 0.3,   # Low need - satisfied
        medicine: 0.9     # Very high need - severe bottleneck
      },
      memory: %{
        successful_domains: %{},
        failed_domains: %{},
        recurring_bottlenecks: [:energy, :medicine],  # Already tracked
        adaptation_history: [],
        last_updated_tick: 0
      }
    }
    
    stuck = WorldMemory.stuck_in_bottleneck?(world, [])
    
    # Should detect bottleneck (recurring list has 2 items, threshold is 3)
    refute stuck  # Not yet at threshold
    
    # Add more history
    world_with_more_history = %{world | memory: %{world.memory | recurring_bottlenecks: [:energy, :medicine, :energy, :medicine]}}
    stuck_after = WorldMemory.stuck_in_bottleneck?(world_with_more_history, [])
    
    assert stuck_after  # Now exceeds threshold
  end
  
  # ============================================================================
  # Test 3: Bias Genome Toward Success
  # ============================================================================
  
  test "bias_genome_toward_success adjusts traits toward successful domain" do
    base_genome = %{
      exploration_rate: 0.5,
      validation_priority: 0.5,
      cross_domain_synthesis: 0.5,
      anomaly_sensitivity: 0.5,
      risk_tolerance: 0.5
    }
    
    world_memory = %{
      successful_domains: %{
        exploration: 10,  # Most successful
        validation: 3
      },
      failed_domains: %{},
      recurring_bottlenecks: [],
      adaptation_history: [],
      last_updated_tick: 5000
    }
    
    biased_genome = WorldMemory.bias_genome_toward_success(base_genome, world_memory)
    
    # Exploration should increase (most successful domain)
    assert biased_genome.exploration_rate > base_genome.exploration_rate
    
    # Other traits should remain relatively unchanged
    assert biased_genome.validation_priority >= base_genome.validation_priority * 0.9
  end
  
  # ============================================================================
  # Test 4: Domain Performance Metrics
  # ============================================================================
  
  test "get_domain_performance calculates success rates" do
    world_memory = %{
      successful_domains: %{
        exploration: 8,
        validation: 5
      },
      failed_domains: %{
        exploration: 2,
        validation: 5
      }
    }
    
    performance = WorldMemory.get_domain_performance(world_memory)
    
    # Should have both domains
    assert Map.has_key?(performance, :exploration)
    assert Map.has_key?(performance, :validation)
    
    # Exploration: 8 successes, 2 failures = 80% success rate
    exploration_perf = Map.get(performance, :exploration)
    assert exploration_perf.success_count == 8
    assert exploration_perf.failure_count == 2
    assert exploration_perf.success_rate == 0.8
    
    # Validation: 5 successes, 5 failures = 50% success rate
    validation_perf = Map.get(performance, :validation)
    assert validation_perf.success_rate == 0.5
  end
  
  # ============================================================================
  # Test 5: Summarize World Memory
  # ============================================================================
  
  test "summarize_world_memory produces readable output" do
    world_memory = %{
      successful_domains: %{exploration: 10, synthesis: 5},
      failed_domains: %{high_risk: 3},
      recurring_bottlenecks: [:energy, :materials],
      adaptation_history: [%{tick: 1000}, %{tick: 2000}],
      last_updated_tick: 5000
    }
    
    summary = WorldMemory.summarize_world_memory(world_memory)
    
    assert String.contains?(summary, "=== World Memory Summary ===")
    assert String.contains?(summary, "Last updated: tick 5000")
    assert String.contains?(summary, "Successful Domains:")
    assert String.contains?(summary, "exploration")
    assert String.contains?(summary, "Failed Domains:")
    assert String.contains?(summary, "Recurring Bottlenecks")
    assert String.contains?(summary, "Adaptation Events: 2")
  end
  
  # ============================================================================
  # Test 6: Empty State Handling
  # ============================================================================
  
  test "update_world_memory handles empty programs and graveyard" do
    world = %{
      id: :w1,
      name: "Empty World",
      needs_vector: %{},
      memory: %{
        successful_domains: %{},
        failed_domains: %{},
        recurring_bottlenecks: [],
        adaptation_history: [],
        last_updated_tick: 0
      }
    }
    
    state = %State{
      worlds: %{w1: world},
      research_programs: %{},
      program_graveyard: %{},
      economy: %{tick: 1000}
    }
    
    updated_state = WorldMemory.update_world_memory(state, :w1)
    updated_world = Map.get(updated_state.worlds, :w1)
    
    # Should not crash, memory should update with empty data
    assert updated_world.memory.last_updated_tick == 1000
  end
  
  # ============================================================================
  # Test 7: Non-existent World Handling
  # ============================================================================
  
  test "update_world_memory returns unchanged state for non-existent world" do
    state = %State{
      worlds: %{},
      research_programs: %{},
      program_graveyard: %{},
      economy: %{tick: 1000}
    }
    
    result = WorldMemory.update_world_memory(state, :nonexistent)
    
    assert result == state
  end
end
