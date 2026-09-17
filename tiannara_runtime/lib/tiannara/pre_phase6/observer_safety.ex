defmodule Tiannara.PrePhase6.ObserverSafety do
  @moduledoc """
  Validates OSL + RRG boundaries: ensures observer recursion is contained
  and substrate primitives remain inaccessible.
  """

  @max_recursion_depth 4
  @min_uncertainty_injection 0.05

  @spec validate_observer_boundaries(observer_states :: map()) :: {:ok, map()} | {:error, String.t()}
  def validate_observer_boundaries(observer_states) do
    with :ok <- verify_recursion_limits(observer_states),
         :ok <- check_substrate_opacity(observer_states),
         :ok <- ensure_uncertainty_injection(observer_states) do
      {:ok, %{status: :safe, observers_validated: map_size(observer_states)}}
    end
  end

  defp verify_recursion_limits(observer_states) do
    violations = Enum.filter(observer_states, fn {_id, obs} ->
      Map.get(obs, :recursion_depth, 0) > @max_recursion_depth
    end)

    if violations == [] do
      :ok
    else
      {:error, "Recursion limit exceeded in #{length(violations)} observers"}
    end
  end

  defp check_substrate_opacity(observer_states) do
    breaches = Enum.filter(observer_states, fn {_id, obs} ->
      primitives = Map.get(obs, :accessed_primitives, [])
      Enum.any?(primitives, &(&1 in [:garbage_collection, :memory_compact, :branch_prune]))
    end)

    if breaches == [] do
      :ok
    else
      {:error, "Substrate access violation in #{length(breaches)} observers"}
    end
  end

  defp ensure_uncertainty_injection(observer_states) do
    high_recursion = Enum.filter(observer_states, fn {_id, obs} ->
      Map.get(obs, :recursion_depth, 0) > 3
    end)

    insufficient = Enum.filter(high_recursion, fn {_id, obs} ->
      Map.get(obs, :uncertainty_injection, 0.0) < @min_uncertainty_injection
    end)

    if insufficient == [] do
      :ok
    else
      {:error, "Insufficient uncertainty injection for #{length(insufficient)} observers"}
    end
  end
end
