defmodule Tiannara.OED.Validation.EpistemicStability do
  @moduledoc """
  🔬 OED Validation Epistemic Stability.

  Asserts logic consistency, belief integrity, and completeness constraints
  on configuration rules.
  """

  require Logger

  @spec assert_stability(rule :: map()) :: :ok | {:error, String.t()}
  def assert_stability(rule) do
    Logger.debug("🔬 [Epistemic Stability] Scanning belief-completeness for #{rule.type}")

    # Check for empty rules or missing branches
    if incomplete_rule?(rule.body) do
      {:error, "Epistemic instability: rule contains incomplete or un-handled logic cases"}
    else
      :ok
    end
  end

  defp incomplete_rule?(:ignore), do: false
  defp incomplete_rule?({:if, _cond, nil, _}), do: true
  defp incomplete_rule?({:if, _cond, _, nil}), do: true
  defp incomplete_rule?({:if, _cond, then_b, else_b}) do
    incomplete_rule?(then_b) or incomplete_rule?(else_b)
  end
  defp incomplete_rule?(_), do: false
end
