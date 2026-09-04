# scripts/rea_7_b_comparative_advantage.exs
defmodule Tiannara.REA.ComparativeAdvantageTest do
  @moduledoc """
  Phase REA-7B: Scarcity + Comparative Advantage.
  
  Builds upon REA-7A by introducing physical morphology-based efficiency penalties (Comparative Advantage).
  Also tracks formal speciation based on REA-6B divergence thresholds to determine if Comparative Advantage
  can force the Extinction/Speciation Ratio (ESR) below 1.0.
  """
  require Logger

  @epochs 3_000
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

  def run() do
    Logger.info("🧬 [REA-7B] Initiating Scarcity + Comparative Advantage...")
    
    kg = generate_finite_knowledge_graph(1_000)
    base_pop = generate_ecological_population()
    
    initial_registry = Map.new(base_pop, fn a -> 
      {a.lineage_id, %{
        ancestral_weights: a.ancestral_weights,
        status: :confirmed,
        start_epoch: 0,
        parent_lineage: nil
      }}
    end)
    
    {_final_pop, _final_kg, telemetry, _reg} = evolve(
      base_pop, kg, @epochs, initial_registry, [], %{speciations: 0, extinctions: 0}
    )
    
    print_results(telemetry)
  end

  defp evolve(pop, kg, 0, registry, telemetry, _counts), do: {pop, kg, telemetry, registry}
  defp evolve([], kg, epochs_remaining, registry, telemetry, counts) do
    Logger.warning("☠️ TOTAL EXTINCTION at Epoch #{@epochs - epochs_remaining}. Thermodynamic collapse.")
    {[], kg, telemetry, registry}
  end
  defp evolve(pop, kg, epochs_remaining, registry, telemetry, counts) do
    current_epoch = @epochs - epochs_remaining + 1
    
    shuffled_pop = Enum.shuffle(pop)
    
    # 1. Foraging with Continuous Comparative Advantage
    {foraged_pop, updated_kg} = Enum.map_reduce(shuffled_pop, kg, fn agent, current_kg ->
      {harvested_energy, new_kg} = simulate_advantage_walk(agent.heuristic_weights, current_kg, @walk_steps)
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
        acc # Death
      end
    end)
    
    # 4. Speciation Verification & Extinction Tracking
    active_lineage_ids = survivors |> Enum.map(& &1.lineage_id) |> MapSet.new()
    active_pop_by_lineage = Enum.group_by(survivors, & &1.lineage_id)
    
    {updated_registry, updated_counts} = Enum.reduce(registry, {registry, counts}, fn {l_id, l_data}, {reg_acc, counts_acc} ->
      is_active = MapSet.member?(active_lineage_ids, l_id)
      
      cond do
        # Extinction of a confirmed species
        not is_active and l_data.status == :confirmed ->
          new_reg = Map.delete(reg_acc, l_id)
          {new_reg, Map.update!(counts_acc, :extinctions, & &1 + 1)}
          
        # Extinction of a candidate (does not count towards ESR)
        not is_active and l_data.status == :candidate ->
          new_reg = Map.delete(reg_acc, l_id)
          {new_reg, counts_acc}
          
        # Candidate matures into Confirmed Species
        is_active and l_data.status == :candidate and (current_epoch - l_data.start_epoch >= @speciation_maturity_epochs) ->
          agents = Map.get(active_pop_by_lineage, l_id, [])
          centroid = calculate_centroid(agents)
          
          # Verify it maintained divergence from its PARENT lineage
          parent_data = Map.get(reg_acc, l_data.parent_lineage)
          
          if parent_data != nil do
            divergence = euclidean_distance(centroid, parent_data.ancestral_weights)
            if divergence > @speciation_threshold do
              # SPECIATION ACHIEVED!
              new_data = %{l_data | status: :confirmed, ancestral_weights: centroid}
              new_reg = Map.put(reg_acc, l_id, new_data)
              {new_reg, Map.update!(counts_acc, :speciations, & &1 + 1)}
            else
              # Failed to maintain divergence, collapse back into parent lineage
              # (We handle the agent id reassignment later or just leave them as candidate indefinitely. 
              # Let's revoke their candidate status and merge back)
              # Simplest: just wait longer or let them die. We'll leave them as candidate.
              {reg_acc, counts_acc}
            end
          else
            # Parent went extinct, candidate becomes confirmed by default
            new_data = %{l_data | status: :confirmed, ancestral_weights: centroid}
            new_reg = Map.put(reg_acc, l_id, new_data)
            {new_reg, Map.update!(counts_acc, :speciations, & &1 + 1)}
          end
          
        true -> {reg_acc, counts_acc}
      end
    end)
    
    # 5. Mitosis (Reproduction & Candidate Spawning)
    {next_gen, final_registry} = Enum.flat_map_reduce(survivors, updated_registry, fn agent, reg_acc ->
      if agent.energy >= @reproduction_threshold do
        split_energy = agent.energy / 2.0
        parent = Map.put(agent, :energy, split_energy)
        
        child_id = "agent_#{System.unique_integer([:positive])}"
        child_weights = mutate_weights(parent.heuristic_weights)
        
        # Check for candidate divergence
        lineage_data = Map.get(reg_acc, parent.lineage_id)
        # If parent is a candidate, we measure against the true ancestral root (parent's parent) or the candidate root.
        # Measuring against the confirmed root is safer.
        root_weights = lineage_data.ancestral_weights
        
        div = euclidean_distance(child_weights, root_weights)
        
        {final_child_lineage, new_reg} = if div > @speciation_threshold do
          cand_id = "CAND_#{System.unique_integer([:positive])}"
          c_data = %{
            ancestral_weights: child_weights,
            status: :candidate,
            start_epoch: current_epoch,
            parent_lineage: parent.lineage_id
          }
          {cand_id, Map.put(reg_acc, cand_id, c_data)}
        else
          {parent.lineage_id, reg_acc}
        end
        
        child = %{
          id: child_id,
          lineage_id: final_child_lineage,
          parent_id: parent.id,
          ancestral_weights: child_weights,
          heuristic_weights: child_weights,
          energy: split_energy
        }
        {[parent, child], new_reg}
      else
        {[agent], reg_acc}
      end
    end)
    
    # 6. Telemetry
    new_telemetry = if epochs_remaining == 1 or rem(current_epoch, 100) == 0 do
      [record_snapshot(next_gen, current_epoch, final_registry, updated_counts, regenerated_kg) | telemetry]
    else
      telemetry
    end
    
    evolve(next_gen, regenerated_kg, epochs_remaining - 1, final_registry, new_telemetry, updated_counts)
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
        ancestral_weights: weights, heuristic_weights: weights,
        energy: 100.0
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
        id: i, 
        shortcut_potential: w_c / sum, 
        novelty_value: w_e / sum, 
        consistency: w_p / sum,
        current_energy: @node_max_energy,
        neighbors: Enum.map(1..10, fn _ -> :rand.uniform(size) - 1 end) |> Enum.uniq() |> List.delete(i)
      })
    end)
    %{nodes: nodes, total_active_nodes: size}
  end
  
  defp simulate_advantage_walk([w_comp, w_expl, w_pred] = hw, kg, steps) do
    start_node = :rand.uniform(kg.total_active_nodes) - 1
    
    # Normalize agent vector
    agent_sum = w_comp + w_expl + w_pred
    agent_vec = if agent_sum > 0, do: [w_comp/agent_sum, w_expl/agent_sum, w_pred/agent_sum], else: [0.33, 0.33, 0.33]
    
    {total_harvest, final_kg, _} = Enum.reduce(1..steps, {0.0, kg, MapSet.new([start_node])}, fn _, {harvested, current_kg, visited} ->
      current_node_id = Enum.random(MapSet.to_list(visited))
      current_node = current_kg.nodes[current_node_id]
      
      best_neighbor_id = current_node.neighbors |> Enum.max_by(fn n_id -> 
        neighbor = current_kg.nodes[n_id]
        score = (hw |> Enum.at(0) |> Kernel.*(neighbor.shortcut_potential)) + 
                (hw |> Enum.at(1) |> Kernel.*(neighbor.novelty_value)) + 
                (hw |> Enum.at(2) |> Kernel.*(neighbor.consistency))
        
        energy_bonus = if neighbor.current_energy > 0, do: 1.0, else: -5.0
        score + energy_bonus
      end, fn -> Enum.random(current_node.neighbors) end)
      
      target_node = current_kg.nodes[best_neighbor_id]
      
      # Comparative Advantage Dot Product
      node_vec = [target_node.shortcut_potential, target_node.novelty_value, target_node.consistency]
      efficiency = Enum.zip(agent_vec, node_vec) |> Enum.map(fn {a, n} -> a * n end) |> Enum.sum()
      
      # Harvest
      yield = min(target_node.current_energy, @harvest_cap)
      actual_energy_gained = yield * efficiency
      
      updated_node = Map.put(target_node, :current_energy, target_node.current_energy - yield) # Node loses full yield, agent only gets efficient portion
      updated_nodes = Map.put(current_kg.nodes, best_neighbor_id, updated_node)
      
      {harvested + actual_energy_gained, %{current_kg | nodes: updated_nodes}, MapSet.put(visited, best_neighbor_id)}
    end)
    
    {total_harvest, final_kg}
  end

  defp regenerate_nodes(kg) do
    new_nodes = Enum.into(kg.nodes, %{}, fn {id, node} ->
      {id, Map.put(node, :current_energy, min(@node_max_energy, node.current_energy + @node_regen_rate))}
    end)
    %{kg | nodes: new_nodes}
  end

  defp record_snapshot(pop, epoch, registry, counts, _kg) do
    pop_size = length(pop)
    
    confirmed_lineages = pop |> Enum.filter(fn a -> registry[a.lineage_id].status == :confirmed end) |> Enum.map(& &1.lineage_id)
    lineage_counts = Enum.frequencies(confirmed_lineages)
    
    diversity = calculate_shannon(Map.values(lineage_counts), length(confirmed_lineages))
    
    active_confirmed_species = map_size(lineage_counts)
    
    esr = if counts.speciations == 0, do: counts.extinctions * 1.0, else: counts.extinctions / counts.speciations
    
    %{
      epoch: epoch,
      pop_size: pop_size,
      diversity: diversity,
      active_species: active_confirmed_species,
      speciations: counts.speciations,
      extinctions: counts.extinctions,
      esr: esr
    }
  end

  defp print_results(telemetry) do
    Logger.info("\n===================================================================================")
    Logger.info("🧬 REA-7B COMPARATIVE ADVANTAGE MATRIX (SCARCITY + SPECIALIZATION)")
    Logger.info("===================================================================================")
    Logger.info("Epoch | Pop Size | Shannon | Confirmed Spc | Speciations | Extinctions | ESR Ratio")
    Logger.info("-----------------------------------------------------------------------------------")
    
    Enum.each(Enum.reverse(telemetry), fn r ->
      e = "#{r.epoch}" |> String.pad_trailing(5)
      p = "#{r.pop_size}" |> String.pad_trailing(8)
      d = Float.round(r.diversity, 3) |> Float.to_string() |> String.pad_trailing(7)
      spc = "#{r.active_species}" |> String.pad_trailing(13)
      spec = "#{r.speciations}" |> String.pad_trailing(11)
      ext = "#{r.extinctions}" |> String.pad_trailing(11)
      esr = Float.round(r.esr, 3) |> Float.to_string()
      
      Logger.info("#{e} | #{p} | #{d} | #{spc} | #{spec} | #{ext} | #{esr}")
    end)
    Logger.info("===================================================================================")
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
      counts
      |> Enum.filter(& &1 > 0)
      |> Enum.map(fn c -> p = c / total; -p * :math.log2(p) end)
      |> Enum.sum()
    end
  end
end

Tiannara.REA.ComparativeAdvantageTest.run()
