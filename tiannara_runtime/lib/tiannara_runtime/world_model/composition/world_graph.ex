defmodule TiannaraRuntime.WorldModel.Composition.WorldGraph do
  @moduledoc """
  Phase 17.6.1 — WorldGraph struct.
  A directed graph where nodes are world models, variables, equations, causal structures,
  evidence, predictions, and counterfactuals. Edges represent dependency, causality,
  synchronization, composition, and ownership.
  Fields: graph_id, nodes, edges, metadata.
  """
  defstruct [:graph_id, :nodes, :edges, :metadata]

  @type t :: %__MODULE__{
          graph_id: String.t() | nil,
          nodes: [TiannaraRuntime.WorldModel.Composition.WorldNode.t()],
          edges: [TiannaraRuntime.WorldModel.Composition.WorldEdge.t()],
          metadata: map() | nil
        }

  def generate_id(canonical) when is_map(canonical) do
    hash =
      :crypto.hash(:sha256, Jason.encode!(deep_struct_to_map(canonical))) |> Base.encode16(case: :lower)
    "wg_" <> hash
  end

  defp deep_struct_to_map(value) when is_struct(value) do
    value
    |> Map.from_struct()
    |> Enum.map(fn {k, v} -> {k, deep_struct_to_map(v)} end)
    |> Map.new()
  end

  defp deep_struct_to_map(value) when is_map(value) do
    Enum.map(value, fn {k, v} -> {k, deep_struct_to_map(v)} end) |> Map.new()
  end

  defp deep_struct_to_map(value) when is_list(value) do
    Enum.map(value, &deep_struct_to_map/1)
  end

  defp deep_struct_to_map(value), do: value
end
