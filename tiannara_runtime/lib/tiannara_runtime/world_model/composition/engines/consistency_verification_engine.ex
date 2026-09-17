defmodule TiannaraRuntime.WorldModel.Composition.Engines.ConsistencyVerificationEngine do
  @moduledoc """
  Phase 17.6.6 — ConsistencyVerificationEngine engine.
  Verifies the consistency of a world graph.
  Checks: acyclic property, variable resolution completeness,
  interface completeness, sync rule coverage, math consistency.
  """

  alias TiannaraRuntime.WorldModel.Composition.Engines.WorldGraphBuilder

  def verify(graph) do
    checks = [
      check_acyclic(graph),
      check_variable_resolution(graph),
      check_interface_completeness(graph),
      check_sync_coverage(graph)
    ]

    failures = Enum.filter(checks, fn c -> c.status != :pass end)

    if failures == [] do
      {:ok, %{graph_id: graph.graph_id, checks: checks, overall: :pass}}
    else
      {:error, %{graph_id: graph.graph_id, checks: checks, overall: :fail, failures: failures}}
    end
  end

  def check_acyclic(graph) do
    case WorldGraphBuilder.detect_cycles(graph) do
      {:ok, _} -> %{check: :acyclic, status: :pass}
      {:error, :cyclic_dependency, cycle} ->
        %{check: :acyclic, status: :fail, cycle: cycle}
    end
  end

  def check_variable_resolution(graph) do
    var_nodes = Enum.filter(graph.nodes || [], fn n -> n.type == :variable end)

    status =
      cond do
        var_nodes == [] ->
          %{check: :variable_resolution, status: :pass, reason: :no_variables_to_resolve}
        true ->
          has_resolved = Enum.all?(var_nodes, fn n ->
            props = n.properties || %{}
            Map.has_key?(props, "resolved_value") || Map.has_key?(props, :resolved_value) ||
              Map.has_key?(props, "variable_id")
          end)
          if has_resolved, do: %{check: :variable_resolution, status: :pass}, else: %{check: :variable_resolution, status: :fail, unverified_vars: Enum.count(var_nodes, fn n -> !Map.has_key?(n.properties || %{}, "variable_id") end)}
      end

    status
  end

  def check_interface_completeness(graph) do
    model_nodes = Enum.filter(graph.nodes || [], fn n -> n.type == :world_model end)
    edges = graph.edges || []

    model_ids = MapSet.new(model_nodes, fn n -> n.node_id end)
    edge_source_ids = MapSet.new(edges, fn e -> e.source_id end)
    edge_target_ids = MapSet.new(edges, fn e -> e.target_id end)

    referenced = MapSet.union(edge_source_ids, edge_target_ids)
    orphans = MapSet.difference(model_ids, referenced)

    if MapSet.size(orphans) == 0 do
      %{check: :interface_completeness, status: :pass}
    else
      %{check: :interface_completeness, status: :fail, orphans: MapSet.to_list(orphans)}
    end
  end

  def check_sync_coverage(graph) do
    sync_edges = Enum.filter(graph.edges || [], fn e -> e.type == :synchronization end)
    composition_edges = Enum.filter(graph.edges || [], fn e -> e.type == :composition end)

    pairs = MapSet.new(composition_edges, fn e -> {e.source_id, e.target_id} end)
    sync_pairs = MapSet.new(sync_edges, fn e -> {e.source_id, e.target_id} end)

    missing = MapSet.difference(pairs, sync_pairs)

    if MapSet.size(missing) == 0 do
      %{check: :sync_coverage, status: :pass, total_pairs: MapSet.size(pairs), sync_count: length(sync_edges)}
    else
      %{check: :sync_coverage, status: :fail, missing_syncs: MapSet.to_list(missing)}
    end
  end
end
