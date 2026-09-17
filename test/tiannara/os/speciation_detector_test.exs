defmodule Tiannara.OS.SpeciationDetectorTest do
  @moduledoc """
  Test suite for Enhanced Speciation Detector.
  
  Validates that:
  1. Species are correctly classified by genome similarity
  2. New species form when distance exceeds threshold
  3. Extinction events are detected
  4. Diversity metrics are calculated correctly
  5. Lineage depth is tracked
  """
  
  use ExUnit.Case, async: false
  
  alias TiannaraOS.SpeciationDetector
  alias TiannaraOS.State
  alias TiannaraOS.ResearchProgram
  
  # ============================================================================
  # Test 1: Species Classification
  # ============================================================================
  
  test "classify_program creates new species when registry is empty" do
    program = create_test_program(:prog_1, %{
      exploration_rate: 0.5,
      validation_priority: 0.5,
      cross_domain_synthesis: 0.5,
      anomaly_sensitivity: 0.5,
      risk_tolerance: 0.5
    })
    
    {species_id, updated_registry} = SpeciationDetector.classify_program(program, %{}, 100)
    
    assert species_id != nil
    assert map_size(updated_registry) == 1
    
    species = Map.get(updated_registry, species_id)
    assert species.member_count == 1
    assert species.founding_program == :prog_1
    assert species.founded_at_tick == 100
    assert species.extinct == false
  end
  
  test "classify_program adds to existing species when similar" do
    # Create first program and species
    prog_1 = create_test_program(:prog_1, %{
      exploration_rate: 0.5,
      validation_priority: 0.5,
      cross_domain_synthesis: 0.5,
      anomaly_sensitivity: 0.5,
      risk_tolerance: 0.5
    })
    
    {species_id_1, registry_1} = SpeciationDetector.classify_program(prog_1, %{}, 100)
    
    # Create second program with very similar genome (should join same species)
    prog_2 = create_test_program(:prog_2, %{
      exploration_rate: 0.52,  # Very close to 0.5
      validation_priority: 0.48,
      cross_domain_synthesis: 0.51,
      anomaly_sensitivity: 0.49,
      risk_tolerance: 0.5
    })
    
    {species_id_2, registry_2} = SpeciationDetector.classify_program(prog_2, registry_1, 200)
    
    # Should be same species
    assert species_id_2 == species_id_1
    
    # Member count should increase
    species = Map.get(registry_2, species_id_1)
    assert species.member_count == 2
    assert species.total_births == 2
  end
  
  test "classify_program creates new species when distant" do
    # Create first program (explorer type)
    prog_1 = create_test_program(:prog_1, %{
      exploration_rate: 0.9,
      validation_priority: 0.1,
      cross_domain_synthesis: 0.2,
      anomaly_sensitivity: 0.3,
      risk_tolerance: 0.7
    })
    
    {species_id_1, registry_1} = SpeciationDetector.classify_program(prog_1, %{}, 100)
    
    # Create second program with very different genome (validator type)
    prog_2 = create_test_program(:prog_2, %{
      exploration_rate: 0.1,  # Very different from 0.9
      validation_priority: 0.9,
      cross_domain_synthesis: 0.2,
      anomaly_sensitivity: 0.2,
      risk_tolerance: 0.2
    })
    
    {species_id_2, registry_2} = SpeciationDetector.classify_program(prog_2, registry_1, 200)
    
    # Should be different species
    assert species_id_2 != species_id_1
    assert map_size(registry_2) == 2
  end
  
  # ============================================================================
  # Test 2: Genome Distance Calculation
  # ============================================================================
  
  test "calculate_genome_distance returns 0 for identical genomes" do
    genome = %{
      exploration_rate: 0.5,
      validation_priority: 0.5,
      cross_domain_synthesis: 0.5,
      anomaly_sensitivity: 0.5,
      risk_tolerance: 0.5
    }
    
    distance = SpeciationDetector.calculate_genome_distance(genome, genome)
    
    assert distance == 0.0
  end
  
  test "calculate_genome_distance increases with trait divergence" do
    genome_1 = %{
      exploration_rate: 0.5,
      validation_priority: 0.5,
      cross_domain_synthesis: 0.5,
      anomaly_sensitivity: 0.5,
      risk_tolerance: 0.5
    }
    
    genome_2 = %{
      exploration_rate: 0.9,  # +0.4
      validation_priority: 0.9,  # +0.4
      cross_domain_synthesis: 0.5,
      anomaly_sensitivity: 0.5,
      risk_tolerance: 0.5
    }
    
    distance = SpeciationDetector.calculate_genome_distance(genome_1, genome_2)
    
    # Euclidean distance = sqrt(0.4^2 + 0.4^2) = sqrt(0.32) ≈ 0.566
    assert distance > 0.5
    assert distance < 0.6
  end
  
  # ============================================================================
  # Test 3: Extinction Detection
  # ============================================================================
  
  test "detect_extinctions marks species extinct when no members" do
    species = %{
      id: :species_1,
      member_count: 0,
      total_births: 5,
      total_deaths: 5,
      current_members: [],
      extinct: false,
      founded_at_tick: 100,
      last_new_member_tick: 1000
    }
    
    registry = %{species_1: species}
    
    updated_registry = SpeciationDetector.detect_extinctions(registry, 2000)
    extinct_species = Map.get(updated_registry, :species_1)
    
    assert extinct_species.extinct == true
    assert extinct_species.extinct_at_tick == 2000
    assert extinct_species.lifespan_ticks == 1900
  end
  
  test "detect_extinctions marks species extinct after timeout" do
    species = %{
      id: :species_1,
      member_count: 2,
      total_births: 10,
      total_deaths: 8,
      current_members: [:prog_1, :prog_2],
      extinct: false,
      founded_at_tick: 100,
      last_new_member_tick: 1000  # Last new member 6000 ticks ago
    }
    
    registry = %{species_1: species}
    
    # Current tick is 7000, timeout is 5000
    updated_registry = SpeciationDetector.detect_extinctions(registry, 7000)
    extinct_species = Map.get(updated_registry, :species_1)
    
    assert extinct_species.extinct == true
    assert extinct_species.lifespan_ticks == 6900
  end
  
  test "detect_extinctions keeps active species alive" do
    species = %{
      id: :species_1,
      member_count: 5,
      total_births: 15,
      total_deaths: 10,
      current_members: [:prog_1, :prog_2, :prog_3],
      extinct: false,
      founded_at_tick: 100,
      last_new_member_tick: 4500  # Recent activity
    }
    
    registry = %{species_1: species}
    
    updated_registry = SpeciationDetector.detect_extinctions(registry, 5000)
    active_species = Map.get(updated_registry, :species_1)
    
    assert active_species.extinct == false
    assert active_species.extinct_at_tick == nil
  end
  
  # ============================================================================
  # Test 4: Diversity Metrics
  # ============================================================================
  
  test "calculate_diversity_metrics returns correct counts" do
    registry = %{
      species_1: create_test_species(:species_1, 10, false),
      species_2: create_test_species(:species_2, 5, false),
      species_3: create_test_species(:species_3, 0, true)
    }
    
    metrics = SpeciationDetector.calculate_diversity_metrics(registry)
    
    assert metrics.total_species == 3
    assert metrics.active_species == 2
    assert metrics.extinct_species == 1
  end
  
  test "calculate_shannon_index increases with evenness" do
    # Uneven distribution: one species dominates
    uneven_registry = %{
      species_1: create_test_species(:species_1, 90, false),
      species_2: create_test_species(:species_2, 10, false)
    }
    
    # Even distribution: species equally sized
    even_registry = %{
      species_1: create_test_species(:species_1, 50, false),
      species_2: create_test_species(:species_2, 50, false)
    }
    
    uneven_index = SpeciationDetector.calculate_shannon_index(uneven_registry)
    even_index = SpeciationDetector.calculate_shannon_index(even_registry)
    
    # Even distribution should have higher diversity
    assert even_index > uneven_index
  end
  
  test "calculate_shannon_index is 0 for single species" do
    registry = %{
      species_1: create_test_species(:species_1, 100, false)
    }
    
    index = SpeciationDetector.calculate_shannon_index(registry)
    
    assert index == 0.0  # No diversity when only one species
  end
  
  # ============================================================================
  # Test 5: Primary Domain Inference
  # ============================================================================
  
  test "infer_primary_domain identifies explorer type" do
    genome = %{
      exploration_rate: 0.85,
      validation_priority: 0.3,
      cross_domain_synthesis: 0.4,
      anomaly_sensitivity: 0.4,
      risk_tolerance: 0.6
    }
    
    domain = SpeciationDetector.infer_primary_domain(genome)
    
    assert domain == :explorer
  end
  
  test "infer_primary_domain identifies validator type" do
    genome = %{
      exploration_rate: 0.3,
      validation_priority: 0.85,
      cross_domain_synthesis: 0.4,
      anomaly_sensitivity: 0.4,
      risk_tolerance: 0.5
    }
    
    domain = SpeciationDetector.infer_primary_domain(genome)
    
    assert domain == :validator
  end
  
  test "infer_primary_domain identifies synthesizer type" do
    genome = %{
      exploration_rate: 0.4,
      validation_priority: 0.4,
      cross_domain_synthesis: 0.85,
      anomaly_sensitivity: 0.5,
      risk_tolerance: 0.5
    }
    
    domain = SpeciationDetector.infer_primary_domain(genome)
    
    assert domain == :synthesizer
  end
  
  test "infer_primary_domain identifies generalist type" do
    genome = %{
      exploration_rate: 0.5,
      validation_priority: 0.5,
      cross_domain_synthesis: 0.5,
      anomaly_sensitivity: 0.5,
      risk_tolerance: 0.5
    }
    
    domain = SpeciationDetector.infer_primary_domain(genome)
    
    assert domain == :generalist
  end
  
  # ============================================================================
  # Test 6: Integration - Full Classification Cycle
  # ============================================================================
  
  test "classify_and_register_species processes multiple programs" do
    programs = [
      create_test_program(:prog_1, %{exploration_rate: 0.9, validation_priority: 0.1, cross_domain_synthesis: 0.2, anomaly_sensitivity: 0.3, risk_tolerance: 0.7}),
      create_test_program(:prog_2, %{exploration_rate: 0.88, validation_priority: 0.12, cross_domain_synthesis: 0.22, anomaly_sensitivity: 0.28, risk_tolerance: 0.68}),
      create_test_program(:prog_3, %{exploration_rate: 0.1, validation_priority: 0.9, cross_domain_synthesis: 0.2, anomaly_sensitivity: 0.2, risk_tolerance: 0.2}),
      create_test_program(:prog_4, %{exploration_rate: 0.12, validation_priority: 0.88, cross_domain_synthesis: 0.18, anomaly_sensitivity: 0.22, risk_tolerance: 0.18})
    ]
    
    state = %State{
      research_programs: Enum.into(programs, %{}, fn p -> {p.id, p} end),
      species_registry: %{},
      economy: %{tick: 1000}
    }
    
    updated_state = SpeciationDetector.classify_and_register_species(state)
    
    # Should have 2 species (2 explorers, 2 validators)
    assert map_size(updated_state.species_registry) == 2
    
    # Check diversity metrics were calculated
    assert updated_state.economy.diversity_metrics != nil
    assert updated_state.economy.diversity_metrics.active_species == 2
  end
  
  # ============================================================================
  # Test 7: Speciation Summary
  # ============================================================================
  
  test "summarize_speciation produces readable output" do
    registry = %{
      species_1: create_test_species(:species_1, 10, false),
      species_2: create_test_species(:species_2, 5, false),
      species_3: create_test_species(:species_3, 0, true)
    }
    
    summary = SpeciationDetector.summarize_speciation(registry)
    
    assert String.contains?(summary, "Speciation Summary")
    assert String.contains?(summary, "Total species: 3")
    assert String.contains?(summary, "Active species: 2")
    assert String.contains?(summary, "Extinct species: 1")
    
    IO.puts("\n=== Speciation Summary Example ===\n#{summary}\n")
  end
  
  # ============================================================================
  # Helper Functions
  # ============================================================================
  
  defp create_test_program(id, genome) do
    %ResearchProgram{
      id: id,
      world_id: :w1,
      strategy_genome: genome,
      budget: %{credits: 500, compute: 100, attention: 50},
      status: :active,
      generation: 1,
      metadata: %{
        created_at_tick: 0,
        current_tick: 1000
      }
    }
  end
  
  defp create_test_species(id, member_count, extinct) do
    %{
      id: id,
      founding_program: :"founding_#{id}",
      founded_at_tick: 100,
      member_count: member_count,
      total_births: member_count + 5,
      total_deaths: 5,
      current_members: [],
      extinct: extinct,
      extinct_at_tick: if(extinct, do: 5000, else: nil),
      lifespan_ticks: if(extinct, do: 4900, else: 0),
      centroid_genome: %{
        exploration_rate: 0.5,
        validation_priority: 0.5,
        cross_domain_synthesis: 0.5,
        anomaly_sensitivity: 0.5,
        risk_tolerance: 0.5
      },
      primary_domain: :generalist,
      last_new_member_tick: 1000,
      max_generation: 3,
      avg_portfolio_value: 1000.0
    }
  end
end
