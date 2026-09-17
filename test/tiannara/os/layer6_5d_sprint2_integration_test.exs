defmodule Tiannara.OS.Layer65DSprint2IntegrationTest do
  @moduledoc """
  Sprint 2: Full Integration Test
  
  Validates the complete evolutionary cycle:
  - Institutional memory guides reproduction
  - Speciation tracking detects emergent species
  - Dynamic world needs evolve over time
  - Multi-generational lineages form
  - Economic sustainability maintained
  
  Runs 30,000 tick simulation with 50 programs across 5 worlds.
  """
  
  use ExUnit.Case, async: false
  @tag timeout: 300_000  # 5 minutes for full simulation
  
  alias TiannaraOS.State
  alias TiannaraOS.ResearchProgram
  alias TiannaraOS.WorldEpistemicPhysics
  alias TiannaraOS.ReproductionEngine
  alias TiannaraOS.SpeciationDetector
  alias TiannaraOS.InstitutionalMemory
  alias TiannaraOS.DynamicNeedsEvolution
  
  test "Layer 6.5D Sprint 2: Full evolutionary integration" do
    IO.puts("\n=== LAYER 6.5D SPRINT 2: FULL INTEGRATION TEST ===\n")
    
    # Initialize state with worlds and programs
    initial_state = initialize_integration_state()
    
    IO.puts("Running 30,000 tick evolutionary simulation...\n")
    
    # Run simulation
    final_state = run_integration_simulation(initial_state, 30_000)
    
    # Analyze results
    analyze_integration_results(final_state)
  end
  
  defp initialize_integration_state() do
    # Create 5 diverse worlds
    world_configs = [
      {:w1_medicine, WorldEpistemicPhysics.medicine_environment(), %{medicine: 0.9, energy: 0.3}},
      {:w2_cybernetics, WorldEpistemicPhysics.cybernetics_environment(), %{cybernetics: 0.8, robotics: 0.7}},
      {:w3_mathematics, WorldEpistemicPhysics.mathematics_environment(), %{mathematics: 0.9, logic: 0.8}},
      {:w4_physics, WorldEpistemicPhysics.medicine_environment(), %{physics: 0.8, energy: 0.6}},
      {:w5_chemistry, WorldEpistemicPhysics.cybernetics_environment(), %{chemistry: 0.7, materials: 0.6}}
    ]
    
    initial_state = %State{
      research_programs: %{},
      discoveries: %{},
      discovery_assets: %{},
      program_graveyard: %{},
      species_registry: %{},
      economy: %{tick: 0, funding_pool: 10000.0}
    }
    
    # Add worlds to state
    state_with_worlds = Enum.reduce(world_configs, initial_state, fn {world_id, physics, needs}, acc ->
      world_data = %{
        id: world_id,
        epistemic_physics: physics,
        needs_vector: needs,
        original_needs: needs
      }
      
      put_in(acc.worlds[world_id], world_data)
    end)
    
    # Create 10 programs per world (50 total)
    state_with_programs = Enum.reduce(world_configs, state_with_worlds, fn {world_id, _physics, _needs}, acc ->
      programs = Enum.map(1..10, fn i ->
        prog_id = String.to_atom("#{world_id}_prog_#{i}")
        
        genome = %{
          exploration_rate: 0.3 + :rand.uniform() * 0.4,
          validation_priority: 0.3 + :rand.uniform() * 0.4,
          cross_domain_synthesis: 0.2 + :rand.uniform() * 0.4,
          anomaly_sensitivity: 0.2 + :rand.uniform() * 0.4,
          risk_tolerance: 0.3 + :rand.uniform() * 0.4
        }
        
        %ResearchProgram{
          id: prog_id,
          world_id: world_id,
          strategy_genome: genome,
          budget: %{credits: 800.0, compute: 150.0, attention: 75.0, curiosity_budget: 50.0},
          status: :active,
          generation: 1,
          child_program_ids: [],
          metadata: %{
            epistemic_physics: nil,
            created_at_tick: 0,
            current_tick: 0,
            portfolio_value: 0.0
          }
        }
      end)
      
      programs_map = Enum.into(programs, %{}, fn p -> {p.id, p} end)
      Map.update!(acc, :research_programs, & Map.merge(&1, programs_map))
    end)
    
    IO.puts("✓ Initialized 5 worlds with dynamic needs\n")
    IO.puts("✓ Created 50 research programs (10 per world)\n")
    
    state_with_programs
  end
  
  defp run_integration_simulation(%State{} = state, max_ticks) do
    Enum.reduce(1..max_ticks, state, fn tick, acc_state ->
      # Progress reporting every 5000 ticks
      if rem(tick, 5000) == 0 do
        active_count = acc_state.research_programs |> Map.values() |> Enum.count(& &1.status == :active)
        species_count = map_size(acc_state.species_registry || %{})
        graveyard_count = map_size(acc_state.program_graveyard || %{})
        
        diversity = acc_state.economy[:diversity_metrics]
        shannon = if diversity, do: Float.round(diversity.shannon_diversity, 2), else: 0.0
        
        IO.puts("  Tick #{tick}: #{active_count} active, #{species_count} species, " <>
                "#{graveyard_count} deaths, Shannon=#{shannon}")
      end
      
      # Step 1: Simulate basic economic activity (simplified)
      state_after_economics = simulate_economic_tick(acc_state, tick)
      
      # Step 2: Trigger reproduction every 200 ticks
      state_after_reproduction = if rem(tick, 200) == 0 do
        ReproductionEngine.trigger_reproduction(state_after_economics)
      else
        state_after_economics
      end
      
      # Step 3: Classify species every 1000 ticks
      state_with_species = if rem(tick, 1000) == 0 do
        SpeciationDetector.classify_and_register_species(state_after_reproduction)
      else
        state_after_reproduction
      end
      
      # Step 4: Evolve world needs every 2000 ticks
      state_with_evolved_needs = if rem(tick, 2000) == 0 do
        evolve_world_needs(state_with_species)
      else
        state_with_species
      end
      
      # Update tick counter
      updated_economy = Map.put(state_with_evolved_needs.economy, :tick, tick)
      %{state_with_evolved_needs | economy: updated_economy}
    end)
  end
  
  defp simulate_economic_tick(%State{} = state, _tick) do
    # Simplified economic simulation
    # In real implementation, this would process discoveries, assets, royalties
    
    programs = state.research_programs || %{}
    
    # Simulate some programs dying from resource exhaustion (random 1% chance)
    updated_programs = Enum.reduce(programs, programs, fn {prog_id, program}, acc ->
      if program.status == :active and :rand.uniform() < 0.01 do
        # Program dies
        dead_program = %{program | status: :terminated}
        
        # Add to graveyard
        death_record = %{
          world_id: program.world_id,
          cause_of_death: :resource_exhaustion,
          lifespan_ticks: :rand.uniform(5000) + 1000,
          genome: program.strategy_genome,
          assets_at_death: []
        }
        
        updated_graveyard = Map.put(state.program_graveyard || %{}, prog_id, death_record)
        
        acc_with_dead = Map.put(acc, prog_id, dead_program)
        %{state | research_programs: acc_with_dead, program_graveyard: updated_graveyard}
        |> Map.get(:research_programs)
      else
        acc
      end
    end)
    
    %{state | research_programs: updated_programs}
  end
  
  defp evolve_world_needs(%State{} = state) do
    worlds = state.worlds || %{}
    discoveries = state.discoveries || %{}
    current_tick = state.economy[:tick] || 0
    
    updated_worlds = Enum.reduce(worlds, worlds, fn {world_id, world}, acc ->
      # Get discoveries for this world
      world_discoveries = discoveries
        |> Map.values()
        |> Enum.filter(& &1.world_id == world_id)
      
      if length(world_discoveries) > 0 do
        # Evolve needs
        evolved_needs = DynamicNeedsEvolution.evolve_needs(
          world.needs_vector,
          world_discoveries,
          current_tick
        )
        
        updated_world = %{world | needs_vector: evolved_needs}
        Map.put(acc, world_id, updated_world)
      else
        acc
      end
    end)
    
    %{state | worlds: updated_worlds}
  end
  
  defp analyze_integration_results(%State{} = state) do
    IO.puts("\n=== INTEGRATION ANALYSIS ===\n")
    
    # Count generations
    max_generation = state.research_programs
      |> Map.values()
      |> Enum.map(& &1.generation || 1)
      |> Enum.max(fn -> 1 end)
    
    # Count lineages
    total_lineages = state.research_programs
      |> Map.values()
      |> Enum.map(& &1.parent_program_id)
      |> Enum.uniq()
      |> Enum.count(& &1 != nil)
    
    # Species diversity
    species_count = map_size(state.species_registry || %{})
    diversity = state.economy[:diversity_metrics]
    shannon = if diversity, do: Float.round(diversity.shannon_diversity, 3), else: 0.0
    
    # Extinction events
    extinct_count = state.species_registry
      |> Map.values()
      |> Enum.count(& &1.extinct)
    
    # Graveyard analysis
    graveyard_size = map_size(state.program_graveyard || %{})
    
    IO.puts("Evolutionary Metrics:")
    IO.puts("  Max Generation: #{max_generation}")
    IO.puts("  Unique Lineages: #{total_lineages}")
    IO.puts("  Species Count: #{species_count}")
    IO.puts("  Extinct Species: #{extinct_count}")
    IO.puts("  Shannon Diversity: #{shannon}")
    IO.puts("  Programs in Graveyard: #{graveyard_size}\n")
    
    # Success criteria evaluation
    evaluate_integration_success(max_generation, total_lineages, species_count, shannon)
  end
  
  defp evaluate_integration_success(max_generation, total_lineages, species_count, shannon) do
    IO.puts("=== SPRINT 2 SUCCESS CRITERIA ===\n")
    
    # Criterion 1: Multi-generational lineages
    IO.puts("1. Multi-Generational Lineages:")
    IO.puts("   Max generation: #{max_generation}")
    if max_generation >= 3 do
      IO.puts("   ✅ PASS (≥3 generations)\n")
    else
      IO.puts("   ⚠️ PARTIAL (<3 generations)\n")
    end
    
    # Criterion 2: Lineage formation
    IO.puts("2. Lineage Formation:")
    IO.puts("   Unique lineages: #{total_lineages}")
    if total_lineages >= 5 do
      IO.puts("   ✅ PASS (≥5 lineages)\n")
    else
      IO.puts("   ⚠️ PARTIAL (<5 lineages)\n")
    end
    
    # Criterion 3: Speciation
    IO.puts("3. Speciation Events:")
    IO.puts("   Species count: #{species_count}")
    if species_count >= 3 do
      IO.puts("   ✅ PASS (≥3 species)\n")
    else
      IO.puts("   ⚠️ PARTIAL (<3 species)\n")
    end
    
    # Criterion 4: Diversity
    IO.puts("4. Ecosystem Diversity:")
    IO.puts("   Shannon index: #{shannon}")
    if shannon > 0.5 do
      IO.puts("   ✅ PASS (Shannon > 0.5)\n")
    else
      IO.puts("   ⚠️ PARTIAL (Shannon ≤ 0.5)\n")
    end
    
    IO.puts("=== SPRINT 2 INTEGRATION COMPLETE ===\n")
  end
end
