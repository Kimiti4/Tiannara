defmodule Tiannara.World.ProvenanceEngine do
  use GenServer
  use Tiannara.ExecutiveService.Base
  require Logger

  alias Tiannara.CEL.Services.{ExecutiveMemory, EventBus}
  alias Tiannara.CEL.Kernel.ConstitutionalScore

  @impl true
  def id, do: :provenance_engine

  @impl true
  def version, do: "1.0.0"

  @impl true
  def capabilities do
    [:lineage_tracking, :evidence_management, :confidence_propagation,
     :uncertainty_quantification, :ownership_tracking, :provenance_reconstruction]
  end

  @impl true
  def dependencies, do: [:executive_memory, :executive_service_bus]

  @impl true
  def health, do: if(Process.whereis(__MODULE__), do: :healthy, else: :unhealthy)

  @impl true
  def constitutional_score do
    %ConstitutionalScore{
      service_id: id(), health: 1.0, constitutional_alignment: 1.0,
      transparency: 1.0, explainability: 1.0, evidence_quality: 1.0,
      human_oversight: 1.0, computed_at: DateTime.utc_now()
    }
  end

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def record_provenance(spec), do: GenServer.call(__MODULE__, {:record, spec})
  def reconstruct_lineage(entity_id, entity_spec), do: GenServer.call(__MODULE__, {:reconstruct, entity_id, entity_spec})
  def confidence_path(entity_id), do: GenServer.call(__MODULE__, {:confidence_path, entity_id})
  def verify_provenance(entity_id), do: GenServer.call(__MODULE__, {:verify_provenance, entity_id})
  def stats, do: GenServer.call(__MODULE__, :stats)

  @impl true
  def init(_opts) do
    {:ok, %{records: %{}, total: 0, healthy: true, started_at: DateTime.utc_now()}}
  end

  @impl true
  def handle_call({:record, spec}, _from, state) do
    record = %{
      entity_id: spec.entity_id, origin: Map.get(spec, :origin),
      contributors: Map.get(spec, :contributors, []),
      evidence: Map.get(spec, :evidence, []),
      confidence: Map.get(spec, :confidence, 0.5),
      uncertainty: Map.get(spec, :uncertainty, 0.5),
      owner: Map.get(spec, :owner),
      recorded_at: DateTime.utc_now()
    }

    records = Map.put(state.records, spec.entity_id, record)
    ExecutiveMemory.record_event(:provenance, :recorded, %{entity_id: spec.entity_id})
    EventBus.publish("world.provenance.recorded", %{entity_id: spec.entity_id}, [])

    {:reply, :ok, %{state | records: records, total: state.total + 1}}
  end

  @impl true
  def handle_call({:reconstruct, entity_id, entity_spec}, _from, state) do
    lineage = build_lineage(entity_id, entity_spec, state.records, MapSet.new())
    {:reply, {:ok, lineage}, state}
  end

  @impl true
  def handle_call({:confidence_path, entity_id}, _from, state) do
    case Map.fetch(state.records, entity_id) do
      {:ok, prov} ->
        path = %{
          entity_id: entity_id, confidence: prov.confidence,
          evidence_count: length(prov.evidence), contributor_count: length(prov.contributors),
          confidence_sources: Enum.map(prov.evidence, fn e ->
            %{evidence: e, weight: 1.0 / max(1, length(prov.evidence))}
          end)
        }
        {:reply, {:ok, path}, state}
      :error -> {:reply, {:error, :no_provenance_record}, state}
    end
  end

  @impl true
  def handle_call({:verify_provenance, entity_id}, _from, state) do
    case Map.fetch(state.records, entity_id) do
      {:ok, prov} ->
        missing = Enum.reduce([:entity_id, :origin, :recorded_at], [], fn field, acc ->
          if Map.has_key?(prov, field), do: acc, else: [field | acc]
        end)
        issues = if prov.confidence + prov.uncertainty > 1.01, do: [:confidence_uncertainty_sum > 1.0], else: []
        {:reply, {:ok, %{complete: missing == [], missing_fields: missing, issues: issues, record: prov}}, state}
      :error ->
        {:reply, {:error, :no_provenance_record}, state}
    end
  end

  @impl true
  def handle_call(:stats, _from, state) do
    {:reply, %{healthy: state.healthy, total_records: state.total_records, entities_with_provenance: map_size(state.records)}, state}
  end

  defp build_lineage(entity_id, entity_spec, records, visited) do
    if MapSet.member?(visited, entity_id) do
      %{entity_id: entity_id, cyclic: true}
    else
      visited = MapSet.put(visited, entity_id)
      case Map.fetch(records, entity_id) do
        {:ok, prov} ->
          contributors = Enum.map(prov.contributors, fn cid ->
            build_lineage(cid, %{id: cid}, records, visited)
          end)
          %{entity_id: entity_id, origin: prov.origin, confidence: prov.confidence,
            uncertainty: prov.uncertainty, evidence: prov.evidence, owner: prov.owner,
            contributors: contributors, recorded_at: prov.recorded_at}
        :error ->
          %{entity_id: entity_id, origin: :unknown, confidence: Map.get(entity_spec, :confidence, 0.5), contributors: []}
      end
    end
  end
end
