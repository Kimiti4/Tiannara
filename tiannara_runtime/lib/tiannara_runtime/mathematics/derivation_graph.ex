defmodule TiannaraRuntime.Mathematics.DerivationGraph do
  @moduledoc """
  Immutable-style derivation lineage for mathematical reasoning.

  Each node records a mathematical object and the rule/evidence that produced it.
  The graph is explanatory provenance, not proof by itself.
  """

  alias TiannaraRuntime.Mathematics.MathematicalID

  def new(root) do
    id = MathematicalID.from_canonical_map(%{"root" => root})
    %{graph_id: "derivation_" <> id, roots: [node_id(root)], nodes: %{node_id(root) => root_node(root)}, edges: []}
  end

  def add(graph, parent_id, result, rule, conditions \ []) do
    if Map.has_key?(graph.nodes, parent_id) do
      id = node_id(result)
      node = %{id: id, object: result, status: :derived}
      edge = %{from: parent_id, to: id, rule: rule, side_conditions: conditions}
      {:ok, %{graph | nodes: Map.put(graph.nodes, id, node), edges: graph.edges ++ [edge]}}
    else
      {:error, :parent_node_not_found}
    end
  end

  def node_id(object), do: "node_" <> MathematicalID.from_canonical_map(%{"object" => object})

  defp root_node(object), do: %{id: node_id(object), object: object, status: :root}
end
