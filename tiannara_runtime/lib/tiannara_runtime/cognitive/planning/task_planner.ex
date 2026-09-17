defmodule TiannaraRuntime.Cognitive.Planning.TaskPlanner do
  alias TiannaraRuntime.Cognitive.Planning.PlanNode
  alias TiannaraRuntime.Cognitive.Planning.PlanEdge

  defp make_node(plan_id, step, subsystem, cost, duration, deps) do
    %PlanNode{
      id: "pn_#{plan_id}_#{step}",
      plan_id: plan_id,
      step: step,
      subsystem: subsystem,
      estimated_cost: cost,
      estimated_duration: duration,
      dependencies: deps,
      fingerprint: "fp_#{plan_id}_#{step}",
      schema_version: 1,
      ontology_version: 1,
      created_with_phase: "18.5",
      migration_version: 0
    }
  end

  defp make_edge(plan_id, src, tgt, rel) do
    %PlanEdge{
      id: "pe_#{plan_id}_#{src}_#{tgt}",
      plan_id: plan_id,
      source_node: src,
      target_node: tgt,
      relationship: rel,
      fingerprint: "fp_edge_#{plan_id}_#{src}_#{tgt}",
      schema_version: 1,
      ontology_version: 1,
      created_with_phase: "18.5",
      migration_version: 0
    }
  end

  def plan(hierarchy) do
    levels = Map.get(hierarchy, :levels, [])
    nodes =
      levels
      |> Enum.with_index(1)
      |> Enum.map(fn {_goal, idx} ->
        make_node("plan_1", idx, :default, 10 * idx, 5 * idx, if(idx > 1, do: ["pn_prev"], else: []))
      end)
    edges =
      nodes
      |> Enum.chunk_every(2, 1, :discard)
      |> Enum.map(fn [src, tgt] ->
        make_edge("plan_1", src.id, tgt.id, :depends_on)
      end)
    {:ok, %{nodes: nodes, edges: edges, node_count: length(nodes), edge_count: length(edges)}}
  end

  def build_task_graph(nodes, edges) do
    graph_map = %{
      nodes: Enum.map(nodes, & &1.id),
      edges: Enum.map(edges, fn e -> %{from: e.source_node, to: e.target_node} end)
    }
    {:ok, graph_map}
  end
end
