# scripts/rea_7_d_mutual_dependency.exs
defmodule Tiannara.REA.MutualDependencyTest do
  @moduledoc """
  Phase REA-7D: Mutual Dependency Closure
  
  Tests if a closed metabolic loop (Exploration <-> Compression <-> Prediction)
  is the mathematically necessary engine of a civilization attractor.
  """
  require Logger

  @epochs 5_000
  @initial_population 100
  
  # Thermodynamic Constants
  @metabolic_cost 20.0
  @reproduction_threshold 150.0
  @harvest_cap 5.0
  @walk_steps 50
  
  @node_max_energy 100.0
  @node_regen_rate 1.0

  @speciation_threshold 0.165
  @speciation_maturity_epochs 100
  @speciation_min_pop 5
  
  @generalist_tax_alpha 1.0

  def run() do
    Logger.info("⭕ [REA-7D] Initiating Mutual Dependency Closure Test...")
    
    kg = generate_finite_knowledge_graph(1_000)
    base_pop = generate_ecological_population()
    
    initial_registry = Map.new(base_pop, fn a -> 
      {a.lineage_id, %{
        ancestral_weights: a.ancestral_weights,
        status: :confirmed,
        start_epoch: 0,
        parent_lineage: nil,
        max_population: 1
      }}
    end)
    
    state = %{
      novelty_reservoir: 5000.0,
      compression_reservoir: 500.0,
      prediction_reservoir: 500.0,
      counts: %{speciations: 0, extinctions: 0}
    }
    
    {_final_pop, _final_kg, telemetry, _reg, _state} = evolve(
      base_pop, kg, @epochs, initial_registry, [], state
    )
    
    print_results(telemetry)
  end

  defp evolve(pop, kg, 0, registry, telemetry, state), do: {pop, kg, telemetry, registry, state}
  defp evolve([], kg, epochs_remaining, registry, telemetry, state) do
    Logger.warning("☠️ TOTAL EXTINCTION at Epoch #{@epochs - epochs_remaining}. Civilization collapse.")
    {[], kg, telemetry, registry, state}
  end
  defp evolve(pop, kg, epochs_remaining, registry, telemetry, state) do
    current_epoch = @epochs - epochs_remaining + 1
    
    shuffled_pop = Enum.shuffle(pop)
    
    initial_metrics = %{
      req_trace: 0.0, act_trace: 0.0, bonus_yield: 0.0, 
      res_consumed: 0.0, node_trace_consumed: 0.0, state: state
    }
    
    # 1. Foraging with Circular Resource Gating
    {foraged_pop, updated_kg, epoch_metrics} = Enum.reduce(shuffled_pop, {[], kg, initial_metrics}, fn agent, {pop_acc, current_kg, m} ->
      {updated_agent, new_kg, run_metrics} = simulate_gated_walk(agent, current_kg, @walk_steps, m.state)
      
      new_metrics = %{
        req_trace: m.req_trace + run_metrics.req_trace,
        act_trace: m.act_trace + run_metrics.act_trace,
        bonus_yield: m.bonus_yield + run_metrics.bonus_yield,
        res_consumed: m.res_consumed + run_metrics.res_consumed,
        node_trace_consumed: m.node_trace_consumed + run_metrics.node_trace_consumed,
        state: run_metrics.state
      }
      
      {[updated_agent | pop_acc], new_kg, new_metrics}
    end)
    
    # 2. Reservoir Decay
    final_state = %{epoch_metrics.state | 
      novelty_reservoir: epoch_metrics.state.novelty_reservoir * 0.95,
      compression_reservoir: epoch_metrics.state.compression_reservoir * 0.95,
      prediction_reservoir: epoch_metrics.state.prediction_reservoir * 0.95
    }
    
    # 3. Resource Regeneration & Trace Decay
    regenerated_kg = regenerate_nodes(updated_kg)
    
    # 4. Metabolism & Selection
    survivors = Enum.reduce(foraged_pop, [], fn agent, acc ->
      new_energy = agent.energy - @metabolic_cost
      if new_energy > 0 do
        [Map.put(agent, :energy, new_energy) | acc]
      else
        acc # Death
      end
    end)
    
    # 5. Speciation Tracking
    active_lineage_ids = survivors |> Enum.map(& &1.lineage_id) |> MapSet.new()
    active_pop_by_lineage = Enum.group_by(survivors, & &1.lineage_id)
    
    {updated_registry, updated_counts} = Enum.reduce(registry, {registry, final_state.counts}, fn {l_id, l_data}, {reg_acc, counts_acc} ->
      is_active = MapSet.member?(active_lineage_ids, l_id)
      
      cond do
        not is_active and l_data.status == :confirmed ->
          {Map.delete(reg_acc, l_id), Map.update!(counts_acc, :extinctions, & &1 + 1)}
          
        not is_active and l_data.status == :candidate ->
          {Map.delete(reg_acc, l_id), counts_acc}
          
        is_active and l_data.status == :candidate ->
          agents = Map.get(active_pop_by_lineage, l_id, [])
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
    
    # 6. Mitosis
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
          ancestral_weights: child_weights, heuristic_weights: child_weights, energy: split_energy
        }
        {[parent, child], new_reg}
      else
        {[agent], reg_acc}
      end
    end)
    
    # 7. Telemetry & CR / DE Calculation
    cr = if epoch_metrics.req_trace > 0, do: epoch_metrics.act_trace / epoch_metrics.req_trace, else: 1.0
    de = if epoch_metrics.act_trace > 0, do: epoch_metrics.bonus_yield / epoch_metrics.act_trace, else: 0.0
    
    new_telemetry = if epochs_remaining == 1 or rem(current_epoch, 100) == 0 do
      [record_snapshot(next_gen, current_epoch, final_registry, updated_counts, cr, de, final_state_with_counts) | telemetry]
    else
      telemetry
    end
    
    evolve(next_gen, regenerated_kg, epochs_remaining - 1, final_registry, new_telemetry, final_state_with_counts)
  end

  # =========================================================================
  # CORE LOGIC
  # =========================================================================

  defp generate_ecological_population() do
    Enum.map(1..@initial_population, fn i ->
      {weights, lineage_id} = cond do
        i <= 80 -> {[0.85, 0.30, 0.30], "L_COMP"}
        i <= 90 -> {[0.30, 0.85, 0.30], "L_EXPL"}
        true    -> {[0.30, 0.30, 0.85], "L_PRED"}
      end
      %{
        id: "init_#{i}", lineage_id: lineage_id, parent_id: nil,
        ancestral_weights: weights, heuristic_weights: weights, energy: 100.0
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
      Map.put(acc, i, %{
        id: i, shortcut_potential: w_c / sum, novelty_value: w_e / sum, consistency: w_p / sum,
        current_energy: @node_max_energy, novelty_trace: 0.0, compression_trace: 0.0, prediction_trace: 0.0,
        neighbors: Enum.map(1..10, fn _ -> :rand.uniform(size) - 1 end) |> Enum.uniq() |> List.delete(i)
      })
    end)
    %{nodes: nodes, total_active_nodes: size}
  end
  
  defp simulate_gated_walk(agent, kg, steps, initial_state) do
    [w_comp, w_expl, w_pred] = agent.heuristic_weights
    agent_sum = w_comp + w_expl + w_pred
    agent_vec = if agent_sum > 0, do: [w_comp/agent_sum, w_expl/agent_sum, w_pred/agent_sum], else: [0.33, 0.33, 0.33]
    
    max_entropy = :math.log2(3)
    entropy = agent_vec |> Enum.filter(& &1 > 0) |> Enum.map(fn p -> -p * :math.log2(p) end) |> Enum.sum()
    specialization_bonus = 1.0 + @generalist_tax_alpha * (1.0 - (entropy / max_entropy))
    
    start_node = :rand.uniform(kg.total_active_nodes) - 1
    
    initial_metrics = %{
      req_trace: 0.0, act_trace: 0.0, bonus_yield: 0.0, 
      res_consumed: 0.0, node_trace_consumed: 0.0, state: initial_state
    }
    
    Enum.reduce(1..steps, {agent, kg, initial_metrics}, fn _, {current_agent, current_kg, m} ->
      target_node_id = Enum.random(current_kg.nodes[start_node].neighbors)
      node = current_kg.nodes[target_node_id]
      
      yield = min(node.current_energy, @harvest_cap)
      
      # 1. EXPLORATION - Requires Prediction Trace (Soft Penalty 0.2)
      raw_expl_yield = yield * Enum.at(agent_vec, 1) * node.novelty_value * specialization_bonus
      {actual_pred_trace_consumed, new_pred_trace, new_pred_res, e_node_consumed, e_res_consumed} = consume_trace(raw_expl_yield, node.prediction_trace, m.state.prediction_reservoir)
      
      actual_expl_yield = (actual_pred_trace_consumed * 1.0) + ((raw_expl_yield - actual_pred_trace_consumed) * 0.2)
      e_bonus_yield = actual_pred_trace_consumed * 0.8 # The bonus provided by the trace over the 0.2 baseline
      
      node_energy_after_expl = node.current_energy - actual_expl_yield
      node_nov_trace = node.novelty_trace + actual_expl_yield
      
      # 2. COMPRESSION - Requires Novelty Trace (Hard Gate 0.0)
      raw_comp_yield = yield * Enum.at(agent_vec, 0) * node.shortcut_potential * specialization_bonus
      {actual_comp_yield, new_nov_trace, new_nov_res, c_node_consumed, c_res_consumed} = consume_trace(raw_comp_yield, node_nov_trace, m.state.novelty_reservoir)
      c_bonus_yield = actual_comp_yield * 1.0 # 100% bonus over 0.0 baseline
      
      node_energy_after_comp = node_energy_after_expl - actual_comp_yield
      node_comp_trace = node.compression_trace + actual_comp_yield
      
      # 3. PREDICTION - Requires Compression Trace (Hard Gate 0.0)
      raw_pred_yield = yield * Enum.at(agent_vec, 2) * node.consistency * specialization_bonus
      {actual_pred_yield, new_comp_trace, new_comp_res, p_node_consumed, p_res_consumed} = consume_trace(raw_pred_yield, node_comp_trace, m.state.compression_reservoir)
      p_bonus_yield = actual_pred_yield * 1.0 # 100% bonus over 0.0 baseline
      
      node_energy_after_pred = node_energy_after_comp - actual_pred_yield
      node_pred_trace_final = new_pred_trace + actual_pred_yield
      
      total_energy_gained = actual_expl_yield + actual_comp_yield + actual_pred_yield
      updated_agent = %{current_agent | energy: current_agent.energy + total_energy_gained}
      
      updated_node = %{node | 
        current_energy: max(0.0, node_energy_after_pred),
        novelty_trace: new_nov_trace,
        compression_trace: new_comp_trace,
        prediction_trace: node_pred_trace_final
      }
      
      new_kg = %{current_kg | nodes: Map.put(current_kg.nodes, target_node_id, updated_node)}
      
      new_m = %{
        req_trace: m.req_trace + raw_expl_yield + raw_comp_yield + raw_pred_yield,
        act_trace: m.act_trace + actual_pred_trace_consumed + actual_comp_yield + actual_pred_yield,
        bonus_yield: m.bonus_yield + e_bonus_yield + c_bonus_yield + p_bonus_yield,
        res_consumed: m.res_consumed + e_res_consumed + c_res_consumed + p_res_consumed,
        node_trace_consumed: m.node_trace_consumed + e_node_consumed + c_node_consumed + p_node_consumed,
        state: %{m.state | novelty_reservoir: new_nov_res, compression_reservoir: new_comp_res, prediction_reservoir: new_pred_res}
      }
      
      {updated_agent, new_kg, new_m}
    end)
  end
  
  defp consume_trace(required, node_trace, reservoir) do
    if required <= 0.0 do
      {0.0, node_trace, reservoir, 0.0, 0.0}
    else
      if node_trace >= required do
        {required, node_trace - required, reservoir, required, 0.0}
      else
        remaining_req = required - node_trace
        if reservoir >= remaining_req do
          {required, 0.0, reservoir - remaining_req, node_trace, remaining_req}
        else
          actual = node_trace + reservoir
          {actual, 0.0, 0.0, node_trace, reservoir}
        end
      end
    end
  end

  defp regenerate_nodes(kg) do
    new_nodes = Enum.into(kg.nodes, %{}, fn {id, node} ->
      {id, %{node | 
        current_energy: min(@node_max_energy, node.current_energy + @node_regen_rate),
        novelty_trace: node.novelty_trace * 0.99,
        compression_trace: node.compression_trace * 0.99,
        prediction_trace: node.prediction_trace * 0.99
      }}
    end)
    %{kg | nodes: new_nodes}
  end

  defp record_snapshot(pop, epoch, registry, counts, cr, de, state) do
    pop_size = length(pop)
    
    confirmed_lineage_ids = pop |> Enum.filter(fn a -> registry[a.lineage_id].status == :confirmed end) |> Enum.map(& &1.lineage_id)
    lineage_counts = Enum.frequencies(confirmed_lineage_ids)
    
    diversity = calculate_shannon(Map.values(lineage_counts), length(confirmed_lineage_ids))
    active_confirmed_species = map_size(lineage_counts)
    
    esr = if counts.speciations == 0, do: counts.extinctions * 1.0, else: counts.extinctions / counts.speciations
    
    # Track niche pop counts to calculate max_share
    {nc, total_niche_pop} = Enum.reduce(pop, {%{comp: 0, expl: 0, pred: 0, gen: 0}, 0}, fn a, {acc, t} ->
      [w_comp, w_expl, w_pred] = a.ancestral_weights
      sum = w_comp + w_expl + w_pred
      [n_c, n_e, n_p] = if sum > 0, do: [w_comp/sum, w_expl/sum, w_pred/sum], else: [0.33, 0.33, 0.33]
      
      new_acc = cond do
        n_c > 0.5 -> Map.update!(acc, :comp, & &1 + 1)
        n_e > 0.5 -> Map.update!(acc, :expl, & &1 + 1)
        n_p > 0.5 -> Map.update!(acc, :pred, & &1 + 1)
        true -> Map.update!(acc, :gen, & &1 + 1)
      end
      {new_acc, t + 1}
    end)
    
    max_share = if total_niche_pop > 0 do
      max_count = Enum.max(Map.values(nc))
      max_count / total_niche_pop
    else
      0.0
    end
    
    %{
      epoch: epoch, pop_size: pop_size, diversity: diversity, active_species: active_confirmed_species,
      speciations: counts.speciations, extinctions: counts.extinctions, esr: esr,
      cr: cr, de: de, max_share: max_share,
      nov_res: state.novelty_reservoir, comp_res: state.compression_reservoir, pred_res: state.prediction_reservoir,
      niche_census: nc
    }
  end

  defp print_results(telemetry) do
    Logger.info("\n================================================================================================================")
    Logger.info("⭕ REA-7D MUTUAL DEPENDENCY MATRIX (Circular Closed Loop)")
    Logger.info("================================================================================================================")
    Logger.info("Epoch | Pop | Shannon | Spc | CR    | DE    | Max Niche % | Nov Res | C/P Res | Comp | Expl | Pred | Gen")
    Logger.info("----------------------------------------------------------------------------------------------------------------")
    
    Enum.each(Enum.reverse(telemetry), fn r ->
      e = "#{r.epoch}" |> String.pad_trailing(5)
      p = "#{r.pop_size}" |> String.pad_trailing(3)
      d = Float.round(r.diversity, 3) |> Float.to_string() |> String.pad_trailing(7)
      spc = "#{r.active_species}" |> String.pad_trailing(3)
      cr = Float.round(r.cr, 3) |> Float.to_string() |> String.pad_trailing(5)
      de = Float.round(r.de, 3) |> Float.to_string() |> String.pad_trailing(5)
      
      pct = Float.round(r.max_share * 100, 1) |> Float.to_string() |> String.pad_trailing(5)
      m_sh = "#{pct}%" |> String.pad_trailing(11)
      
      nr = Float.round(r.nov_res, 1) |> Float.to_string() |> String.pad_trailing(7)
      cpr = Float.round(r.comp_res, 1) |> Float.to_string() |> String.pad_trailing(7)
      
      nc = r.niche_census
      Logger.info("#{e} | #{p} | #{d} | #{spc} | #{cr} | #{de} | #{m_sh} | #{nr} | #{cpr} | #{nc.comp}   | #{nc.expl}   | #{nc.pred}   | #{nc.gen}")
    end)
    Logger.info("================================================================================================================")
  end

  # =========================================================================
  # HELPER FUNCTIONS
  # =========================================================================

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
  defp calculate_shannon(counts, total) do
    if total == 0 do
      0.0
    else
      counts |> Enum.filter(& &1 > 0) |> Enum.map(fn c -> p = c / total; -p * :math.log2(p) end) |> Enum.sum()
    end
  end
end

Tiannara.REA.MutualDependencyTest.run()
