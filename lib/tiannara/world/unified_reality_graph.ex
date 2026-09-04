defmodule Tiannara.World.UnifiedRealityGraph do
  use GenServer
  use Tiannara.ExecutiveService.Base
  require Logger

  alias Tiannara.CEL.Services.ExecutiveMemory
  alias Tiannara.CEL.Kernel.ConstitutionalScore

  @graph_name :world_reality_graph
  @snapshot_interval :timer.minutes(10)

  @impl true
  def id, do: :unified_reality_graph

  @impl true
  def version, do: "2.0.0"

  @impl true
  def capabilities do
    [:entity_management, :relationship_tracking, :causal_reasoning,
     :temporal_queries, :uncertainty_propagation, :provenance_integration,
     :blast_radius_analysis]
  end

  @impl true
  def dependencies, do: [:executive_memory, :executive_service_bus]

  @impl true
  def health do
    if Process.whereis(__MODULE__), do: :healthy, else: :unhealthy
  end

  @impl true
  def constitutional_score do
    stats = if Process.whereis(__MODULE__), do: GenServer.call(__MODULE__, :stats), else: %{healthy: true, entity_count: 0, relationship_count: 0, entities_with_provenance: 0}
    prov_ratio = if stats.entity_count > 0, do: stats.entities_with_provenance / stats.entity_count, else: 1.0

    %ConstitutionalScore{
      service_id: id(), health: if(stats.healthy, do: 1.0, else: 0.0),
      constitutional_alignment: 1.0, transparency: 1.0, explainability: 1.0,
      evidence_quality: prov_ratio, human_oversight: 1.0, computed_at: DateTime.utc_now()
    }
  end

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def add_entity(spec), do: GenServer.call(__MODULE__, {:add_entity, spec})
  def remove_entity(entity_id), do: GenServer.call(__MODULE__, {:remove_entity, entity_id})
  def remove_relationships_for_entity(entity_id), do: GenServer.call(__MODULE__, {:remove_relationships_for_entity, entity_id})
  def add_relationship(spec), do: GenServer.call(__MODULE__, {:add_relationship, spec})
  def get_entity(entity_id), do: GenServer.call(__MODULE__, {:get_entity, entity_id})
  def query_entities(opts \\ []), do: GenServer.call(__MODULE__, {:query_entities, opts})
  def get_relationships(entity_id, direction \\ :both, type_filter \\ nil), do: GenServer.call(__MODULE__, {:get_relationships, entity_id, direction, type_filter})
  def blast_radius(entity_id), do: GenServer.call(__MODULE__, {:blast_radius, entity_id})
  def causal_analysis(entity_ids), do: GenServer.call(__MODULE__, {:causal_analysis, entity_ids})
  def propagate_uncertainty(entity_id, new_confidence, evidence), do: GenServer.call(__MODULE__, {:propagate_uncertainty, entity_id, new_confidence, evidence})
  def historical_state(timestamp), do: GenServer.call(__MODULE__, {:historical_state, timestamp})
  def stats, do: GenServer.call(__MODULE__, :stats)

  def detect_cycles do
    GenServer.call(__MODULE__, :detect_cycles)
  end

  def detect_orphans do
    GenServer.call(__MODULE__, :detect_orphans)
  end

  def tag_orphan(entity_id) do
    GenServer.call(__MODULE__, {:tag_orphan, entity_id})
  end

  @impl true
  def init(_opts) do
    graph = :digraph.new([:cyclic, :protected])
    Process.send_after(self(), :snapshot, @snapshot_interval)
    {:ok, %{
      graph: graph, entity_count: 0, relationship_count: 0,
      entities_with_provenance: 0, mutation_log: [], healthy: true,
      started_at: DateTime.utc_now()
    }}
  end

  @impl true
  def handle_call({:add_entity, spec}, _from, state) do
    with :ok <- validate_spec(spec, [:id, :type]) do
      vertex = {:entity, spec.id}
      enriched = Map.merge(spec, %{ingested_at: DateTime.utc_now(), version: Map.get(spec, :version, 1)})

      {reply, entity_count} = case :digraph.vertex(state.graph, vertex) do
        false ->
          :digraph.add_vertex(state.graph, vertex, enriched)
          {{:ok, spec.id}, state.entity_count + 1}
        _ ->
          :digraph.add_vertex(state.graph, vertex, enriched)
          {{:ok, spec.id}, state.entity_count}
      end

      new_state = %{state | entity_count: entity_count, mutation_log: [spec.id | state.mutation_log]}
      {:reply, reply, new_state}
    else {:error, r} -> {:reply, {:error, r}, state} end
  end

  @impl true
  def handle_call({:remove_entity, entity_id}, _from, state) do
    vertex = {:entity, entity_id}
    :digraph.del_vertex(state.graph, vertex)
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:remove_relationships_for_entity, entity_id}, _from, state) do
    vertex = {:entity, entity_id}
    in_edges = :digraph.in_edges(state.graph, vertex)
    out_edges = :digraph.out_edges(state.graph, vertex)
    Enum.each(in_edges ++ out_edges, fn edge -> :digraph.del_edge(state.graph, edge) end)
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:add_relationship, spec}, _from, state) do
    with :ok <- validate_spec(spec, [:from_id, :to_id, :type]) do
      from = {:entity, spec.from_id}; to = {:entity, spec.to_id}
      ensure_vertex(state.graph, from, spec.from_id)
      ensure_vertex(state.graph, to, spec.to_id)

      case :digraph.add_edge(state.graph, from, to, spec.type, spec) do
        {:error, {:bad_edge, _}} -> {:reply, {:error, :circular_dependency}, state}
        edge -> {:reply, {:ok, edge}, %{state | relationship_count: state.relationship_count + 1}}
      end
    else {:error, r} -> {:reply, {:error, r}, state} end
  end

  @impl true
  def handle_call({:get_entity, entity_id}, _from, state) do
    case :digraph.vertex(state.graph, {:entity, entity_id}) do
      {_, spec} -> {:reply, {:ok, spec}, state}
      false -> {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_call({:query_entities, opts}, _from, state) do
    predicate = Keyword.get(opts, :predicate, fn _ -> true end)
    limit = Keyword.get(opts, :limit, 1000)

    results =
      :digraph.vertices(state.graph)
      |> Enum.filter(fn {:entity, _id} = v ->
        case :digraph.vertex(state.graph, v) do
          {_, spec} -> predicate.(spec)
          _ -> false
        end
      end)
      |> Enum.map(fn {:entity, id} -> id end)
      |> Enum.take(limit)

    {:reply, {:ok, results}, state}
  end

  @impl true
  def handle_call({:get_relationships, entity_id, direction, type_filter}, _from, state) do
    vertex = {:entity, entity_id}
    edges = get_edges(state.graph, vertex, direction)

    results =
      Enum.flat_map(edges, fn edge ->
        case :digraph.edge(state.graph, edge) do
          {_, from, to, type, meta} ->
            if type_filter == nil or type == type_filter do
              [%{edge_id: edge, from: elem(from, 1), to: elem(to, 1), type: type, metadata: meta}]
            else [] end
          _ -> []
        end
      end)

    {:reply, {:ok, results}, state}
  end

  @impl true
  def handle_call({:blast_radius, entity_id}, _from, state) do
    vertex = {:entity, entity_id}
    affected = traverse(state.graph, vertex, [:depends_on, :causes, :supports], :out, MapSet.new(), [])
    {:reply, {:ok, %{entity_id: entity_id, affected_entities: affected}}, state}
  end

  @impl true
  def handle_call({:causal_analysis, entity_ids}, _from, state) do
    effects =
      entity_ids
      |> Enum.flat_map(fn id -> traverse(state.graph, {:entity, id}, [:causes], :out, MapSet.new(), []) end)
      |> Enum.uniq()
    {:reply, {:ok, %{input_entities: entity_ids, downstream_effects: effects}}, state}
  end

  @impl true
  def handle_call({:propagate_uncertainty, entity_id, new_confidence, evidence}, _from, state) do
    vertex = {:entity, entity_id}
    case :digraph.vertex(state.graph, vertex) do
      false -> {:reply, {:error, :not_found}, state}
      {_, spec} ->
        updated = %{spec | confidence: new_confidence, uncertainty: 1.0 - new_confidence,
          evidence: (Map.get(spec, :evidence, []) ++ [evidence]), last_updated: DateTime.utc_now()}
        :digraph.add_vertex(state.graph, vertex, updated)

        Enum.each(get_connected(state.graph, vertex, :depends_on, :in), fn dep_id ->
          case :digraph.vertex(state.graph, {:entity, dep_id}) do
            {_, dep_spec} ->
              dep_conf = (dep_spec.confidence + new_confidence) / 2.0
              :digraph.add_vertex(state.graph, {:entity, dep_id}, %{dep_spec | confidence: dep_conf, last_updated: DateTime.utc_now()})
            _ -> :ok
          end
        end)
        {:reply, :ok, state}
    end
  end

  @impl true
  def handle_call({:historical_state, _timestamp}, _from, state) do
    {:reply, {:ok, %{entity_count: state.entity_count, relationship_count: state.relationship_count}}, state}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    {:reply, %{healthy: state.healthy, entity_count: state.entity_count,
      relationship_count: state.relationship_count, entities_with_provenance: state.entities_with_provenance}, state}
  end

  @impl true
  def handle_call(:detect_orphans, _from, state) do
    all_vertices = :digraph.vertices(state.graph)
    orphans = Enum.filter(all_vertices, fn vertex ->
      edges = :digraph.in_edges(state.graph, vertex) ++ :digraph.out_edges(state.graph, vertex)
      edges == []
    end)
    orphan_ids = Enum.map(orphans, fn {:entity, id} -> id end)
    {:reply, {:ok, orphan_ids}, state}
  end

  @impl true
  def handle_call({:tag_orphan, entity_id}, _from, state) do
    case :digraph.vertex(state.graph, {:entity, entity_id}) do
      {_, spec} ->
        updated = Map.put(spec, :orphan, true)
        :digraph.add_vertex(state.graph, {:entity, entity_id}, updated)
        {:reply, :ok, state}
      false ->
        {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_call(:detect_cycles, _from, state) do
    cycles =
      :digraph.vertices(state.graph)
      |> Enum.reduce([], fn vertex, acc ->
        case :digraph.get_cycle(state.graph, vertex) do
          false -> acc
          cycle -> [cycle | acc]
        end
      end)
      |> Enum.uniq()
    {:reply, {:ok, cycles}, state}
  end

  @impl true
  def handle_info(:snapshot, state) do
    ExecutiveMemory.record_event(:reality_graph, :snapshot, %{entity_count: state.entity_count, relationship_count: state.relationship_count})
    Process.send_after(self(), :snapshot, @snapshot_interval)
    {:noreply, state}
  end

  defp validate_spec(spec, required) do
    missing = Enum.reject(required, &Map.has_key?(spec, &1))
    if missing == [], do: :ok, else: {:error, {:missing_fields, missing}}
  end

  defp ensure_vertex(graph, vertex, id) do
    unless :digraph.vertex(graph, vertex), do: :digraph.add_vertex(graph, vertex, %{id: id, auto_created: true, ingested_at: DateTime.utc_now()})
  end

  defp get_edges(graph, vertex, direction) do
    case direction do
      :in -> :digraph.in_edges(graph, vertex)
      :out -> :digraph.out_edges(graph, vertex)
      :both -> :digraph.in_edges(graph, vertex) ++ :digraph.out_edges(graph, vertex)
    end
  end

  defp traverse(graph, vertex, allowed, dir, visited, acc) do
    if MapSet.member?(visited, vertex) do
      acc
    else
      visited = MapSet.put(visited, vertex)
      id = elem(vertex, 1)

      allowed_set = MapSet.new(allowed)

      neighbors =
        get_edges(graph, vertex, dir)
        |> Enum.flat_map(fn e ->
          case :digraph.edge(graph, e) do
            {_, from, to, label, _} ->
              if MapSet.member?(allowed_set, label), do: [if(dir == :in, do: from, else: to)], else: []
            _ -> []
          end
        end)

      Enum.reduce(neighbors, [id | acc], fn n, a ->
        traverse(graph, n, allowed, dir, visited, a)
      end)
    end
  end

  defp get_connected(graph, vertex, label, dir) do
    get_edges(graph, vertex, dir)
    |> Enum.flat_map(fn e ->
      case :digraph.edge(graph, e) do
        {_, from, to, ^label, _} ->
          [elem((if dir == :in, do: from, else: to), 1)]
        _ -> []
      end
    end)
  end
end
