defmodule Tiannara.Logic.Rule do
  @moduledoc """
  Canonical rule-evaluation kernel (MC-002 L4).

  Evaluates a conditional rule against a set of facts with an honest
  three-state verdict:

    - `:pass` — all conditions are determined and satisfied;
    - `:fail` — a condition is determined and violated;
    - `:undetermined` — required facts are missing or a condition cannot be
      decided. `:undetermined` is never coerced into `:pass` or `:fail`.

  Constitutional basis: "Uncertainty should never be hidden".
  """

  @type facts :: map()
  @type condition :: (facts() -> boolean()) | {:key, term(), term()}
  @type rule :: %{
          optional(:requires) => [term()],
          optional(:conditions) => [condition()],
          optional(:fun) => (facts() -> boolean()),
          optional(:description) => String.t()
        }

  @type verdict :: :pass | :fail | :undetermined

  @doc """
  Evaluate a rule against a set of facts.

  Rule forms:

    - `%{fun: fun}` — single 1-arity predicate;
    - `%{conditions: [fun ...]}` — conjunction of 1-arity predicates;
    - `%{requires: [keys], ...}` — facts missing any required key are
      `:undetermined`.

  A predicate may return a boolean or `:pass` / `:fail` / `:undetermined`.
  """
  @spec evaluate(rule(), facts()) :: verdict()
  def evaluate(%{fun: fun}, facts) when is_function(fun, 1),
    do: evaluate_condition(fun, facts)

  def evaluate(%{conditions: conditions} = rule, facts) when is_list(conditions) and conditions != [] do
    if any_requirement_missing?(rule, facts) do
      :undetermined
    else
      verdicts = Enum.map(conditions, &evaluate_condition(&1, facts))
      Enum.reduce(verdicts, :pass, &conjoin/2)
    end
  end

  def evaluate(%{requires: required} = rule, facts) when is_list(required) do
    if any_requirement_missing?(rule, facts) do
      :undetermined
    else
      evaluate(remove_requires(rule), facts)
    end
  end

  def evaluate(%{description: _} = rule, facts), do: evaluate(remove_requires(rule), facts)
  def evaluate(_other, _facts), do: :undetermined

  defp evaluate_condition(fun, facts) when is_function(fun, 1) do
    case fun.(facts) do
      true -> :pass
      false -> :fail
      :pass -> :pass
      :fail -> :fail
      :undetermined -> :undetermined
      _ -> :undetermined
    end
  rescue
    _ -> :undetermined
  end

  defp evaluate_condition(_other, _facts), do: :undetermined

  defp conjoin(a, b) do
    cond do
      a == :fail or b == :fail -> :fail
      a == :undetermined or b == :undetermined -> :undetermined
      true -> :pass
    end
  end

  defp any_requirement_missing?(%{requires: required}, facts) do
    Enum.any?(required, fn key -> not Map.has_key?(facts, key) end)
  end

  defp any_requirement_missing?(_rule, _facts), do: false

  defp remove_requires(%{requires: _} = rule), do: Map.delete(rule, :requires)
  defp remove_requires(rule), do: rule
end