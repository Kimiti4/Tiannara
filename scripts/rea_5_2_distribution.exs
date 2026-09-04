# scripts/rea_5_2_distribution.exs
defmodule Tiannara.REA.REA52Distribution do
  require Logger

  @epochs 500
  @population_size 100
  @mutation_rate 0.05

  def run() do
    Logger.info("🧪 [REA-5.2] Running Distribution Analysis for Metric Calibration...")
    kg = generate_knowledge_graph(1_000)
    
    base_epistemology = %{
      id: "root", 
      heuristic_weights: [0.5, 0.5, 0.5, 0.5], 
      fitness: 0.0, 
      metrics: %{predictive_compression_ratio: 0.0, novelty_yield: 0.0, prediction_accuracy: 0.0}
    }
    initial_pop = Enum.map(1..@population_size, fn i -> %{base_epistemology | id: "agent_#{i}"} end)
    
    final_pop = evolve(initial_pop, kg, @epochs)
    analyze_distributions(final_pop)
  end

  defp evolve(pop, _kg, 0), do: pop
  defp evolve(pop, kg, epochs_remaining) do
    evaluated_pop = Enum.map(pop, fn agent ->
      traversal = simulate_weighted_walk(agent.heuristic_weights, kg, 50)
      metrics = %{
        predictive_compression_ratio: traversal.compression_score,
        novelty_yield: traversal.novelty_score,
        prediction_accuracy: traversal.prediction_score
      }
      fitness = (metrics.predictive_compression_ratio * 0.4) + 
                (metrics.novelty_yield * 0.4) + 
                (metrics.prediction_accuracy * 0.2)
      %{agent | fitness: fitness, metrics: metrics}
    end)
    
    survivors = Enum.map(1..@population_size, fn _ ->
      contenders = Enum.take_random(evaluated_pop, 3)
      Enum.max_by(contenders, & &1.fitness)
    end)
    
    next_gen = Enum.map(survivors, fn parent ->
      if :rand.uniform() < @mutation_rate do
        new_weights = Enum.map(parent.heuristic_weights, fn w ->
          max(0.0, min(1.0, w + (:rand.uniform() - 0.5) * 0.3))
        end)
        %{parent | id: "agent_#{System.unique_integer()}", heuristic_weights: new_weights}
      else
        %{parent | id: "agent_#{System.unique_integer()}"}
      end
    end)
    
    evolve(next_gen, kg, epochs_remaining - 1)
  end

  defp analyze_distributions(pop) do
    comps = Enum.map(pop, & &1.metrics.predictive_compression_ratio) |> Enum.sort()
    novs  = Enum.map(pop, & &1.metrics.novelty_yield) |> Enum.sort()
    preds = Enum.map(pop, & &1.metrics.prediction_accuracy) |> Enum.sort()

    Logger.info("\n📊 METRIC DISTRIBUTION ANALYSIS (Epoch #{@epochs})")
    print_stats("Compression", comps)
    print_stats("Novelty", novs)
    print_stats("Prediction", preds)
  end

  defp print_stats(name, sorted_list) do
    len = length(sorted_list)
    min_val = List.first(sorted_list)
    max_val = List.last(sorted_list)
    p50 = Enum.at(sorted_list, round(len * 0.50))
    p75 = Enum.at(sorted_list, round(len * 0.75))
    p90 = Enum.at(sorted_list, round(len * 0.90))
    
    Logger.info("#{String.pad_trailing(name, 12)} | Min: #{Float.round(min_val, 3)} | P50: #{Float.round(p50, 3)} | P75: #{Float.round(p75, 3)} | P90: #{Float.round(p90, 3)} | Max: #{Float.round(max_val, 3)}")
  end

  # --- Simplified Helpers ---
  defp generate_knowledge_graph(size) do
    nodes = Enum.reduce(0..(size-1), %{}, fn i, acc ->
      Map.put(acc, i, %{
        id: i, shortcut_potential: :rand.uniform(), novelty_value: :rand.uniform(), consistency: :rand.uniform(),
        neighbors: Enum.map(1..10, fn _ -> :rand.uniform(size) - 1 end) |> Enum.uniq() |> List.delete(i)
      })
    end)
    %{nodes: nodes, total_active_nodes: size}
  end

  defp simulate_weighted_walk([w_comp, w_expl, w_pred, w_gen], kg, steps) do
    start_node = :rand.uniform(kg.total_active_nodes) - 1
    {visited, comp_acc, nov_acc, pred_acc} = Enum.reduce(1..steps, {MapSet.new([start_node]), 0.0, 0.0, 0.0}, fn _, {visited_set, c, n, p} ->
      current_node = kg.nodes[Enum.random(MapSet.to_list(visited_set))]
      best_neighbor_id = current_node.neighbors |> Enum.max_by(fn n_id -> 
        neighbor = kg.nodes[n_id]
        score = (w_comp * neighbor.shortcut_potential) + (w_expl * neighbor.novelty_value) + (w_pred * neighbor.consistency) + (w_gen * :rand.uniform())
        score - (if MapSet.member?(visited_set, n_id), do: w_expl * 0.5, else: 0.0)
      end, fn -> Enum.random(current_node.neighbors) end)
      
      chosen = kg.nodes[best_neighbor_id]
      {MapSet.put(visited_set, best_neighbor_id), c + chosen.shortcut_potential, n + chosen.novelty_value, p + chosen.consistency}
    end)
    %{compression_score: comp_acc / steps, novelty_score: nov_acc / steps, prediction_score: pred_acc / steps}
  end
end

Tiannara.REA.REA52Distribution.run()
