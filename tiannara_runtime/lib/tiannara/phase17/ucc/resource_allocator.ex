defmodule Tiannara.Phase17.UCC.ResourceAllocator do
  @moduledoc """
  Maps IR complexity to available compute targets & enforces capacity bounds.
  """
  @default_capacity %{cpu: 100.0, gpu: 500.0, wasi: 50.0, quantum: 10.0}
  @safe_threshold 0.85

  @spec estimate(ir :: map(), target :: atom()) :: %{utilization_ratio: float(), capacity: float()}
  def estimate(ir, target) do
    complexity = length(ir.nodes) * 2.0 + length(ir.edges) * 1.5
    capacity = Map.get(@default_capacity, target, 50.0)
    
    ratio = min(complexity / capacity, 1.0)
    %{utilization_ratio: ratio, capacity: capacity}
  end

  @spec within_bounds?(ratio :: float()) :: boolean()
  def within_bounds?(ratio), do: ratio <= @safe_threshold
end