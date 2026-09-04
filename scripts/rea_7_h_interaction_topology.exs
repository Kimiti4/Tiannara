# scripts/rea_7_h_interaction_topology.exs
defmodule Tiannara.REA.InteractionTopologyTest do
  @moduledoc """
  Phase REA-7H: Interaction Topology & Partner Discovery.
  Tests the 3-layer causal stack: Spatial Locality, Stigmergic Resonance, and Memory.
  """
  require Logger

  @epochs 5_000
  @initial_population 100
  
  @metabolic_cost 20.0
  @reproduction_threshold 150.0
  @shallow_harvest_cap 5.0
  @walk_steps 50
  
  @shallow_max_energy 100.0
  @shallow_regen_rate 1.0

  @speciation_threshold 0.165
  @speciation_maturity_epochs 100
  @speciation_min_pop 5
  @generalist_tax_alpha 1.0

  def run() do
    Logger.info("🌌 [REA-7H] Initiating Unified Interaction Topology Test...")
    
    conditions = [
      %{name: "H0: Random Walk", locality: false, pheromones: false, memory: false},
      %{name: "H1: Locality Only", locality: true, pheromones: false, memory: false},
      %{name: "H2: Locality + Pheromones", locality: true, pheromones: true, memory: false},
      %{name: "H3: Locality + Phero + Memory", locality: true, pheromones: true, memory: true}
    ]
    
    Enum.each(conditions, fn config ->
      Logger.info("\n======================================================================================================================")
      Logger.info("🧪 RUNNING CONDITION: #{config.name}")
      Logger.info("======================================================================================================================")
      
      kg = generate_finite_knowledge_graph(1_000)
      base_pop = generate_ecological_population(kg)
      
      initial_registry = Map.new(base_pop, fn a -> 
        {a.lineage_id, %{
          ancestral_weights: a.ancestral_weights, status: :confirmed,
          start_epoch: 0, parent_lineage: nil, max_population: 1
        }}
      end)
      
      state = %{
        novelty_reservoir: 5000.0, compression_reservoir: 500.0, prediction_reservoir: 500.0,
        interactions: %{},
        pruned_ages: [],
        counts: %{speciations: 0, extinctions: 0}
      }
      
      {_pop, _kg, telemetry, _reg, _state} = evolve(
        base_pop, kg, @epochs, initial_registry, [], state, config
      )
      
      print_results(telemetry)
    end)
  end

  defp evolve(pop, kg, 0, registry, telemetry, state, _config), do: {pop, kg, telemetry, registry, state}
  defp evolve([], kg, epochs_remaining, registry, telemetry, state, _config) do
    Logger.warning("☠️ TOTAL EXTINCTION at Epoch #{@epochs - epochs_remaining}.")
    {[], kg, telemetry, registry, state}
  end
  defp evolve(pop, kg, epochs_remaining, registry, telemetry, state, config) do
    current_epoch = @epochs - epochs_remaining + 1
    
    shuffled_pop = Enum.shuffle(pop)
    
    # Teleportation vs Locality
    shuffled_pop = if config.locality do
      shuffled_pop
    else
      Enum.map(shuffled_pop, fn a -> %{a | current_node: :rand.uniform(kg.total_nodes) - 1} end)
    end
    
    initial_metrics = %{
      directed_steps: 0, random_steps: 0,
      total_traces_generated: 0.0, total_traces_consumed: 0.0,
      known_partner_consumptions: 0.0,
      state: %{state | pruned_ages: []} # Clear pruned ages for this epoch
    }
    
    # 1. Foraging & Stigmergic Walk
    {foraged_pop, updated_kg, epoch_metrics} = Enum.reduce(shuffled_pop, {[], kg, initial_metrics}, fn agent, {pop_acc, current_kg, m} ->
      {updated_agent, new_kg, run_metrics} = simulate_unified_walk(agent, current_kg, @walk_steps, m, config)
      {[updated_agent | pop_acc], new_kg, run_metrics}
    end)
    
    # 2. Node Regeneration & Trace Diffusion/Decay
    regenerated_kg = decay_and_diffuse_graph(updated_kg)
    
    # 3. Interaction Ledger Decay
    {pruned_interactions, new_pruned_ages} = decay_interactions(epoch_metrics.state.interactions, epoch_metrics.state.pruned_ages)
    
    # 4. Reservoir Decay
    final_state = %{epoch_metrics.state | 
      novelty_reservoir: epoch_metrics.state.novelty_reservoir * 0.95,
      compression_reservoir: epoch_metrics.state.compression_reservoir * 0.95,
      prediction_reservoir: epoch_metrics.state.prediction_reservoir * 0.95,
      interactions: pruned_interactions,
      pruned_ages: new_pruned_ages
    }
    
    # 5. Metabolism & Selection
    survivors = Enum.reduce(foraged_pop, [], fn agent, acc ->
      new_energy = agent.energy - @metabolic_cost
      if new_energy > 0 do
        [Map.put(agent, :energy, new_energy) | acc]
      else
        acc # Death
      end
    end)
    
    # 6. Speciation
    active_lineage_ids = survivors |> Enum.map(& &1.lineage_id) |> MapSet.new()
    survivors_by_lineage = Enum.group_by(survivors, & &1.lineage_id)
    
    {updated_registry, updated_counts} = Enum.reduce(registry, {registry, final_state.counts}, fn {l_id, l_data}, {reg_acc, counts_acc} ->
      is_active = MapSet.member?(active_lineage_ids, l_id)
      cond do
        not is_active and l_data.status == :confirmed ->
          {Map.delete(reg_acc, l_id), Map.update!(counts_acc, :extinctions, & &1 + 1)}
        not is_active and l_data.status == :candidate ->
          {Map.delete(reg_acc, l_id), counts_acc}
        is_active and l_data.status == :candidate ->
          agents = Map.get(survivors_by_lineage, l_id, [])
          current_pop = length(agents)
          new_max_pop = max(l_data.max_population, current_pop)
          if (current_epoch - l_data.start_epoch >= @speciation_maturity_epochs) do
            centroid = calculate_centroid(agents)
            parent_data = Map.get(reg_acc, l_data.parent_lineage)
            div_passed = if parent_data != nil, do: euclidean_distance(centroid, parent_data.ancestral_weights) > @speciation_threshold, else: true
            pop_passed = new_max_pop >= @speciation_min_pop
            if div_passed and pop_passed do
              new_data = %{l_data | status: :confirmed, ancestral_weights: centroid, max_population: new_max_pop}
              {Map.put(reg_acc, l_id, new_data), Map.update!(counts_acc, :speciations, & &1 + 1)}
            else
              {Map.put(reg_acc, l_id, %{l_data | max_population: new_max_pop}), counts_acc}
            end
          else
            {Map.put(reg_acc, l_id, %{l_data | max_population: new_max_pop}), counts_acc}
          end
        true -> {reg_acc, counts_acc}
      end
    end)
    
    final_state_with_counts = %{final_state | counts: updated_counts}
    
    # 7. Mitosis (Children inherit parent's node)
    {next_gen, final_registry} = Enum.flat_map_reduce(survivors, updated_registry, fn agent, reg_acc ->
      if agent.energy >= @reproduction_threshold do
        split_energy = agent.energy / 2.0
        parent = Map.put(agent, :energy, split_energy)
        
        child_id = "agent_#{System.unique_integer([:positive])}"
        child_weights = mutate_weights(parent.heuristic_weights)
        
        lineage_data = Map.get(reg_acc, parent.lineage_id)
        div = euclidean_distance(child_weights, lineage_data.ancestral_weights)
        
        {final_child_lineage, new_reg} = if div > @speciation_threshold do
          cand_id = "CAND_#{System.unique_integer([:positive])}"
          c_data = %{ancestral_weights: child_weights, status: :candidate, start_epoch: current_epoch, parent_lineage: parent.lineage_id, max_population: 1}
          {cand_id, Map.put(reg_acc, cand_id, c_data)}
        else
          {parent.lineage_id, reg_acc}
        end
        
        child = %{
          id: child_id, lineage_id: final_child_lineage, parent_id: parent.id,
          ancestral_weights: child_weights, heuristic_weights: child_weights, energy: split_energy,
          current_node: parent.current_node # Spatial Inheritance
        }
        {[parent, child], new_reg}
      else
        {[agent], reg_acc}
      end
    end)
    
    # 8. Telemetry
    new_telemetry = if epochs_remaining == 1 or rem(current_epoch, 500) == 0 or current_epoch == 100 do
      ecr = if epoch_metrics.total_traces_generated > 0, do: epoch_metrics.total_traces_consumed / epoch_metrics.total_traces_generated, else: 0.0
      pf = if epoch_metrics.total_traces_consumed > 0, do: epoch_metrics.known_partner_consumptions / epoch_metrics.total_traces_consumed, else: 0.0
      
      {ehl, id, mcc, gcr, cr} = calculate_graph_metrics(pruned_interactions, new_pruned_ages, next_gen)
      
      [record_snapshot(next_gen, current_epoch, ecr, pf, ehl, mcc, id, gcr, cr) | telemetry]
    else
      telemetry
    end
    
    evolve(next_gen, regenerated_kg, epochs_remaining - 1, final_registry, new_telemetry, final_state_with_counts, config)
  end

  # =========================================================================
  # CORE LOGIC
  # =========================================================================

  defp generate_ecological_population(kg) do
    Enum.map(1..@initial_population, fn i ->
      {weights, lineage_id} = cond do
        i <= 80 -> {[0.85, 0.30, 0.30], "L_COMP"}
        i <= 90 -> {[0.30, 0.85, 0.30], "L_EXPL"}
        true    -> {[0.30, 0.30, 0.85], "L_PRED"}
      end
      %{
        id: "init_#{i}", lineage_id: lineage_id, parent_id: nil,
        ancestral_weights: weights, heuristic_weights: weights, energy: 100.0,
        current_node: :rand.uniform(kg.total_nodes) - 1
      }
    end)
  end
  
  defp generate_finite_knowledge_graph(size) do
    :rand.seed(:exsss, {1, 2, 3})
    nodes = Enum.reduce(0..(size-1), %{}, fn i, acc ->
      w_c = :rand.uniform()
      w_e = :rand.uniform()
      w_p = :rand.uniform()
      sum = w_c + w_e + w_p
      
      node = %{
        id: i,
        shortcut_potential: w_c / sum, novelty_value: w_e / sum, consistency: w_p / sum,
        neighbors: Enum.map(1..10, fn _ -> :rand.uniform(size) - 1 end) |> Enum.uniq() |> List.delete(i),
        current_energy: @shallow_max_energy,
        novelty_traces: %{}, compression_traces: %{}, prediction_traces: %{}
      }
      Map.put(acc, i, node)
    end)
    %{nodes: nodes, total_nodes: size}
  end
  
  defp get_target_trace(agent_vec) do
    [c, e, p] = agent_vec
    cond do
      c > e and c > p -> :novelty_traces
      e > c and e > p -> :prediction_traces
      true -> :compression_traces
    end
  end
  
  defp simulate_unified_walk(agent, kg, steps, initial_m, config) do
    [w_comp, w_expl, w_pred] = agent.heuristic_weights
    agent_sum = w_comp + w_expl + w_pred
    agent_vec = if agent_sum > 0, do: [w_comp/agent_sum, w_expl/agent_sum, w_pred/agent_sum], else: [0.33, 0.33, 0.33]
    
    max_entropy = :math.log2(3)
    entropy = agent_vec |> Enum.filter(& &1 > 0) |> Enum.map(fn p -> -p * :math.log2(p) end) |> Enum.sum()
    specialization_bonus = 1.0 + @generalist_tax_alpha * (1.0 - (entropy / max_entropy))
    
    target_trace_type = get_target_trace(agent_vec)
    
    Enum.reduce(1..steps, {agent, kg, initial_m}, fn _, {current_agent, current_kg, m} ->
      current_node_id = current_agent.current_node
      
      # Navigation
      {target_node_id, is_directed} = if config.pheromones do
        queue = Enum.map(current_kg.nodes[current_node_id].neighbors, fn n -> {n, 1, n} end)
        visited = MapSet.new([current_node_id])
        {best_first_step, best_score} = do_bfs_sensing(queue, current_kg, target_trace_type, m.state.interactions, current_agent.id, config, visited, {nil, -1.0})
        
        if best_score > 0.01 and best_first_step != nil do
          {best_first_step, true}
        else
          {Enum.random(current_kg.nodes[current_node_id].neighbors), false}
        end
      else
        {Enum.random(current_kg.nodes[current_node_id].neighbors), false}
      end
      
      node = current_kg.nodes[target_node_id]
      
      # Harvest Energy
      yield = min(node.current_energy, @shallow_harvest_cap)
      
      raw_expl_yield = yield * Enum.at(agent_vec, 1) * node.novelty_value * specialization_bonus
      {actual_pred_consumed, new_pred_traces, pred_authors} = consume_traces(node.prediction_traces, raw_expl_yield, m.state.prediction_reservoir)
      new_pred_res = max(0.0, m.state.prediction_reservoir - (raw_expl_yield - actual_pred_consumed))
      actual_expl_yield = (actual_pred_consumed * 1.0) + ((raw_expl_yield - actual_pred_consumed) * 0.2)
      node_energy_after_expl = node.current_energy - actual_expl_yield
      
      raw_comp_yield = yield * Enum.at(agent_vec, 0) * node.shortcut_potential * specialization_bonus
      {actual_comp_yield, new_nov_traces, nov_authors} = consume_traces(node.novelty_traces, raw_comp_yield, m.state.novelty_reservoir)
      new_nov_res = max(0.0, m.state.novelty_reservoir - (raw_comp_yield - actual_comp_yield))
      node_energy_after_comp = node_energy_after_expl - actual_comp_yield
      
      raw_pred_yield = yield * Enum.at(agent_vec, 2) * node.consistency * specialization_bonus
      {actual_pred_yield, new_comp_traces, comp_authors} = consume_traces(node.compression_traces, raw_pred_yield, m.state.compression_reservoir)
      new_comp_res = max(0.0, m.state.compression_reservoir - (raw_pred_yield - actual_pred_yield))
      node_energy_after_pred = node_energy_after_comp - actual_pred_yield
      
      # Update Interactions Ledger and compute PF
      all_authors = pred_authors ++ nov_authors ++ comp_authors
      
      {new_interactions, added_known_consumptions} = Enum.reduce(all_authors, {m.state.interactions, 0.0}, fn {author_id, amount_consumed}, {acc, known_acc} ->
        if author_id != current_agent.id do
          # Check if known partner
          is_known = if config.memory do
            count = get_in(acc, [{author_id, current_agent.id}, :count]) || 0
            count > 0
          else
            false
          end
          new_known_acc = if is_known, do: known_acc + amount_consumed, else: known_acc
          
          new_acc = Map.update(acc, {author_id, current_agent.id}, %{weight: 1.0, count: 1, age: 0}, fn existing ->
            %{existing | weight: existing.weight + 1.0, count: existing.count + 1}
          end)
          
          {new_acc, new_known_acc}
        else
          {acc, known_acc}
        end
      end)
      
      # Deposit Traces
      final_nov_traces = deposit_trace(new_nov_traces, current_agent.id, actual_expl_yield * 0.5)
      final_comp_traces = deposit_trace(new_comp_traces, current_agent.id, actual_comp_yield * 0.5)
      final_pred_traces = deposit_trace(new_pred_traces, current_agent.id, actual_pred_yield * 0.5)
      
      total_energy_gained = actual_expl_yield + actual_comp_yield + actual_pred_yield
      updated_agent = %{current_agent | energy: current_agent.energy + total_energy_gained, current_node: target_node_id}
      
      updated_node = %{node | 
        current_energy: max(0.0, node_energy_after_pred),
        novelty_traces: final_nov_traces, compression_traces: final_comp_traces, prediction_traces: final_pred_traces
      }
      
      new_kg = %{current_kg | nodes: Map.put(current_kg.nodes, target_node_id, updated_node)}
      
      traces_gen = (actual_expl_yield + actual_comp_yield + actual_pred_yield) * 0.5
      traces_con = actual_pred_consumed + actual_comp_yield + actual_pred_yield
      
      new_m = %{m |
        directed_steps: m.directed_steps + (if is_directed, do: 1, else: 0),
        random_steps: m.random_steps + (if is_directed, do: 0, else: 1),
        total_traces_generated: m.total_traces_generated + traces_gen,
        total_traces_consumed: m.total_traces_consumed + traces_con,
        known_partner_consumptions: m.known_partner_consumptions + added_known_consumptions,
        state: %{m.state | novelty_reservoir: new_nov_res, compression_reservoir: new_comp_res, prediction_reservoir: new_pred_res, interactions: new_interactions}
      }
      {updated_agent, new_kg, new_m}
    end)
  end

  defp do_bfs_sensing([], _kg, _ttype, _inter, _agent, _config, _visited, best), do: best
  defp do_bfs_sensing([{node_id, depth, first_step} | rest], kg, target_trace, interactions, agent_id, config, visited, {best_step, best_score}) do
    if depth > 1 do
      do_bfs_sensing(rest, kg, target_trace, interactions, agent_id, config, visited, {best_step, best_score})
    else
      node = kg.nodes[node_id]
      traces = Map.get(node, target_trace)
      
      score = Enum.reduce(traces, 0.0, fn {author_id, intensity}, acc ->
        pref = if config.memory do
          count = get_in(interactions, [{author_id, agent_id}, :count]) || 0
          1.0 + min(1.0, count / 20.0)
        else
          1.0
        end
        acc + (intensity * pref)
      end)
      
      # Distance penalty (so closer traces are preferred if scores are similar)
      discounted_score = score / depth
      
      new_best = if discounted_score > best_score, do: {first_step, discounted_score}, else: {best_step, best_score}
      
      new_visited = MapSet.put(visited, node_id)
      unvisited_neighbors = Enum.reject(node.neighbors, fn n -> MapSet.member?(new_visited, n) end)
      new_queue = rest ++ Enum.map(unvisited_neighbors, fn n -> {n, depth + 1, first_step} end)
      
      do_bfs_sensing(new_queue, kg, target_trace, interactions, agent_id, config, new_visited, new_best)
    end
  end

  defp consume_traces(trace_map, required, reservoir) do
    if required <= 0.0 do
      {0.0, trace_map, []}
    else
      {actual_consumed, new_map, authors} = Enum.reduce(trace_map, {0.0, %{}, []}, fn {author, intensity}, {acc_c, acc_m, acc_a} ->
        if acc_c >= required do
          {acc_c, Map.put(acc_m, author, intensity), acc_a}
        else
          needed = required - acc_c
          if intensity > needed do
            {required, Map.put(acc_m, author, intensity - needed), [{author, needed} | acc_a]}
          else
            {acc_c + intensity, acc_m, [{author, intensity} | acc_a]}
          end
        end
      end)
      
      if actual_consumed < required and reservoir > 0 do
        remaining = required - actual_consumed
        if reservoir >= remaining do
          {required, new_map, authors}
        else
          {actual_consumed + reservoir, new_map, authors}
        end
      else
        {actual_consumed, new_map, authors}
      end
    end
  end

  defp deposit_trace(trace_map, author_id, reinforcement) do
    if reinforcement > 0.0 do
      current = Map.get(trace_map, author_id, 0.0)
      Map.put(trace_map, author_id, min(10.0, current + reinforcement))
    else
      trace_map
    end
  end

  defp decay_and_diffuse_graph(kg) do
    diffused_nov = diffuse_traces(kg, :novelty_traces)
    diffused_comp = diffuse_traces(kg, :compression_traces)
    diffused_pred = diffuse_traces(kg, :prediction_traces)
    
    new_nodes = Enum.reduce(kg.nodes, kg.nodes, fn {id, node}, acc ->
      new_nov = decay_trace_map(Map.get(diffused_nov, id, %{}), 0.1)
      new_comp = decay_trace_map(Map.get(diffused_comp, id, %{}), 0.1)
      new_pred = decay_trace_map(Map.get(diffused_pred, id, %{}), 0.1)
      
      new_node = %{node | 
        current_energy: min(@shallow_max_energy, node.current_energy + @shallow_regen_rate),
        novelty_traces: new_nov, compression_traces: new_comp, prediction_traces: new_pred
      }
      Map.put(acc, id, new_node)
    end)
    %{kg | nodes: new_nodes}
  end

  defp diffuse_traces(kg, trace_type) do
    Enum.reduce(kg.nodes, %{}, fn {id, node}, node_acc ->
      traces = Map.get(node, trace_type)
      num_neighbors = length(node.neighbors)
      
      # Node keeps 80%
      node_acc = Enum.reduce(traces, node_acc, fn {agent_id, intensity}, acc ->
        kept = intensity * 0.8
        update_in(acc, [Access.key(id, %{}), Access.key(agent_id, 0.0)], &(&1 + kept))
      end)
      
      # Neighbors get 20%
      if num_neighbors > 0 do
        Enum.reduce(traces, node_acc, fn {agent_id, intensity}, acc1 ->
          spread = (intensity * 0.2) / num_neighbors
          Enum.reduce(node.neighbors, acc1, fn n_id, acc2 ->
            update_in(acc2, [Access.key(n_id, %{}), Access.key(agent_id, 0.0)], &(&1 + spread))
          end)
        end)
      else
        node_acc
      end
    end)
  end

  defp decay_trace_map(trace_map, decay_rate) do
    Enum.reduce(trace_map, %{}, fn {author, intensity}, acc ->
      new_int = intensity - decay_rate
      if new_int > 0.1 do
        Map.put(acc, author, new_int)
      else
        acc
      end
    end)
  end

  defp decay_interactions(interactions, pruned_ages) do
    Enum.reduce(interactions, {%{}, pruned_ages}, fn {pair, data}, {acc, ages} ->
      new_weight = data.weight * 0.995
      if new_weight >= 0.1 do
        {Map.put(acc, pair, %{data | weight: new_weight, age: data.age + 1}), ages}
      else
        {acc, [data.age | ages]}
      end
    end)
  end

  defp calculate_graph_metrics(interactions, pruned_ages, pop) do
    if map_size(interactions) == 0 or length(pop) == 0 do
      {0.0, 0.0, 0.0, 0.0, 0.0}
    else
      ehl = if length(pruned_ages) > 0 do
        sorted = Enum.sort(pruned_ages)
        age = Enum.at(sorted, div(length(sorted), 2))
        (age * 1.0) |> Float.round(1)
      else
        active_ages = interactions |> Map.values() |> Enum.map(& &1.age) |> Enum.sort()
        if length(active_ages) > 0, do: Enum.at(active_ages, div(length(active_ages), 2)) * 1.0, else: 0.0
      end
      
      active_agents = Enum.map(pop, & &1.id) |> MapSet.new()
      
      adj_list = Enum.reduce(interactions, %{}, fn {{a, b}, data}, acc ->
        if data.weight > 0.5 and MapSet.member?(active_agents, a) and MapSet.member?(active_agents, b) do
          acc |> Map.update(a, [b], &[b | &1]) |> Map.update(b, [a], &[a | &1])
        else
          acc
        end
      end)
      
      visited = MapSet.new()
      {components, _, _} = Enum.reduce(Map.keys(adj_list), {[], visited, adj_list}, fn node, {comps, vis, adj} ->
        if MapSet.member?(vis, node) do
          {comps, vis, adj}
        else
          {comp_size, new_vis} = bfs(node, adj, vis, 0)
          {[comp_size | comps], new_vis, adj}
        end
      end)
      
      mcc = length(components)
      max_comp_size = if length(components) > 0, do: Enum.max(components), else: 0
      gcr = max_comp_size / length(pop)
      
      possible_edges = length(pop) * (length(pop) - 1)
      id = if possible_edges > 0, do: map_size(adj_list) / possible_edges, else: 0.0
      
      cr = if gcr > 0.5, do: 1.0, else: 0.0
      
      {ehl, id, mcc, gcr, cr}
    end
  end

  defp bfs(start_node, adj_list, visited, size) do
    queue = [start_node]
    visited = MapSet.put(visited, start_node)
    do_bfs(queue, adj_list, visited, size + 1)
  end
  defp do_bfs([], _adj_list, visited, size), do: {size, visited}
  defp do_bfs([current | rest], adj_list, visited, size) do
    neighbors = Map.get(adj_list, current, [])
    {new_queue, new_visited, new_size} = Enum.reduce(neighbors, {rest, visited, size}, fn n, {q, v, s} ->
      if MapSet.member?(v, n) do
        {q, v, s}
      else
        {q ++ [n], MapSet.put(v, n), s + 1}
      end
    end)
    do_bfs(new_queue, adj_list, new_visited, new_size)
  end

  # =========================================================================
  # TELEMETRY
  # =========================================================================
  
  defp record_snapshot(pop, epoch, ecr, pf, ehl, mcc, id, gcr, cr) do
    pop_size = length(pop)
    
    {nc, total_niche_pop} = Enum.reduce(pop, {%{comp: 0, expl: 0, pred: 0}, 0}, fn a, {acc, t} ->
      [w_comp, w_expl, w_pred] = a.ancestral_weights
      sum = w_comp + w_expl + w_pred
      [n_c, n_e, n_p] = if sum > 0, do: [w_comp/sum, w_expl/sum, w_pred/sum], else: [0.33, 0.33, 0.33]
      
      new_acc = cond do
        n_c > 0.5 -> Map.update!(acc, :comp, & &1 + 1)
        n_e > 0.5 -> Map.update!(acc, :expl, & &1 + 1)
        n_p > 0.5 -> Map.update!(acc, :pred, & &1 + 1)
        true -> acc
      end
      {new_acc, t + 1}
    end)
    
    p_comp = if total_niche_pop > 0, do: nc.comp / total_niche_pop, else: 0.0
    p_expl = if total_niche_pop > 0, do: nc.expl / total_niche_pop, else: 0.0
    p_pred = if total_niche_pop > 0, do: nc.pred / total_niche_pop, else: 0.0
    
    %{
      epoch: epoch, pop_size: pop_size,
      ecr: ecr, pf: pf, ehl: ehl, mcc: mcc, id: id, gcr: gcr, cr: cr,
      p_comp: p_comp, p_expl: p_expl, p_pred: p_pred
    }
  end

  defp print_results(telemetry) do
    Logger.info("Epoch | Pop | ECR   | PF    | EHL   | MCC | GCR   | %Comp | %Expl | %Pred")
    Logger.info("-------------------------------------------------------------------------")
    
    Enum.each(Enum.reverse(telemetry), fn r ->
      e = "#{r.epoch}" |> String.pad_trailing(5)
      p = "#{r.pop_size}" |> String.pad_trailing(3)
      ecr = Float.round(r.ecr, 3) |> Float.to_string() |> String.pad_trailing(5)
      pf  = Float.round(r.pf, 3) |> Float.to_string() |> String.pad_trailing(5)
      ehl = "#{r.ehl}" |> String.pad_trailing(5)
      mcc = "#{r.mcc}" |> String.pad_trailing(3)
      gcr = Float.round(r.gcr, 3) |> Float.to_string() |> String.pad_trailing(5)
      
      c_pct = Float.round(r.p_comp * 100, 1) |> Float.to_string() |> String.pad_trailing(5)
      e_pct = Float.round(r.p_expl * 100, 1) |> Float.to_string() |> String.pad_trailing(5)
      p_pct = Float.round(r.p_pred * 100, 1) |> Float.to_string() |> String.pad_trailing(5)
      
      Logger.info("#{e} | #{p} | #{ecr} | #{pf} | #{ehl} | #{mcc} | #{gcr} | #{c_pct} | #{e_pct} | #{p_pct}")
    end)
  end

  defp mutate_weights(weights) do
    Enum.map(weights, fn w -> max(0.0, min(1.0, w + (:rand.uniform() - 0.5) * 0.15)) end)
  end
  defp euclidean_distance(w1, w2) do
    sum_sq = Enum.zip(w1, w2) |> Enum.map(fn {a, b} -> :math.pow(a - b, 2) end) |> Enum.sum()
    :math.sqrt(sum_sq)
  end
  defp calculate_centroid(agents) do
    count = length(agents)
    if count == 0 do
      [0.0, 0.0, 0.0]
    else
      sums = Enum.reduce(agents, [0.0, 0.0, 0.0], fn a, [c, e, p] -> 
        [w1, w2, w3] = a.heuristic_weights
        [c + w1, e + w2, p + w3]
      end)
      Enum.map(sums, & &1 / count)
    end
  end
end

Tiannara.REA.InteractionTopologyTest.run()
