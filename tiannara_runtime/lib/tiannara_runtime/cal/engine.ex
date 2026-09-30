defmodule TiannaraRuntime.CAL.Engine do
  @moduledoc """
  Bounded Coalition Arbitration Layer for an isolated world.

  Deterministic: decisions derive only from the supplied world CAL state.
  It does not invent agents, coalitions or success outcomes.
  """

  def step(state) when is_map(state) do
    coalitions = Map.get(state, :coalitions, [])
    weights = Map.get(state, :arbitration_weights, %{})
    decisions = arbitrate(coalitions, weights)

    {
      :ok,
      %{
        coalitions: coalitions,
        coalitions_updated: decisions.updated,
        decisions_made: decisions.decisions,
        arbitration_score: decisions.score,
        entropy_delta: decisions.entropy_delta
      }
    }
  end

  def step(_), do: {:error, :invalid_cal_state}

  defp arbitrate(coalitions, weights) do
    decisions =
      coalitions
      |> Enum.filter(&is_map/1)
      |> Enum.map(fn coalition ->
        id = Map.get(coalition, :id, Map.get(coalition, "id"))
        demand = numeric(Map.get(coalition, :demand, Map.get(coalition, "demand")), 0.0)
        support = numeric(Map.get(weights, id, 0.0), 0.0)
        %{coalition: id, demand: demand, support: support, admitted: support >= demand}
      end)

    admitted = Enum.count(decisions, & &1.admitted)
    total = length(decisions)
    score = if total == 0, do: 0.0, else: admitted / total
    entropy_delta = if total == 0, do: 0.0, else: (1.0 - score) * 0.01

    %{updated: coalitions, decisions: decisions, score: score, entropy_delta: entropy_delta}
  end

  defp numeric(value, _default) when is_number(value), do: value / 1.0
  defp numeric(_, default), do: default
end
