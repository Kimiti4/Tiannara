defmodule TiannaraRuntime.WorldModel.Composition.Engines.WorldGraphBuilder do
  @moduledoc """
  Phase 17.6.5 — WorldGraphBuilder engine.
  Constructs a deterministic world graph from models, interfaces, variables, and sync rules.
  Performs topological ordering and cycle detection.
  """

  alias TiannaraRuntime.WorldModel.Composition.WorldGraph
  alias TiannaraRuntime.WorldModel.Composition.WorldNode
  alias TiannaraRuntime.WorldModel.Composition.WorldEdge

  @doc """
  Builds a world graph from constituent components.
  Returns {:ok, WorldGraph.t()} or {:error, reason}.
  """
  def build(models, interfaces, variables, sync_rules) do
    {nodes, model_id_to_node_id, _var_id_to_node_id} = build_nodes(models, variables)
    edges = build_edges(interfaces, sync_rules, model_id_to_node_id)

    with {:ok, ordered_nodes} <- topological_sort(nodes, edges) do
      canonical = %{nodes: ordered_nodes, edges: edges}

      graph = %WorldGraph{
        graph_id: WorldGraph.generate_id(canonical),
        nodes: ordered_nodes,
        edges: edges,
        metadata: %{
          model_count: length(models),
          interface_count: length(interfaces),
          variable_count: length(variables),
          sync_rule_count: length(sync_rules)
        }
      }

      {:ok, graph}
    end
  end

  @doc """
  Detects cycles in the graph.
  Returns {:ok, graph} if acyclic, {:error, :cyclic_dependency, cycle} if cyclic.
  """
  def detect_cycles(graph) do
    adjacency = build_adjacency(graph.edges)
    visited = MapSet.new()
    rec_stack = MapSet.new()

    case detect_cycles_from(graph.nodes, adjacency, visited, rec_stack) do
      {:ok, _} -> {:ok, graph}
      {:error, cycle} -> {:error, :cyclic_dependency, cycle}
    end
  end

  defp build_nodes(models, variables) do
    model_nodes =
      Enum.map(models, fn model ->
        %WorldNode{
          node_id: "wn_" <> (:crypto.hash(:sha256, inspect(model)) |> Base.encode16(case: :lower)),
          type: :world_model,
          label: model.name || inspect(model),
          properties: %{"model_id" => model.world_model_id}
        }
      end)

    model_id_to_node_id = Map.new(model_nodes, fn n -> {n.properties["model_id"], n.node_id} end)

    var_nodes =
      Enum.map(variables, fn var ->
        %WorldNode{
          node_id: "wn_" <> (:crypto.hash(:sha256, var.name) |> Base.encode16(case: :lower)),
          type: :variable,
          label: var.name,
          properties: %{"variable_id" => var.variable_id}
        }
      end)

    var_id_to_node_id = Map.new(var_nodes, fn n -> {n.properties["variable_id"], n.node_id} end)

    {model_nodes ++ var_nodes, model_id_to_node_id, var_id_to_node_id}
  end

  defp build_edges(interfaces, sync_rules, model_id_to_node_id) do
    interface_edges =
      Enum.map(interfaces, fn iface ->
        source_node_id = Map.get(model_id_to_node_id, iface.source_domain, iface.source_domain)
        target_node_id = Map.get(model_id_to_node_id, iface.target_domain, iface.target_domain)

        edge_id_canon = %{
          source: source_node_id,
          target: target_node_id,
          type: :composition
        }

        %WorldEdge{
          edge_id: WorldEdge.generate_id(edge_id_canon |> Map.put(:type, :composition)),
          source_id: source_node_id,
          target_id: target_node_id,
          type: :composition,
          metadata: %{interface_id: iface.interface_id}
        }
      end)

    sync_edges =
      Enum.map(sync_rules, fn rule ->
        source_node_id = Map.get(model_id_to_node_id, rule.source_model, rule.source_model)
        target_node_id = Map.get(model_id_to_node_id, rule.target_model, rule.target_model)

        edge_id_canon = %{
          source: source_node_id,
          target: target_node_id,
          type: :synchronization
        }

        %WorldEdge{
          edge_id: WorldEdge.generate_id(edge_id_canon |> Map.put(:type, :synchronization)),
          source_id: source_node_id,
          target_id: target_node_id,
          type: :synchronization,
          metadata: %{rule_id: rule.rule_id, variable: rule.variable}
        }
      end)

    interface_edges ++ sync_edges
  end

  defp topological_sort(nodes, edges) do
    adjacency = build_adjacency(edges)
    in_degree = build_in_degree(nodes, edges)

    queue = :queue.from_list(Enum.filter(nodes, fn n -> Map.get(in_degree, n.node_id, 0) == 0 end))
    sorted = do_topological_sort(queue, in_degree, adjacency, [])

    if length(sorted) == length(nodes) do
      {:ok, Enum.reverse(sorted)}
    else
      cycle_nodes = nodes -- sorted
      {:error, :cyclic_dependency, cycle_nodes}
    end
  end

  defp do_topological_sort(queue, in_degree, adjacency, acc) do
    case :queue.out(queue) do
      {{:value, node}, rest} ->
        neighbors = Map.get(adjacency, node.node_id, [])
        {new_queue, new_in_degree} =
          Enum.reduce(neighbors, {rest, in_degree}, fn neighbor_id, {q, deg} ->
            new_deg = Map.get(deg, neighbor_id, 1) - 1
            if new_deg == 0 do
              neighbor_node = find_node(node, neighbors) # simplified
              {:queue.in(%WorldNode{node_id: neighbor_id}, q), Map.put(deg, neighbor_id, new_deg)}
            else
              {q, Map.put(deg, neighbor_id, new_deg)}
            end
          end)
        do_topological_sort(new_queue, new_in_degree, adjacency, [node | acc])

      {:empty, _} ->
        acc
    end
  end

  defp build_adjacency(edges) do
    Enum.reduce(edges, %{}, fn edge, acc ->
      Map.update(acc, edge.source_id, [edge.target_id], fn existing ->
        [edge.target_id | existing]
      end)
    end)
  end

  defp build_in_degree(nodes, edges) do
    Enum.reduce(edges, %{}, fn edge, acc ->
      Map.update(acc, edge.target_id, 1, &(&1 + 1))
    end)
  end

  defp find_node(_, _), do: nil

  defp detect_cycles_from(nodes, adjacency, visited, rec_stack) do
    Enum.reduce_while(nodes, {:ok, true}, fn node, _acc ->
      node_id = node.node_id

      cond do
        MapSet.member?(rec_stack, node_id) ->
          {:halt, {:error, [node_id]}}

        MapSet.member?(visited, node_id) ->
          {:cont, {:ok, true}}

        true ->
          new_visited = MapSet.put(visited, node_id)
          new_rec_stack = MapSet.put(rec_stack, node_id)
          neighbors = Map.get(adjacency, node_id, [])

          neighbor_nodes =
            Enum.map(neighbors, fn nid ->
              Enum.find(nodes, %WorldNode{node_id: nid}, fn n -> n.node_id == nid end)
            end)

          case detect_cycles_from(neighbor_nodes, adjacency, new_visited, new_rec_stack) do
            {:ok, _} -> {:cont, {:ok, true}}
            {:error, cycle} -> {:halt, {:error, cycle ++ [node_id]}}
          end
      end
    end)
  end
end
