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
  alias Tiannara.LifecycleRegistry

  @capability_unlock_threshold 0.4
  
  # Selection and Extinction Parameters
  @selection_decay_rate 0.01
  @extinction_threshold 0.05

  @doc """
  Get all capabilities available in a world.
  """
  @spec get_world_capabilities(State.t(), atom()) :: map()
  def get_world_capabilities(%State{} = state, world_id) do
    world = Map.get(state.worlds || %{}, world_id)
    if world, do: world.capabilities || %{}, else: %{}
  end

  @doc """
  Register a discovery, mutating the program's capability graph.
  """
  @spec register_discovery(State.t(), Discovery.t()) :: State.t()
  def register_discovery(%State{} = state, %Discovery{} = discovery) do
    prog_id = discovery.origin_program_id
    program = Map.get(state.research_programs || %{}, prog_id)
    
    if program do
      current_tick = state.economy[:tick] || 0
      
      world = Map.get(state.worlds || %{}, program.world_id)
      world_needs = if world, do: world.needs_vector || %{}, else: %{}
      
      # 1. Decay and prune old capabilities (Selection Layer)
      {pruned_caps, extinctions, extinct_ids} = apply_capability_selection(program.capabilities || %{}, current_tick, world_needs)
      
      # Run 16: Record capability extinctions for ecology tracking
      # PHASE 1 DUAL-WRITE: Emit both legacy ecology events AND new lifecycle events
      Enum.each(extinct_ids, fn cap_id ->
        # Legacy ecology tracking (will be retired after validation)
        record_capability_death(cap_id, current_tick)
        
        # New event-sourced lifecycle registry
        Tiannara.LifecycleRegistry.record_removed(:capability, cap_id, current_tick, :selection, %{
          program_id: program.id,
          world_id: program.world_id
        })
      end)
      
      # 2. Mutate based on discovery
      {mutated_caps, births} = apply_discovery_mutation(pruned_caps, discovery, current_tick, world_needs)
      
      # Update program
      updated_program = %{program | capabilities: mutated_caps}
      updated_programs = Map.put(state.research_programs, prog_id, updated_program)
      
      meta = state.metadata || %{}
      
      # Determine Rediscovery Taxonomy
      # We check if the world already has a capability with this exact ID (Direct)
      # Or if the world has a capability with this base domain (Convergent)
      # Otherwise Novel
      world = Map.get(state.worlds || %{}, program.world_id)
      world_caps = if world, do: world.capabilities || %{}, else: %{}
      
      meta = Enum.reduce(mutated_caps, meta, fn {cap_id, node}, m_acc ->
        if not Map.has_key?(pruned_caps, cap_id) do # It's a new birth in the program
          cond do
            Map.has_key?(world_caps, cap_id) -> 
              Map.update(m_acc, :rediscovery_direct, 1, &(&1 + 1))
            Enum.any?(world_caps, fn {_, w_node} -> 
              Map.keys(w_node.domain_vector) == Map.keys(node.domain_vector)
            end) ->
              Map.update(m_acc, :rediscovery_convergent, 1, &(&1 + 1))
            true ->
              Map.update(m_acc, :rediscovery_novel, 1, &(&1 + 1))
          end
        else
          m_acc
        end
      end)
      
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
  # ===========================================================================

  # Run 16: Helper to record capability births for ecology tracking
  defp record_capability_birth(node_id, parent_nodes, depth, current_tick) do
    # Use deepest parent as lineage identifier, or node itself if root
    lineage_id = 
      case parent_nodes do
        [] -> node_id  # Root capability is its own lineage
        parents -> 
          # For synthesis/paradigm shifts, use first parent as lineage anchor
          hd(parents)
      end
    
    # PHASE 1 DUAL-WRITE: Emit both legacy ecology events AND new lifecycle events
    
    # Legacy ecology tracking (will be retired after validation)
    Tiannara.Ecology.record_birth(node_id, lineage_id, current_tick)
    
    # New event-sourced lifecycle registry with version tracking
    Tiannara.LifecycleRegistry.record_created(:capability, node_id, current_tick, %{
      lineage_id: lineage_id,
      depth: depth,
      parent_ids: parent_nodes,
      version: 1
    })
  end

  # Run 16: Helper to record capability deaths for ecology tracking
  defp record_capability_death(cap_id, current_tick) do
    Tiannara.Ecology.record_death(cap_id, current_tick)
  end

  defp apply_capability_selection(capabilities, current_tick, world_needs) do
    evaluated = capabilities
    |> Enum.map(fn {id, node} ->
      ticks_since_use = current_tick - (node.last_used_tick || 0)
      decay = if ticks_since_use > 3000, do: @selection_decay_rate, else: 0.0
      
      new_selection = max(0.0, node.selection_score - decay)
      extinction_risk = if new_selection < 0.2, do: 1.0 - (new_selection * 5), else: 0.0
      
      updated_node = %{node | 
        selection_score: new_selection,
        extinction_risk: extinction_risk
      }
      # Re-evaluate fitness occasionally or on use? We don't need to re-evaluate it here unless the world needs changed.
      updated_node = update_fitness(updated_node, world_needs)
      {id, updated_node}
    end)
    
    survivors = evaluated
    |> Enum.filter(fn {_id, node} -> node.selection_score > @extinction_threshold end)
    |> Enum.into(%{})
    
    # Run 16: Identify extinct capabilities and record deaths for ecology tracking
    # PHASE 1 DUAL-WRITE: Emit both legacy ecology events AND new lifecycle events
    extinct_ids = Map.keys(capabilities) -- Map.keys(survivors)
    Enum.each(extinct_ids, fn cap_id ->
      # Legacy ecology tracking (will be retired after validation)
      record_capability_death(cap_id, current_tick)
      
      # New event-sourced lifecycle registry
      Tiannara.LifecycleRegistry.record_removed(:capability, cap_id, current_tick, :selection, %{
        extinction_risk: Map.get(capabilities, cap_id).extinction_risk
      })
    end)
    
    extinctions = length(extinct_ids)
    {survivors, extinctions, extinct_ids}
  end

  defp apply_discovery_mutation(capabilities, discovery, current_tick, world_needs) do
    domain_vector = Map.get(discovery.metadata, :domain_vector, %{})
    
    valid_domains = domain_vector
      |> Enum.filter(fn {_, w} -> w >= @capability_unlock_threshold end)
      |> Enum.map(fn {d, w} -> {d, w} end)
      
    cond do
      length(valid_domains) == 0 -> {capabilities, 0}
      length(valid_domains) == 1 ->
        {domain, weight} = hd(valid_domains)
        apply_single_domain_mutation(capabilities, domain, weight, discovery, current_tick, world_needs)
      true ->
        apply_synthesis_mutation(capabilities, valid_domains, discovery, current_tick, world_needs)
    end
  end

  defp apply_single_domain_mutation(capabilities, domain, weight, discovery, current_tick, world_needs) do
    existing_node = Map.get(capabilities, domain)
    rand = :rand.uniform()
    
    if existing_node do
      if rand < 0.05 do
        # Type 4: Paradigm Shift (binary string ID — not atom)
        # PERF: Use binary string ID, not atom — atoms are never GC'd and
        # exhausted the BEAM atom table (1M limit) at ~70k ticks.
        hash = :crypto.hash(:md5, "#{domain}_paradigm_#{:rand.uniform(100000)}") |> Base.encode16() |> binary_part(0, 8)
        new_id = "p_#{hash}"
        # True lineage depth = parent's depth + 1 (not length of parent list)
        new_node = create_node(new_id, [domain], weight * 0.8, discovery, current_tick, world_needs, existing_node.depth + 1)
        
        # Run 16: Record capability birth for ecology tracking
        record_capability_birth(new_id, [domain], existing_node.depth + 1, current_tick)
        
        updated_parent = %{existing_node | child_nodes: Enum.uniq([new_id | existing_node.child_nodes])}
        {Map.put(capabilities, new_id, new_node) |> Map.put(domain, updated_parent), 1}
      else
        if rand < 0.20 do
          # Type 2: Specialization (binary string ID — not atom)
          hash = :crypto.hash(:md5, "#{domain}_spec_#{:rand.uniform(100000)}") |> Base.encode16() |> binary_part(0, 8)
          new_id = "s_#{hash}"
          # True lineage depth = parent's depth + 1
          new_node = create_node(new_id, [domain], existing_node.efficiency + 0.1, discovery, current_tick, world_needs, existing_node.depth + 1)
          
          # Run 16: Record capability birth for ecology tracking
          record_capability_birth(new_id, [domain], existing_node.depth + 1, current_tick)
          
          updated_parent = %{existing_node | child_nodes: Enum.uniq([new_id | existing_node.child_nodes])}
          {Map.put(capabilities, new_id, new_node) |> Map.put(domain, updated_parent), 1}
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
          updated = update_fitness(updated, world_needs)
          {Map.put(capabilities, domain, updated), 0}
        end
      end
    else
      new_node = create_node(domain, [], weight, discovery, current_tick, world_needs)
      
      # Run 16: Record root capability birth for ecology tracking
      record_capability_birth(domain, [], 1, current_tick)
      
      {Map.put(capabilities, domain, new_node), 1}
    end
  end

  defp apply_synthesis_mutation(capabilities, domains, discovery, current_tick, world_needs) do
    parent_ids = Enum.map(domains, fn {d, _} -> d end)
    
    updated_caps = Enum.reduce(parent_ids, capabilities, fn p_id, acc ->
      if node = Map.get(acc, p_id) do
        updated = %{node | 
          usage_count: node.usage_count + 1,
          last_used_tick: current_tick,
          selection_score: min(1.0, node.selection_score + 0.1)
        }
        Map.put(acc, p_id, update_fitness(updated, world_needs))
      else
        # PHASE 1 DUAL-WRITE: Parent node created during synthesis - must track lifecycle
        new_parent_node = create_node(p_id, [], 0.5, discovery, current_tick, world_needs)
        record_capability_birth(p_id, [], 1, current_tick)
        Map.put(acc, p_id, new_parent_node)
      end
    end)
    
    sorted_parents = parent_ids |> Enum.map(&to_string/1) |> Enum.sort() |> Enum.join("_")
    hash = :crypto.hash(:md5, "syn_#{sorted_parents}") |> Base.encode16() |> binary_part(0, 8)
    # Binary string ID — not atom. Synthesis nodes were the largest source of atom
    # table growth (1 per multi-domain discovery). Strings are GC'd; atoms are not.
    syn_id = "syn_#{hash}"
    
    # Update parents to point to new child
    updated_caps = Enum.reduce(parent_ids, updated_caps, fn p_id, acc ->
      node = Map.get(acc, p_id)
      Map.put(acc, p_id, %{node | child_nodes: Enum.uniq([syn_id | node.child_nodes])})
    end)
    
    avg_efficiency = updated_caps
      |> Map.take(parent_ids)
      |> Map.values()
      |> Enum.map(& &1.efficiency)
      |> Enum.sum()
      |> Kernel./(max(1, length(parent_ids)))
    
    # True lineage depth = deepest parent + 1 (not sum of parent list length)
    max_parent_depth =
      updated_caps
      |> Map.take(parent_ids)
      |> Map.values()
      |> Enum.map(fn n -> n.depth || 1 end)
      |> Enum.max(fn -> 1 end)
      
    syn_node = create_node(syn_id, parent_ids, avg_efficiency + 0.2, discovery, current_tick, world_needs, max_parent_depth + 1)
    syn_node = %{syn_node | novelty: 0.9}
    syn_node = update_fitness(syn_node, world_needs)
    
    # Run 16: Record synthesis capability birth for ecology tracking
    record_capability_birth(syn_id, parent_ids, max_parent_depth + 1, current_tick)
    
    {Map.put(updated_caps, syn_id, syn_node), 1}
  end

  # depth: explicit lineage depth. Defaults to 1 + length(parents) if not provided,
  # but call sites should pass the true depth (max_parent_depth + 1) for accuracy.
  defp create_node(id, parents, base_efficiency, discovery, current_tick, world_needs, depth \\ nil) do
    computed_depth = depth || (1 + length(parents))
    
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
      depth: computed_depth,
      discovered_by: discovery.origin_program_id,
      usage_count: 1,
      adoption_count: 1,
      selection_score: 1.0, # Starts fully selected
      last_used_tick: current_tick,
      extinction_risk: 0.0,
      promoted: false
    }
    update_fitness(node, world_needs)
  end

  defp update_fitness(node, world_needs \\ %{}) do
    alignment = if map_size(world_needs) > 0 do
      # Calculate similarity between capability domain vector and world needs
      # Simple dot product mapped to [0.5, 1.5] base scaling
      dot_product = Enum.sum(Enum.map(node.domain_vector || %{}, fn {k, v} -> 
        v * Map.get(world_needs, k, 0.0)
      end))
      # Baseline 0.5 + up to 1.0 from alignment
      min(1.5, 0.5 + dot_product)
    else
      1.0 # Default if no world needs
    end

    # Logarithmic adoption scaling to prevent monopoly runaway
    adoption_multiplier = 1.0 + :math.log(max(2, node.adoption_count))
    
    fitness = node.efficiency * node.reliability * adoption_multiplier * node.novelty * alignment
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
             # INTERVENTION 2: HIGHER PROMOTION THRESHOLDS
             cap.fitness_score > 1.2 and 
             cap.usage_count >= 5 and
             cap.version >= 2
           end)
        |> Enum.group_by(& &1.id)
        
      # Only promote if adopted by at least one lineage (strict reproduction rules make even 1 lineage reaching the threshold difficult)
      promoted_nodes = promotable
        |> Enum.filter(fn {_id, instances} -> length(instances) >= 1 end)
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
        
        # PHASE 1 DUAL-WRITE: Record promotion lifecycle events
        # Note: promote_program_to_world doesn't have tick context, using 0 as placeholder
        Enum.each(Map.keys(promoted_nodes), fn cap_id ->
          Tiannara.LifecycleRegistry.record_promoted(:capability, cap_id, "#{cap_id}_world_#{world_id}", 0, %{
            from_layer: :program,
            to_layer: :world,
            world_id: world_id
          })
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
      
    # INTERVENTION 2: HIGHER PROMOTION THRESHOLDS (Promote to civ level if present in 40% of worlds)
    threshold = max(2, map_size(worlds) * 0.4 |> round())
    
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
    
    # PHASE 1 DUAL-WRITE: Record world→civilization promotion lifecycle events
    # Note: promote_world_to_civilization doesn't have tick context, using 0 as placeholder
    Enum.each(Map.keys(promoted_nodes), fn cap_id ->
      Tiannara.LifecycleRegistry.record_promoted(:capability, "#{cap_id}_world", "#{cap_id}_civ", 0, %{
        from_layer: :world,
        to_layer: :civilization
      })
    end)
    
    # Using Map.put because state struct might not have `capabilities` explicitly defined
    # Actually, TiannaraOS.State needs to be updated in Phase F to have `:capabilities`.
    Map.put(state, :capabilities, merged_civ_caps)
  end

end
