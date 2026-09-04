defmodule Tiannara.Sentinel.CausalIntelligence do
  @moduledoc """
  Causal Intelligence — root-cause analysis and impact propagation
  through a directed causal graph of observed events, metrics, and
  subsystem states within Tiannara.

  Maintains an ETS-backed causal graph and provides:
  - Backward traversal to identify root causes of anomalies
  - Forward traversal to predict downstream impact
  - Causal pathway explanations for human understanding
  - Integration with AnomalyDetector and the Observation system
  """
  use GenServer
  require Logger

  # ── Configuration ──

  @max_depth 10
  @min_confidence 0.1
  @default_edge_weight 0.5

  # ── Public API ──

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Records a causal relationship: `cause` leads to `effect`.
  Edge weight represents causal strength (0.0 to 1.0).
  """
  def record_causal_link(cause, effect, opts \\ []) do
    weight = Map.get(opts, :weight, @default_edge_weight)
    confidence = Map.get(opts, :confidence, 0.8)
    metadata = Map.get(opts, :metadata, %{})
    GenServer.cast(__MODULE__, {:record_causal_link, cause, effect, weight, confidence, metadata})
  end

  @doc """
  Records a node in the causal graph. A node represents an observable
  entity: a metric, event, subsystem state, or discovery.
  """
  def record_node(node_id, type, opts \\ []) do
    metadata = Map.get(opts, :metadata, %{})
    GenServer.cast(__MODULE__, {:record_node, node_id, type, metadata})
  end

  @doc """
  Traces backwards from an effect to find root causes.
  Returns a list of causal pathways, each with a chain of nodes
  from root cause to the given effect.
  """
  def trace_root_causes(effect_id, opts \\ []) do
    max_depth = Map.get(opts, :max_depth, @max_depth)
    min_confidence = Map.get(opts, :min_confidence, @min_confidence)
    GenServer.call(__MODULE__, {:trace_root_causes, effect_id, max_depth, min_confidence})
  end

  @doc """
  Traces forwards from a cause to find all downstream effects.
  Returns a list of pathways showing impact propagation.
  """
  def trace_impact(cause_id, opts \\ []) do
    max_depth = Map.get(opts, :max_depth, @max_depth)
    GenServer.call(__MODULE__, {:trace_impact, cause_id, max_depth})
  end

  @doc """
  Given an anomaly from AnomalyDetector, finds likely root causes
  by matching anomaly keys to causal graph nodes.
  """
  def analyze_anomaly(anomaly) do
    anomaly_key = Map.get(anomaly, :key, Map.get(anomaly, :subsystem))
    GenServer.call(__MODULE__, {:analyze_anomaly, anomaly_key, anomaly})
  end

  @doc """
  Returns the full causal graph as nodes and edges for visualization.
  """
  def get_graph do
    GenServer.call(__MODULE__, :get_graph)
  end

  @doc """
  Returns the adjacency map for a given node.
  """
  def get_node(node_id) do
    GenServer.call(__MODULE__, {:get_node, node_id})
  end

  # ── GenServer Callbacks ──

  @impl true
  def init(_opts) do
    :ets.new(:causal_nodes, [:set, :public, :named_table])
    # edges: {from, to, weight, confidence, metadata}
    :ets.new(:causal_edges, [:bag, :public, :named_table])
    Logger.info("🧠 [CAUSAL] Causal Intelligence initialized.")
    {:ok, %{
      nodes_table: :causal_nodes,
      edges_table: :causal_edges
    }}
  end

  @impl true
  def handle_cast({:record_node, node_id, type, metadata}, state) do
    entry = {node_id, type, metadata, DateTime.utc_now()}
    :ets.insert(state.nodes_table, entry)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:record_causal_link, cause, effect, weight, confidence, metadata}, state) do
    edge = {cause, effect, weight, confidence, metadata}
    :ets.insert(state.edges_table, edge)
    Logger.debug("[CAUSAL] Link: #{cause} -> #{effect} (w=#{weight}, c=#{confidence})")
    {:noreply, state}
  end

  @impl true
  def handle_call({:trace_root_causes, effect_id, max_depth, min_confidence}, _from, state) do
    pathways = find_root_causes(state.edges_table, state.nodes_table, effect_id, max_depth, min_confidence)
    {:reply, pathways, state}
  end

  @impl true
  def handle_call({:trace_impact, cause_id, max_depth}, _from, state) do
    pathways = find_downstream(state.edges_table, state.nodes_table, cause_id, max_depth)
    {:reply, pathways, state}
  end

  @impl true
  def handle_call({:analyze_anomaly, anomaly_key, anomaly}, _from, state) do
    analysis = analyze_anomaly_internal(state.edges_table, state.nodes_table, anomaly_key, anomaly)
    {:reply, analysis, state}
  end

  @impl true
  def handle_call(:get_graph, _from, state) do
    nodes = :ets.tab2list(state.nodes_table)
    edges = :ets.tab2list(state.edges_table)
    {:reply, %{nodes: nodes, edges: edges}, state}
  end

  @impl true
  def handle_call({:get_node, node_id}, _from, state) do
    result = case :ets.lookup(state.nodes_table, node_id) do
      [{_id, type, metadata, ts}] ->
        incoming_edges = find_incoming_edges(state.edges_table, node_id)
        outgoing_edges = find_outgoing_edges(state.edges_table, node_id)
        %{
          id: node_id,
          type: type,
          metadata: metadata,
          recorded_at: ts,
          causes: incoming_edges,
          effects: outgoing_edges
        }
      [] -> {:error, :not_found}
    end
    {:reply, result, state}
  end

  # ── Private Helpers ──

  defp find_root_causes(edges_table, _nodes_table, start, max_depth, min_confidence) do
    do_trace_backward(edges_table, start, max_depth, min_confidence, [start], 0)
    |> Enum.filter(fn pathway -> length(pathway) > 1 end)
    |> Enum.sort_by(fn pathway -> pathway |> Enum.map(fn {_id, _w, c} -> c end) |> Enum.sum() end, :desc)
  end

  defp do_trace_backward(_edges_table, _node, max_depth, _min_confidence, path, depth) when depth >= max_depth do
    [Enum.reverse(path)]
  end

  defp do_trace_backward(edges_table, node, max_depth, min_confidence, path, depth) do
    causes = find_incoming_edges(edges_table, node)
    |> Enum.filter(fn {_cause, _effect, _weight, confidence, _meta} ->
      confidence >= min_confidence
    end)

    if causes == [] do
      [Enum.reverse(path)]
    else
      causes
      |> Enum.flat_map(fn {cause, _effect, weight, confidence, _meta} ->
        if cause in path do
          [Enum.reverse(path)]
        else
          extended_path = [{cause, weight, confidence} | path]
          do_trace_backward(edges_table, cause, max_depth, min_confidence, extended_path, depth + 1)
        end
      end)
    end
  end

  defp find_downstream(edges_table, _nodes_table, start, max_depth) do
    do_trace_forward(edges_table, start, max_depth, [start], 0)
    |> Enum.filter(fn pathway -> length(pathway) > 1 end)
  end

  defp do_trace_forward(_edges_table, _node, max_depth, path, depth) when depth >= max_depth do
    [Enum.reverse(path)]
  end

  defp do_trace_forward(edges_table, node, max_depth, path, depth) do
    effects = find_outgoing_edges(edges_table, node)

    if effects == [] do
      [Enum.reverse(path)]
    else
      effects
      |> Enum.flat_map(fn {_cause, effect, weight, confidence, _meta} ->
        if effect in path do
          [Enum.reverse(path)]
        else
          extended_path = [{effect, weight, confidence} | path]
          do_trace_forward(edges_table, effect, max_depth, extended_path, depth + 1)
        end
      end)
    end
  end

  defp find_incoming_edges(table, node_id) do
    :ets.match_object(table, {:_, node_id, :_, :_, :_})
  end

  defp find_outgoing_edges(table, node_id) do
    :ets.match_object(table, {node_id, :_, :_, :_, :_})
  end

  defp analyze_anomaly_internal(edges_table, nodes_table, anomaly_key, anomaly) do
    root_causes = find_root_causes(edges_table, nodes_table, anomaly_key, @max_depth, @min_confidence)

    top_pathways = Enum.take(root_causes, 5)
    |> Enum.map(fn pathway ->
      %{
        root: List.first(pathway),
        path: pathway,
        chain_length: length(pathway),
        average_confidence: pathway |> Enum.map(fn {_id, _w, c} -> c end) |> then(fn cs -> if cs == [], do: 0.0, else: Enum.sum(cs) / length(cs) end)
      }
    end)

    primary_root = case top_pathways do
      [] -> nil
      [best | _] ->
        case best.root do
          {root_id, _w, _c} -> root_id
          _ -> best.root
        end
    end

    explanations = if top_pathways != [] do
      generate_pathway_explanations(top_pathways)
    else
      [%{message: "No causal root found — anomaly may be novel or uncorrelated", confidence: 0.3}]
    end

    %{
      anomaly_key: anomaly_key,
      severity: Map.get(anomaly, :severity, :unknown),
      primary_root_cause: primary_root,
      root_cause_pathways: top_pathways,
      explanations: explanations,
      confidence: if(top_pathways != [], do: hd(top_pathways).average_confidence, else: 0.0)
    }
  end

  defp generate_pathway_explanations(pathways) do
    Enum.map(pathways, fn pathway ->
      path_names = pathway.path |> Enum.map(fn {id, _w, _c} -> to_string(id) end)
      avg_conf = pathway.average_confidence

      direction = cond do
        avg_conf >= 0.8 -> "strong causal chain"
        avg_conf >= 0.5 -> "moderate causal chain"
        true -> "weak causal chain"
      end

      %{
        message: "#{direction}: #{Enum.join(Enum.reverse(path_names), " → ")}",
        confidence: avg_conf,
        chain_length: pathway.chain_length,
        nodes: path_names
      }
    end)
  end
end
