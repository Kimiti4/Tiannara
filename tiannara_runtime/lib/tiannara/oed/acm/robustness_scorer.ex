defmodule Tiannara.OED.ACM.RobustnessScorer do
  @moduledoc """
  ⚔️ ACM Robustness Scorer.

  Evaluates survival margins and assigns a strict numeric metric representing
  the configuration rule's robustness under high chaos levels.
  """

  require Logger

  @spec score(rule :: map(), metrics :: map()) :: float()
  def score(rule, metrics) do
    # Calculate components
    stability = Map.get(metrics, :stability, 1.0)
    divergence = Map.get(metrics, :divergence, 0.0)
    failures = Map.get(metrics, :failures, 0)

    # 1. Base stability component
    stability_factor = clamp(stability, 0.0, 1.0)

    # 2. Divergence penalty: high divergence decreases score
    divergence_penalty = clamp(divergence * 0.5, 0.0, 0.5)

    # 3. Failures penalty
    failure_penalty = clamp(failures * 0.1, 0.0, 0.3)

    # 4. AST complexity sanity check
    complexity_factor = compute_ast_complexity(rule.body)

    score = (stability_factor - divergence_penalty - failure_penalty) * complexity_factor
    final_score = Float.round(clamp(score, 0.0, 1.0), 3)

    Logger.info("⚔️ [Robustness Scorer] Rule #{rule.type} scored #{final_score} (stability=#{stability_factor}, div=#{divergence})")
    final_score
  end

  # ==================== Helpers ====================

  defp compute_ast_complexity({:if, _cond, then_b, else_b}) do
    # Moderate penalty for deep branches
    0.95 * min(compute_ast_complexity(then_b), compute_ast_complexity(else_b))
  end

  defp compute_ast_complexity({:apply, _op, _args}), do: 1.0
  defp compute_ast_complexity(_), do: 1.0

  defp clamp(val, min_v, max_v) do
    val |> max(min_v) |> min(max_v)
  end
end
