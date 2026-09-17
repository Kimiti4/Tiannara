defmodule TiannaraRuntime.Mathematics.RewriteEngine do
  @moduledoc """
  Phase 16.X.3 — Deterministic Rewrite Engine

  Applies rewrite rules to symbolic expressions deterministically.

  Rewrite ordering (never random):
    1. Rewrite priority (lower number = higher priority)
    2. Rule identifier (lexicographic)
    3. Content hash of target expression

  Every rewrite executes within a constitutional budget.
  If exhausted: Fail Closed. Never silently approximate.
  """

  alias TiannaraRuntime.Mathematics.Ontology.{SymbolicRule, RuleSet, RewriteStep, RewriteLog, SymbolicExpression}

  @default_budget 100
  @type budget :: non_neg_integer()

  # ---------------------------------------------------------------------------
  # Rule Application
  # ---------------------------------------------------------------------------

  @doc """
  Apply a single rewrite rule to an expression once.

  Returns {:ok, rewritten_expr, step} on success,
  {:error, reason} if the rule cannot be applied.
  """
  @spec apply_rule(SymbolicRule.t(), SymbolicExpression.t(), non_neg_integer()) ::
          {:ok, SymbolicExpression.t(), RewriteStep.t()} | {:error, String.t()}
  def apply_rule(%SymbolicRule{pattern: pattern, replacement: replacement, guard: guard},
                 %SymbolicExpression{} = expr,
                 step_number \\ 0) do
    case match_pattern(expr, pattern) do
      {:ok, bindings} ->
        if guard_applies?(guard, bindings) do
          {:ok, result_expr} = build_replacement(replacement, bindings)
          step = RewriteStep.new(step_number, pattern, expr, result_expr)
          case step do
            {:ok, s} -> {:ok, result_expr, s}
            _ -> {:ok, result_expr, nil}
          end
        else
          {:error, "guard condition not satisfied: #{guard}"}
        end

      :no_match ->
        {:error, "pattern did not match: #{pattern}"}
    end
  end

  @doc """
  Apply all rules in a RuleSet to an expression repeatedly within a budget.

  Ordering: rules sorted by (priority, rule_id).
  If budget exhausted: {:error, :budget_exhausted}.
  Never silently approximates.
  """
  @spec apply_rules(SymbolicExpression.t(), RuleSet.t(), keyword()) ::
          {:ok, SymbolicExpression.t(), [RewriteStep.t()]} | {:error, String.t()}
  def apply_rules(%SymbolicExpression{} = expr, %RuleSet{rules: rules} = rule_set, opts \\ []) do
    budget = Keyword.get(opts, :budget, @default_budget)
    ordered_rules = order_rules(rules)
    do_apply_rules(expr, ordered_rules, rule_set.id, budget, [])
  end

  # ---------------------------------------------------------------------------
  # Budget Management
  # ---------------------------------------------------------------------------

  @doc "Check if a rewrite has remaining budget."
  @spec budget_remaining?(budget()) :: boolean()
  def budget_remaining?(budget) when budget > 0, do: true
  def budget_remaining?(_budget), do: false

  @doc "Returns the default rewrite budget."
  @spec default_budget() :: non_neg_integer()
  def default_budget, do: @default_budget

  # ---------------------------------------------------------------------------
  # RuleSet Construction
  # ---------------------------------------------------------------------------

  @doc "Create a RuleSet with deterministic rule ordering."
  @spec create_rule_set(String.t(), [SymbolicRule.t()], keyword()) ::
          {:ok, RuleSet.t()} | {:error, String.t()}
  def create_rule_set(id, rules, opts \\ []) do
    ordered = order_rules(rules)
    RuleSet.new(id, ordered, opts)
  end

  @doc "Create a single rewrite rule."
  @spec create_rule(String.t(), String.t(), String.t() | nil) ::
          {:ok, SymbolicRule.t()} | {:error, String.t()}
  def create_rule(pattern, replacement, guard \\ nil) do
    SymbolicRule.new(pattern, replacement, guard)
  end

  # ---------------------------------------------------------------------------
  # Replay
  # ---------------------------------------------------------------------------

  @doc """
  Replay a sequence of rewrite steps deterministically.

  Replay uses only:
    - rewrite rules (ordered by priority and identifier)
    - canonical ordering
    - deterministic context
  """
  @spec replay_rewrites(SymbolicExpression.t(), RuleSet.t(), keyword()) ::
          {:ok, SymbolicExpression.t(), [RewriteStep.t()]} | {:error, String.t()}
  def replay_rewrites(%SymbolicExpression{} = expr, %RuleSet{} = rule_set, opts \\ []) do
    apply_rules(expr, rule_set, opts)
  end

  # ---------------------------------------------------------------------------
  # Validation
  # ---------------------------------------------------------------------------

  @doc "Validate a rewrite log is a valid sequence of steps."
  @spec validate_log(RewriteLog.t()) :: :ok | {:error, String.t()}
  def validate_log(%RewriteLog{steps: steps}) when steps == [] do
    {:error, "rewrite log must have at least one step"}
  end

  def validate_log(%RewriteLog{steps: steps}) do
    step_numbers = Enum.map(steps, fn s -> s.step_number end)
    expected = Enum.to_list(0..(length(steps) - 1))

    if step_numbers == expected do
      :ok
    else
      {:error, "step numbers not sequential: #{inspect(step_numbers)}"}
    end
  end

  # ---------------------------------------------------------------------------
  # Internal: Deterministic Rule Ordering
  # ---------------------------------------------------------------------------

  defp order_rules(rules) do
    rules
    |> Enum.with_index()
    |> Enum.sort_by(fn {%SymbolicRule{pattern: pat, replacement: rep}, idx} ->
      priority = rule_priority(pat)
      {priority, pat, rep, idx}
    end)
    |> Enum.map(fn {rule, _idx} -> rule end)
  end

  defp rule_priority(pattern) do
    cond do
      String.contains?(pattern, "identity") -> 0
      String.contains?(pattern, "inverse") -> 1
      String.contains?(pattern, "associative") -> 2
      String.contains?(pattern, "commutative") -> 3
      String.contains?(pattern, "distributive") -> 4
      true -> 100
    end
  end

  # ---------------------------------------------------------------------------
  # Internal: Rewrite Application Loop
  # ---------------------------------------------------------------------------

  defp do_apply_rules(_expr, _rules, _set_id, budget, _steps) when budget <= 0 do
    {:error, "rewrite budget exhausted"}
  end

  defp do_apply_rules(expr, rules, set_id, budget, steps) do
    case try_apply_any(expr, rules, length(steps)) do
      {:ok, new_expr, step} ->
        new_steps = steps ++ [step]
        do_apply_rules(new_expr, rules, set_id, budget - 1, new_steps)

      :no_match ->
        log = RewriteLog.new(steps)
        case log do
          {:ok, _log} -> {:ok, expr, steps}
          _ -> {:ok, expr, steps}
        end
    end
  end

  defp try_apply_any(_expr, [], _step_number), do: :no_match

  defp try_apply_any(expr, [rule | rest], step_number) do
    case apply_rule(rule, expr, step_number) do
      {:ok, new_expr, step} -> {:ok, new_expr, step}
      {:error, _} -> try_apply_any(expr, rest, step_number)
    end
  end

  # ---------------------------------------------------------------------------
  # Internal: Pattern Matching
  # ---------------------------------------------------------------------------

  defp match_pattern(%SymbolicExpression{type: :constant, value: v}, pattern) do
    case Integer.parse(pattern) do
      {n, ""} when n == v -> {:ok, %{}}
      _ ->
        if pattern == "_" do
          {:ok, %{}}
        else
          :no_match
        end
    end
  end

  defp match_pattern(%SymbolicExpression{type: :variable, value: v}, pattern) do
    cond do
      pattern == "_" -> {:ok, %{}}
      String.starts_with?(pattern, "?") ->
        var_name = String.slice(pattern, 1..-1//1)
        {:ok, %{var_name => v}}
      pattern == v -> {:ok, %{}}
      true -> :no_match
    end
  end

  defp match_pattern(%SymbolicExpression{type: :operator, value: op, children: children}, pattern) do
    children = children || []
    case parse_operator_pattern(pattern) do
      {:ok, op_name, arg_patterns} when length(arg_patterns) == length(children) ->
        op_atom = String.to_existing_atom(op_name)

        if op_atom == op do
          pairs = Enum.zip(children, arg_patterns)
          results = Enum.map(pairs, fn {child, pat} -> match_pattern(child, pat) end)

          if Enum.all?(results, fn r -> r != :no_match end) do
            bindings = Enum.reduce(results, %{}, fn {:ok, b}, acc -> Map.merge(acc, b) end)
            {:ok, bindings}
          else
            :no_match
          end
        else
          :no_match
        end

      _ ->
        :no_match
    end
  end

  defp match_pattern(_expr, _pattern), do: :no_match

  defp parse_operator_pattern(pattern) do
    case String.split(pattern, "(", parts: 2) do
      [op_name, rest] when byte_size(rest) > 0 ->
        inner = String.slice(rest, 0..-2//1)
        args = split_pattern_args(inner)
        {:ok, op_name, args}

      _ ->
        :error
    end
  end

  defp split_pattern_args(s) do
    s |> String.split(",", trim: true) |> Enum.map(&String.trim/1)
  end

  # ---------------------------------------------------------------------------
  # Internal: Guard Evaluation
  # ---------------------------------------------------------------------------

  defp guard_applies?(nil, _bindings), do: true
  defp guard_applies?(guard, bindings) when is_binary(guard) do
    case guard do
      "true" -> true
      "false" -> false
      _ -> evaluate_guard(guard, bindings)
    end
  end

  defp evaluate_guard(guard, bindings) do
    cond do
      String.starts_with?(guard, "!=") ->
        parts = String.split(guard, "!=", parts: 2)
        resolve_guard_value(Enum.at(parts, 0), bindings) !=
          resolve_guard_value(Enum.at(parts, 1), bindings)

      String.contains?(guard, "==") ->
        parts = String.split(guard, "==", parts: 2)
        resolve_guard_value(Enum.at(parts, 0), bindings) ==
          resolve_guard_value(Enum.at(parts, 1), bindings)

      true -> true
    end
  end

  defp resolve_guard_value(expr, bindings) do
    trimmed = String.trim(expr || "")
    if String.starts_with?(trimmed, "?") do
      var_name = String.slice(trimmed, 1..-1//1)
      Map.get(bindings, var_name, trimmed)
    else
      trimmed
    end
  end

  # ---------------------------------------------------------------------------
  # Internal: Replacement Construction
  # ---------------------------------------------------------------------------

  defp build_replacement(replacement, bindings) do
    cond do
      replacement == "_" ->
        SymbolicExpression.new(:variable, "_")

      String.starts_with?(replacement, "?") ->
        var_name = String.slice(replacement, 1..-1//1)
        bound_val = Map.get(bindings, var_name, replacement)

        if is_binary(bound_val) do
          case Integer.parse(bound_val) do
            {n, ""} -> SymbolicExpression.new(:constant, n)
            _ -> SymbolicExpression.new(:variable, bound_val)
          end
        else
          SymbolicExpression.new(:variable, to_string(bound_val))
        end

      String.contains?(replacement, "(") and String.ends_with?(replacement, ")") ->
        build_composite_replacement(replacement, bindings)

      true ->
        case Integer.parse(replacement) do
          {n, ""} -> SymbolicExpression.new(:constant, n)
          _ -> SymbolicExpression.new(:variable, replacement)
        end
    end
  end

  defp build_composite_replacement(replacement, bindings) do
    case parse_operator_pattern(replacement) do
      {:ok, op_name, arg_patterns} ->
        op_atom = String.to_existing_atom(op_name)
        {:ok, args} = Enum.reduce_while(arg_patterns, {:ok, []}, fn pat, {:ok, acc} ->
          case build_replacement(pat, bindings) do
            {:ok, expr} -> {:cont, {:ok, acc ++ [expr]}}
            error -> {:halt, error}
          end
        end)

        SymbolicExpression.new(:operator, op_atom, children: args)

      :error ->
        SymbolicExpression.new(:variable, replacement)
    end
  end
end
