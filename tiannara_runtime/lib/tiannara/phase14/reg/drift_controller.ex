defmodule Tiannara.Phase14.REG.DriftController do
  @moduledoc """
  EMA smoothing & drift bound enforcement.
  """
  @alpha 0.85

  @spec compute_drift(base :: map(), novel :: map()) :: float()
  def compute_drift(base, novel) do
    keys = Map.keys(base) ++ Map.keys(novel) |> Enum.uniq()
    diffs = Enum.map(keys, fn k ->
      v1 = Map.get(base, k, :undefined)
      v2 = Map.get(novel, k, :undefined)
      if v1 == v2, do: 0.0, else: 1.0
    end)
    Enum.sum(diffs) / max(length(diffs), 1)
  end

  @spec smooth_drift(current :: float(), previous :: float()) :: float()
  def smooth_drift(current, previous), do: @alpha * current + (1 - @alpha) * previous
end