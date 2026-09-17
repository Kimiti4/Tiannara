defmodule Tiannara.Meta.OPC.Stabilization.EntropyEstimator do
  @moduledoc """
  Phase 5F.6 — Entropy Estimator

  Estimates the structural entropy of an observer physics AST.
  High-entropy proposals risk destabilising the causal substrate;
  proposals that exceed the entropy limit are rejected before GPU
  dispatch.

  ## Constraint

  entropy(AST) = complexity(AST) / 100.0 ≤ @entropy_limit (default: 0.92)

  ## Usage

      ast = {:op, :+, [{:const, 1.0}, {:const, 2.0}]}
      {:ok, 0.03} = EntropyEstimator.estimate(ast)
  """

  require Logger

  @entropy_limit 0.92

  @doc """
  Estimates the entropy of the given AST.

  ## Returns
  - `{:ok, entropy}` — Entropy value in [0.0, 1.0]; proposal is safe
  - `{:error, :entropy_limit_exceeded}` — Entropy exceeds the safe threshold
  """
  def estimate(ast) do
    entropy = complexity(ast) / 100.0

    if entropy > @entropy_limit do
      Logger.warning(
        "🛑 [EntropyEstimator] Entropy #{Float.round(entropy, 4)} exceeds limit #{@entropy_limit}"
      )

      {:error, :entropy_limit_exceeded}
    else
      Logger.debug("✅ [EntropyEstimator] Entropy #{Float.round(entropy, 4)} within bounds")
      {:ok, entropy}
    end
  end

  # ── Private Functions ─────────────────────────────────────────────────────

  defp complexity({:op, _, args}) when is_list(args) do
    1 + Enum.sum(Enum.map(args, &complexity/1))
  end

  defp complexity(list) when is_list(list) do
    Enum.sum(Enum.map(list, &complexity/1))
  end

  defp complexity(_leaf), do: 1
end
