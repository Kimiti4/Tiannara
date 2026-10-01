defmodule TiannaraRuntime.Mathematics.AssumptionEnvironment do
  @moduledoc """
  Scoped assumptions for mathematical reasoning.

  Assumptions are tracked explicitly and never silently promoted to facts.
  """

  def new, do: %{assumptions: [], scope: []}

  def assume(env, proposition, source \ :problem) do
    %{env | assumptions: [%{proposition: proposition, source: source} | env.assumptions]}
  end

  def push_scope(env), do: %{env | scope: [length(env.assumptions) | env.scope]}

  def pop_scope(%{scope: [mark | rest], assumptions: assumptions} = env) do
    %{env | assumptions: Enum.take(assumptions, mark), scope: rest}
  end

  def pop_scope(env), do: env

  def contains?(env, proposition) do
    Enum.any?(env.assumptions, &(&1.proposition == proposition))
  end
end
