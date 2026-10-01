defmodule TiannaraRuntime.Mathematics.TransformationEngine do
  @moduledoc """
  Applies conservative symbolic transformations and records every obligation.

  Transformations are derivations, not proofs. A transformation may only be
  considered valid under an assumption environment when all generated side
  conditions are present there.
  """

  alias TiannaraRuntime.Mathematics.{FormalAST, TypeChecker, AssumptionEnvironment, SideConditionEngine}

  def apply(:add_zero, expr, _env), do: {:ok, %{before: expr, after: expr, rule: :add_zero, conditions: []}}
  def apply(:multiply_one, expr, _env), do: {:ok, %{before: expr, after: expr, rule: :multiply_one, conditions: []}}

  def apply(:divide_by, {:op, :multiply, [a, b]}, env) do
    condition = SideConditionEngine.require_nonzero(b)
    result = {:op, :divide, [{:op, :multiply, [a, b]}, b]}
    status = if AssumptionEnvironment.contains?(env, condition), do: :conditionally_valid, else: :requires_condition
    {:ok, %{before: {:op, :multiply, [a, b]}, after: result, rule: :divide_by,
            conditions: [condition], status: status}}
  end

  def apply(:normalize_add, {:op, :add, [a, b]}, _env) do
    {:ok, %{before: {:op, :add, [a, b]}, after: {:op, :add, [b, a]},
            rule: :commutativity_add, conditions: [], status: :valid}}
  end

  def apply(:normalize_multiply, {:op, :multiply, [a, b]}, _env) do
    {:ok, %{before: {:op, :multiply, [a, b]}, after: {:op, :multiply, [b, a]},
            rule: :commutativity_multiply, conditions: [], status: :valid}}
  end

  def apply(rule, expr, _env) do
    with :ok <- FormalAST.validate(expr),
         {:ok, _} <- TypeChecker.check(expr) do
      {:error, {:unsupported_transformation, rule}}
    end
  end
end
