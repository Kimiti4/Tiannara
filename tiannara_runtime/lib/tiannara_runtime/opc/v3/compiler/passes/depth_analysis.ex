defmodule Tiannara.OPC.V3.Compiler.DepthAnalysis do
  @moduledoc """
  Depth Analysis Pass
  Analyzes the depth of the IR to ensure it meets safety bounds
  """

  alias Tiannara.OPC.V3.IR.OIR
  alias Tiannara.OPC.V3.IR.DepthCalculator

  @max_allowed_depth 32

  def apply(%OIR{} = oir) do
    depth = DepthCalculator.depth(oir)
    
    if depth > @max_allowed_depth do
      raise "IR depth #{depth} exceeds maximum allowed depth #{@max_allowed_depth}"
    end

    # Add depth information to metadata
    update_metadata_with_depth(oir, depth)
  end

  defp update_metadata_with_depth(%OIR{children: children} = node, depth) when is_list(children) do
    new_children = Enum.map(children, &update_metadata_with_depth(&1, depth))
    %{node | children: new_children, meta: Map.put(node.meta, :calculated_depth, depth)}
  end

  defp update_metadata_with_depth(%OIR{} = node, depth) do
    %{node | meta: Map.put(node.meta, :calculated_depth, depth)}
  end
end
