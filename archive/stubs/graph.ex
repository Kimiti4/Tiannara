defmodule Graph do
  use Tiannara.Stub, subsystem: :graph, phase: "Omega+", priority: :high

  def out_edges(graph, vertex) do
    stub_result(:out_edges, [graph, vertex], [])
  end
end
