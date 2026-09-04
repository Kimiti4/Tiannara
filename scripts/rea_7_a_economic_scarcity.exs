# scripts/rea_7_a_economic_scarcity.exs
defmodule Tiannara.REA.EconomicScarcityTest do
  @moduledoc """
  Phase REA-7A: Economic Thermodynamics (Scarcity Only).
  
  Replaces Darwinian fitness with physical energy ledgers. 
  Nodes possess finite, regenerating energy. Agents must harvest energy to offset
  metabolic costs. Tests whether physical scarcity alone can prevent monoculture collapse.
  """
  require Logger

  @epochs 2_000
  @initial_population 100
  @hmt_frequency 0.20
  
  # Thermodynamic Constants
  @metabolic_cost 20.0
  @reproduction_threshold 150.0
  @harvest_cap 5.0
  @walk_steps 50
  
  @node_max_energy 100.0
  @node_regen_rate 1.0

  def run() do
    Logger.info("🔥 [REA-7A] Initiating Economic Thermodynamics (Scarcity Only)...")
    
    kg = generate_finite_knowledge_graph(1_000)
    base_pop = generate_ecological_population()
    lineage_registry = initialize_lineage_registry(base_pop)
    
    {_final_pop, _final_kg, telemetry, _reg} = evolve_thermodynamic(
      base_pop, kg, @epochs, lineage_registry, %{}, [], []
    )
    
    print_results(telemetry)
  end

  defp evolve_thermodynamic(pop, kg, 0, registry, _persistence_map, telemetry, _lineage_lifespans), do: {pop, kg, telemetry, registry}
  defp evolve_thermodynamic([], kg, epochs_remaining, registry, pers_map, telemetry, lifespans) do
    Logger.warning("☠️ TOTAL EXTINCTION at Epoch #{@epochs - epochs_remaining}. Thermodynamic collapse.")
    {[], kg, telemetry, registry}
  end
  defp evolve_thermodynamic(pop, kg, epochs_remaining, registry, persistence_map, telemetry, lineage_lifespans) do
    current_epoch = @epochs - epochs_remaining + 1
    
    # Randomize traversal order so agents don't always harvest in the same sequence
    shuffled_pop = Enum.shuffle(pop)
    
    # 1. Foraging (Energy Harvest)
    {foraged_pop, updated_kg} = Enum.map_reduce(shuffled_pop, kg, fn agent, current_kg ->
      {harvested_energy, new_kg} = simulate_finite_walk(agent.heuristic_weights, current_kg, @walk_steps)
      updated_agent = Map.update!(agent, :energy, &(&1 + harvested_energy))
      {updated_agent, new_kg}
    end)
    
    # 2. Resource Regeneration
    regenerated_kg = regenerate_nodes(updated_kg)
    
    # 3. Metabolism & Selection (Death)
    survivors = Enum.reduce(foraged_pop, [], fn agent, acc ->
      new_energy = agent.energy - @metabolic_cost
      if new_energy > 0 do
        [Map.put(agent, :energy, new_energy) | acc]
      else
        acc # Agent dies (garbage collected)
      end
    end)
    
    # Update lineage lifespans (extinction tracking)
    active_lineages = survivors |> Enum.map(& &1.lineage_id) |> MapSet.new()
    {updated_lifespans, extinct_count} = update_lifespans(lineage_lifespans, active_lineages, current_epoch)
    
    # 4. Mitosis (Reproduction)
    next_gen = Enum.flat_map(survivors, fn agent ->
      if agent.energy >= @reproduction_threshold do
        # Clone and split wealth
        split_energy = agent.energy / 2.0
        parent = Map.put(agent, :energy, split_energy)
        
        child_id = "agent_#{System.unique_integer([:positive])}"
        child_weights = mutate_weights(parent.heuristic_weights)
        
        child = %{
          id: child_id,
          lineage_id: parent.lineage_id,
          parent_id: parent.id,
          ancestral_weights: parent.ancestral_weights,
          original_niche: parent.original_niche,
          heuristic_weights: child_weights,
          energy: split_energy
        }
        [parent, child]
      else
        [agent]
      end
    end)
    
    # 5. Telemetry
    new_telemetry = if epochs_remaining == 1 or rem(current_epoch, 100) == 0 do
      [record_snapshot(next_gen, current_epoch, updated_lifespans, extinct_count, regenerated_kg) | telemetry]
    else
      telemetry
    end
    
    evolve_thermodynamic(next_gen, regenerated_kg, epochs_remaining - 1, registry, persistence_map, new_telemetry, updated_lifespans)
  end

  # =========================================================================
  # CORE LOGIC
  # =========================================================================

  defp generate_ecological_population() do
    Enum.map(1..@initial_population, fn i ->
      {weights, niche, lineage_id} = cond do
        i <= 80 -> {[0.85, 0.30, 0.30, 0.30], :compression, "L_COMP"}
        i <= 90 -> {[0.30, 0.85, 0.30, 0.30], :exploration, "L_EXPL"}
        true    -> {[0.30, 0.30, 0.85, 0.30], :prediction,  "L_PRED"}
      end
      
      %{
        id: "init_#{i}", lineage_id: lineage_id, parent_id: nil,
        ancestral_weights: weights, original_niche: niche, heuristic_weights: weights,
        energy: 100.0 # Initial thermodynamic endowment
      }
    end)
  end
  
  defp generate_finite_knowledge_graph(size) do
    :rand.seed(:exsss, {1, 2, 3})
    nodes = Enum.reduce(0..(size-1), %{}, fn i, acc ->
      Map.put(acc, i, %{
        id: i, 
        shortcut_potential: :rand.uniform(), 
        novelty_value: :rand.uniform(), 
        consistency: :rand.uniform(),
        current_energy: @node_max_energy,
        neighbors: Enum.map(1..10, fn _ -> :rand.uniform(size) - 1 end) |> Enum.uniq() |> List.delete(i)
      })
    end)
    %{nodes: nodes, total_active_nodes: size}
  end
  
  defp simulate_finite_walk([w_comp, w_expl, w_pred, w_gen], kg, steps) do
    start_node = :rand.uniform(kg.total_active_nodes) - 1
    
    {total_harvest, final_kg, _} = Enum.reduce(1..steps, {0.0, kg, MapSet.new([start_node])}, fn _, {harvested, current_kg, visited} ->
      current_node_id = Enum.random(MapSet.to_list(visited))
      current_node = current_kg.nodes[current_node_id]
      
      best_neighbor_id = current_node.neighbors |> Enum.max_by(fn n_id -> 
        neighbor = current_kg.nodes[n_id]
        score = (w_comp * neighbor.shortcut_potential) + (w_expl * neighbor.novelty_value) + (w_pred * neighbor.consistency) + (w_gen * :rand.uniform())
        # Prefer nodes that still have energy
        energy_bonus = if neighbor.current_energy > 0, do: 1.0, else: -5.0
        score + energy_bonus
      end, fn -> Enum.random(current_node.neighbors) end)
      
      target_node = current_kg.nodes[best_neighbor_id]
      
      # Harvest energy
      yield = min(target_node.current_energy, @harvest_cap)
      updated_node = Map.put(target_node, :current_energy, target_node.current_energy - yield)
      updated_nodes = Map.put(current_kg.nodes, best_neighbor_id, updated_node)
      
      {harvested + yield, %{current_kg | nodes: updated_nodes}, MapSet.put(visited, best_neighbor_id)}
    end)
    
    {total_harvest, final_kg}
  end

  defp regenerate_nodes(kg) do
    new_nodes = Enum.into(kg.nodes, %{}, fn {id, node} ->
      {id, Map.put(node, :current_energy, min(@node_max_energy, node.current_energy + @node_regen_rate))}
    end)
    %{kg | nodes: new_nodes}
  end

  defp update_lifespans(lifespans, active_lineages, current_epoch) do
    # For every active lineage, if it's not in lifespans, add it. If it is, update its end_epoch.
    updated = Enum.reduce(active_lineages, lifespans, fn lin, acc ->
      case List.keyfind(acc, lin, 0) do
        {^lin, start_epoch, _end_epoch, is_extinct} -> 
          List.keyreplace(acc, lin, 0, {lin, start_epoch, current_epoch, is_extinct})
        nil -> 
          [{lin, current_epoch, current_epoch, false} | acc]
      end
    end)
    
    # Mark extinct
    final = Enum.map(updated, fn {lin, s, e, extinct} ->
      if not extinct and not MapSet.member?(active_lineages, lin) do
        {lin, s, e, true}
      else
        {lin, s, e, extinct}
      end
    end)
    
    extinct_count = Enum.count(final, fn {_, _, _, ext} -> ext end)
    {final, extinct_count}
  end

  defp record_snapshot(pop, epoch, lifespans, extinct_count, kg) do
    pop_size = length(pop)
    
    lineage_counts = Enum.frequencies(Enum.map(pop, & &1.lineage_id))
    gini = calculate_gini(Map.values(lineage_counts))
    diversity = calculate_shannon(Map.values(lineage_counts), pop_size)
    
    energies = Enum.map(pop, & &1.energy)
    energy_gini = calculate_gini(energies)
    
    node_energies = Enum.map(Map.values(kg.nodes), & &1.current_energy)
    resource_gini = calculate_gini(node_energies)
    
    extinct_lifespans = lifespans |> Enum.filter(fn {_, _, _, ext} -> ext end) |> Enum.map(fn {_, s, e, _} -> e - s end)
    mean_lifespan = mean(extinct_lifespans)
    
    %{
      epoch: epoch,
      pop_size: pop_size,
      diversity: diversity,
      gini: gini,
      energy_gini: energy_gini,
      resource_gini: resource_gini,
      extinct_count: extinct_count,
      mean_lifespan: mean_lifespan
    }
  end

  defp print_results(telemetry) do
    Logger.info("\n=====================================================================================================")
    Logger.info("🔥 REA-7A ECONOMIC THERMODYNAMICS MATRIX (SCARCITY ONLY)")
    Logger.info("=====================================================================================================")
    Logger.info("Epoch | Pop Size | Shannon | WTA Gini | Energy Gini | Rsrc Gini | Extinct # | Mean Lifespan")
    Logger.info("-----------------------------------------------------------------------------------------------------")
    
    Enum.each(Enum.reverse(telemetry), fn r ->
      e = "#{r.epoch}" |> String.pad_trailing(5)
      p = "#{r.pop_size}" |> String.pad_trailing(8)
      d = Float.round(r.diversity, 3) |> Float.to_string() |> String.pad_trailing(7)
      g = Float.round(r.gini, 3) |> Float.to_string() |> String.pad_trailing(8)
      eg = Float.round(r.energy_gini, 3) |> Float.to_string() |> String.pad_trailing(11)
      rg = Float.round(r.resource_gini, 3) |> Float.to_string() |> String.pad_trailing(9)
      ex = "#{r.extinct_count}" |> String.pad_trailing(9)
      ml = Float.round(r.mean_lifespan, 1) |> Float.to_string()
      
      Logger.info("#{e} | #{p} | #{d} | #{g} | #{eg} | #{rg} | #{ex} | #{ml}")
    end)
    Logger.info("=====================================================================================================")
  end

  # =========================================================================
  # HELPER FUNCTIONS
  # =========================================================================

  defp mean(list), do: if(length(list) == 0, do: 0.0, else: Enum.sum(list) / length(list))
  defp mutate_weights(weights) do
    Enum.map(weights, fn w -> max(0.0, min(1.0, w + (:rand.uniform() - 0.5) * 0.15)) end)
  end
  defp initialize_lineage_registry(pop) do
    Map.new(pop, fn agent -> {agent.lineage_id, %{original_niche: agent.original_niche}} end)
  end
  defp calculate_gini(counts) do
    n = length(counts)
    if n <= 1 do
      0.0
    else
      sorted = Enum.sort(counts)
      total = Enum.sum(sorted)
      if total == 0, do: 0.0, else: (((2.0 * (Enum.with_index(sorted, 1) |> Enum.map(fn {v, i} -> i * v end) |> Enum.sum())) / (n * total)) - ((n + 1.0) / n))
    end
  end
  defp calculate_shannon(counts, total) do
    if total == 0 do
      0.0
    else
      counts
      |> Enum.filter(& &1 > 0)
      |> Enum.map(fn c -> p = c / total; -p * :math.log2(p) end)
      |> Enum.sum()
    end
  end
end

Tiannara.REA.EconomicScarcityTest.run()
