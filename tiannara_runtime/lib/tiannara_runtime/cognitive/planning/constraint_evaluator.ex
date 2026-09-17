defmodule TiannaraRuntime.Cognitive.Planning.ConstraintEvaluator do
  def evaluate(alternative, constraints) do
    cost = Map.get(alternative, :cost, Map.get(alternative, :score, 0))
    max_cost = Map.get(constraints, :max_cost, Map.get(constraints, :value, 100))
    violations =
      if cost > max_cost do
        [%{constraint: :max_cost, actual: cost, expected: max_cost, severity: :high}]
      else
        []
      end
    {:ok, %{violations: violations}}
  end
end
