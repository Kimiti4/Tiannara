defmodule Tiannara.PrePhase6.CausalIntegrity do
  @moduledoc """
  Validates CTL + TWP coherence.
  Ensures causal histories remain reconcilable and branch pruning is sound.
  """

  @spec validate_causal_graph(branch_registry :: map()) :: {:ok, map()} | {:error, String.t()}
  def validate_causal_graph(registry) do
    with :ok <- check_branch_consistency(registry),
         :ok <- verify_pruning_soundness(registry),
         :ok <- ensure_reconciliation_feasibility(registry) do
      {:ok, %{status: :coherent, branches_validated: map_size(registry)}}
    end
  end

  defp check_branch_consistency(registry) do
    contradictions = Enum.filter(registry, fn {_id, branch} ->
      contains_contradiction?(Map.get(branch, :events, []))
    end)

    if contradictions == [] do
      :ok
    else
      {:error, "Causal contradictions detected in #{length(contradictions)} branches"}
    end
  end

  defp contains_contradiction?(events) do
    if length(events) < 2 do
      false
    else
      event_pairs = for i <- 0..(length(events)-2), j <- (i+1)..(length(events)-1) do
        {Enum.at(events, i), Enum.at(events, j)}
      end

      Enum.any?(event_pairs, fn {e1, e2} -> mutually_exclusive?(e1, e2) end)
    end
  end

  # Contradiction: same subject, opposing state
  defp mutually_exclusive?(%{type: t1, state: s1}, %{type: t2, state: s2}) when t1 == t2 and s1 != s2, do: true
  defp mutually_exclusive?(_, _), do: false

  defp verify_pruning_soundness(registry) do
    invalid_prunes = Enum.filter(registry, fn {_id, branch} ->
      Map.get(branch, :state) == :collapsed and
      (Map.get(branch, :persistence_prob, 0.0) > 0.35 or Map.get(branch, :observer_density, 0.0) > 0.5)
    end)

    if invalid_prunes == [] do
      :ok
    else
      {:error, "Invalid pruning: #{length(invalid_prunes)} high-value branches collapsed"}
    end
  end

  defp ensure_reconciliation_feasibility(registry) do
    total_required_bandwidth = Enum.sum(Enum.map(Map.values(registry), & Map.get(&1, :reconciliation_cost, 10.0)))
    available_bandwidth = get_sync_budget()

    if total_required_bandwidth <= available_bandwidth do
      :ok
    else
      {:error, "Insufficient sync bandwidth for branch reconciliation"}
    end
  end

  defp get_sync_budget do
    if Process.whereis(Tiannara.CTL.Supervisor) do
      try do
        Tiannara.CTL.Supervisor.get_global_sync_budget()
      rescue
        _ -> 1000.0
      end
    else
      1000.0
    end
  end
end
