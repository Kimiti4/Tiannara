defmodule TiannaraRuntime.CausalDiscovery.GraphValidator do
  alias TiannaraRuntime.WorldModel.Ontology.CausalGraph
  alias TiannaraRuntime.WorldModel.Ontology.Intervention
  alias TiannaraRuntime.CausalDiscovery.ValidationCheck
  alias TiannaraRuntime.CausalDiscovery.CausalValidationResult

  @spec validate_acyclic(CausalGraph.t()) :: :ok | {:error, [String.t()]}
  def validate_acyclic(%CausalGraph{edges: edges, nodes: nodes}) do
    adj = build_adjacency(edges)
    node_ids = Enum.map(nodes, & &1.node_id)
    case find_cycles(adj, node_ids) do
      [] -> :ok
      cycles -> {:error, cycles}
    end
  end

  @spec validate_reachability(CausalGraph.t()) :: :ok | {:error, [String.t()]}
  def validate_reachability(%CausalGraph{edges: edges, nodes: nodes}) do
    adj = build_adjacency(edges)
    exogenous_ids = nodes |> Enum.filter(&(&1.type == :exogenous)) |> Enum.map(& &1.node_id)
    all_ids = MapSet.new(nodes, & &1.node_id)
    reached = bfs_reachable(adj, exogenous_ids)
    unreachable = MapSet.difference(all_ids, reached) |> MapSet.to_list()
    case unreachable do
      [] -> :ok
      _ -> {:error, unreachable}
    end
  end

  @spec validate_do_calculus(CausalGraph.t()) :: {:ok, 1 | 2 | 3}
  def validate_do_calculus(%CausalGraph{latent_variables: latents, confounders: confounders}) do
    level = cond do
      is_list(latents) and length(latents) > 0 -> 3
      is_list(confounders) and length(confounders) > 0 -> 2
      true -> 1
    end
    {:ok, level}
  end

  @spec validate_intervention_safety(CausalGraph.t(), Intervention.t()) :: :ok | {:error, String.t()}
  def validate_intervention_safety(%CausalGraph{nodes: nodes}, %Intervention{target_variable: tv, do_operator: dop}) do
    node_ids = MapSet.new(nodes, & &1.node_id)
    cond do
      not MapSet.member?(node_ids, tv) ->
        {:error, "Intervention target '#{tv}' not found in graph nodes"}
      dop not in ~w(atomic conditional stochastic)a ->
        {:error, "Invalid do_operator: #{inspect(dop)}"}
      true ->
        :ok
    end
  end

  @spec validate_replay(CausalGraph.t(), list(), map()) :: :ok | {:error, String.t()}
  def validate_replay(%CausalGraph{graph_fingerprint: fp, edges: edges}, evidence_set, config) do
    cond do
      is_nil(fp) ->
        {:error, "Graph fingerprint is nil; cannot verify replay"}
      evidence_set == nil or (is_list(evidence_set) and evidence_set == []) ->
        {:error, "No evidence set provided for replay verification"}
      length(edges) > 0 and config == %{} ->
        {:error, "Graph has edges but no replay configuration"}
      true ->
        :ok
    end
  end

  @spec validate_all(CausalGraph.t(), keyword()) :: {:ok, CausalValidationResult.t()}
  def validate_all(%CausalGraph{} = graph, opts \\ []) do
    acyclic = case validate_acyclic(graph) do
      :ok -> build_check("acyclic", :pass)
      {:error, details} -> build_check("acyclic", :fail, inspect(details))
    end

    reachability = case validate_reachability(graph) do
      :ok -> build_check("reachability", :pass)
      {:error, details} -> build_check("reachability", :fail, inspect(details))
    end

    {do_level, _} = validate_do_calculus(graph)
    do_calc = build_check("do_calculus", :pass, "Level #{do_level}")

    replay = case validate_replay(graph, Keyword.get(opts, :evidence_set), Keyword.get(opts, :config)) do
      :ok -> build_check("replay", :pass)
      {:error, details} -> build_check("replay", :fail, details)
    end

    checks = [acyclic, reachability, do_calc, replay]

    checks = case Keyword.get(opts, :intervention) do
      nil -> checks
      %Intervention{} = iv -> case validate_intervention_safety(graph, iv) do
        :ok -> checks ++ [build_check("intervention_safety", :pass)]
        {:error, details} -> checks ++ [build_check("intervention_safety", :fail, details)]
      end
    end

    overall = cond do
      Enum.any?(checks, &(&1.status == :fail)) -> :fail
      Enum.all?(checks, &(&1.status == :pass)) -> :pass
      true -> :inconclusive
    end

    {:ok, vr} = CausalValidationResult.new(
      graph_fingerprint: graph.graph_fingerprint,
      checks: checks,
      overall: overall
    )

    {:ok, vr}
  end

  defp build_check(name, status, details \\ nil) do
    {:ok, vc} = ValidationCheck.new(check_name: name, status: status, details: details)
    vc
  end

  defp build_adjacency(edges) do
    Enum.reduce(edges, %{}, fn e, acc ->
      Map.update(acc, e.source, [e.target], fn existing -> [e.target | existing] end)
    end)
  end

  defp find_cycles(adj, node_ids) do
    {cycles, _, _} = Enum.reduce(node_ids, {[], MapSet.new(), MapSet.new()}, fn node, {cy, vis, ps} ->
      if MapSet.member?(vis, node), do: {cy, vis, ps}, else: dfs_cycle(node, adj, vis, ps, [], cy)
    end)
    Enum.reverse(cycles)
  end

  defp dfs_cycle(node, adj, visited, path_set, path, cycles_acc) do
    visited = MapSet.put(visited, node)
    path_set = MapSet.put(path_set, node)
    current_path = [node | path]

    {cycles_acc, visited, path_set} =
      Map.get(adj, node, [])
      |> Enum.reduce({cycles_acc, visited, path_set}, fn neighbor, {cy, vis, ps} ->
        cond do
          MapSet.member?(ps, neighbor) ->
            cycle_path = [neighbor | current_path] |> Enum.reverse()
            {[cycle_path | cy], vis, ps}
          MapSet.member?(vis, neighbor) ->
            {cy, vis, ps}
          true ->
            dfs_cycle(neighbor, adj, vis, ps, current_path, cy)
        end
      end)

    path_set = MapSet.delete(path_set, node)
    {cycles_acc, visited, path_set}
  end

  defp bfs_reachable(adj, seeds) do
    do_bfs(adj, :queue.from_list(seeds), MapSet.new(seeds))
  end

  defp do_bfs(adj, queue, reached) do
    case :queue.out(queue) do
      {{:value, node}, queue_tail} ->
        neighbors = Map.get(adj, node, [])
        {queue_tail, reached} = Enum.reduce(neighbors, {queue_tail, reached}, fn n, {q, r} ->
          if MapSet.member?(r, n), do: {q, r}, else: {:queue.in(n, q), MapSet.put(r, n)}
        end)
        do_bfs(adj, queue_tail, reached)
      {:empty, _} ->
        reached
    end
  end
end
