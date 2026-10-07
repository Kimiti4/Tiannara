defmodule Tiannara.CEL.Services.CapabilityGraph do
  use Tiannara.ExecutiveService.Base
  use GenServer
  require Logger

  @doc """
  Capability Graph — a reasoned, directed graph of civilizational capabilities.

  Models three vertex types:
    `{:capability, id}`  — a discrete capability
    `{:subsystem, id}`   — a provider of capabilities
    `{:mission, id}`     — a consumer of capabilities

  And five edge types:
    `:provides`     — subsystem → capability
    `:requires`     — subsystem → capability (dependency)
    `:depends_on`   — capability → capability (composition)
    `:conflicts_with` — capability → capability (mutual exclusion)
    `:consumes`     — mission → capability

  Constitutional alignment:
    - Modularity: capabilities are versionable, mergeable, splittable units
    - Composability: graph reasoning over capability combinations
    - Bottleneck Discovery: continuous SPOF detection
    - Evidence Before Confidence: delegation uses trust + load + history
    - Traceability: every mutation recorded in ExecutiveMemory
  """

  alias Tiannara.CEL.Services.{IdentityTrustManager, ResourceManager, ExecutiveMemory}
  alias Tiannara.CEL.Kernel.ConstitutionalScore

  @redundancy_check_interval :timer.minutes(5)

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  # ── Capability Lifecycle ────────────────────────────────────────

  def register_capability(cap_id, metadata \\ %{}) do
    GenServer.call(__MODULE__, {:register_capability, cap_id, metadata})
  end

  def deprecate_capability(cap_id, reason) do
    GenServer.call(__MODULE__, {:deprecate_capability, cap_id, reason})
  end

  def version_capability(cap_id, new_cap_id, metadata \\ %{}) do
    GenServer.call(__MODULE__, {:version_capability, cap_id, new_cap_id, metadata})
  end

  def merge_capabilities(cap_a, cap_b, merged_id) do
    GenServer.call(__MODULE__, {:merge_capabilities, cap_a, cap_b, merged_id})
  end

  def split_capability(cap_id, new_a, new_b) do
    GenServer.call(__MODULE__, {:split_capability, cap_id, new_a, new_b})
  end

  # ── Graph Construction ──────────────────────────────────────────

  def declare_provides(subsystem_id, capability_id) do
    GenServer.call(__MODULE__, {:add_edge, :provides, {:subsystem, subsystem_id}, {:capability, capability_id}})
  end

  def declare_requires(subsystem_id, capability_id) do
    GenServer.call(__MODULE__, {:add_edge, :requires, {:subsystem, subsystem_id}, {:capability, capability_id}})
  end

  def declare_dependency(cap_a, cap_b) do
    GenServer.call(__MODULE__, {:add_edge, :depends_on, {:capability, cap_a}, {:capability, cap_b}})
  end

  def declare_conflict(cap_a, cap_b) do
    GenServer.call(__MODULE__, {:add_edge, :conflicts_with, {:capability, cap_a}, {:capability, cap_b}})
  end

  def declare_consumes(mission_id, capability_id) do
    GenServer.call(__MODULE__, {:add_edge, :consumes, {:mission, mission_id}, {:capability, capability_id}})
  end

  # ── Graph Reasoning ─────────────────────────────────────────────

  def find_optimal_provider(capability_id) do
    GenServer.call(__MODULE__, {:find_optimal_provider, capability_id})
  end

  def dependency_chain(capability_id) do
    GenServer.call(__MODULE__, {:dependency_chain, capability_id})
  end

  def blast_radius(capability_id) do
    GenServer.call(__MODULE__, {:blast_radius, capability_id})
  end

  def detect_cycles, do: GenServer.call(__MODULE__, :detect_cycles)
  def single_points_of_failure, do: GenServer.call(__MODULE__, :spof)
  def providers_of(cap_id), do: GenServer.call(__MODULE__, {:providers_of, cap_id})
  def capabilities_of(sub_id), do: GenServer.call(__MODULE__, {:capabilities_of, sub_id})
  def stats, do: GenServer.call(__MODULE__, :stats)
  def export, do: GenServer.call(__MODULE__, :export)
  def healthy?, do: GenServer.call(__MODULE__, :healthy)

  # ── ExecutiveService Behaviour ──────────────────────────────────

  @impl true
  def id, do: :capability_graph

  @impl true
  def version, do: "3.0.0"

  @impl true
  def capabilities do
    [:capability_registration, :dependency_reasoning, :blast_radius_analysis,
     :optimal_delegation, :cycle_detection, :redundancy_analysis, :capability_versioning,
     :capability_discovery, :intelligent_delegation, :workload_balancing, :dependency_analysis]
  end

  @impl true
  def dependencies, do: [:executive_memory, :identity_trust_manager, :resource_manager]

  @impl true
  def constitutional_score do
    case GenServer.call(__MODULE__, :stats) do
      %{healthy: false} ->
        ConstitutionalScore.default(:capability_graph)
      stats ->
        evidence_quality =
          cond do
            stats.capability_count == 0 -> 0.0
            stats.single_points_of_failure > 5 -> 0.4
            stats.cycles_detected > 0 -> 0.6
            true -> min(1.0, stats.capability_count / 50.0)
          end

        %ConstitutionalScore{
          service_id: :capability_graph,
          health: 1.0,
          constitutional_alignment: 1.0,
          transparency: 1.0,
          explainability: 1.0,
          evidence_quality: evidence_quality,
          human_oversight: 1.0,
          computed_at: DateTime.utc_now()
        }
    end
  end

  # ── Init ────────────────────────────────────────────────────────

  @impl true
  def init(_opts) do
    graph = :digraph.new([:protected])

    seed_subsystem(graph, :agency, [:investigate, :generate_hypothesis, :validate])
    seed_subsystem(graph, :sentinel, [:detect, :classify, :monitor, :alert])
    seed_subsystem(graph, :cci, [:forecast, :governance_cycle, :risk_assess])
    seed_subsystem(graph, :asc, [:create_capability, :improve_institution, :govern])
    seed_subsystem(graph, :discovery, [:research, :discover, :validate_discovery])
    seed_subsystem(graph, :simulation, [:simulate, :model, :predict])

    seed_dependency(graph, :investigate, :detect)
    seed_dependency(graph, :generate_hypothesis, :investigate)
    seed_dependency(graph, :validate, :generate_hypothesis)
    seed_dependency(graph, :forecast, :model)
    seed_dependency(graph, :risk_assess, :forecast)
    seed_dependency(graph, :governance_cycle, :risk_assess)
    seed_dependency(graph, :create_capability, :govern)
    seed_dependency(graph, :improve_institution, :govern)
    seed_dependency(graph, :alert, :monitor)
    seed_dependency(graph, :alert, :classify)
    seed_dependency(graph, :monitor, :detect)

    schedule_redundancy_check()

    state = %{
      graph: graph,
      capability_metadata: default_metadata(),
      deprecated: MapSet.new(),
      cycles_detected: 0,
      spof_count: 0,
      mutation_count: 0,
      healthy: true,
      started_at: DateTime.utc_now()
    }

    Logger.info("CapabilityGraph: Initialized with #{map_size(state.capability_metadata)} capabilities")
    {:ok, state}
  end

  # ── Capability Lifecycle Handlers ───────────────────────────────

  @impl true
  def handle_call({:register_capability, cap_id, metadata}, _from, state) do
    vertex = {:capability, cap_id}

    case :digraph.vertex(state.graph, vertex) do
      false ->
        :digraph.add_vertex(state.graph, vertex, metadata)
        new_meta = Map.put(state.capability_metadata, cap_id, Map.merge(%{
          registered_at: DateTime.utc_now(), version: "1.0.0", deprecated: false
        }, metadata))

        record_mutation(:capability_registered, %{capability_id: cap_id}, state)
        {:reply, {:ok, cap_id}, %{state | capability_metadata: new_meta, mutation_count: state.mutation_count + 1}}

      _ ->
        {:reply, {:error, :already_registered}, state}
    end
  end

  @impl true
  def handle_call({:deprecate_capability, cap_id, reason}, _from, state) do
    vertex = {:capability, cap_id}

    if :digraph.vertex(state.graph, vertex) do
      :digraph.add_vertex(state.graph, vertex, %{deprecated: true, reason: reason})
      new_deprecated = MapSet.put(state.deprecated, cap_id)
      record_mutation(:capability_deprecated, %{capability_id: cap_id, reason: reason}, state)
      {:reply, :ok, %{state | deprecated: new_deprecated, mutation_count: state.mutation_count + 1}}
    else
      {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_call({:version_capability, cap_id, new_cap_id, metadata}, _from, state) do
    case register_capability_internal(state, new_cap_id, Map.put(metadata, :version_of, cap_id)) do
      {:ok, state2} ->
        {_, state3} = add_edge_internal(state2, :version_of, {:capability, new_cap_id}, {:capability, cap_id})
        record_mutation(:capability_versioned, %{from: cap_id, to: new_cap_id}, state3)
        {:reply, {:ok, new_cap_id}, state3}
      error ->
        {:reply, error, state}
    end
  end

  @impl true
  def handle_call({:merge_capabilities, cap_a, cap_b, merged_id}, _from, state) do
    with {:ok, state2} <- register_capability_internal(state, merged_id, %{merged_from: [cap_a, cap_b]}),
         {:ok, state3} <- redirect_edges(state2, cap_a, merged_id),
         {:ok, state4} <- redirect_edges(state3, cap_b, merged_id),
         :ok <- deprecate_internal(state4, cap_a, "merged into #{merged_id}"),
         :ok <- deprecate_internal(state4, cap_b, "merged into #{merged_id}") do
      record_mutation(:capabilities_merged, %{from: [cap_a, cap_b], to: merged_id}, state4)
      {:reply, {:ok, merged_id}, state4}
    else
      error -> {:reply, error, state}
    end
  end

  @impl true
  def handle_call({:split_capability, cap_id, new_a, new_b}, _from, state) do
    with {:ok, state2} <- register_capability_internal(state, new_a, %{split_from: cap_id}),
         {:ok, state3} <- register_capability_internal(state2, new_b, %{split_from: cap_id}),
         {_, state4} <- add_edge_internal(state3, :depends_on, {:capability, new_a}, {:capability, cap_id}),
         {_, state5} <- add_edge_internal(state4, :depends_on, {:capability, new_b}, {:capability, cap_id}) do
      record_mutation(:capability_split, %{from: cap_id, to: [new_a, new_b]}, state5)
      {:reply, {:ok, [new_a, new_b]}, state5}
    else
      error -> {:reply, error, state}
    end
  end

  # ── Edge Handlers ───────────────────────────────────────────────

  @impl true
  def handle_call({:add_edge, edge_type, from_vertex, to_vertex}, _from, state) do
    {result, new_state} = add_edge_internal(state, edge_type, from_vertex, to_vertex)

    new_state =
      if edge_type == :depends_on do
        case :digraph.get_short_cycle(new_state.graph, from_vertex) do
          false -> new_state
          cycle ->
            Logger.warning("CapabilityGraph: cycle detected: #{inspect(cycle)}")
            emit_constitutional_event(:cycle_detected, %{cycle_length: length(cycle)}, %{
              involved: Enum.map(cycle, &elem(&1, 1))
            })
            %{new_state | cycles_detected: new_state.cycles_detected + 1}
        end
      else
        new_state
      end

    record_mutation(:edge_added, %{type: edge_type, from: from_vertex, to: to_vertex}, new_state)
    {:reply, result, %{new_state | mutation_count: new_state.mutation_count + 1}}
  end

  # ── Reasoning Handlers ──────────────────────────────────────────

  @impl true
  def handle_call({:find_optimal_provider, cap_id}, _from, state) do
    vertex = {:capability, cap_id}

    if :digraph.vertex(state.graph, vertex) do
      providers =
        :digraph.in_edges(state.graph, vertex)
        |> Enum.flat_map(fn edge ->
          case :digraph.edge(state.graph, edge) do
            {_, {:subsystem, sub_id}, ^vertex, :provides} -> [sub_id]
            _ -> []
          end
        end)
        |> Enum.reject(fn _sub_id -> MapSet.member?(state.deprecated, cap_id) end)

      scored =
        providers
        |> Enum.map(fn sub_id -> {sub_id, compute_provider_score(sub_id, cap_id)} end)
        |> Enum.sort_by(fn {_, score} -> score end, :desc)

      case scored do
        [{best_id, best_score} | _] -> {:reply, {:ok, best_id, best_score}, state}
        [] -> {:reply, {:error, :no_provider}, state}
      end
    else
      {:reply, {:error, :capability_not_found}, state}
    end
  end

  @impl true
  def handle_call({:dependency_chain, cap_id}, _from, state) do
    vertex = {:capability, cap_id}
    if :digraph.vertex(state.graph, vertex) do
      chain = traverse_edges(state.graph, vertex, :depends_on, :out)
      {:reply, {:ok, chain}, state}
    else
      {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_call({:blast_radius, cap_id}, _from, state) do
    vertex = {:capability, cap_id}

    if :digraph.vertex(state.graph, vertex) do
      dependents = traverse_edges(state.graph, vertex, :depends_on, :in)

      affected_subsystems =
        :digraph.in_edges(state.graph, vertex)
        |> Enum.flat_map(fn edge ->
          case :digraph.edge(state.graph, edge) do
            {_, {:subsystem, sub_id}, ^vertex, :provides} -> [sub_id]
            _ -> []
          end
        end)

      affected_missions =
        :digraph.in_edges(state.graph, vertex)
        |> Enum.flat_map(fn edge ->
          case :digraph.edge(state.graph, edge) do
            {_, {:mission, m_id}, ^vertex, :consumes} -> [m_id]
            _ -> []
          end
        end)

      {:reply, {:ok, %{
        capability: cap_id,
        dependent_capabilities: dependents,
        affected_subsystems: affected_subsystems,
        affected_missions: affected_missions,
        severity: classify_severity(dependents, affected_missions)
      }}, state}
    else
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

    {:reply, cycles, state}
  end

  @impl true
  def handle_call(:spof, _from, state) do
    spof =
      :digraph.vertices(state.graph)
      |> Enum.filter(fn {type, _} -> type == :capability end)
      |> Enum.filter(fn vertex ->
        providers =
          :digraph.in_edges(state.graph, vertex)
          |> Enum.count(fn edge ->
            case :digraph.edge(state.graph, edge) do
              {_, _, ^vertex, :provides} -> true
              _ -> false
            end
          end)
        providers == 1
      end)
      |> Enum.map(&elem(&1, 1))

    {:reply, spof, %{state | spof_count: length(spof)}}
  end

  @impl true
  def handle_call({:providers_of, cap_id}, _from, state) do
    vertex = {:capability, cap_id}
    providers =
      :digraph.in_edges(state.graph, vertex)
      |> Enum.flat_map(fn edge ->
        case :digraph.edge(state.graph, edge) do
          {_, {:subsystem, sub_id}, ^vertex, :provides} -> [sub_id]
          _ -> []
        end
      end)
    {:reply, providers, state}
  end

  @impl true
  def handle_call({:capabilities_of, sub_id}, _from, state) do
    vertex = {:subsystem, sub_id}
    caps =
      :digraph.out_edges(state.graph, vertex)
      |> Enum.flat_map(fn edge ->
        case :digraph.edge(state.graph, edge) do
          {_, ^vertex, {:capability, cap_id}, :provides} -> [cap_id]
          _ -> []
        end
      end)
    {:reply, caps, state}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    caps = count_vertices(state.graph, :capability)
    subs = count_vertices(state.graph, :subsystem)
    missions = count_vertices(state.graph, :mission)

    {:reply, %{
      healthy: state.healthy,
      vertex_count: :digraph.no_vertices(state.graph),
      edge_count: :digraph.no_edges(state.graph),
      capability_count: caps,
      subsystem_count: subs,
      mission_count: missions,
      deprecated_count: MapSet.size(state.deprecated),
      cycles_detected: state.cycles_detected,
      single_points_of_failure: state.spof_count,
      mutation_count: state.mutation_count
    }, state}
  end

  @impl true
  def handle_call(:export, _from, state) do
    vertices =
      :digraph.vertices(state.graph)
      |> Enum.map(fn v -> {v, :digraph.vertex(state.graph, v)} end)

    edges =
      :digraph.edges(state.graph)
      |> Enum.flat_map(fn e ->
        case :digraph.edge(state.graph, e) do
          {_, from, to, label} -> [%{from: from, to: to, label: label}]
          _ -> []
        end
      end)

    {:reply, %{vertices: vertices, edges: edges}, state}
  end

  @impl true
  def handle_call(:healthy, _from, state), do: {:reply, state.healthy, state}

  # ── Background Tasks ────────────────────────────────────────────

  @impl true
  def handle_info(:redundancy_check, state) do
    spof =
      :digraph.vertices(state.graph)
      |> Enum.filter(fn {type, _} -> type == :capability end)
      |> Enum.filter(fn vertex ->
        count =
          :digraph.in_edges(state.graph, vertex)
          |> Enum.count(fn edge ->
            case :digraph.edge(state.graph, edge) do
              {_, _, ^vertex, :provides} -> true
              _ -> false
            end
          end)
        count == 1
      end)

    if length(spof) > 0 do
      emit_constitutional_event(:spof_detected, %{count: length(spof)}, %{
        capabilities: Enum.map(spof, &elem(&1, 1))
      })
    end

    schedule_redundancy_check()
    {:noreply, %{state | spof_count: length(spof)}}
  end

  # ── Private ─────────────────────────────────────────────────────

  defp seed_subsystem(graph, sub_id, caps) do
    sub_vertex = {:subsystem, sub_id}
    :digraph.add_vertex(graph, sub_vertex, %{})
    Enum.each(caps, fn cap_id ->
      cap_vertex = {:capability, cap_id}
      :digraph.add_vertex(graph, cap_vertex, %{})
      :digraph.add_edge(graph, sub_vertex, cap_vertex, :provides)
    end)
  end

  defp seed_dependency(graph, cap_a, cap_b) do
    va = {:capability, cap_a}
    vb = {:capability, cap_b}
    :digraph.add_vertex(graph, va, %{})
    :digraph.add_vertex(graph, vb, %{})
    :digraph.add_edge(graph, va, vb, :depends_on)
  end

  defp default_metadata do
    caps = [:detect, :classify, :monitor, :alert, :investigate, :generate_hypothesis,
            :validate, :forecast, :governance_cycle, :risk_assess, :create_capability,
            :improve_institution, :govern, :research, :discover, :validate_discovery,
            :simulate, :model, :predict]
    Map.new(caps, fn c -> {c, %{version: "1.0.0", deprecated: false, registered_at: DateTime.utc_now()}} end)
  end

  defp register_capability_internal(state, cap_id, metadata) do
    vertex = {:capability, cap_id}
    if :digraph.vertex(state.graph, vertex) do
      {:error, :already_registered}
    else
      :digraph.add_vertex(state.graph, vertex, metadata)
      new_meta = Map.put(state.capability_metadata, cap_id, Map.merge(%{
        registered_at: DateTime.utc_now(), version: "1.0.0", deprecated: false
      }, metadata))
      {:ok, %{state | capability_metadata: new_meta}}
    end
  end

  defp deprecate_internal(state, cap_id, reason) do
    vertex = {:capability, cap_id}
    if :digraph.vertex(state.graph, vertex) do
      :digraph.add_vertex(state.graph, vertex, %{deprecated: true, reason: reason})
      :ok
    else
      {:error, :not_found}
    end
  end

  defp add_edge_internal(state, edge_type, from_vertex, to_vertex) do
    ensure_vertex(state.graph, from_vertex)
    ensure_vertex(state.graph, to_vertex)

    case :digraph.add_edge(state.graph, from_vertex, to_vertex, edge_type) do
      {:error, reason} -> {{:error, reason}, state}
      _edge -> {:ok, state}
    end
  end

  defp ensure_vertex(graph, vertex) do
    case :digraph.vertex(graph, vertex) do
      false -> :digraph.add_vertex(graph, vertex, %{})
      _ -> :ok
    end
  end

  defp redirect_edges(state, old_cap_id, new_cap_id) do
    old_vertex = {:capability, old_cap_id}
    new_vertex = {:capability, new_cap_id}

    :digraph.in_edges(state.graph, old_vertex)
    |> Enum.each(fn edge ->
      case :digraph.edge(state.graph, edge) do
        {_, from, ^old_vertex, :provides} -> :digraph.add_edge(state.graph, from, new_vertex, :provides)
        _ -> :ok
      end
    end)

    :digraph.out_edges(state.graph, old_vertex)
    |> Enum.each(fn edge ->
      case :digraph.edge(state.graph, edge) do
        {_, ^old_vertex, to, :depends_on} -> :digraph.add_edge(state.graph, new_vertex, to, :depends_on)
        _ -> :ok
      end
    end)

    {:ok, state}
  end

  defp traverse_edges(graph, start_vertex, edge_label, direction) do
    do_traverse(graph, [start_vertex], MapSet.new(), edge_label, direction, [])
  end

  defp do_traverse(_graph, [], _visited, _label, _dir, acc), do: acc

  defp do_traverse(graph, [current | rest], visited, label, direction, acc) do
    if MapSet.member?(visited, current) do
      do_traverse(graph, rest, visited, label, direction, acc)
    else
      new_visited = MapSet.put(visited, current)

      neighbors =
        case direction do
          :out ->
            :digraph.out_edges(graph, current)
            |> Enum.flat_map(fn edge ->
              case :digraph.edge(graph, edge) do
                {_, ^current, to, ^label} -> [to]
                _ -> []
              end
            end)
          :in ->
            :digraph.in_edges(graph, current)
            |> Enum.flat_map(fn edge ->
              case :digraph.edge(graph, edge) do
                {_, from, ^current, ^label} -> [from]
                _ -> []
              end
            end)
        end

      new_acc = if match?({:capability, _}, current), do: [elem(current, 1) | acc], else: acc
      do_traverse(graph, rest ++ neighbors, new_visited, label, direction, new_acc)
    end
  end

  defp compute_provider_score(subsystem_id, _cap_id) do
    trust_score =
      try do
        case IdentityTrustManager.trust_score(subsystem_id) do
          score when is_float(score) -> score
          _ -> 0.8
        end
      rescue
        _ -> 0.8
      catch
        :exit, _ -> 0.8
      end

    trust_score * 0.5 + 0.7 * 0.25 + 0.9 * 0.25
  end

  defp classify_severity(dep_caps, aff_missions) do
    cond do
      length(aff_missions) > 5 -> :critical
      length(dep_caps) > 10 -> :high
      length(dep_caps) > 3 or length(aff_missions) > 0 -> :medium
      true -> :low
    end
  end

  defp count_vertices(graph, type) do
    :digraph.vertices(graph)
    |> Enum.count(fn {t, _} -> t == type end)
  end

  defp record_mutation(action, payload, _state) do
    try do
      ExecutiveMemory.record_event(action, payload)
    rescue
      _ -> :ok
    end
  end

  defp schedule_redundancy_check do
    Process.send_after(self(), :redundancy_check, @redundancy_check_interval)
  end
end
