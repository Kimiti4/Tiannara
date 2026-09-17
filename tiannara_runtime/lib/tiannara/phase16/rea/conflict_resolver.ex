defmodule Tiannara.Phase16.REA.ConflictResolver do
  @moduledoc """
  Computes constraint conflict density and applies minimal adjunction relaxation.
  """
  
  @spec compute_density(unified :: map()) :: float()
  def compute_density(unified) do
    weights = Map.get(unified, :weights, %{})
    total = map_size(weights)
    if total == 0, do: 0.0, else: Enum.count(weights, fn {_, w} -> w < 1.0 end) / total
  end

  @spec relax(axioms :: map(), unified :: map()) :: map()
  def relax(axioms, unified) do
    Map.update(axioms, :constraints, [], fn constraints ->
      Enum.map(constraints, &relax_single/1)
    end)
  end

  defp relax_single(constraint) do
    Map.update(constraint, :weight, 1.0, &max(0.7, &1 * 0.9))
  end
end