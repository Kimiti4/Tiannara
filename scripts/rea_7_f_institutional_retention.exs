# scripts/rea_7_f_institutional_retention.exs
defmodule Tiannara.REA.InstitutionalRetentionTest do
  @moduledoc """
  Phase REA-7F: Institutional Retention
  
  Tests if civilization can preserve its surplus through active property rights,
  maintenance costs, and ownership dilution, preventing the Grave-Robber phenomenon.
  """
  require Logger

  @epochs 5_000
  @initial_population 100
  
  # Thermodynamic Constants
  @metabolic_cost 20.0
  @reproduction_threshold 150.0
  @shallow_harvest_cap 5.0
  @eden_harvest_cap 50.0
  @walk_steps 50
  
  @shallow_max_energy 100.0
  @shallow_regen_rate 1.0
  
  @eden_max_energy 1000.0
  @eden_base_regen 10.0 # 5.0 to Commons, 5.0 to Dividends
  @eden_initial_energy 700.0
  @dkn_immediate_reward 100.0 # Per contributor (300 total)

  @speciation_threshold 0.165
  @speciation_maturity_epochs 100
  @speciation_min_pop 5
  
  @generalist_tax_alpha 1.0

  def run() do
    Logger.info("🏛️ [REA-7F] Initiating Institutional Retention Test...")
    
    kg = generate_finite_knowledge_graph(1_000)
    base_pop = generate_ecological_population()
    
    initial_registry = Map.new(base_pop, fn a -> 
      {a.lineage_id, %{
        ancestral_weights: a.ancestral_weights, status: :confirmed,
        start_epoch: 0, parent_lineage: nil, max_population: 1
      }}
    end)
    
    state = %{
      novelty_reservoir: 5000.0, compression_reservoir: 500.0, prediction_reservoir: 500.0,
      counts: %{speciations: 0, extinctions: 0}
    }
    
    {_final_pop, _final_kg, telemetry, _reg, _state} = evolve(
      base_pop, kg, @epochs, initial_registry, [], state
    )
    
    print_results(telemetry)
  end

  defp evolve(pop, kg, 0, registry, telemetry, state), do: {pop, kg, telemetry, registry, state}
  defp evolve([], kg, epochs_remaining, registry, telemetry, state) do
    Logger.warning("☠️ TOTAL EXTINCTION at Epoch #{@epochs - epochs_remaining}. Institutional collapse.")
    {[], kg, telemetry, registry, state}
  end
  defp evolve(pop, kg, epochs_remaining, registry, telemetry, state) do
    current_epoch = @epochs - epochs_remaining + 1
    
    # Reservoir wipe at Epoch 1000
    state = if current_epoch == 1000 do
      %{state | novelty_reservoir: 0.0, compression_reservoir: 0.0, prediction_reservoir: 0.0}
    else
      state
    end
    
    shuffled_pop = Enum.shuffle(pop)
    
    initial_metrics = %{
      req_trace: 0.0, act_trace: 0.0, shallow_energy_gen: 0.0, eden_energy_gen: 0.0,
      state: state, activated_dkns: 0, total_immediate_dividends: 0.0,
      immediate_ledger: %{}
    }
    
    # 1. Foraging
    {foraged_pop_raw, updated_kg, epoch_metrics} = Enum.reduce(shuffled_pop, {[], kg, initial_metrics}, fn agent, {pop_acc, current_kg, m} ->
      {updated_agent, new_kg, run_metrics} = simulate_gated_walk(agent, current_kg, @walk_steps, m)
      {[updated_agent | pop_acc], new_kg, run_metrics}
    end)
    
    # 2. Resource Regeneration, Dilution, & Dividend Calculation
    {regenerated_kg, global_dividends, ownership_changed, total_ownership_pool, fp_sum, maintained_edens, active_edens, total_built_edens} = process_nodes(updated_kg)
    
    # 3. Apply Immediate Dividends & Active Decay
    foraged_pop = Enum.map(foraged_pop_raw, fn agent ->
      imm = Map.get(epoch_metrics.immediate_ledger, agent.id, 0.0)
      new_activity = max(0.0, agent.activity_score - 0.01)
      %{agent | energy: agent.energy + imm, activity_score: new_activity}
    end)
    
    # 4. Apply Global Institutional Dividends
    # Group active agents by lineage
    active_pop_by_lineage = foraged_pop 
      |> Enum.filter(&(&1.activity_score > 0.0))
      |> Enum.group_by(& &1.lineage_id)
      
    total_distributed_dividends = Enum.reduce(global_dividends, 0.0, fn {_, div}, acc -> acc + div end)
      
    foraged_pop = Enum.map(foraged_pop, fn agent ->
      if agent.activity_score > 0.0 do
        lineage_div = Map.get(global_dividends, agent.lineage_id, 0.0)
        lineage_pop = length(Map.get(active_pop_by_lineage, agent.lineage_id, []))
        if lineage_pop > 0 do
          %{agent | energy: agent.energy + (lineage_div / lineage_pop)}
        else
          agent
        end
      else
        agent
      end
    end)
    
    # 5. Reservoir Decay
    final_state = %{epoch_metrics.state | 
      novelty_reservoir: epoch_metrics.state.novelty_reservoir * 0.95,
      compression_reservoir: epoch_metrics.state.compression_reservoir * 0.95,
      prediction_reservoir: epoch_metrics.state.prediction_reservoir * 0.95
    }
    
    # 6. Metabolism & Selection
    survivors = Enum.reduce(foraged_pop, [], fn agent, acc ->
      new_energy = agent.energy - @metabolic_cost
      if new_energy > 0 do
        [Map.put(agent, :energy, new_energy) | acc]
      else
        acc # Death
      end
    end)
    
    # 7. Speciation
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
    
    # 8. Mitosis
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
          ancestral_weights: child_weights, heuristic_weights: child_weights, energy: split_energy, activity_score: 1.0
        }
        {[parent, child], new_reg}
      else
        {[agent], reg_acc}
      end
    end)
    
    # 9. Telemetry 
    cr = if epoch_metrics.req_trace > 0, do: epoch_metrics.act_trace / epoch_metrics.req_trace, else: 1.0
    
    total_energy_gen = epoch_metrics.shallow_energy_gen + epoch_metrics.eden_energy_gen + epoch_metrics.total_immediate_dividends + total_distributed_dividends
    cd = if total_energy_gen > 0, do: (epoch_metrics.eden_energy_gen + epoch_metrics.total_immediate_dividends + total_distributed_dividends) / total_energy_gen, else: 0.0
    
    itr = if total_ownership_pool > 0, do: ownership_changed / total_ownership_pool, else: 0.0
    idr = if total_energy_gen > 0, do: total_distributed_dividends / total_energy_gen, else: 0.0
    imr = if total_built_edens > 0, do: maintained_edens / total_built_edens, else: 0.0
    fp = if active_edens > 0, do: fp_sum / active_edens, else: 0.0
    
    new_telemetry = if epochs_remaining == 1 or rem(current_epoch, 100) == 0 do
      [record_snapshot(next_gen, current_epoch, final_registry, cr, cd, itr, idr, imr, fp, regenerated_kg, final_state_with_counts) | telemetry]
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
        ancestral_weights: weights, heuristic_weights: weights, energy: 100.0, activity_score: 1.0
      }
    end)
  end
  
  defp generate_finite_knowledge_graph(size) do
    :rand.seed(:exsss, {1, 2, 3})
    nodes = Enum.reduce(0..(size-1), %{}, fn i, acc ->
      type = if rem(i, 10) == 0, do: :deep_locked, else: :shallow
      
      w_c = :rand.uniform()
      w_e = :rand.uniform()
      w_p = :rand.uniform()
      sum = w_c + w_e + w_p
      
      base_node = %{
        id: i, type: type,
        shortcut_potential: w_c / sum, novelty_value: w_e / sum, consistency: w_p / sum,
        neighbors: Enum.map(1..10, fn _ -> :rand.uniform(size) - 1 end) |> Enum.uniq() |> List.delete(i)
      }
      
      node = if type == :shallow do
        Map.merge(base_node, %{
          current_energy: @shallow_max_energy, novelty_trace: 0.0, compression_trace: 0.0, prediction_trace: 0.0
        })
      else
        Map.merge(base_node, %{
          current_energy: 0.0, novelty_trace: 0.0, compression_trace: 0.0, prediction_trace: 0.0,
          contributors: %{nov: nil, comp: nil, pred: nil},
          founder_lineages: [], cap_table: %{}, health: 100.0, maintainers_this_epoch: []
        })
      end
      
      Map.put(acc, i, node)
    end)
    %{nodes: nodes, total_active_nodes: size}
  end
  
  defp simulate_gated_walk(agent, kg, steps, initial_m) do
    [w_comp, w_expl, w_pred] = agent.heuristic_weights
    agent_sum = w_comp + w_expl + w_pred
    agent_vec = if agent_sum > 0, do: [w_comp/agent_sum, w_expl/agent_sum, w_pred/agent_sum], else: [0.33, 0.33, 0.33]
    
    max_entropy = :math.log2(3)
    entropy = agent_vec |> Enum.filter(& &1 > 0) |> Enum.map(fn p -> -p * :math.log2(p) end) |> Enum.sum()
    specialization_bonus = 1.0 + @generalist_tax_alpha * (1.0 - (entropy / max_entropy))
    
    start_node = :rand.uniform(kg.total_active_nodes) - 1
    
    Enum.reduce(1..steps, {agent, kg, initial_m}, fn _, {current_agent, current_kg, m} ->
      target_node_id = Enum.random(current_kg.nodes[start_node].neighbors)
      node = current_kg.nodes[target_node_id]
      
      cond do
        node.type == :shallow ->
          yield = min(node.current_energy, @shallow_harvest_cap)
          
          # 1. EXPLORATION
          raw_expl_yield = yield * Enum.at(agent_vec, 1) * node.novelty_value * specialization_bonus
          {actual_pred_trace_consumed, new_pred_trace, new_pred_res} = consume_trace(raw_expl_yield, node.prediction_trace, m.state.prediction_reservoir)
          actual_expl_yield = (actual_pred_trace_consumed * 1.0) + ((raw_expl_yield - actual_pred_trace_consumed) * 0.2)
          node_energy_after_expl = node.current_energy - actual_expl_yield
          node_nov_trace = node.novelty_trace + actual_expl_yield
          
          # 2. COMPRESSION
          raw_comp_yield = yield * Enum.at(agent_vec, 0) * node.shortcut_potential * specialization_bonus
          {actual_comp_yield, new_nov_trace, new_nov_res} = consume_trace(raw_comp_yield, node_nov_trace, m.state.novelty_reservoir)
          node_energy_after_comp = node_energy_after_expl - actual_comp_yield
          node_comp_trace = node.compression_trace + actual_comp_yield
          
          # 3. PREDICTION
          raw_pred_yield = yield * Enum.at(agent_vec, 2) * node.consistency * specialization_bonus
          {actual_pred_yield, new_comp_trace, new_comp_res} = consume_trace(raw_pred_yield, node_comp_trace, m.state.compression_reservoir)
          node_energy_after_pred = node_energy_after_comp - actual_pred_yield
          node_pred_trace_final = new_pred_trace + actual_pred_yield
          
          total_energy_gained = actual_expl_yield + actual_comp_yield + actual_pred_yield
          updated_agent = %{current_agent | energy: current_agent.energy + total_energy_gained}
          
          updated_agent = if total_energy_gained > 0, do: %{updated_agent | activity_score: 1.0}, else: updated_agent
          
          updated_node = %{node | 
            current_energy: max(0.0, node_energy_after_pred),
            novelty_trace: new_nov_trace, compression_trace: new_comp_trace, prediction_trace: node_pred_trace_final
          }
          
          new_kg = %{current_kg | nodes: Map.put(current_kg.nodes, target_node_id, updated_node)}
          new_m = %{m |
            req_trace: m.req_trace + raw_expl_yield + raw_comp_yield + raw_pred_yield,
            act_trace: m.act_trace + actual_pred_trace_consumed + actual_comp_yield + actual_pred_yield,
            shallow_energy_gen: m.shallow_energy_gen + total_energy_gained,
            state: %{m.state | novelty_reservoir: new_nov_res, compression_reservoir: new_comp_res, prediction_reservoir: new_pred_res}
          }
          {updated_agent, new_kg, new_m}
          
        node.type == :deep_locked ->
          [v_comp, v_expl, v_pred] = agent_vec
          
          c_nov = if v_expl > 0.5 and node.contributors.nov == nil, do: current_agent, else: node.contributors.nov
          c_comp = if v_comp > 0.5 and node.contributors.comp == nil, do: current_agent, else: node.contributors.comp
          c_pred = if v_pred > 0.5 and node.contributors.pred == nil, do: current_agent, else: node.contributors.pred
          
          updated_agent = if (v_expl > 0.5 or v_comp > 0.5 or v_pred > 0.5), do: %{current_agent | activity_score: 1.0}, else: current_agent
          
          if c_nov != nil and c_comp != nil and c_pred != nil do
            # ACTIVATE EDEN NODE
            new_ledger = m.immediate_ledger
              |> Map.update(c_nov.id, @dkn_immediate_reward, & &1 + @dkn_immediate_reward)
              |> Map.update(c_comp.id, @dkn_immediate_reward, & &1 + @dkn_immediate_reward)
              |> Map.update(c_pred.id, @dkn_immediate_reward, & &1 + @dkn_immediate_reward)
              
            cap_table = %{
              c_nov.lineage_id => 0.3333,
              c_comp.lineage_id => 0.3333,
              c_pred.lineage_id => 0.3334
            }
              
            updated_node = %{node | 
              type: :eden,
              current_energy: @eden_initial_energy,
              contributors: %{nov: nil, comp: nil, pred: nil},
              founder_lineages: [c_nov.lineage_id, c_comp.lineage_id, c_pred.lineage_id],
              cap_table: cap_table,
              health: 100.0,
              maintainers_this_epoch: []
            }
            new_kg = %{current_kg | nodes: Map.put(current_kg.nodes, target_node_id, updated_node)}
            new_m = %{m |
              immediate_ledger: new_ledger,
              activated_dkns: m.activated_dkns + 1,
              total_immediate_dividends: m.total_immediate_dividends + (@dkn_immediate_reward * 3.0)
            }
            {updated_agent, new_kg, new_m}
          else
            # JUST UPDATE CONTRIBUTORS
            updated_node = %{node | contributors: %{nov: c_nov, comp: c_comp, pred: c_pred}}
            new_kg = %{current_kg | nodes: Map.put(current_kg.nodes, target_node_id, updated_node)}
            {updated_agent, new_kg, m}
          end
          
        node.type == :eden ->
          # EDEN PUBLIC COMMONS - No Traces Required, Massive Harvest Cap
          yield = min(node.current_energy, @eden_harvest_cap)
          
          raw_expl_yield = yield * Enum.at(agent_vec, 1) * node.novelty_value * specialization_bonus
          raw_comp_yield = yield * Enum.at(agent_vec, 0) * node.shortcut_potential * specialization_bonus
          raw_pred_yield = yield * Enum.at(agent_vec, 2) * node.consistency * specialization_bonus
          
          total_energy_gained = raw_expl_yield + raw_comp_yield + raw_pred_yield
          updated_agent = %{current_agent | energy: current_agent.energy + total_energy_gained}
          
          health_boost = 0.0
          health_boost = if raw_expl_yield > 0, do: health_boost + 1.0, else: health_boost
          health_boost = if raw_comp_yield > 0, do: health_boost + 1.0, else: health_boost
          health_boost = if raw_pred_yield > 0, do: health_boost + 1.0, else: health_boost
          
          maintainers = if health_boost > 0, do: [current_agent.lineage_id | node.maintainers_this_epoch], else: node.maintainers_this_epoch
          updated_agent = if health_boost > 0, do: %{updated_agent | activity_score: 1.0}, else: updated_agent
          
          updated_node = %{node | 
            current_energy: max(0.0, node.current_energy - total_energy_gained),
            health: min(100.0, node.health + health_boost),
            maintainers_this_epoch: maintainers
          }
          new_kg = %{current_kg | nodes: Map.put(current_kg.nodes, target_node_id, updated_node)}
          
          new_m = %{m | eden_energy_gen: m.eden_energy_gen + total_energy_gained}
          {updated_agent, new_kg, new_m}
      end
    end)
  end
  
  defp consume_trace(required, node_trace, reservoir) do
    if required <= 0.0 do
      {0.0, node_trace, reservoir}
    else
      if node_trace >= required do
        {required, node_trace - required, reservoir}
      else
        remaining_req = required - node_trace
        if reservoir >= remaining_req do
          {required, 0.0, reservoir - remaining_req}
        else
          actual = node_trace + reservoir
          {actual, 0.0, 0.0}
        end
      end
    end
  end

  defp process_nodes(kg) do
    Enum.reduce(kg.nodes, {kg, %{}, 0.0, 0.0, 0.0, 0, 0, 0}, fn {id, node}, {kg_acc, div_acc, own_change, pool, fp, maint_count, act_count, total_built} ->
      cond do
        node.type == :shallow ->
          new_node = %{node | 
            current_energy: min(@shallow_max_energy, node.current_energy + @shallow_regen_rate),
            novelty_trace: node.novelty_trace * 0.99,
            compression_trace: node.compression_trace * 0.99,
            prediction_trace: node.prediction_trace * 0.99
          }
          {%{kg_acc | nodes: Map.put(kg_acc.nodes, id, new_node)}, div_acc, own_change, pool, fp, maint_count, act_count, total_built}
          
        node.type == :eden ->
          new_health = node.health - 1.0
          if new_health <= 0 do
            # COLLAPSE
            new_node = %{node | 
              type: :deep_locked, health: 100.0, cap_table: %{}, founder_lineages: [], maintainers_this_epoch: [], current_energy: 0.0,
              contributors: %{nov: nil, comp: nil, pred: nil}
            }
            {%{kg_acc | nodes: Map.put(kg_acc.nodes, id, new_node)}, div_acc, own_change, pool, fp, maint_count, act_count, total_built + 1}
          else
            # 1. Ownership Dilution
            total_diluted = 0.001
            {diluted_cap_table, actual_diluted} = Enum.reduce(node.cap_table, {%{}, 0.0}, fn {k, v}, {ct, total} ->
              drop = v * total_diluted
              {Map.put(ct, k, v - drop), total + drop}
            end)
            
            unique_maintainers = Enum.uniq(node.maintainers_this_epoch)
            
            final_cap_table = if length(unique_maintainers) > 0 do
              share = actual_diluted / length(unique_maintainers)
              Enum.reduce(unique_maintainers, diluted_cap_table, fn m_id, ct ->
                Map.update(ct, m_id, share, & &1 + share)
              end)
            else
              diluted_cap_table # Diluted ownership is lost to entropy if no maintainers
            end
            
            # 2. Regeneration & Dividends
            output_mult = new_health / 100.0
            {commons_regen, dividend_regen} = if new_health < 25.0 do
              {0.0, 0.0} # Critical state
            else
              total_regen = @eden_base_regen * output_mult
              {total_regen / 2.0, total_regen / 2.0}
            end
            
            new_div_acc = Enum.reduce(final_cap_table, div_acc, fn {l_id, pct}, acc ->
              Map.update(acc, l_id, dividend_regen * pct, & &1 + (dividend_regen * pct))
            end)
            
            new_node = %{node | 
              health: new_health,
              cap_table: final_cap_table,
              current_energy: min(@eden_max_energy, node.current_energy + commons_regen),
              maintainers_this_epoch: []
            }
            
            node_fp = Enum.reduce(node.founder_lineages, 0.0, fn f, sum -> sum + Map.get(final_cap_table, f, 0.0) end)
            
            is_maint = if length(unique_maintainers) > 0, do: 1, else: 0
            
            {%{kg_acc | nodes: Map.put(kg_acc.nodes, id, new_node)}, new_div_acc, own_change + actual_diluted, pool + 1.0, fp + node_fp, maint_count + is_maint, act_count + 1, total_built + 1}
          end
          
        true ->
          {%{kg_acc | nodes: Map.put(kg_acc.nodes, id, node)}, div_acc, own_change, pool, fp, maint_count, act_count, total_built}
      end
    end)
  end

  defp record_snapshot(pop, epoch, registry, cr, cd, itr, idr, imr, fp, kg, state) do
    pop_size = length(pop)
    
    confirmed_lineage_ids = pop |> Enum.filter(fn a -> registry[a.lineage_id].status == :confirmed end) |> Enum.map(& &1.lineage_id)
    lineage_counts = Enum.frequencies(confirmed_lineage_ids)
    
    diversity = calculate_shannon(Map.values(lineage_counts), length(confirmed_lineage_ids))
    active_confirmed_species = map_size(lineage_counts)
    
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
    
    max_share = if total_niche_pop > 0, do: Enum.max(Map.values(nc)) / total_niche_pop, else: 0.0
    
    act_avg = if pop_size > 0, do: Enum.sum(Enum.map(pop, & &1.activity_score)) / pop_size, else: 0.0
    
    %{
      epoch: epoch, pop_size: pop_size, diversity: diversity, active_species: active_confirmed_species,
      cr: cr, cd: cd, itr: itr, idr: idr, imr: imr, fp: fp, act_avg: act_avg, max_share: max_share,
      nov_res: state.novelty_reservoir, niche_census: nc
    }
  end

  defp print_results(telemetry) do
    Logger.info("\n=======================================================================================================================================")
    Logger.info("🏛️ REA-7F INSTITUTIONAL RETENTION MATRIX (Active Property Rights & Dilution)")
    Logger.info("=======================================================================================================================================")
    Logger.info("Epoch | Pop | Spc | CR    | CD    | IDR   | ITR   | IMR   | FP    | Max Niche | ActAvg | Nov Res | Comp | Expl | Pred | Gen")
    Logger.info("---------------------------------------------------------------------------------------------------------------------------------------")
    
    Enum.each(Enum.reverse(telemetry), fn r ->
      e = "#{r.epoch}" |> String.pad_trailing(5)
      p = "#{r.pop_size}" |> String.pad_trailing(3)
      spc = "#{r.active_species}" |> String.pad_trailing(3)
      cr = Float.round(r.cr, 3) |> Float.to_string() |> String.pad_trailing(5)
      cd = Float.round(r.cd, 3) |> Float.to_string() |> String.pad_trailing(5)
      idr = Float.round(r.idr, 3) |> Float.to_string() |> String.pad_trailing(5)
      itr = Float.round(r.itr, 4) |> Float.to_string() |> String.pad_trailing(5)
      imr = Float.round(r.imr, 2) |> Float.to_string() |> String.pad_trailing(5)
      fp = Float.round(r.fp, 3) |> Float.to_string() |> String.pad_trailing(5)
      
      pct = Float.round(r.max_share * 100, 1) |> Float.to_string() |> String.pad_trailing(4)
      m_sh = "#{pct}%" |> String.pad_trailing(9)
      
      act = Float.round(r.act_avg, 2) |> Float.to_string() |> String.pad_trailing(6)
      nr = Float.round(r.nov_res, 1) |> Float.to_string() |> String.pad_trailing(7)
      
      nc = r.niche_census
      Logger.info("#{e} | #{p} | #{spc} | #{cr} | #{cd} | #{idr} | #{itr} | #{imr} | #{fp} | #{m_sh} | #{act} | #{nr} | #{nc.comp}   | #{nc.expl}   | #{nc.pred}   | #{nc.gen}")
    end)
    Logger.info("=======================================================================================================================================")
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
    if total == 0, do: 0.0, else: counts |> Enum.filter(& &1 > 0) |> Enum.map(fn c -> p = c / total; -p * :math.log2(p) end) |> Enum.sum()
  end
end

Tiannara.REA.InstitutionalRetentionTest.run()
