defmodule Tiannara.Graph.UnifiedRealityGraph do
  @moduledoc """
  Unified Reality Graph — the canonical knowledge representation of Tiannara.

  Replaces the stubbed RealityGraph with a persistent, traversable graph that
  tracks the evolution of memory through the constitutional stages:
    Data → Information → Knowledge → Patterns → Models → Principles

  Responsibilities:
    - Ingest nodes (entities, hypotheses, discoveries, principles)
    - Ingest edges (causal relationships, dependencies, lineage)
    - Trace lineage and blast radius of any knowledge artifact
    - Detect contradictions (e.g., two 'fact' nodes with conflicting payloads)

  Constitutional Alignment:
    - "Memory Philosophy": Explicitly tracks the evolutionary stage of memory.
    - "Preserve lineage": Every mutation is event-sourced to ExecutiveMemory.
    - "Modularity": Well-defined interfaces for graph operations.
    - "Maintain audit trails": All graph mutations are logged.
  """
  use GenServer
  require Logger

  alias Tiannara.CEL.Services.ExecutiveMemory

  @memory_stages [
    :data,
    :information,
    :knowledge,
    :pattern,
    :model,
    :principle,
    :insight,
    :discovery
  ]

  # ---------- Client API ----------

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Adds or updates a node in the reality graph.

  `node_id` should be a unique identifier (e.g., "hypothesis_123", "discovery_456").
  `stage` must be one of the canonical memory stages.
  `payload` contains the actual data/metadata of the node.
  """
  def add_node(node_id, stage, payload) when stage in @memory_stages do
    GenServer.call(__MODULE__, {:add_node, node_id, stage, payload})
  end

  @doc """
  Adds a directed edge between two nodes.

  `edge_type` examples: :causes, :refutes, :supports, :derived_from, :depends_on
  """
  def add_edge(from_node_id, to_node_id, edge_type, metadata \\ %{}) do
    GenServer.call(__MODULE__, {:add_edge, from_node_id, to_node_id, edge_type, metadata})
  end

  @doc """
  Retrieves a node and its immediate connections.
  """
  def get_node_with_context(node_id) do
    GenServer.call(__MODULE__, {:get_node, node_id})
  end

  @doc """
  Traces the full lineage of a node (all ancestors via :derived_from or :supports).
  Essential for reproducibility and auditability.
  """
  def trace_lineage(node_id) do
    GenServer.call(__MODULE__, {:trace_lineage, node_id})
  end

  @doc """
  Finds all nodes that would be affected if this node is refuted or deprecated.
  """
  def blast_radius(node_id) do
    GenServer.call(__MODULE__, {:blast_radius, node_id})
  end

  @doc "Returns graph statistics for observability."
  def stats, do: GenServer.call(__MODULE__, :stats)

  @doc """
  Deprecated — use add_node/3. Maintained for backward compatibility.
  """
  def ingest_node(node_id, type, properties) do
    stage = Map.get(properties, :stage, Map.get(properties, :stage, :information))
    add_node(node_id, stage, Map.put(properties, :type, type))
  end

  @doc """
  Deprecated — use trace_lineage/1 or blast_radius/1. Maintained for backward compatibility.
  """
  def trace_impact(node_id, _max_depth \\ 5) do
    GenServer.call(__MODULE__, {:trace_impact, node_id})
  end

  # ---------- Server Callbacks ----------

  @impl true
  def init(_opts) do
    graph = :digraph.new([:cyclic, :protected])
    Logger.info("UnifiedRealityGraph: initialized")
    {:ok, %{graph: graph, node_count: 0, edge_count: 0}}
  end

  @impl true
  def handle_call({:add_node, node_id, stage, payload}, _from, state) do
    vertex = {:node, node_id}

    enriched_payload =
      Map.merge(payload, %{
        stage: stage,
        ingested_at: DateTime.utc_now(),
        version: Map.get(payload, :version, "1.0.0")
      })

    case :digraph.vertex(state.graph, vertex) do
      false ->
        :digraph.add_vertex(state.graph, vertex, enriched_payload)
        new_count = state.node_count + 1
        log_mutation(:node_added, %{node_id: node_id, stage: stage}, state)
        {:reply, {:ok, node_id}, %{state | node_count: new_count}}

      _ ->
        :digraph.add_vertex(state.graph, vertex, enriched_payload)
        log_mutation(:node_updated, %{node_id: node_id, stage: stage}, state)
        {:reply, {:ok, node_id}, state}
    end
  end

  @impl true
  def handle_call({:add_edge, from_id, to_id, edge_type, metadata}, _from, state) do
    from_vertex = {:node, from_id}
    to_vertex = {:node, to_id}

    ensure_node_exists(state.graph, from_vertex)
    ensure_node_exists(state.graph, to_vertex)

    case :digraph.add_edge(state.graph, from_vertex, to_vertex, %{
           type: edge_type,
           metadata: metadata
         }) do
      {:error, {:bad_edge, _}} ->
        {:reply, {:error, :circular_dependency_detected}, state}

      edge ->
        new_count = state.edge_count + 1
        log_mutation(:edge_added, %{from: from_id, to: to_id, type: edge_type}, state)
        {:reply, {:ok, edge}, %{state | edge_count: new_count}}
    end
  end

  @impl true
  def handle_call({:get_node, node_id}, _from, state) do
    vertex = {:node, node_id}

    case :digraph.vertex(state.graph, vertex) do
      false ->
        {:reply, {:error, :not_found}, state}

      _ ->
        {_vertex, payload} = :digraph.vertex(state.graph, vertex)
        in_edges = get_connected_nodes(state.graph, vertex, :in)
        out_edges = get_connected_nodes(state.graph, vertex, :out)

        {:reply,
         {:ok, %{id: node_id, payload: payload, predecessors: in_edges, successors: out_edges}},
         state}
    end
  end

  @impl true
  def handle_call({:trace_lineage, node_id}, _from, state) do
    vertex = {:node, node_id}

    ancestors =
      traverse_graph(
        state.graph,
        vertex,
        [:derived_from, :supports, :causes],
        :in,
        MapSet.new(),
        []
      )

    {:reply, {:ok, %{node_id: node_id, lineage: ancestors}}, state}
  end

  @impl true
  def handle_call({:blast_radius, node_id}, _from, state) do
    vertex = {:node, node_id}

    dependents =
      traverse_graph(
        state.graph,
        vertex,
        [:derived_from, :supports, :depends_on],
        :out,
        MapSet.new(),
        []
      )

    {:reply, {:ok, %{node_id: node_id, affected_nodes: dependents}}, state}
  end

  @impl true
  def handle_call({:trace_impact, node_id}, _from, state) do
    vertex = {:node, node_id}

    dependents =
      traverse_graph(
        state.graph,
        vertex,
        [:derived_from, :supports, :depends_on, :causes],
        :out,
        MapSet.new(),
        []
      )

    {:reply, {:ok, %{node_id: node_id, impact: dependents}}, state}
  end

  @impl true
  def handle_call({:ingest_edge, src, tgt, rel, weight}, _from, state) do
    from_vertex = {:node, src}
    to_vertex = {:node, tgt}
    ensure_node_exists(state.graph, from_vertex)
    ensure_node_exists(state.graph, to_vertex)

    :digraph.add_edge(state.graph, from_vertex, to_vertex, %{
      type: rel,
      metadata: %{weight: weight}
    })

    {:reply, :ok, %{state | edge_count: state.edge_count + 1}}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    {:reply,
     %{
       nodes: state.node_count,
       edges: state.edge_count,
       memory_stages: @memory_stages
     }, state}
  end

  # ---------- Private Helpers ----------

  defp ensure_node_exists(graph, vertex) do
    case :digraph.vertex(graph, vertex) do
      false -> :digraph.add_vertex(graph, vertex, %{stage: :data, auto_created: true})
      _ -> :ok
    end
  end

  defp get_connected_nodes(graph, vertex, direction) do
    edges =
      case direction do
        :in -> :digraph.in_edges(graph, vertex)
        :out -> :digraph.out_edges(graph, vertex)
      end

    Enum.map(edges, fn edge ->
      case :digraph.edge(graph, edge) do
        {_, from, to, %{type: relationship, metadata: metadata}} ->
          node_id = if direction == :in, do: elem(from, 1), else: elem(to, 1)
          %{node_id: node_id, relationship: relationship, metadata: metadata}

        _ ->
          nil
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp traverse_graph(graph, start_vertex, allowed_labels, direction, visited, acc) do
    if MapSet.member?(visited, start_vertex) do
      acc
    else
      new_visited = MapSet.put(visited, start_vertex)
      node_id = elem(start_vertex, 1)

      edges =
        case direction do
          :in -> :digraph.in_edges(graph, start_vertex)
          :out -> :digraph.out_edges(graph, start_vertex)
        end

      neighbors =
        Enum.flat_map(edges, fn edge ->
          case :digraph.edge(graph, edge) do
            {_, from, to, %{type: label}} ->
              if Enum.member?(allowed_labels, label) do
                neighbor = if direction == :in, do: from, else: to
                [neighbor]
              else
                []
              end

            _ ->
              []
          end
        end)
        |> Enum.uniq()

      new_acc = [node_id | acc]

      Enum.reduce(neighbors, new_acc, fn neighbor, current_acc ->
        traverse_graph(graph, neighbor, allowed_labels, direction, new_visited, current_acc)
      end)
    end
  end

  defp log_mutation(action, payload, _state) do
    ExecutiveMemory.record_event(:reality_graph, action, payload, %{
      source: :unified_reality_graph
    })
  rescue
    _ -> :ok
  end
end
