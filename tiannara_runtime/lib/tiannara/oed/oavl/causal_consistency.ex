defmodule Tiannara.OED.OAVL.CausalConsistency do
  @moduledoc """
  📐 OAVL Causal Consistency.

  Verifies timeline history integrity and ensures that candidate rules preserve
  the partial order of events across space-time matrices, preventing temporal logic violations.
  """

  require Logger

  @spec verify(rule :: map()) :: :ok | {:error, String.t()}
  def verify(rule) do
    Logger.debug("📐 [Causal Consistency] Scanning partial event ordering parameters for #{rule.type}")

    if violates_causal_ordering?(rule.body) do
      {:error, "Causal consistency breach: rule introduces retroactive event causality"}
    else
      :ok
    end
  end

  # ==================== Internal Ordering Checkers ====================

  defp violates_causal_ordering?({:apply, :retroactive_mutation, _}), do: true

  defp violates_causal_ordering?({:if, _cond, then_b, else_b}) do
    violates_causal_ordering?(then_b) or violates_causal_ordering?(else_b)
  end

  defp violates_causal_ordering?({op, a, b}) when is_tuple(a) or is_tuple(b) do
    violates_causal_ordering?(a) or violates_causal_ordering?(b)
  end

  defp violates_causal_ordering?(_), do: false
end
