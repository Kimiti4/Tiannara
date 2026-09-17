defmodule Tiannara.OED.Quarantine.RehabilitationPipeline do
  @moduledoc """
  🗃️ Quarantine Subsystem Rehabilitation Pipeline.

  Mutates and refines quarantined rules to resolve contradictions, add limits,
  or constrain bounds, preparing rehabilitated rules for re-validation.
  """

  require Logger

  @spec rehabilitate(rule :: map(), reason :: String.t()) :: {:ok, map()} | {:error, String.t()}
  def rehabilitate(rule, reason) do
    Logger.info("🗃️ [Rehabilitation] Attempting rehabilitation on quarantined rule #{rule.type}")

    try do
      rehabilitated_body = resolve_conflict(rule.body, reason)
      # Re-assert correct invariants and safety constraints
      rehab_rule =
        rule
        |> Map.put(:body, rehabilitated_body)
        |> Map.put(:invariants, [:causal_conservation, :observer_safety, :entropy_non_decrease, :psi_stability_bound])
      {:ok, rehab_rule}
    rescue
      e -> {:error, "Rehabilitation failure: #{inspect(e)}"}
    end
  end

  # ==================== Internal Resolvers ====================

  defp resolve_conflict(body, reason) do
    cond do
      reason =~ "infinite regress" or reason =~ "regress" ->
        # Inject standard recursion compilation depth guard
        {:if, {:<=, :compilation_depth, 3}, body, :ignore}

      reason =~ "unconstrained division" or reason =~ "division" ->
        # Inject a safety guard to check that denominator is non-zero
        {:if, {:>, :denominator, 0}, body, :ignore}

      reason =~ "non-homomorphic" or reason =~ "Identity morphism violation" ->
        # Clamp coefficients to stable contraction intervals
        clamp_ast_coefficients(body)

      true ->
        # Fallback default: wrap inside local safety conditions
        {:if, {:>, :stability_index, 0.5}, body, :ignore}
    end
  end

  defp clamp_ast_coefficients({:diffuse, field, _rate, cap}) do
    {:diffuse, field, 0.05, cap}
  end

  defp clamp_ast_coefficients({:if, cond, then_b, else_b}) do
    {:if, cond, clamp_ast_coefficients(then_b), clamp_ast_coefficients(else_b)}
  end

  defp clamp_ast_coefficients(term), do: term
end
