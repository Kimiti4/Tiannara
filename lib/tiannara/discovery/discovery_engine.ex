defmodule Tiannara.Discovery.DiscoveryEngine do
  use GenServer
  use Tiannara.ExecutiveService.Base
  require Logger

  alias Tiannara.Discovery.{Discovery, Events, EvidenceIntegrator, DiscoveryLineage}
  alias Tiannara.Discovery.Domain.{KnowledgeGap, DiscoveryResult}
  alias Tiannara.CEL.Kernel.ConstitutionalScore

  @impl Tiannara.ExecutiveService
  def id, do: :discovery_engine

  @impl Tiannara.ExecutiveService
  def version, do: "1.0.0"

  @impl Tiannara.ExecutiveService
  def capabilities, do: [:discovery_orchestration, :hypothesis_generation, :prediction_generation, :evidence_routing]

  @impl Tiannara.ExecutiveService
  def dependencies, do: [:executive_memory, :executive_service_bus, :knowledge_coordinator]

  @impl Tiannara.ExecutiveService
  def priority, do: :medium

  @impl Tiannara.ExecutiveService
  def constitutional_score do
    GenServer.call(__MODULE__, :constitutional_score)
  end

  @impl Tiannara.ExecutiveService
  def health do
    GenServer.call(__MODULE__, :health)
  end

  @impl Tiannara.ExecutiveService
  def boot(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl Tiannara.ExecutiveService
  def shutdown(reason), do: GenServer.stop(__MODULE__, reason)

  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def init(_opts) do
    {:ok, %{discoveries: %{}, active_workflows: %{}, stats: %{total_discoveries: 0, completed: 0, abandoned: 0, failed: 0, evidence_routed: 0}}}
  end

  def create_discovery(%KnowledgeGap{} = gap) do
    GenServer.call(__MODULE__, {:create_discovery, gap})
  end

  def get_discovery(id) do
    GenServer.call(__MODULE__, {:get_discovery, id})
  end

  def route_evidence(discovery_id, evidence) do
    GenServer.call(__MODULE__, {:route_evidence, discovery_id, evidence})
  end

  def get_stats do
    GenServer.call(__MODULE__, :get_stats)
  end

  def handle_call({:create_discovery, gap}, _from, state) do
    disc = Discovery.from_gap(gap)
    Events.emit(:discovery_created, disc.id, %{gap_id: gap.id, status: disc.status})
    new_state = put_in(state, [:discoveries, disc.id], disc)
    new_state = put_in(new_state, [:stats, :total_discoveries], state.stats.total_discoveries + 1)
    {:reply, {:ok, disc}, new_state}
  end

  def handle_call({:get_discovery, id}, _from, state) do
    case Map.get(state.discoveries, id) do
      nil -> {:reply, {:error, :not_found}, state}
      disc -> {:reply, {:ok, disc}, state}
    end
  end

  def handle_call({:route_evidence, discovery_id, evidence}, _from, state) do
    case Map.get(state.discoveries, discovery_id) do
      nil ->
        {:reply, {:error, :not_found}, state}
      disc ->
        results = List.wrap(evidence) |> Enum.map(fn e ->
          if is_struct(e, DiscoveryResult), do: e, else: DiscoveryResult.new(e)
        end)
        evaluations = EvidenceIntegrator.integrate(results, %{})
        updated = Discovery.add_evidence(disc, results)
        Events.emit(:evidence_collected, discovery_id, %{evidence_count: length(results),
          outcome: (if evaluations != [], do: hd(evaluations).outcome, else: :inconclusive)})
        integrity = DiscoveryLineage.verify_integrity(updated)
        new_state = put_in(state, [:discoveries, discovery_id], updated)
        new_state = put_in(new_state, [:stats, :evidence_routed], state.stats.evidence_routed + 1)
        {:reply, {:ok, %{discovery: updated, evaluations: evaluations, integrity: integrity}}, new_state}
    end
  end

  def handle_call(:get_stats, _from, state), do: {:reply, state.stats, state}

  def handle_call(:constitutional_score, _from, state) do
    discovery_count = map_size(state.discoveries)
    score = %ConstitutionalScore{
      service_id: :discovery_engine,
      health: if(state.stats.failed == 0, do: 1.0, else: 0.8),
      constitutional_alignment: if(discovery_count > 0, do: 0.9, else: 1.0),
      transparency: 0.9,
      explainability: 0.8,
      evidence_quality: if(discovery_count > 0, do: 0.85, else: 1.0),
      human_oversight: 0.7,
      computed_at: DateTime.utc_now()
    }
    {:reply, score, state}
  end

  def handle_call(:health, _from, state) do
    status = if state.stats.failed > state.stats.total_discoveries * 0.5 and state.stats.total_discoveries > 0,
      do: :unhealthy, else: (if state.stats.failed > 0, do: :degraded, else: :healthy)
    {:reply, status, state}
  end

  def handle_info({:evidence_result, discovery_id, result}, state) do
    case Map.get(state.discoveries, discovery_id) do
      nil -> {:noreply, state}
      disc ->
        updated = Discovery.add_evidence(disc, [result])
        {:noreply, put_in(state, [:discoveries, discovery_id], updated)}
    end
  end
end
