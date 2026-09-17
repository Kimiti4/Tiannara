defmodule Tiannara.Kernel.MutationEngine do
  @moduledoc """
  Evolves configuration rules by applying safe, bounded, and depth-dampened mutations.
  """

  @mutation_operators [
    :adjust_threshold,
    :swap_strategy,
    :add_constraint,
    :relax_bound
  ]

  @spec generate(rules :: map(), depth :: non_neg_integer(), opts :: keyword()) :: {:ok, map()} | {:error, String.t()}
  def generate(rules, depth, opts \\ []) do
    modifier = Keyword.get(opts, :modifier, 1.0)
    # Mutation probability decreases with depth to prevent runaway evolution, scaled by reinforcement learning feedback
    mutation_rate = (0.5 / (depth + 1)) * modifier

    mutated = Map.new(rules, fn {key, rule_ast} ->
      if :rand.uniform() < mutation_rate do
        {key, apply_random_mutation(rule_ast)}
      else
        {key, rule_ast}
      end
    end)

    {:ok, mutated}
  end

  defp apply_random_mutation(rule_ast) do
    operator = Enum.random(@mutation_operators)
    apply_mutation(rule_ast, operator)
  end

  defp apply_mutation(%{body: {:if, cond, then_branch, else_branch}} = rule, :adjust_threshold) do
    new_cond = perturb_condition(cond)
    %{rule | body: {:if, new_cond, then_branch, else_branch}}
  end

  defp apply_mutation(rule, :swap_strategy) do
    strategies = [:adaptive, :conservative, :aggressive, :stochastic]
    current = extract_strategy(rule.body)
    new_strategy = Enum.random(strategies -- [current])
    substitute_strategy(rule, new_strategy)
  end

  defp apply_mutation(rule, _other), do: rule

  # ==================== Helpers ====================

  defp perturb_condition({:>, var, threshold}) when is_number(threshold) do
    # ±5% random perturbation
    delta = threshold * 0.05 * (:rand.uniform() * 2 - 1)
    {:>, var, Float.round(threshold + delta, 3)}
  end

  defp perturb_condition(cond), do: cond

  defp extract_strategy({:apply, strategy, _args}), do: strategy
  defp extract_strategy(_), do: :adaptive

  defp substitute_strategy(rule, new_strategy) do
    Map.update!(rule, :body, fn body ->
      substitute_in_ast(body, new_strategy)
    end)
  end

  defp substitute_in_ast({:apply, _old, args}, new), do: {:apply, new, args}
  defp substitute_in_ast({op, a, b}, new), do: {op, substitute_in_ast(a, new), substitute_in_ast(b, new)}
  defp substitute_in_ast({op, a, b, c}, new), do: {op, substitute_in_ast(a, new), substitute_in_ast(b, new), substitute_in_ast(c, new)}
  defp substitute_in_ast(term, _new), do: term
end
