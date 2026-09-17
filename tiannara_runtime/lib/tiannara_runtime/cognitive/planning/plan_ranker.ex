defmodule TiannaraRuntime.Cognitive.Planning.PlanRanker do
  @moduledoc "Phase 18.5 — Deterministic ranking of planning alternatives"

  def rank(alternatives_with_scores) do
    ranked = Enum.sort_by(alternatives_with_scores, fn %{alternative: alt, score: score} ->
      nodes = length(Map.get(alt, :task_graph, []))
      desc = Map.get(alt, :description, "")
      sci = if String.contains?(desc, "research") or String.contains?(desc, "discover"), do: 1, else: 0
      content_hash = :crypto.hash(:sha256, inspect(alt)) |> Base.encode16(case: :lower)
      {-score, nodes, -sci, content_hash}
    end)
    {:ok, ranked}
  end

  def rank_stable(alternatives_with_scores, iterations) do
    first = rank(alternatives_with_scores)
    {:ok, first_ranked} = first
    stable = Enum.reduce(2..iterations, true, fn _i, acc ->
      {:ok, ranked} = rank(alternatives_with_scores)
      acc && ranked == first_ranked
    end)
    if stable, do: {:ok, :stable}, else: {:error, :unstable}
  end
end
