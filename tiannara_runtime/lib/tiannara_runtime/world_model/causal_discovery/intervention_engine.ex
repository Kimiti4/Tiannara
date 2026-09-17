defmodule TiannaraRuntime.CausalDiscovery.InterventionEngine do
  alias TiannaraRuntime.WorldModel.Ontology.CausalGraph
  alias TiannaraRuntime.WorldModel.Ontology.Intervention
  alias TiannaraRuntime.CausalDiscovery.InterventionPlan

  @spec plan_intervention(CausalGraph.t(), String.t(), term(), keyword()) :: {:ok, InterventionPlan.t()} | {:error, String.t()}
  def plan_intervention(%CausalGraph{nodes: nodes, latent_variables: latents, graph_fingerprint: fp}, target_variable, set_value, opts \\ []) do
    target_node = Enum.find(nodes, &(&1.node_id == target_variable))
    case target_node do
      nil -> {:error, "Target variable '#{target_variable}' not found in graph"}
      _ ->
        intervention_type = infer_intervention_type(set_value)
        identifiability = determine_identifiability(latents)
        do_operator = Keyword.get(opts, :do_operator, "do")
        conditional_values = Keyword.get(opts, :conditional_values)

        {:ok, plan} = InterventionPlan.new(
          target_variable: target_variable,
          intervention_type: intervention_type,
          set_value: set_value,
          conditional_values: conditional_values,
          do_operator: do_operator,
          graph_fingerprint: fp,
          identifiability: identifiability
        )

        {:ok, plan}
    end
  end

  @spec identify_controllable(CausalGraph.t()) :: [String.t()]
  def identify_controllable(%CausalGraph{nodes: nodes}) do
    nodes
    |> Enum.filter(&(&1.type == :exogenous))
    |> Enum.map(& &1.node_id)
  end

  @spec trace_pathway(CausalGraph.t(), String.t(), String.t()) :: {:ok, [String.t()]} | {:error, :no_path}
  def trace_pathway(%CausalGraph{edges: edges, nodes: nodes}, source, target) do
    node_ids = MapSet.new(nodes, & &1.node_id)
    cond do
      not MapSet.member?(node_ids, source) -> {:error, :no_path}
      not MapSet.member?(node_ids, target) -> {:error, :no_path}
      true ->
        adj = build_adjacency(edges)
        case bfs_path(adj, source, target) do
          nil -> {:error, :no_path}
          path -> {:ok, path}
        end
    end
  end

  @spec predict_effect(CausalGraph.t(), Intervention.t(), String.t()) :: {:ok, %{expected: float(), confidence_interval: map()}} | {:error, String.t()}
  def predict_effect(%CausalGraph{} = graph, %Intervention{target_variable: iv_target}, target_var) do
    case trace_pathway(graph, iv_target, target_var) do
      {:ok, _path} ->
        {:ok, %{expected: 0.0, confidence_interval: %{lower: -1.0, upper: 1.0, confidence_level: 0.95}}}
      {:error, :no_path} ->
        {:error, "No causal pathway from '#{iv_target}' to '#{target_var}'"}
    end
  end

  @spec verify_identifiability(CausalGraph.t(), Intervention.t(), String.t()) :: :identified | :partial | :non_identifiable
  def verify_identifiability(%CausalGraph{latent_variables: latents} = graph, %Intervention{target_variable: iv_target}, target_var) do
    case trace_pathway(graph, iv_target, target_var) do
      {:ok, _path} ->
        if is_list(latents) and length(latents) > 0, do: :partial, else: :identified
      {:error, :no_path} ->
        :non_identifiable
    end
  end

  defp infer_intervention_type(:remove), do: :atomic
  defp infer_intervention_type({:fix, _}), do: :atomic
  defp infer_intervention_type({:set_distribution, _}), do: :stochastic
  defp infer_intervention_type(_), do: :atomic

  defp determine_identifiability(latents) do
    if is_list(latents) and length(latents) > 0, do: :partial, else: :identified
  end

  defp build_adjacency(edges) do
    Enum.reduce(edges, %{}, fn e, acc ->
      Map.update(acc, e.source, [e.target], fn existing -> [e.target | existing] end)
    end)
  end

  defp bfs_path(adj, source, target) do
    do_bfs_path(:queue.from_list([{source, [source]}]), MapSet.new([source]), adj, target)
  end

  defp do_bfs_path(queue, visited, adj, target) do
    case :queue.out(queue) do
      {{:value, {node, path}}, queue_tail} ->
        if node == target do
          Enum.reverse(path)
        else
          neighbors = Map.get(adj, node, [])
          {queue_tail, visited} = Enum.reduce(neighbors, {queue_tail, visited}, fn n, {q, vis} ->
            if MapSet.member?(vis, n) do
              {q, vis}
            else
              {:queue.in({n, [n | path]}, q), MapSet.put(vis, n)}
            end
          end)
          do_bfs_path(queue_tail, visited, adj, target)
        end
      {:empty, _} ->
        nil
    end
  end
end
