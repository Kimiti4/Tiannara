defmodule TiannaraRuntime.Mathematics.SideConditionEngine do
  @moduledoc """
  Tracks mathematical side conditions introduced by transformations.

  A transformation is not considered generally valid until its side conditions
  are discharged or explicitly carried as assumptions.
  """

  def require_nonzero(expr), do: {:condition, :not_equal, expr, {:const, 0, :integer}}
  def require_positive(expr), do: {:condition, :greater_than, expr, {:const, 0, :integer}}

  def attach(statement, conditions) when is_list(conditions) do
    %{statement: statement, side_conditions: Enum.uniq(conditions), discharged: []}
  end

  def discharge(bundle, condition, evidence) do
    if condition in bundle.side_conditions and is_map(evidence) and
         Map.get(evidence, :verified, Map.get(evidence, "verified", false)) == true do
      {:ok, %{bundle | discharged: Enum.uniq([condition | bundle.discharged])}}
    else
      {:error, :side_condition_not_verified}
    end
  end

  def unresolved?(bundle) do
    bundle.side_conditions -- bundle.discharged != []
  end
end
