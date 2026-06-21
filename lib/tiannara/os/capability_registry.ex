defmodule TiannaraOS.CapabilityRegistry do
  @moduledoc """
  Three-Layer Capability Graph Architecture
  
  Manages the evolution of capabilities at the Program layer.
  Discoveries drive mutations (Improvement, Specialization, Synthesis, Paradigm Shift).
  """
  
  alias TiannaraOS.State
  alias TiannaraOS.Discovery
  alias TiannaraOS.CapabilityNode
  alias TiannaraOS.ResearchProgram

  @capability_unlock_threshold 0.4
  
  # Selection and Extinction Parameters
  @selection_decay_rate 0.05
  @extinction_threshold 0.1

  @doc """
  Register a discovery, mutating the program's capability graph.
  """
  @spec register_discovery(State.t(), Discovery.t()) :: State.t()
  def register_discovery(%State{} = state, %Discovery{} = discovery) do
    prog_id = discovery.origin_program_id
    program = Map.get(state.research_programs || %{}, prog_id)
    
    if program do
      current_tick = state.economy[:tick] || 0
      
      # 1. Decay and prune old capabilities (Selection Layer)
      {pruned_caps, extinctions} = apply_capability_selection(program.capabilities || %{}, current_tick)
      
      # 2. Mutate based on discovery
      {mutated_caps, births} = apply_discovery_mutation(pruned_caps, discovery, current_tick)
      
      # Update program
      updated_program = %{program | capabilities: mutated_caps}
      updated_programs = Map.put(state.research_programs, prog_id, updated_program)
      
      meta = state.metadata || %{}
      meta = Map.update(meta, :capability_births, births, &(&1 + births))
      meta = Map.update(meta, :capability_extinctions, extinctions, &(&1 + extinctions))
      
      # Track rediscovery (if capability was birthed but it's not truly novel)
      # We just count total capability births over time as "Total Discoveries", 
      # and the unique capability size as "Unique Capabilities".
      
      %{state | research_programs: updated_programs, metadata: meta}
    else
      state
    end
  end

  @doc """
  Check if a discovery's capability prerequisites are satisfied by the program.
  """
  @spec check_capability_prerequisites(State.t(), Discovery.t()) :: {:ok, map()} | {:blocked, [atom()]}
  def check_capability_prerequisites(%State{} = state, %Discovery{} = discovery) do
    prog_id = discovery.origin_program_id
    program = Map.get(state.research_programs || %{}, prog_id)
    
    if program do
      program_caps = program.capabilities || %{}
      required = infer_required_capabilities(discovery)
      
      # Check if program has nodes that satisfy requirements
      missing = Enum.filter(required, fn {req_domain, req_level} ->
        # Find best node matching this domain or descended from it
        best_efficiency = program_caps
          |> Map.values()
          |> Enum.filter(fn node -> 
               node.id == req_domain || req_domain in (node.parent_nodes || [])
             end)
          |> Enum.map(& &1.efficiency)
          |> Enum.max(fn -> 0.0 end)
          
        best_efficiency < req_level
      end)
      
      if Enum.empty?(missing) do
        {:ok, %{}}
      else
        {:blocked, Enum.map(missing, fn {cap, _} -> cap end)}
      end
    else
      {:blocked, [:no_program]}
    end
  end

  # ============================================================================
  # Internal Engine
  # ============================================================================

  defp apply_capability_selection(capabilities, current_tick) do
    evaluated = capabilities
    |> Enum.map(fn {id, node} ->
      ticks_since_use = current_tick - (node.last_used_tick || 0)
      decay = if ticks_since_use > 500, do: @selection_decay_rate, else: 0.0
      
      new_selection = max(0.0, node.selection_score - decay)
      extinction_risk = if new_selection < 0.2, do: 1.0 - (new_selection * 5), else: 0.0
      
      updated_node = %{node | 
        selection_score: new_selection,
        extinction_risk: extinction_risk
      }
      {id, updated_node}
    end)
    
    survivors = evaluated
    |> Enum.filter(fn {_id, node} -> node.selection_score > @extinction_threshold end)
    |> Enum.into(%{})
    
    extinctions = map_size(capabilities) - map_size(survivors)
    {survivors, extinctions}
    # Decay selection score over time if unused. Extinct if < threshold.
    capabilities
    |> Enum.map(fn {id, node} ->
      ticks_since_use = current_tick - (node.last_used_tick || 0)
      decay = if ticks_since_use > 500, do: @selection_decay_rate, else: 0.0
      
      new_selection = max(0.0, node.selection_score - decay)
      extinction_risk = if new_selection < 0.2, do: 1.0 - (new_selection * 5), else: 0.0
      
      updated_node = %{node | 
        selection_score: new_selection,
        extinction_risk: extinction_risk
      }
      {id, updated_node}
    end)
    |> Enum.filter(fn {_id, node} -> node.selection_score > @extinction_threshold end)
    |> Enum.into(%{})
  end

  defp apply_discovery_mutation(capabilities, discovery, current_tick) do
    domain_vector = Map.get(discovery.metadata, :domain_vector, %{})
    
    valid_domains = domain_vector
      |> Enum.filter(fn {_, w} -> w >= @capability_unlock_threshold end)
      |> Enum.map(fn {d, w} -> {d, w} end)
      
    cond do
      length(valid_domains) == 0 -> {capabilities, 0}
      length(valid_domains) == 1 ->
        {domain, weight} = hd(valid_domains)
        apply_single_domain_mutation(capabilities, domain, weight, discovery, current_tick)
      true ->
        apply_synthesis_mutation(capabilities, valid_domains, discovery, current_tick)
    end
  end

  defp apply_single_domain_mutation(capabilities, domain, weight, discovery, current_tick) do
    existing_node = Map.get(capabilities, domain)
    rand = :rand.uniform()
    
    if existing_node do
      if rand < 0.05 do
        # Type 4: Paradigm Shift
        new_id = String.to_atom("#{domain}_paradigm_#{:rand.uniform(1000)}")
        new_node = create_node(new_id, [domain], weight * 0.8, discovery, current_tick)
        {Map.put(capabilities, new_id, new_node), 1}
      else
        if rand < 0.20 do
          # Type 2: Specialization
          new_id = String.to_atom("#{domain}_spec_#{:rand.uniform(1000)}")
          new_node = create_node(new_id, [domain], existing_node.efficiency + 0.1, discovery, current_tick)
          {Map.put(capabilities, new_id, new_node), 1}
        else
          # Type 1: Improvement
          updated = %{existing_node |
            version: existing_node.version + 1,
            efficiency: min(1.5, existing_node.efficiency + (weight * 0.05)),
            reliability: min(1.0, existing_node.reliability + 0.02),
            usage_count: existing_node.usage_count + 1,
            last_used_tick: current_tick,
            selection_score: min(1.0, existing_node.selection_score + 0.1)
          }
          updated = update_fitness(updated)
          {Map.put(capabilities, domain, updated), 0}
        end
      end
    else
      new_node = create_node(domain, [], weight, discovery, current_tick)
      {Map.put(capabilities, domain, new_node), 1}
    end
  end

  defp apply_synthesis_mutation(capabilities, domains, discovery, current_tick) do
    parent_ids = Enum.map(domains, fn {d, _} -> d end)
    
    updated_caps = Enum.reduce(parent_ids, capabilities, fn p_id, acc ->
      if node = Map.get(acc, p_id) do
        updated = %{node | 
          usage_count: node.usage_count + 1,
          last_used_tick: current_tick,
          selection_score: min(1.0, node.selection_score + 0.1)
        }
        Map.put(acc, p_id, update_fitness(updated))
      else
        Map.put(acc, p_id, create_node(p_id, [], 0.5, discovery, current_tick))
      end
    end)
    
    syn_id = String.to_atom("syn_" <> Enum.join(parent_ids, "_") <> "_#{:rand.uniform(1000)}")
    
    avg_efficiency = updated_caps
      |> Map.take(parent_ids)
      |> Map.values()
      |> Enum.map(& &1.efficiency)
      |> Enum.sum()
      |> Kernel./(max(1, length(parent_ids)))
      
    syn_node = create_node(syn_id, parent_ids, avg_efficiency + 0.2, discovery, current_tick)
    syn_node = %{syn_node | novelty: 0.9}
    syn_node = update_fitness(syn_node)
    
    {Map.put(updated_caps, syn_id, syn_node), 1}
  end

  defp create_node(id, parents, base_efficiency, discovery, current_tick) do
    depth = 1 + (length(parents) * 1) # Simplified depth calc
    
    node = %CapabilityNode{
      id: id,
      domain_vector: Map.get(discovery.metadata, :domain_vector, %{}),
      version: 1,
      efficiency: min(1.5, base_efficiency),
      reliability: 0.5,
      novelty: 0.8,
      maturity: 0.1,
      parent_nodes: parents,
      child_nodes: [],
      depth: depth,
      discovered_by: discovery.origin_program_id,
      usage_count: 1,
      adoption_count: 1,
      selection_score: 1.0, # Starts fully selected
      last_used_tick: current_tick,
      extinction_risk: 0.0,
      promoted: false
    }
    update_fitness(node)
  end

  defp update_fitness(node) do
    fitness = node.efficiency * node.reliability * max(1, node.adoption_count) * node.novelty
    %{node | fitness_score: fitness}
  end

  defp infer_required_capabilities(%Discovery{} = discovery) do
    domain_vector = Map.get(discovery.metadata, :domain_vector, %{})
    
    domain_vector
      |> Enum.filter(fn {_, w} -> w > 0.4 end)
      |> Enum.map(fn {d, w} -> {d, Float.round(w * 0.5, 2)} end)
      |> Enum.into(%{})
  end
  
  def get_unlocked_capabilities(%Discovery{} = discovery) do
    # Fallback for old tests if needed
    domain_vector = Map.get(discovery.metadata, :domain_vector, %{})
    domain_vector |> Map.keys()
  end

  @doc """
  Promotes mature capabilities from Program -> World -> Civilization layer.
  Runs periodically to solidify knowledge.
  """
  @spec promote_capabilities(State.t()) :: State.t()
  def promote_capabilities(%State{} = state) do
    # 1. Program -> World Promotion
    updated_state = promote_program_to_world(state)
    
    # 2. World -> Civilization Promotion
    promote_world_to_civilization(updated_state)
  end
  
  defp promote_program_to_world(state) do
    meta = state.metadata || %{}
    worlds = state.worlds || %{}
    programs = state.research_programs || %{}
    
    # Group programs by world
    programs_by_world = Enum.group_by(Map.values(programs), & &1.world_id)
    
    updated_worlds = Enum.reduce(worlds, worlds, fn {world_id, world}, acc_worlds ->
      world_progs = Map.get(programs_by_world, world_id, [])
      
      # Collect all capabilities across all programs in this world
      all_caps = Enum.flat_map(world_progs, fn p -> Map.values(p.capabilities || %{}) end)
      
      # Find capabilities meeting promotion criteria
      promotable = all_caps
        |> Enum.filter(fn cap -> 
             cap.fitness_score > 0.8 and 
             cap.usage_count > 5 and
             cap.version > 2
           end)
        |> Enum.group_by(& &1.id)
        
      # Only promote if adopted by multiple lineages (adoption count > 1 isn't enough, we need multiple instances)
      promoted_nodes = promotable
        |> Enum.filter(fn {_id, instances} -> length(instances) >= 3 end)
        |> Enum.map(fn {id, instances} -> 
             # Take best instance
             best_node = Enum.max_by(instances, & &1.fitness_score)
             {id, %{best_node | promoted: true}}
           end)
        |> Enum.into(%{})
        
      if map_size(promoted_nodes) > 0 do
        world_caps = world.capabilities || %{}
        merged_world_caps = Map.merge(world_caps, promoted_nodes, fn _k, v1, v2 -> 
          if v1.fitness_score > v2.fitness_score, do: v1, else: v2 
        end)
        
        updated_world = %{world | capabilities: merged_world_caps}
        meta = Process.get(:tmp_meta, state.metadata || %{})
        Process.put(:tmp_meta, Map.update(meta, :capability_promotions, map_size(promoted_nodes), &(&1 + map_size(promoted_nodes))))
        Map.put(acc_worlds, world_id, updated_world)
      else
        acc_worlds
      end
    end)
    
    final_meta = Process.get(:tmp_meta, meta)
    %{state | worlds: updated_worlds, metadata: final_meta}
  end
  
  defp promote_world_to_civilization(state) do
    civ_caps = Map.get(state, :capabilities, %{})
    worlds = state.worlds || %{}
    
    all_world_caps = worlds
      |> Map.values()
      |> Enum.flat_map(fn w -> Map.values(w.capabilities || %{}) end)
      |> Enum.group_by(& &1.id)
      
    # Promote to civ level if present in 20% of worlds
    threshold = max(1, map_size(worlds) * 0.2 |> round())
    
    promoted_nodes = all_world_caps
      |> Enum.filter(fn {_id, instances} -> length(instances) >= threshold end)
      |> Enum.map(fn {id, instances} -> 
             best_node = Enum.max_by(instances, & &1.fitness_score)
             {id, %{best_node | promoted: true}}
           end)
      |> Enum.into(%{})
      
    merged_civ_caps = Map.merge(civ_caps, promoted_nodes, fn _k, v1, v2 -> 
      if v1.fitness_score > v2.fitness_score, do: v1, else: v2 
    end)
    
    # Using Map.put because state struct might not have `capabilities` explicitly defined
    # Actually, TiannaraOS.State needs to be updated in Phase F to have `:capabilities`.
    Map.put(state, :capabilities, merged_civ_caps)
  end

end
