defmodule TiannaraRuntime.CAL.Engine do
  @moduledoc """
  Bounded Coalition Arbitration Layer for an isolated world.

  Deterministic: decisions derive only from the supplied world CAL state.
  It does not invent agents, coalitions or success outcomes.
  """

  def step(state) when is_map(state) do
    coalitions = Map.get(state, :coalitions)
    weights = Map.get(state, :arbitration_weights)

    with true <- is_list(coalitions) and coalitions != [],
         true <- is_map(weights),
         {:ok, decisions} <- arbitrate(coalitions, weights) do
      {:ok,
       %{
         coalitions: coalitions,
         coalitions_updated: decisions.updated,
         decisions_made: decisions.decisions,
         arbitration_score: decisions.score,
         entropy_delta: decisions.entropy_delta
       }}
    else
      false -> {:error, :insufficient_cal_state}
      {:error, reason} -> {:error, reason}
    end
  end

  def step(_), do: {:error, :invalid_cal_state}

  defp arbitrate(coalitions, weights) do
    results =
      Enum.map(coalitions, fn coalition ->
        with true <- is_map(coalition),
             {:ok, id} <- required_id(coalition),
             {:ok, demand} <- required_numeric(coalition, :demand),
             {:ok, support} <- required_weight(weights, id) do
          {:ok, %{coalition: id, demand: demand, support: support, admitted: support >= demand}}
        else
          false -> {:error, :invalid_coalition}
          {:error, reason} -> {:error, reason}
        end
      end)

    case Enum.find(results, &match?({:error, _}, &1)) do
      {:error, reason} -> {:error, reason}
      nil ->
        decisions = Enum.map(results, fn {:ok, decision} -> decision end)
        admitted = Enum.count(decisions, & &1.admitted)
        total = length(decisions)
        score = admitted / total
        entropy_delta = (1.0 - score) * 0.01
        {:ok, %{updated: coalitions, decisions: decisions, score: score, entropy_delta: entropy_delta}}
    end
  end

  defp required_id(coalition) do
    case Map.get(coalition, :id, Map.get(coalition, "id")) do
      id when is_binary(id) and id != "" -> {:ok, id}
      id when is_atom(id) -> {:ok, id}
      _ -> {:error, :missing_coalition_id}
    end
  end

  defp required_numeric(map, key) do
    case Map.get(map, key, Map.get(map, Atom.to_string(key))) do
      value when is_number(value) -> {:ok, value / 1.0}
      _ -> {:error, {:missing_numeric_metric, key}}
    end
  end

  defp required_weight(weights, id) do
    case Map.get(weights, id) do
      value when is_number(value) -> {:ok, value / 1.0}
      _ -> {:error, {:missing_arbitration_weight, id}}
    end
  end
end
