defmodule Tiannara.Meta.CausalDataLayer.Traversal do
  @moduledoc "Sparse causal traversal over an explicitly supplied graph snapshot."

  def get_sparse_snapshot(%{nodes: nodes, edges: edges}) when is_list(nodes) and is_list(edges) do
    {:ok, %{nodes: nodes, edges: edges}}
  end
  def get_sparse_snapshot(%{graph: graph}), do: get_sparse_snapshot(graph)
  def get_sparse_snapshot(_world_id), do: {:error, :causal_snapshot_not_loaded}
end
