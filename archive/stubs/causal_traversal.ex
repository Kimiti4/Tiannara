defmodule Tiannara.Meta.CausalDataLayer.Traversal do
  use Tiannara.Stub, subsystem: :meta, phase: "Omega+", priority: :high

  def get_sparse_snapshot(world_id) do
    stub_result(:get_sparse_snapshot, [world_id], %{nodes: [], edges: []})
  end
end
