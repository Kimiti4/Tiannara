defmodule TiannaraRuntime.Cognitive.Planning.TradeoffAnalyzer do
  @moduledoc "Phase 18.5 — Deterministic tradeoff analysis across planning alternatives"

  defstruct [:scores, :recommendation, :alternatives_scored]

  def analyze(alternatives, dimensions) do
    scored = Enum.map(alternatives, fn alt ->
      scores = Enum.reduce(dimensions, %{}, fn dim, acc ->
        Map.put(acc, dim, score_dimension(alt, dim))
      end)
      %{alternative: alt, scores: scores}
    end)
    best = Enum.max_by(scored, fn s -> avg_score(s.scores) end)
    {:ok, %{scores: best.scores, recommendation: best.alternative.id, alternatives_scored: scored}}
  end

  def compare(alternative_a, alternative_b) do
    dims = [:speed, :quality, :cost, :memory, :risk, :complexity, :scientific_value]
    {a_better, b_better, tie} = Enum.reduce(dims, {[], [], []}, fn dim, {ab, bb, t} ->
      sa = score_dimension(alternative_a, dim)
      sb = score_dimension(alternative_b, dim)
      cond do
        sa > sb -> {ab ++ [dim], bb, t}
        sb > sa -> {ab, bb ++ [dim], t}
        true -> {ab, bb, t ++ [dim]}
      end
    end)
    {:ok, %{a_better_in: a_better, b_better_in: b_better, tie_in: tie}}
  end

  defp score_dimension(alternative, dim) do
    case dim do
      :speed ->
        dur = Map.get(alternative, :estimated_duration, 1)
        1.0 / max(dur, 1)
      :quality ->
        constraints = Map.get(alternative, :constraints, %{})
        total = map_size(constraints)
        if total == 0, do: 0.5, else: Enum.count(constraints, fn {_k, v} -> v != nil end) / total
      :cost ->
        cost = Map.get(alternative, :estimated_cost, 100)
        1.0 / max(cost, 1)
      :memory ->
        tg = Map.get(alternative, :task_graph, %{})
        nodes = if is_map(tg), do: map_size(tg), else: length(tg)
        1.0 / max(nodes, 1)
      :risk ->
        cons = Map.get(alternative, :constraints, %{})
        depth = Map.get(cons, :depth, 1)
        1.0 / max(depth, 1)
      :complexity ->
        tg = Map.get(alternative, :task_graph, %{})
        nodes = if is_map(tg), do: map_size(tg), else: length(tg)
        1.0 / max(nodes, 1)
      :scientific_value ->
        desc = Map.get(alternative, :description, "")
        if String.contains?(desc, "research") or String.contains?(desc, "discover"), do: 0.8, else: 0.3
    end
  end

  defp avg_score(scores) do
    vals = Map.values(scores)
    Enum.sum(vals) / max(length(vals), 1)
  end
end
