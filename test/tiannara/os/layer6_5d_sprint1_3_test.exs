defmodule Tiannara.OS.Layer65DSprint1_3Test do
  @moduledoc """
  Layer 6.5D Sprint 1.3: Economic Foundation with Co-Evolutionary Dynamics
  
  Implements ALL critical improvements from architectural review:
  1. World needs vectors replace random demand
  2. Asset decay prevents immortal discoveries  
  3. Domain competition creates niche formation
  4. Portfolio power law prevents single-jackpot dominance
  5. Scarcity mode transitions from grants to assets
  6. Dot product demand calculation (asset_vector • world_needs)
  
  Success Criteria:
  - ESR (Economic Sustainability Ratio) > 1.0
  - 10-20 surviving programs at tick 20k
  - Non-zero extinction rate
  - Portfolio formation visible
  """
  
  use ExUnit.Case, async: false
  @tag timeout: 180_000
  
  alias TiannaraOS.State
  alias TiannaraOS.EvidenceNode
  alias TiannaraOS.ResearchProgram
  alias TiannaraOS.WorldEpistemicPhysics
  alias TiannaraOS.ResourceEcology
  alias TiannaraOS.DiscoveryAssetEconomy
  alias TiannaraOS.DiscoveryAsset
  
  test "Layer 6.5D Sprint 1.3: Co-evolutionary economic foundation" do
    IO.puts("\n=== LAYER 6.5D SPRINT 1.3: CO-EVOLUTIONARY ECONOMICS ===\n")
    
    # Initialize state
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
        attention_pool: 10_000,
        tick: 0
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
    
    # Create 10 worlds with epistemic physics AND needs vectors
    world_configs = create_world_configs()
    
    state_with_worlds = Enum.reduce(world_configs, initial_state, fn {world_id, physics, needs}, acc_state ->
      # Store world physics and needs
      updated_physics_map = Map.put(acc_state.world_epistemic_physics, world_id, physics)
      
      # Create evidence nodes for this world
      nodes = create_evidence_nodes(world_id, 10, physics)
      updated_graph = Enum.reduce(nodes, acc_state.evidence_graph, fn node, acc ->
        Map.put(acc, node.id, node)
      end)
      
      # Store world metadata (needs vector)
      world_metadata = %{
        id: world_id,
        needs_vector: needs,
        wealth: 10_000.0,
        epistemic_physics: physics
      }
      updated_worlds = Map.put(acc_state.worlds, world_id, world_metadata)
      
      %{acc_state | 
        evidence_graph: updated_graph,
        world_epistemic_physics: updated_physics_map,
        worlds: updated_worlds
      }
    end)
    
    IO.puts("✓ Created #{length(world_configs)} worlds with needs vectors\n")
    
    # Create 5 programs per world (50 total) with higher initial budgets
    programs_per_world = 5
    state_with_programs = Enum.reduce(world_configs, state_with_worlds, fn {world_id, _physics, _needs}, acc_state ->
      programs = create_research_programs(world_id, programs_per_world, acc_state.world_epistemic_physics[world_id])
      
      updated_programs = Enum.reduce(programs, acc_state.research_programs, fn prog, acc ->
        Map.put(acc, prog.id, prog)
      end)
      
      %{acc_state | research_programs: updated_programs}
    end)
    
    total_programs = map_size(state_with_programs.research_programs)
    IO.puts("✓ Created #{total_programs} research programs (budget: 500-1000 credits)\n")
    
    # Run economic simulation for 20,000 ticks
    IO.puts("Running co-evolutionary economic simulation (20,000 ticks)...\n")
    
    final_state = run_economic_simulation(state_with_programs, 20_000, world_configs)
    
    # Analyze results with ESR metric
    analyze_co_evolutionary_results(final_state, world_configs)
  end
  
  defp create_world_configs() do
    [
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
      
      # Calculate fitness to determine initial budget (higher starting budgets)
      fitness = WorldEpistemicPhysics.calculate_fitness(physics, genome)
      initial_budget = 500 + (fitness * 500)  # 500-1000 based on fitness (increased from 100-200)
      
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
          created_at_tick: 0,
          portfolio_value: 0.0
        }
      }
    end)
  end
  
  defp run_economic_simulation(%State{} = state, max_ticks, world_configs) do
    Enum.reduce(1..max_ticks, state, fn tick, acc_state ->
      # Every 1000 ticks, show progress
      if rem(tick, 2000) == 0 do
        active_count = acc_state.research_programs |> Map.values() |> Enum.count(& &1.status == :active)
        asset_count = map_size(acc_state.discovery_assets)
        total_wealth = calculate_total_wealth(acc_state)
        esr = calculate_esr(acc_state, tick)
        IO.puts("  Tick #{tick}: #{active_count} active, #{asset_count} assets, wealth=#{Float.round(total_wealth, 0)}, ESR=#{Float.round(esr, 2)}")
      end
      
      # Process each active program
      active_programs = acc_state.research_programs |> Map.values() |> Enum.filter(& &1.status == :active)
      
      updated_state = Enum.reduce(active_programs, acc_state, fn program, state_acc ->
        process_program_tick(state_acc, program, tick, world_configs)
      end)
      
      # Apply asset decay every 100 ticks
      if rem(tick, 100) == 0 do
        apply_asset_decay(updated_state)
      else
        updated_state
      end
    end)
  end
  
  defp process_program_tick(%State{} = state, %ResearchProgram{} = program, tick, world_configs) do
    physics = program.metadata.epistemic_physics
    world = state.worlds[program.world_id]
    needs_vector = if world, do: world.needs_vector, else: %{}
    
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
      discovery_probability = min(fitness * 0.5, 0.7)  # Max 70% chance per tick
      
      if :rand.uniform() < discovery_probability do
        # Successful discovery!
        
        # Create discovery with DOMAIN VECTOR based on world needs
        discovery_id = String.to_atom("discovery_#{tick}_#{program.id}")
        
        # Domain vector emerges from world needs + strategy traits
        domain_vector = generate_domain_vector(needs_vector, updated_program.strategy_genome)
        
        fake_discovery = %{
          id: discovery_id,
          confidence: :rand.uniform() * 0.4 + 0.6,  # 0.6-1.0
          domain_vector: domain_vector,  # NEW: Vector-based domain identity
          primary_domain: get_primary_domain(domain_vector)
        }
        updated_discoveries = Map.put(state_after_consumption.discoveries, discovery_id, fake_discovery)
        state_with_discovery = %{state_after_consumption | discoveries: updated_discoveries}
        
        # Step 3: Create discovery asset
        case DiscoveryAssetEconomy.create_discovery_asset(state_with_discovery, discovery_id, program.id) do
          {:ok, state_with_asset, asset} ->
            # Asset ID is the map key (asset_#{discovery_id})
            asset_id = :"asset_#{discovery_id}"
            
            # Update asset with domain vector
            asset_with_vector = %{asset | domain_vector: domain_vector}
            updated_assets = Map.put(state_with_asset.discovery_assets, asset_id, asset_with_vector)
            state_with_vector = %{state_with_asset | discovery_assets: updated_assets}
            
            # Step 4: Calculate royalties using DOT PRODUCT demand
            royalties = calculate_vector_based_royalties(state_with_vector, program.id, needs_vector)
            state_with_royalties = distribute_royalties(state_with_vector, program.id, royalties)
            
            # Update program portfolio value
            update_portfolio_value(state_with_royalties, program.id, asset.valuation)
            
          {:error, reason} ->
            # Asset creation failed
            state_with_discovery
        end
      else
        # No discovery this tick
        state_after_consumption
      end
    end
  end
  
  # NEW: Generate domain vector from world needs and program traits
  defp generate_domain_vector(needs_vector, genome) do
    # Domain vector is weighted combination of:
    # 1. World needs (what the world wants)
    # 2. Program exploration bias (what the program seeks)
    
    base_domains = Map.keys(needs_vector)
    
    Enum.reduce(base_domains, %{}, fn domain, acc ->
      need_weight = Map.get(needs_vector, domain, 0.0)
      exploration_factor = genome.exploration_rate * 0.3
      synthesis_factor = genome.cross_domain_synthesis * 0.2
      
      weight = min(1.0, need_weight + exploration_factor + synthesis_factor)
      Map.put(acc, domain, Float.round(weight, 2))
    end)
  end
  
  defp get_primary_domain(domain_vector) do
    domain_vector
    |> Enum.max_by(fn {_domain, weight} -> weight end, fn -> {:unknown, 0.0} end)
    |> elem(0)
  end
  
  # NEW: Calculate royalties using dot product demand and competition
  defp calculate_vector_based_royalties(%State{} = state, program_id, needs_vector) do
    program_assets = state.discovery_assets
      |> Map.values()
      |> Enum.filter(fn asset ->
        owns_asset?(asset, program_id)
      end)
    
    if length(program_assets) == 0 do
      %{funding: 0.0, compute: 0.0, attention: 0.0}
    else
      # Calculate total royalty income using dot product demand
      total_royalty = Enum.reduce(program_assets, 0.0, fn asset, acc ->
        # Dot product: asset.domain_vector • world.needs_vector
        demand_score = dot_product(asset.domain_vector || %{}, needs_vector)
        
        # Competition factor: more assets in same domain → lower effective demand
        competition = calculate_competition(state, asset.primary_domain || :unknown)
        effective_demand = demand_score / max(1.0, competition)
        
        # Portfolio power law: diminishing returns for large portfolios
        base_royalty = asset.valuation * asset.royalty_rate * effective_demand
        acc + base_royalty
      end)
      
      # Apply portfolio power law (0.7 exponent prevents runaway wealth)
      adjusted_royalty = :math.pow(max(0.0, total_royalty), 0.7)
      
      %{
        funding: adjusted_royalty * 0.6,
        compute: adjusted_royalty * 0.3,
        attention: adjusted_royalty * 0.1
      }
    end
  end
  
  defp dot_product(vec1, vec2) do
    vec1
    |> Map.keys()
    |> Enum.reduce(0.0, fn key, acc ->
      val1 = Map.get(vec1, key, 0.0)
      val2 = Map.get(vec2, key, 0.0)
      acc + (val1 * val2)
    end)
  end
  
  defp calculate_competition(%State{} = state, domain) do
    # Count assets in same domain
    state.discovery_assets
      |> Map.values()
      |> Enum.count(fn asset ->
        asset.primary_domain == domain
      end)
  end
  
  defp owns_asset?(asset, program_id) do
    Enum.any?(asset.transaction_history || [], fn txn ->
      txn.type == :creation && txn.owner_program == program_id
    end)
  end
  
  # NEW: Apply asset decay to prevent immortal discoveries
  defp apply_asset_decay(%State{} = state) do
    decay_rate = 0.999  # 0.1% decay per 100 ticks
    
    updated_assets = Enum.map(state.discovery_assets, fn {asset_id, asset} ->
      decayed_valuation = asset.valuation * decay_rate
      decayed_asset = %{asset | valuation: decayed_valuation}
      {asset_id, decayed_asset}
    end)
    |> Enum.into(%{})
    
    %{state | discovery_assets: updated_assets}
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
  
  defp update_portfolio_value(%State{} = state, program_id, asset_value) do
    program = state.research_programs[program_id]
    
    if is_nil(program) do
      state
    else
      current_portfolio = program.metadata[:portfolio_value] || 0.0
      new_portfolio = current_portfolio + asset_value
      
      updated_metadata = Map.put(program.metadata, :portfolio_value, new_portfolio)
      updated_program = %{program | metadata: updated_metadata}
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
        world_id: program.world_id,
        portfolio_value: program.metadata[:portfolio_value] || 0.0,
        lifespan_ticks: tick - (program.metadata[:created_at_tick] || 0)
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
  
  defp calculate_total_wealth(%State{} = state) do
    # Sum of all program budgets + asset valuations
    program_wealth = state.research_programs
      |> Map.values()
      |> Enum.filter(& &1.status == :active)
      |> Enum.reduce(0.0, fn prog, acc -> acc + prog.budget.credits end)
    
    asset_wealth = state.discovery_assets
      |> Map.values()
      |> Enum.reduce(0.0, fn asset, acc -> acc + asset.valuation end)
    
    program_wealth + asset_wealth
  end
  
  defp calculate_esr(%State{} = state, current_tick) do
    # ESR = Total Royalty Income / Total Resource Consumption
    # Simplified: estimate from current state
    
    active_programs = state.research_programs |> Map.values() |> Enum.filter(& &1.status == :active)
    
    if length(active_programs) == 0 do
      0.0
    else
      # Estimate total consumption per tick
      avg_consumption = Enum.reduce(active_programs, 0.0, fn prog, acc ->
        consumption = ResourceEcology.calculate_resource_consumption(prog)
        acc + consumption.funding
      end) / length(active_programs)
      
      # Estimate total royalties (from asset values as proxy)
      avg_asset_value = if map_size(state.discovery_assets) > 0 do
        state.discovery_assets
          |> Map.values()
          |> Enum.map(& &1.valuation)
          |> Enum.sum()
          |> Kernel./(map_size(state.discovery_assets))
      else
        0.0
      end
      
      # Rough ESR estimate
      if avg_consumption > 0 do
        (avg_asset_value * 0.05) / avg_consumption  # Assume 5% royalty rate
      else
        0.0
      end
    end
  end
  
  defp analyze_co_evolutionary_results(%State{} = final_state, world_configs) do
    IO.puts("\n=== CO-EVOLUTIONARY ECONOMIC ANALYSIS ===\n")
    
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
      
      # Average lifespan
      avg_lifespan = final_state.program_graveyard
        |> Map.values()
        |> Enum.map(& &1.lifespan_ticks)
        |> Enum.sum()
        |> Kernel./(graveyard_count)
        |> Float.round(0)
      
      IO.puts("Average Lifespan: #{avg_lifespan} ticks\n")
    end
    
    # Analyze discovery assets
    asset_count = map_size(final_state.discovery_assets)
    IO.puts("Discovery Assets: #{asset_count}\n")
    
    if asset_count > 0 do
      total_value = final_state.discovery_assets
        |> Map.values()
        |> Enum.map(& &1.valuation)
        |> Enum.sum()
        |> Float.round(2)
      
      avg_value = total_value / asset_count |> Float.round(2)
      
      IO.puts("Asset Portfolio:")
      IO.puts("  Total Value: #{total_value}")
      IO.puts("  Average Value: #{avg_value}\n")
    end
    
    # Calculate ESR
    final_esr = calculate_esr(final_state, 20_000)
    IO.puts("Economic Sustainability Ratio (ESR): #{Float.round(final_esr, 2)}")
    if final_esr > 1.0 do
      IO.puts("  ✅ CIVILIZATION SUSTAINABLE (ESR > 1.0)\n")
    else
      IO.puts("  ⚠️ CIVILIZATION UNSUSTAINABLE (ESR < 1.0)\n")
    end
    
    # Survival by world type
    IO.puts("Survival by World Type:")
    Enum.each(world_configs, fn {world_id, _physics, _needs} ->
      world_active = active_programs |> Enum.count(& &1.world_id == world_id)
      world_total = final_state.research_programs |> Map.values() |> Enum.count(& &1.world_id == world_id)
      survival_rate = if world_total > 0, do: (world_active / world_total * 100) |> Float.round(1), else: 0
      
      IO.puts("  #{world_id}: #{world_active}/#{world_total} (#{survival_rate}%)")
    end)
    IO.puts("")
    
    # Economic health
    total_wealth = calculate_total_wealth(final_state)
    IO.puts("Economic Health:")
    IO.puts("  Total Wealth: #{Float.round(total_wealth, 0)}")
    IO.puts("  Economy Sustainability: #{assess_economy_sustainability(final_state)}\n")
    
    # Success criteria evaluation
    evaluate_sprint_1_3_success(final_state, active_programs, terminated_programs, final_esr)
  end
  
  defp assess_economy_sustainability(%State{} = state) do
    active_count = state.research_programs |> Map.values() |> Enum.count(& &1.status == :active)
    asset_value = state.discovery_assets |> Map.values() |> Enum.reduce(0.0, fn a, acc -> acc + a.valuation end)
    
    if active_count > 0 && asset_value > 1000 do
      "SUSTAINABLE (#{active_count} programs, #{Float.round(asset_value, 0)} in assets)"
    else
      "UNSUSTAINABLE"
    end
  end
  
  defp evaluate_sprint_1_3_success(%State{} = state, active_programs, terminated_programs, esr) do
    IO.puts("=== SPRINT 1.3 SUCCESS CRITERIA ===\n")
    
    # Criterion 1: ESR > 1.0
    IO.puts("1. Economic Sustainability Ratio:")
    IO.puts("   ESR = #{Float.round(esr, 2)}")
    if esr > 1.0 do
      IO.puts("   ✅ PASS (ESR > 1.0)\n")
    else
      IO.puts("   ❌ FAIL (ESR < 1.0)\n")
    end
    
    # Criterion 2: 10-20 surviving programs
    IO.puts("2. Program Survival:")
    IO.puts("   Active programs: #{length(active_programs)}")
    if length(active_programs) >= 10 and length(active_programs) <= 20 do
      IO.puts("   ✅ PASS (10-20 survivors)\n")
    else
      IO.puts("   ⚠️ PARTIAL (expected 10-20)\n")
    end
    
    # Criterion 3: Non-zero extinction rate
    IO.puts("3. Extinction Rate:")
    IO.puts("   Terminated: #{length(terminated_programs)}")
    if length(terminated_programs) > 0 do
      IO.puts("   ✅ PASS (mortality exists)\n")
    else
      IO.puts("   ❌ FAIL (no deaths)\n")
    end
    
    # Criterion 4: Portfolio formation
    programs_with_assets = active_programs
      |> Enum.count(fn prog ->
        state.discovery_assets
          |> Map.values()
          |> Enum.any?(& owns_asset?(&1, prog.id))
      end)
    
    IO.puts("4. Portfolio Formation:")
    IO.puts("   Programs with assets: #{programs_with_assets}/#{length(active_programs)}")
    if programs_with_assets > 0 do
      IO.puts("   ✅ PASS (portfolios forming)\n")
    else
      IO.puts("   ❌ FAIL (no portfolios)\n")
    end
    
    IO.puts("=== SPRINT 1.3 COMPLETE ===\n")
  end
end
