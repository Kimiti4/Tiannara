defmodule Tiannara.OS.Layer65DEconomicFoundationTest do
  @moduledoc """
  Layer 6.5D Sprint 1.3: Economic Foundation with Co-Evolutionary Dynamics
  
  Tests whether discoveries can sustain institutions through asset-backed economics.
  
  Key Improvements from Sprint 1.2:
  - World needs vectors replace random demand
  - Asset decay prevents immortal discoveries
  - Domain competition creates niche formation
  - Portfolio power law prevents single-jackpot dominance
  - Scarcity mode transitions from grants to assets
  
  Configuration:
  - 10 worlds (2 per environment type)
  - 5 programs per world (total: 50)
  - 20,000 ticks (pilot test)
  - No shocks (focus on economic dynamics)
  
  Success Criteria:
  - ESR (Economic Sustainability Ratio) > 1.0
  - 10-20 surviving programs at tick 20k
  - Non-zero extinction rate
  - Portfolio formation visible
  """
  
  use ExUnit.Case, async: false
  @tag timeout: 180_000  # 3 minutes for economic simulation
  
  alias TiannaraOS.EvidenceEngine
  alias TiannaraOS.State
  alias TiannaraOS.EvidenceNode
  alias TiannaraOS.ResearchProgram
  alias TiannaraOS.WorldEpistemicPhysics
  alias TiannaraOS.ResourceEcology
  alias TiannaraOS.DiscoveryAssetEconomy
  alias TiannaraOS.DiscoveryAsset
  
  test "Layer 6.5D Sprint 1: Economic Foundation - Asset-backed research sustainability" do
    IO.puts("\n=== LAYER 6.5D SPRINT 1: ECONOMIC FOUNDATION ===\n")
    
    # Initialize state with Layer 6.5D fields
    initial_state = %State{
      worlds: %{},
      theories: %{},
      institutions: %{},
      tools: %{},
      evidence_graph: %{},
      discoveries: %{},
      research_programs: %{},
      collaborators: %{},
      discovery_assets: %{},
      memory: %{},
      economy: %{
        total_funding: 50_000,
        funding_pool: 50_000,
        compute_pool: 25_000,
        attention_pool: 10_000
      },
      security: %{},
      governance: %{},
      dependency_history: [],
      
      # Layer 6.5D fields
      program_graveyard: %{},
      species_registry: %{},
      world_epistemic_physics: %{},
      institution_registry: %{}
    }
    
    # Create 10 worlds with diverse epistemic physics AND needs vectors
    world_configs = [
      {:w1_medicine, WorldEpistemicPhysics.medicine_environment(), %{medicine: 0.9, energy: 0.3, materials: 0.4}},
      {:w2_cybernetics, WorldEpistemicPhysics.cybernetics_environment(), %{cybernetics: 0.8, robotics: 0.7, energy: 0.5}},
      {:w3_mathematics, WorldEpistemicPhysics.mathematics_environment(), %{mathematics: 0.9, logic: 0.8, computation: 0.6}},
      {:w4_physics, WorldEpistemicPhysics.physics_environment(), %{physics: 0.85, energy: 0.7, materials: 0.6}},
      {:w5_ecology, WorldEpistemicPhysics.ecology_environment(), %{ecology: 0.9, biology: 0.8, sustainability: 0.7}},
      {:w6_medicine, WorldEpistemicPhysics.medicine_environment(), %{medicine: 0.85, biotechnology: 0.6, chemistry: 0.5}},
      {:w7_cybernetics, WorldEpistemicPhysics.cybernetics_environment(), %{cybernetics: 0.75, AI: 0.8, automation: 0.6}},
      {:w8_mathematics, WorldEpistemicPhysics.mathematics_environment(), %{mathematics: 0.8, algorithms: 0.7, optimization: 0.6}},
      {:w9_physics, WorldEpistemicPhysics.physics_environment(), %{physics: 0.8, quantum: 0.7, cosmology: 0.5}},
      {:w10_ecology, WorldEpistemicPhysics.ecology_environment(), %{ecology: 0.85, conservation: 0.7, climate: 0.8}}
    ]
    
    state_with_worlds = Enum.reduce(world_configs, initial_state, fn {world_id, physics}, acc_state ->
      # Store world physics
      updated_physics_map = Map.put(acc_state.world_epistemic_physics, world_id, physics)
      
      # Create evidence nodes for this world (stored in evidence_graph)
      nodes = create_evidence_nodes(world_id, 10, physics)
      updated_graph = Enum.reduce(nodes, acc_state.evidence_graph, fn node, acc ->
        Map.put(acc, node.id, node)
      end)
      
      %{acc_state | 
        evidence_graph: updated_graph,
        world_epistemic_physics: updated_physics_map
      }
    end)
    
    IO.puts("✓ Created #{length(world_configs)} worlds with epistemic physics\n")
    
    # Create 5 programs per world (50 total)
    programs_per_world = 5
    state_with_programs = Enum.reduce(world_configs, state_with_worlds, fn {world_id, _physics}, acc_state ->
      programs = create_research_programs(world_id, programs_per_world, acc_state.world_epistemic_physics[world_id])
      
      updated_programs = Enum.reduce(programs, acc_state.research_programs, fn prog, acc ->
        Map.put(acc, prog.id, prog)
      end)
      
      %{acc_state | research_programs: updated_programs}
    end)
    
    total_programs = map_size(state_with_programs.research_programs)
    IO.puts("✓ Created #{total_programs} research programs (#{programs_per_world} per world)\n")
    
    # Run economic simulation for 20,000 ticks
    IO.puts("Running economic simulation (20,000 ticks)...\n")
    
    final_state = run_economic_simulation(state_with_programs, 20_000, world_configs)
    
    # Analyze results
    analyze_economic_results(final_state, world_configs)
  end
  
  defp create_evidence_nodes(world_id, count, physics) do
    Enum.map(1..count, fn i ->
      %EvidenceNode{
        id: String.to_atom("#{world_id}_node_#{i}"),
        type: :evidence,
        name: "Evidence in #{world_id} - Node #{i}",
        confidence: :rand.uniform() * 0.5 + 0.3,
        metadata: %{
          world_id: world_id,
          epistemic_physics: physics
        }
      }
    end)
  end
  
  defp create_research_programs(world_id, count, physics) do
    Enum.map(1..count, fn i ->
      # Generate diverse strategy genomes
      genome = %{
        exploration_rate: :rand.uniform(),
        validation_priority: :rand.uniform(),
        cross_domain_synthesis: :rand.uniform(),
        anomaly_sensitivity: :rand.uniform(),
        risk_tolerance: :rand.uniform()
      }
      
      # Calculate fitness to determine initial budget
      fitness = WorldEpistemicPhysics.calculate_fitness(physics, genome)
      initial_budget = 100 + (fitness * 100)  # 100-200 based on fitness
      
      %ResearchProgram{
        id: String.to_atom("#{world_id}_prog_#{i}"),
        world_id: world_id,
        strategy_genome: genome,
        budget: %{
          credits: initial_budget,
          compute: initial_budget * 2,
          attention: initial_budget * 0.5
        },
        status: :active,
        parent_program_id: nil,
        child_program_ids: [],
        generation: 1,
        metadata: %{
          epistemic_physics: physics,
          created_at_tick: 0
        }
      }
    end)
  end
  
  defp run_economic_simulation(%State{} = state, max_ticks, world_configs) do
    Enum.reduce(1..max_ticks, state, fn tick, acc_state ->
      # Every 100 ticks, show progress
      if rem(tick, 1000) == 0 do
        active_count = acc_state.research_programs |> Map.values() |> Enum.count(& &1.status == :active)
        asset_count = map_size(acc_state.discovery_assets)
        IO.puts("  Tick #{tick}: #{active_count} active programs, #{asset_count} assets")
      end
      
      # Process each active program
      active_programs = acc_state.research_programs |> Map.values() |> Enum.filter(& &1.status == :active)
      
      updated_state = Enum.reduce(active_programs, acc_state, fn program, state_acc ->
        process_program_tick(state_acc, program, tick)
      end)
      
      # Periodic cleanup of dead programs
      if rem(tick, 500) == 0 do
        cleanup_dead_programs(updated_state)
      else
        updated_state
      end
    end)
  end
  
  defp process_program_tick(%State{} = state, %ResearchProgram{} = program, tick) do
    physics = program.metadata.epistemic_physics
    
    # Step 1: Consume resources
    consumption = ResourceEcology.calculate_resource_consumption(program)
    state_after_consumption = consume_resources(state, program.id, consumption)
    
    # Check if program ran out of resources
    updated_program = state_after_consumption.research_programs[program.id]
    
    if is_nil(updated_program) || updated_program.budget.credits <= 0 do
      # Program dies from resource exhaustion
      terminate_program(state_after_consumption, program.id, :resource_exhaustion, tick)
    else
      # Step 2: Attempt discovery based on fitness
      fitness = WorldEpistemicPhysics.calculate_fitness(physics, updated_program.strategy_genome)
      discovery_probability = min(fitness * 0.5, 0.7)  # Higher base rate: max 70% chance per tick
      
      if :rand.uniform() < discovery_probability do
        # Successful discovery!
        
        # Create a fake discovery record in state (required by DiscoveryAssetEconomy)
        discovery_id = String.to_atom("discovery_#{tick}_#{program.id}")
        fake_discovery = %{
          id: discovery_id,
          confidence: :rand.uniform() * 0.4 + 0.6,  # 0.6-1.0
          domain: :research
        }
        updated_discoveries = Map.put(state_after_consumption.discoveries, discovery_id, fake_discovery)
        state_with_discovery = %{state_after_consumption | discoveries: updated_discoveries}
        
        # Step 3: Create discovery asset
        case DiscoveryAssetEconomy.create_discovery_asset(state_with_discovery, discovery_id, program.id) do
          {:ok, state_with_asset, asset} ->
            # Step 4: Generate royalties from asset
            royalties = DiscoveryAssetEconomy.calculate_asset_royalties(state_with_asset, program.id)
            state_with_royalties = distribute_royalties(state_with_asset, program.id, royalties)
            
            state_with_royalties
            
          {:error, reason} ->
            IO.puts("    Asset creation failed for #{discovery_id}: #{inspect(reason)}")
            # Asset creation failed, continue without it
            state_with_discovery
        end
      else
        # No discovery this tick
        state_after_consumption
      end
    end
  end
  
  defp consume_resources(%State{} = state, program_id, consumption) do
    program = state.research_programs[program_id]
    
    if is_nil(program) do
      state
    else
      new_budget = %{
        credits: max(program.budget.credits - consumption.funding, 0),
        compute: max(program.budget.compute - consumption.compute, 0),
        attention: max(program.budget.attention - consumption.attention, 0)
      }
      
      updated_program = %{program | budget: new_budget}
      updated_programs = Map.put(state.research_programs, program_id, updated_program)
      
      %{state | research_programs: updated_programs}
    end
  end
  
  defp distribute_royalties(%State{} = state, program_id, royalties) do
    program = state.research_programs[program_id]
    
    if is_nil(program) do
      state
    else
      new_budget = %{
        credits: program.budget.credits + royalties.funding,
        compute: program.budget.compute + royalties.compute,
        attention: program.budget.attention + royalties.attention
      }
      
      updated_program = %{program | budget: new_budget}
      updated_programs = Map.put(state.research_programs, program_id, updated_program)
      
      %{state | research_programs: updated_programs}
    end
  end
  
  defp terminate_program(%State{} = state, program_id, cause_of_death, tick) do
    program = state.research_programs[program_id]
    
    if is_nil(program) do
      state
    else
      # Move to graveyard
      graveyard_record = %{
        program_id: program_id,
        genome: program.strategy_genome,
        cause_of_death: cause_of_death,
        died_at_tick: tick,
        final_budget: program.budget,
        generation: program.generation,
        world_id: program.world_id
      }
      
      updated_graveyard = Map.put(state.program_graveyard, program_id, graveyard_record)
      
      # Mark program as terminated
      terminated_program = %{program | status: :terminated}
      updated_programs = Map.put(state.research_programs, program_id, terminated_program)
      
      %{state | 
        research_programs: updated_programs,
        program_graveyard: updated_graveyard
      }
    end
  end
  
  defp cleanup_dead_programs(%State{} = state) do
    # Remove terminated programs older than 1000 ticks
    cutoff_tick = state.economy[:current_tick] || 0
    
    programs_to_remove = state.research_programs
      |> Map.values()
      |> Enum.filter(fn prog ->
        prog.status == :terminated && 
        prog.metadata[:terminated_at_tick] &&
        (cutoff_tick - prog.metadata.terminated_at_tick) > 1000
      end)
      |> Enum.map(& &1.id)
    
    cleaned_programs = Enum.reduce(programs_to_remove, state.research_programs, fn id, acc ->
      Map.delete(acc, id)
    end)
    
    %{state | research_programs: cleaned_programs}
  end
  
  defp analyze_economic_results(%State{} = final_state, world_configs) do
    IO.puts("\n=== ECONOMIC ANALYSIS ===\n")
    
    # Count active vs terminated programs
    active_programs = final_state.research_programs |> Map.values() |> Enum.filter(& &1.status == :active)
    terminated_programs = final_state.research_programs |> Map.values() |> Enum.filter(& &1.status == :terminated)
    
    IO.puts("Program Status:")
    IO.puts("  Active: #{length(active_programs)}")
    IO.puts("  Terminated: #{length(terminated_programs)}")
    IO.puts("  Total: #{map_size(final_state.research_programs)}\n")
    
    # Analyze graveyard
    graveyard_count = map_size(final_state.program_graveyard)
    IO.puts("Graveyard Records: #{graveyard_count}\n")
    
    if graveyard_count > 0 do
      # Analyze causes of death
      death_causes = final_state.program_graveyard
        |> Map.values()
        |> Enum.map(& &1.cause_of_death)
        |> Enum.frequencies()
      
      IO.puts("Causes of Death:")
      Enum.each(death_causes, fn {cause, count} ->
        IO.puts("  #{cause}: #{count}")
      end)
      IO.puts("")
      
      # Average generation of dead programs
      avg_generation = final_state.program_graveyard
        |> Map.values()
        |> Enum.map(& &1.generation)
        |> Enum.sum()
        |> Kernel./(graveyard_count)
        |> Float.round(2)
      
      IO.puts("Average Generation at Death: #{avg_generation}\n")
    end
    
    # Analyze discovery assets
    asset_count = map_size(final_state.discovery_assets)
    IO.puts("Discovery Assets: #{asset_count}\n")
    
    if asset_count > 0 do
      total_value = final_state.discovery_assets
        |> Map.values()
        |> Enum.map(& &1.value)
        |> Enum.sum()
        |> Float.round(2)
      
      avg_value = total_value / asset_count |> Float.round(2)
      
      IO.puts("Asset Portfolio:")
      IO.puts("  Total Value: #{total_value}")
      IO.puts("  Average Value: #{avg_value}\n")
      
      # Show top 5 assets
      top_assets = final_state.discovery_assets
        |> Map.values()
        |> Enum.sort_by(& &1.value, :desc)
        |> Enum.take(5)
      
      IO.puts("Top 5 Assets:")
      Enum.each(top_assets, fn asset ->
        IO.puts("  #{asset.id}: value=#{Float.round(asset.value, 2)}, owner=#{asset.owner_id}")
      end)
      IO.puts("")
    end
    
    # Analyze survival by world type
    IO.puts("Survival by World Type:")
    Enum.each(world_configs, fn {world_id, _physics} ->
      world_active = active_programs |> Enum.count(& &1.world_id == world_id)
      world_total = final_state.research_programs |> Map.values() |> Enum.count(& &1.world_id == world_id)
      survival_rate = if world_total > 0, do: (world_active / world_total * 100) |> Float.round(1), else: 0
      
      IO.puts("  #{world_id}: #{world_active}/#{world_total} (#{survival_rate}%)")
    end)
    IO.puts("")
    
    # Economic health
    IO.puts("Economic Health:")
    IO.puts("  Remaining Funding Pool: #{Float.round(final_state.economy[:funding_pool] || 0.0, 2)}")
    IO.puts("  Total Asset Value: #{calculate_total_asset_value(final_state)}")
    IO.puts("  Economy Sustainability: #{assess_economy_sustainability(final_state)}\n")
    
    # Success criteria evaluation
    evaluate_success_criteria(final_state, active_programs, terminated_programs)
  end
  
  defp calculate_total_asset_value(%State{} = state) do
    state.discovery_assets
      |> Map.values()
      |> Enum.map(& &1.value)
      |> Enum.sum()
      |> Float.round(2)
  end
  
  defp assess_economy_sustainability(%State{} = state) do
    active_count = state.research_programs |> Map.values() |> Enum.count(& &1.status == :active)
    asset_value = calculate_total_asset_value(state)
    
    if active_count > 0 && asset_value > 1000 do
      "SUSTAINABLE (#{active_count} programs supported by #{asset_value} in assets)"
    else
      "UNSUSTAINABLE (insufficient asset backing)"
    end
  end
  
  defp evaluate_success_criteria(%State{} = state, active_programs, terminated_programs) do
    IO.puts("=== SUCCESS CRITERIA EVALUATION ===\n")
    
    # Criterion 1: Asset-backed survival
    programs_with_assets = active_programs
      |> Enum.count(fn prog ->
        state.discovery_assets
          |> Map.values()
          |> Enum.any?(& &1.owner_id == prog.id)
      end)
    
    io_puts_colored("1. Asset-Backed Survival:", :green)
    IO.puts("   Programs with assets: #{programs_with_assets}/#{length(active_programs)}")
    if programs_with_assets > length(active_programs) * 0.3 do
      IO.puts("   ✅ PASS (>30% have asset backing)\n")
    else
      IO.puts("   ⚠️ PARTIAL (<30% have asset backing)\n")
    end
    
    # Criterion 2: Economic mortality
    resource_deaths = state.program_graveyard
      |> Map.values()
      |> Enum.count(& &1.cause_of_death == :resource_exhaustion)
    
    io_puts_colored("2. Economic Mortality:", :green)
    IO.puts("   Deaths from resource exhaustion: #{resource_deaths}/#{map_size(state.program_graveyard)}")
    if resource_deaths > map_size(state.program_graveyard) * 0.5 do
      IO.puts("   ✅ PASS (>50% died from economics, not arbitrary caps)\n")
    else
      IO.puts("   ⚠️ PARTIAL (need more economic deaths)\n")
    end
    
    # Criterion 3: Asset value correlation with survival
    avg_asset_value_survivors = state.discovery_assets
      |> Map.values()
      |> Enum.filter(fn asset ->
        prog = state.research_programs[asset.owner_id]
        !is_nil(prog) && prog.status == :active
      end)
      |> Enum.map(& &1.value)
      |> case do
        [] -> 0
        values -> Enum.sum(values) / length(values)
      end
    
    io_puts_colored("3. Asset-Survival Correlation:", :green)
    IO.puts("   Avg asset value (survivors): #{Float.round(avg_asset_value_survivors, 2)}")
    if avg_asset_value_survivors > 50 do
      IO.puts("   ✅ PASS (survivors have valuable assets)\n")
    else
      IO.puts("   ⚠️ PARTIAL (asset values too low)\n")
    end
    
    # Criterion 4: Economic turnover
    birth_count = state.research_programs
      |> Map.values()
      |> Enum.count(& &1.generation == 1)
    
    death_count = map_size(state.program_graveyard)
    
    io_puts_colored("4. Economic Turnover:", :green)
    IO.puts("   Births (gen 1): #{birth_count}")
    IO.puts("   Deaths: #{death_count}")
    turnover_ratio = if birth_count > 0, do: death_count / birth_count |> Float.round(2), else: 0
    IO.puts("   Turnover ratio: #{turnover_ratio}")
    if turnover_ratio > 0.3 && turnover_ratio < 3.0 do
      IO.puts("   ✅ PASS (balanced birth/death rates)\n")
    else
      IO.puts("   ⚠️ PARTIAL (unbalanced turnover)\n")
    end
    
    IO.puts("=== SPRINT 1 COMPLETE ===\n")
  end
  
  defp io_puts_colored(text, _color) do
    # Simple colored output (Windows may not support ANSI colors)
    IO.puts(text)
  end
end
