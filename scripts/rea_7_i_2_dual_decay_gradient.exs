defmodule Tiannara.REA.DualDecayGradientTest do
  @moduledoc """
  Phase REA-7I.2: Dual-Decay Gradients.
  Tests stigmergic fields with BFS spatial broadcast and proportional temporal decay.
  """
  require Logger

  @epochs 500
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
    Logger.info("🌌 [REA-7I.2] Initiating Dual-Decay Gradient Test...")
    
    conditions = [
      %{name: "I2.0: Control", pure_traces: false, trust: :uniform, dependency_trust: false},
      %{name: "I2.1: Dual-Decay Stigmergy", pure_traces: true, trust: :uniform, dependency_trust: false},
      %{name: "I2.2: Dual-Decay + Cross-Niche Trust", pure_traces: true, trust: :cross_niche, dependency_trust: false},
      %{name: "I2.3: Full Causal Stack", pure_traces: true, trust: :cross_niche, dependency_trust: true}
    ]
    
    Enum.each(conditions, fn config ->
      Logger.info("\n======================================================================================================================")
      Logger.info("🧪 RUNNING CONDITION: #{config.name}")
      Logger.info("Epoch | Pop | ECR   | CNF   | CN-EHL | EAR   | C-MCC | %Comp | %Expl | %Pred")
      Logger.info("--------------------------------------------------------------------------------")
      
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
        pruned_edges: [],
        counts: %{speciations: 0, extinctions: 0}
      }
      
      evolve(base_pop, kg, @epochs, initial_registry, [], state, config)
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
    
    agent_niches = Map.new(shuffled_pop, fn a -> {a.id, get_niche(a.heuristic_weights)} end)
    
    agent_prefs = Enum.reduce(state.interactions, %{}, fn {{author_id, agent_id}, data}, acc ->
      Map.update(acc, agent_id, %{author_id => data.weight}, &Map.put(&1, author_id, data.weight))
    end)
    
    initial_metrics = %{
      directed_steps: 0, random_steps: 0,
      total_traces_generated: 0.0, total_traces_consumed: 0.0,
      known_partner_consumptions: 0.0,
      state: %{state | pruned_edges: []},
      depositions: %{},
      agent_prefs: agent_prefs
    }
    
    {foraged_pop, updated_kg, epoch_metrics} = Enum.reduce(shuffled_pop, {[], kg, initial_metrics}, fn agent, {pop_acc, current_kg, m} ->
      {updated_agent, new_kg, run_metrics} = simulate_unified_walk(agent, current_kg, @walk_steps, m, config, agent_niches)
      {[updated_agent | pop_acc], new_kg, run_metrics}
    end)
    
    broadcasted_kg = apply_batch_broadcast(updated_kg, epoch_metrics.depositions)
    regenerated_kg = decay_graph(broadcasted_kg)
    
    {pruned_interactions, new_pruned_edges} = decay_interactions(epoch_metrics.state.interactions, epoch_metrics.state.pruned_edges)
    
    final_state = %{epoch_metrics.state | 
      novelty_reservoir: epoch_metrics.state.novelty_reservoir * 0.95,
      compression_reservoir: epoch_metrics.state.compression_reservoir * 0.95,
      prediction_reservoir: epoch_metrics.state.prediction_reservoir * 0.95,
      interactions: pruned_interactions,
      pruned_edges: new_pruned_edges
    }
    
    survivors = Enum.reduce(foraged_pop, [], fn agent, acc ->
      new_energy = agent.energy - @metabolic_cost
      if new_energy > 0, do: [Map.put(agent, :energy, new_energy) | acc], else: acc
    end)
    
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
          current_node: parent.current_node
        }
        {[parent, child], new_reg}
      else
        {[agent], reg_acc}
      end
    end)
    
    new_telemetry = if epochs_remaining == 1 or rem(current_epoch, 100) == 0 do
      ecr = if epoch_metrics.total_traces_generated > 0, do: epoch_metrics.total_traces_consumed / epoch_metrics.total_traces_generated, else: 0.0
      
      {cnf, cn_ehl, ear, cn_mcc, p_comp, p_expl, p_pred} = calculate_graph_metrics(pruned_interactions, new_pruned_edges, next_gen)
      
      snap = record_snapshot(next_gen, current_epoch, ecr, cnf, cn_ehl, ear, cn_mcc, p_comp, p_expl, p_pred)
      print_single_snapshot(snap)
      [snap | telemetry]
    else
      telemetry
    end
    
    evolve(next_gen, regenerated_kg, epochs_remaining - 1, final_registry, new_telemetry, final_state_with_counts, config)
  end

  # =========================================================================
  # CORE LOGIC
  # =========================================================================

  defp get_niche(weights) do
    [w_comp, w_expl, w_pred] = weights
    cond do
      w_comp > w_expl and w_comp > w_pred -> :compression
      w_expl > w_comp and w_expl > w_pred -> :exploration
      true -> :prediction
    end
  end

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
    nodes_init = Enum.reduce(0..(size-1), %{}, fn i, acc ->
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
    
    nodes = Enum.reduce(nodes_init, %{}, fn {id, node}, acc ->
      n1_ids = node.neighbors
      n2_ids = Enum.flat_map(n1_ids, fn n -> nodes_init[n].neighbors end) |> Enum.uniq() |> Kernel.--(n1_ids) |> List.delete(id)
      n3_ids = Enum.flat_map(n2_ids, fn n -> nodes_init[n].neighbors end) |> Enum.uniq() |> Kernel.--(n2_ids) |> Kernel.--(n1_ids) |> List.delete(id)
      
      Map.put(acc, id, Map.put(node, :extended_neighbors, %{1 => n1_ids, 2 => n2_ids, 3 => n3_ids}))
    end)
    %{nodes: nodes, total_nodes: size}
  end
  
  defp get_target_trace(agent_vec) do
    [c, e, p] = agent_vec
    cond do
      c > e and c > p -> :novelty_traces     # Compressor seeks novelty
      e > c and e > p -> :prediction_traces  # Explorer seeks prediction (in full loop)
      true -> :compression_traces            # Predictor seeks compression
    end
  end
  
  defp simulate_unified_walk(agent, kg, steps, initial_m, config, agent_niches) do
    [w_comp, w_expl, w_pred] = agent.heuristic_weights
    agent_sum = w_comp + w_expl + w_pred
    agent_vec = if agent_sum > 0, do: [w_comp/agent_sum, w_expl/agent_sum, w_pred/agent_sum], else: [0.33, 0.33, 0.33]
    agent_niche = get_niche(agent_vec)
    
    max_entropy = :math.log2(3)
    entropy = agent_vec |> Enum.filter(& &1 > 0) |> Enum.map(fn p -> -p * :math.log2(p) end) |> Enum.sum()
    specialization_bonus = 1.0 + @generalist_tax_alpha * (1.0 - (entropy / max_entropy))
    
    target_trace_type = get_target_trace(agent_vec)
    
    Enum.reduce(1..steps, {agent, kg, initial_m}, fn _, {current_agent, current_kg, m} ->
      current_node_id = current_agent.current_node
      
      # Navigation
      agent_prefs = Map.get(m.agent_prefs, current_agent.id, %{})
      current_phi = get_node_phi(current_kg.nodes[current_node_id], target_trace_type, current_agent.id, agent_prefs)
      
      neighbors = current_kg.nodes[current_node_id].neighbors
      neighbor_phis = Enum.map(neighbors, fn n_id -> 
        {n_id, get_node_phi(current_kg.nodes[n_id], target_trace_type, current_agent.id, agent_prefs)}
      end)
      
      {best_node, highest_phi} = Enum.max_by(neighbor_phis, fn {_id, phi} -> phi end, fn -> {nil, -1.0} end)
      
      # Thermal Noise
      {target_node_id, is_directed} = if :rand.uniform() < 0.15 do
        {Enum.random(neighbors), false}
      else
        if highest_phi > current_phi do
          {best_node, true}
        else
          {Enum.random(neighbors), false}
        end
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
      
      # Update Interactions Ledger and compute Trust
      all_authors = pred_authors ++ nov_authors ++ comp_authors
      
      new_interactions = Enum.reduce(all_authors, m.state.interactions, fn {author_id, amount_consumed}, acc ->
        if author_id != current_agent.id and amount_consumed > 0.01 do
          author_niche = Map.get(agent_niches, author_id, :exploration) # fallback
          is_cross_niche = (author_niche != agent_niche)
          
          # 1. Base Gain
          base_gain = 0.1
          
          # 2. Dependency Trust Modification
          trust_gain = if config.dependency_trust do
            base_gain * amount_consumed * 10.0
          else
            base_gain
          end
          
          # 3. Trust Ceilings (Cross-Niche Trust)
          max_cap = if config.trust == :cross_niche do
            if is_cross_niche, do: 1.50, else: 1.05
          else
            1.50 # Uniform trust scaling limit
          end
          
          Map.update(acc, {author_id, current_agent.id}, %{weight: 1.0 + trust_gain, count: 1, age: 0, cross_niche: is_cross_niche}, fn existing ->
            %{existing | weight: min(existing.weight + trust_gain, max_cap), count: existing.count + 1}
          end)
        else
          acc
        end
      end)
      
      # Pure Trace Deposition Logic
      {dep_nov, dep_comp, dep_pred} = if config.pure_traces do
        case agent_niche do
          :exploration -> {actual_expl_yield * 0.5, 0.0, 0.0}
          :compression -> {0.0, actual_comp_yield * 0.5, 0.0}
          :prediction  -> {0.0, 0.0, actual_pred_yield * 0.5}
        end
      else
        {actual_expl_yield * 0.5, actual_comp_yield * 0.5, actual_pred_yield * 0.5}
      end

      total_energy_gained = actual_expl_yield + actual_comp_yield + actual_pred_yield
      updated_agent = %{current_agent | energy: current_agent.energy + total_energy_gained, current_node: target_node_id}
      
      total_energy_gained = actual_expl_yield + actual_comp_yield + actual_pred_yield
      updated_agent = %{current_agent | energy: current_agent.energy + total_energy_gained, current_node: target_node_id}
      
      updated_node = %{node | 
        current_energy: max(0.0, node_energy_after_pred),
        novelty_traces: new_nov_traces, compression_traces: new_comp_traces, prediction_traces: new_pred_traces
      }
      
      new_kg = %{current_kg | nodes: Map.put(current_kg.nodes, target_node_id, updated_node)}
      
      deps1 = add_deposition(m.depositions, target_node_id, :novelty_traces, current_agent.id, dep_nov)
      deps2 = add_deposition(deps1, target_node_id, :compression_traces, current_agent.id, dep_comp)
      deps3 = add_deposition(deps2, target_node_id, :prediction_traces, current_agent.id, dep_pred)
      
      traces_gen = (dep_nov + dep_comp + dep_pred)
      traces_con = actual_pred_consumed + actual_comp_yield + actual_pred_yield
      
      new_m = %{m |
        directed_steps: m.directed_steps + (if is_directed, do: 1, else: 0),
        random_steps: m.random_steps + (if is_directed, do: 0, else: 1),
        total_traces_generated: m.total_traces_generated + traces_gen,
        total_traces_consumed: m.total_traces_consumed + traces_con,
        state: %{m.state | novelty_reservoir: new_nov_res, compression_reservoir: new_comp_res, prediction_reservoir: new_pred_res, interactions: new_interactions},
        depositions: deps3
      }
      {updated_agent, new_kg, new_m}
    end)
  end

  defp get_node_phi(node, trace_type, _agent_id, agent_prefs) do
    traces = Map.get(node, trace_type)
    base_phi = Enum.reduce(traces, 0.0, fn {_, int}, acc -> acc + int end)
    
    bonus_phi = Enum.reduce(agent_prefs, 0.0, fn {author_id, weight}, acc ->
      case Map.get(traces, author_id) do
        nil -> acc
        intensity -> acc + (intensity * (weight - 1.0))
      end
    end)
    
    base_phi + bonus_phi
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

  defp add_deposition(deps, _node_id, _trace_type, _author_id, 0.0), do: deps
  defp add_deposition(deps, node_id, trace_type, author_id, amount) do
    Map.update(deps, node_id, %{trace_type => %{author_id => amount}}, fn node_map ->
      Map.update(node_map, trace_type, %{author_id => amount}, fn trace_map ->
        Map.update(trace_map, author_id, amount, &(&1 + amount))
      end)
    end)
  end

  defp apply_batch_broadcast(kg, depositions) do
    max_intensity = 1.0
    
    new_nodes = Enum.reduce(kg.nodes, kg.nodes, fn {node_id, node}, acc ->
      n1_ids = node.extended_neighbors[1]
      
      sum_traces = fn (ids, multiplier, current_sum) ->
        Enum.reduce(ids, current_sum, fn id, sum_acc ->
          node_deps = Map.get(depositions, id, %{})
          Enum.reduce(node_deps, sum_acc, fn {ttype, authors}, sa1 ->
            Enum.reduce(authors, sa1, fn {author_id, amount}, sa2 ->
              update_in(sa2, [Access.key(ttype, %{}), Access.key(author_id, 0.0)], &(&1 + amount * multiplier))
            end)
          end)
        end)
      end
      
      total_incoming = %{}
      total_incoming = sum_traces.([node_id], 1.0, total_incoming)
      total_incoming = sum_traces.(n1_ids, 0.5488, total_incoming)
      
      if total_incoming == %{} do
        acc
      else
        new_node = Enum.reduce(total_incoming, node, fn {ttype, authors}, n_acc ->
          existing_traces = Map.get(n_acc, ttype)
          new_traces = Enum.reduce(authors, existing_traces, fn {author_id, amount}, t_acc ->
            current = Map.get(t_acc, author_id, 0.0)
            Map.put(t_acc, author_id, min(max_intensity, current + amount))
          end)
          Map.put(n_acc, ttype, new_traces)
        end)
        Map.put(acc, node_id, new_node)
      end
    end)
    %{kg | nodes: new_nodes}
  end

  defp decay_graph(kg) do
    decay_multiplier = :math.exp(-0.10)
    new_nodes = Enum.reduce(kg.nodes, kg.nodes, fn {id, node}, acc ->
      new_nov = decay_trace_map(node.novelty_traces, decay_multiplier)
      new_comp = decay_trace_map(node.compression_traces, decay_multiplier)
      new_pred = decay_trace_map(node.prediction_traces, decay_multiplier)
      
      new_node = %{node | 
        current_energy: min(@shallow_max_energy, node.current_energy + @shallow_regen_rate),
        novelty_traces: new_nov, compression_traces: new_comp, prediction_traces: new_pred
      }
      Map.put(acc, id, new_node)
    end)
    %{kg | nodes: new_nodes}
  end

  defp decay_trace_map(trace_map, decay_multiplier) do
    Enum.reduce(trace_map, %{}, fn {author, intensity}, acc ->
      new_int = intensity * decay_multiplier
      if new_int > 1.0e-4 do
        Map.put(acc, author, new_int)
      else
        acc
      end
    end)
  end

  defp decay_interactions(interactions, pruned_edges) do
    Enum.reduce(interactions, {%{}, pruned_edges}, fn {pair, data}, {acc, edges} ->
      new_weight = data.weight * 0.995 # Slow decay
      if new_weight >= 1.01 do # Base is 1.0, so 1.01 means slightly trusted
        {Map.put(acc, pair, %{data | weight: new_weight, age: data.age + 1}), edges}
      else
        # Edge died
        {acc, [%{age: data.age, cross_niche: data.cross_niche} | edges]}
      end
    end)
  end

  defp calculate_graph_metrics(interactions, pruned_edges, pop) do
    pop_size = length(pop)
    if pop_size == 0 do
      {0.0, 0.0, 0.0, 0, 0.0, 0.0, 0.0}
    else
      {nc, total_niche_pop} = Enum.reduce(pop, {%{compression: 0, exploration: 0, prediction: 0}, 0}, fn a, {acc, t} ->
        niche = get_niche(a.heuristic_weights)
        new_acc = Map.update!(acc, niche, & &1 + 1)
        {new_acc, t + 1}
      end)
      
      p_comp = if total_niche_pop > 0, do: nc.compression / total_niche_pop, else: 0.0
      p_expl = if total_niche_pop > 0, do: nc.exploration / total_niche_pop, else: 0.0
      p_pred = if total_niche_pop > 0, do: nc.prediction / total_niche_pop, else: 0.0

      # CNF (Cross-Niche Fidelity): Interactions that are cross-niche vs all interactions
      active_edges = Map.values(interactions)
      total_active_interactions = Enum.reduce(active_edges, 0, & &1.count + &2)
      cross_niche_interactions = active_edges |> Enum.filter(& &1.cross_niche) |> Enum.reduce(0, & &1.count + &2)
      cnf = if total_active_interactions > 0, do: cross_niche_interactions / total_active_interactions, else: 0.0

      # CN-EHL
      cn_pruned = Enum.filter(pruned_edges, & &1.cross_niche)
      cn_ehl = if length(cn_pruned) > 0 do
        sorted = Enum.sort(Enum.map(cn_pruned, & &1.age))
        (Enum.at(sorted, div(length(sorted), 2)) * 1.0) |> Float.round(1)
      else
        cn_active = Enum.filter(active_edges, & &1.cross_niche) |> Enum.map(& &1.age) |> Enum.sort()
        if length(cn_active) > 0, do: (Enum.at(cn_active, div(length(cn_active), 2)) * 1.0) |> Float.round(1), else: 0.0
      end

      # EAR (Economic Attachment Ratio): Average Cross-Niche Trust / Average Same-Niche Trust
      {sum_cn, count_cn} = active_edges |> Enum.filter(& &1.cross_niche) |> Enum.reduce({0.0, 0}, fn e, {s, c} -> {s + e.weight, c + 1} end)
      {sum_sn, count_sn} = active_edges |> Enum.reject(& &1.cross_niche) |> Enum.reduce({0.0, 0}, fn e, {s, c} -> {s + e.weight, c + 1} end)
      
      avg_cn = if count_cn > 0, do: sum_cn / count_cn, else: 0.0
      avg_sn = if count_sn > 0, do: sum_sn / count_sn, else: 1.0 # 1.0 is baseline
      
      ear = if avg_sn > 0.0, do: avg_cn / avg_sn, else: 0.0

      # CN-MCC
      active_agents = Enum.map(pop, & &1.id) |> MapSet.new()
      adj_list = Enum.reduce(interactions, %{}, fn {{a, b}, data}, acc ->
        if data.weight > 1.01 and data.cross_niche and MapSet.member?(active_agents, a) and MapSet.member?(active_agents, b) do
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
      
      cn_mcc = length(components)

      {cnf, cn_ehl, ear, cn_mcc, p_comp, p_expl, p_pred}
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
  
  defp record_snapshot(pop, epoch, ecr, cnf, cn_ehl, ear, cn_mcc, p_comp, p_expl, p_pred) do
    %{
      epoch: epoch, pop_size: length(pop),
      ecr: ecr, cnf: cnf, cn_ehl: cn_ehl, ear: ear, cn_mcc: cn_mcc,
      p_comp: p_comp, p_expl: p_expl, p_pred: p_pred
    }
  end

  defp print_single_snapshot(snap) do
    comp = Float.round(snap.p_comp * 100, 1)
    expl = Float.round(snap.p_expl * 100, 1)
    pred = Float.round(snap.p_pred * 100, 1)
    
    Logger.info(
      "#{String.pad_trailing(Integer.to_string(snap.epoch), 5)} | " <>
      "#{String.pad_trailing(Integer.to_string(snap.pop_size), 3)} | " <>
      "#{String.pad_trailing(Float.to_string(Float.round(snap.ecr, 3)), 5)} | " <>
      "#{String.pad_trailing(Float.to_string(Float.round(snap.cnf, 3)), 5)} | " <>
      "#{String.pad_trailing(Float.to_string(Float.round(snap.cn_ehl, 1)), 6)} | " <>
      "#{String.pad_trailing(Float.to_string(Float.round(snap.ear, 3)), 5)} | " <>
      "#{String.pad_trailing(Integer.to_string(snap.cn_mcc), 5)} | " <>
      "#{String.pad_trailing(Float.to_string(comp), 5)} | " <>
      "#{String.pad_trailing(Float.to_string(expl), 5)} | " <>
      "#{Float.to_string(pred)}"
    )
  end

  defp print_results(telemetry) do
    Enum.each(Enum.reverse(telemetry), fn snap ->
      print_single_snapshot(snap)
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

Tiannara.REA.DualDecayGradientTest.run()
