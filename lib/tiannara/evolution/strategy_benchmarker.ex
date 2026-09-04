defmodule Tiannara.Evolution.StrategyBenchmarker do
  @doc """
  Benchmarks a set of strategies against historical performance data.
  Returns a ranked list with scores.
  """
  @spec benchmark([map()], [map()]) :: [map()]
  def benchmark(strategies, performance_history) when is_list(strategies) do
    Enum.map(strategies, fn strategy ->
      history = Enum.filter(performance_history, fn h ->
        Map.get(h, :strategy_id) == Map.get(strategy, :id)
      end)

      scores = compute_strategy_scores(history)

      %{
        strategy_id: Map.get(strategy, :id),
        strategy_name: Map.get(strategy, :name, "unnamed"),
        scores: scores,
        composite: composite_score(scores),
        sample_size: length(history),
        confidence: min(1.0, length(history) / 20.0),
        recommendation: recommend(scores, length(history))
      }
    end)
    |> Enum.sort_by(& &1.composite, :desc)
  end

  @doc """
  Compares two strategies head-to-head.
  """
  @spec compare(map(), map(), [map()]) :: map()
  def compare(strategy_a, strategy_b, performance_history) do
    history_a = Enum.filter(performance_history, &(Map.get(&1, :strategy_id) == Map.get(strategy_a, :id)))
    history_b = Enum.filter(performance_history, &(Map.get(&1, :strategy_id) == Map.get(strategy_b, :id)))

    scores_a = compute_strategy_scores(history_a)
    scores_b = compute_strategy_scores(history_b)

    dimensions = Map.keys(scores_a)

    wins_a = Enum.count(dimensions, fn d -> Map.get(scores_a, d, 0.0) > Map.get(scores_b, d, 0.0) end)
    wins_b = Enum.count(dimensions, fn d -> Map.get(scores_b, d, 0.0) > Map.get(scores_a, d, 0.0) end)

    %{
      strategy_a: Map.get(strategy_a, :id),
      strategy_b: Map.get(strategy_b, :id),
      scores_a: scores_a,
      scores_b: scores_b,
      wins_a: wins_a,
      wins_b: wins_b,
      winner: cond do
        wins_a > wins_b -> :a
        wins_b > wins_a -> :b
        true -> :tie
      end,
      confidence: min(1.0, (length(history_a) + length(history_b)) / 40.0)
    }
  end

  defp compute_strategy_scores([]) do
    %{throughput: 0.0, quality: 0.0, efficiency: 0.0, novelty: 0.0, reliability: 0.0, speed: 0.0}
  end

  defp compute_strategy_scores(history) do
    n = length(history)

    throughput = Enum.sum(Enum.map(history, &Map.get(&1, :throughput, 0.0))) / n
    quality = Enum.sum(Enum.map(history, &Map.get(&1, :quality, 0.0))) / n
    efficiency = Enum.sum(Enum.map(history, &Map.get(&1, :efficiency, 0.0))) / n
    novelty = Enum.sum(Enum.map(history, &Map.get(&1, :novelty, 0.0))) / n
    failure_rate = Enum.sum(Enum.map(history, &Map.get(&1, :failure_rate, 0.0))) / n
    speed = Enum.sum(Enum.map(history, &Map.get(&1, :speed, 0.0))) / n

    %{
      throughput: throughput,
      quality: quality,
      efficiency: efficiency,
      novelty: novelty,
      reliability: 1.0 - failure_rate,
      speed: speed
    }
  end

  defp composite_score(scores) do
    weights = %{throughput: 0.20, quality: 0.25, efficiency: 0.15, novelty: 0.15, reliability: 0.15, speed: 0.10}

    Enum.reduce(weights, 0.0, fn {dim, weight}, acc ->
      acc + Map.get(scores, dim, 0.0) * weight
    end)
  end

  defp recommend(scores, sample_size) do
    composite = composite_score(scores)

    cond do
      sample_size < 5 -> :insufficient_data
      composite > 0.7 -> :deploy
      composite > 0.5 -> :continue_testing
      composite > 0.3 -> :revise
      true -> :retire
    end
  end
end
