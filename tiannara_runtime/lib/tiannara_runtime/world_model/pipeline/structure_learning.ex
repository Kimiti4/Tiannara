defmodule TiannaraRuntime.WorldModel.Pipeline.StructureLearning do
  @moduledoc """
  Phase 17.2/17.3 — Structure Learning (Pipeline Stage 3).

  Uses Phase 17.3 CausalDiscovery to learn causal graph structure
  from variables and evidence. Falls back to a simple heuristic
  when evidence is minimal.
  """

  @behaviour TiannaraRuntime.WorldModel.Behaviours.Pipeline

  alias TiannaraRuntime.WorldModel.Ontology.{CausalGraph, CausalNode, CausalEdge, Variable}
  alias TiannaraRuntime.CausalDiscovery.{CausalReplay, IndependenceEngine, StructureLearner}

  @impl true
  @spec learn_structure(map(), map()) :: {:ok, map()} | {:error, String.t()}
  def learn_structure(variable_set, evidence_set) do
    variables = Map.get(variable_set, :variables, Map.get(variable_set, "variables", []))

    if has_observational_data?(evidence_set) and length(variables) >= 2 do
      learn_structure_causal(evidence_set, variables)
    else
      learn_structure_heuristic(variables)
    end
  end

  @spec learn_structure_causal(map(), [Variable.t()]) :: {:ok, map()} | {:error, String.t()}
  defp learn_structure_causal(evidence_set, variables) do
    config = %{alpha: 0.05, max_conditioning_size: 3}
    causal_evidence = convert_to_causal_evidence(evidence_set)

    result =
      try do
        CausalReplay.replay_discovery(causal_evidence, config)
      rescue
        e -> {:error, "CausalReplay unavailable: #{Exception.message(e)}"}
      end

    case result do
      {:ok, %{causal_graph: graph, causal_root: root}} ->
        {:ok, %{causal_graph: graph, structure_root: root}}
      {:error, _reason} ->
        learn_structure_heuristic(variables)
    end
  end

  @spec learn_structure_heuristic([Variable.t()]) :: {:ok, map()} | {:error, String.t()}
  defp learn_structure_heuristic(variables) do
    nodes = build_nodes(variables)
    edges = []

    with {:ok, graph} <- CausalGraph.new(
           nodes: nodes,
           edges: edges,
           latent_variables: [],
           confounders: [],
           do_calculus_level: 1
         ),
         :ok <- validate_acyclic(graph) do
      structure_root = compute_structure_root(graph)
      {:ok, %{causal_graph: graph, structure_root: structure_root}}
    end
  end

  @spec build_nodes([Variable.t()]) :: [CausalNode.t()]
  def build_nodes(variables) do
    variables
    |> Enum.map(fn v ->
      {:ok, node} =
        CausalNode.new(
          node_id: v.variable_id,
          type: if(v.is_endogenous, do: :endogenous, else: :exogenous),
          metadata: %{name: v.name}
        )
      node
    end)
  end

  @spec build_edges([Variable.t()], [CausalNode.t()]) :: [CausalEdge.t()]
  def build_edges(variables, nodes) do
    var_ids = MapSet.new(variables, & &1.variable_id)
    node_ids = MapSet.new(nodes, & &1.node_id)
    shared = MapSet.intersection(var_ids, node_ids) |> MapSet.to_list()

    if length(shared) < 2 do
      []
    else
      shared
      |> Enum.chunk_every(2, 1, :discard)
      |> Enum.reject(fn pair -> length(pair) < 2 end)
      |> Enum.map(fn [src, tgt] ->
        {:ok, edge} = CausalEdge.new(source: src, target: tgt, type: :direct)
        edge
      end)
    end
  end

  @spec validate_acyclic(CausalGraph.t()) :: :ok | {:error, String.t()}
  def validate_acyclic(%CausalGraph{nodes: nodes, edges: edges}) do
    adjacency = build_adjacency_list(edges)
    node_ids = Enum.map(nodes, & &1.node_id)
    if has_cycle?(adjacency, node_ids) do
      {:error, "Causal graph contains a cycle"}
    else
      :ok
    end
  end

  @spec compute_structure_root(CausalGraph.t()) :: String.t()
  def compute_structure_root(%CausalGraph{} = graph) do
    canonical =
      %{
        nodes: Enum.map(graph.nodes, &canonical_node/1),
        edges: Enum.map(graph.edges, &canonical_edge/1),
        latent_variables: graph.latent_variables,
        do_calculus_level: graph.do_calculus_level
      }
      |> Jason.encode!()
    :crypto.hash(:sha256, canonical) |> Base.encode16(case: :lower)
  end

  defp has_observational_data?(evidence_set) do
    map_size(evidence_set) > 0 and
      Enum.any?(evidence_set, fn {_k, v} -> is_list(v) and length(v) > 1 end)
  end

  defp convert_to_causal_evidence(evidence_set) do
    observations = Map.get(evidence_set, :observations, Map.get(evidence_set, "observations", []))
    Enum.reduce(observations, %{}, fn obs, acc ->
      payload = Map.get(obs, "payload", Map.get(obs, :payload, %{}))
      Enum.reduce(payload, acc, fn {key, val}, inner_acc ->
        key_str = to_string(key)
        Map.update(inner_acc, key_str, [val], &(&1 ++ [val]))
      end)
    end)
  end

  defp build_adjacency_list(edges) do
    Enum.reduce(edges, %{}, fn e, acc ->
      Map.update(acc, e.source, [e.target], fn targets -> [e.target | targets] end)
    end)
  end

  defp has_cycle?(adjacency, node_ids) do
    Enum.any?(node_ids, fn start ->
      cycle?(adjacency, start, MapSet.new(), MapSet.new())
    end)
  end

  defp cycle?(adjacency, node, path, visited) do
    cond do
      MapSet.member?(path, node) -> true
      MapSet.member?(visited, node) -> false
      true ->
        path = MapSet.put(path, node)
        visited = MapSet.put(visited, node)
        neighbors = Map.get(adjacency, node, [])
        Enum.any?(neighbors, fn neighbor ->
          cycle?(adjacency, neighbor, path, visited)
        end)
    end
  end

  defp canonical_node(%CausalNode{node_id: id, type: type}) do
    %{"node_id" => id, "type" => type}
  end

  defp canonical_edge(%CausalEdge{source: s, target: t, type: type, confidence: c}) do
    %{"source" => s, "target" => t, "type" => type, "confidence" => c}
  end
end
