defmodule Tiannara.World.ConflictDetector do
  use GenServer
  use Tiannara.ExecutiveService.Base
  require Logger

  alias Tiannara.World.{UnifiedWorldModel, WorldQueryEngine, ConflictResolutionEngine, BeliefState}
  alias Tiannara.CEL.Services.{EventBus, ExecutiveMemory}
  alias Tiannara.CEL.Kernel.ConstitutionalScore

  @detection_interval :timer.minutes(5)

  @impl Tiannara.ExecutiveService
  def id, do: :conflict_detector

  @impl Tiannara.ExecutiveService
  def version, do: "1.0.0"

  @impl Tiannara.ExecutiveService
  def capabilities do
    [
      :logical_contradiction_detection, :duplicate_detection,
      :ontology_violation_detection, :confidence_anomaly_detection
    ]
  end

  @impl Tiannara.ExecutiveService
  def dependencies do
    [:persistent_memory, :event_transport, :unified_world_model, :conflict_resolution_engine]
  end

  @impl Tiannara.ExecutiveService
  def priority, do: :high

  @impl Tiannara.ExecutiveService
  def constitutional_score do
    stats = GenServer.call(__MODULE__, :stats)
    health = if stats.unresolved_conflicts > 10, do: 0.6, else: 1.0

    %ConstitutionalScore{
      service_id: id(), health: health,
      constitutional_alignment: 1.0, transparency: 1.0,
      explainability: 1.0, evidence_quality: 1.0,
      human_oversight: 1.0, computed_at: DateTime.utc_now()
    }
  end

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def detect_all, do: GenServer.call(__MODULE__, :detect_all, :timer.minutes(2))

  def stats, do: GenServer.call(__MODULE__, :stats)

  @impl true
  def init(_opts) do
    EventBus.subscribe("world.entity.created", self())
    EventBus.subscribe("world.entity.updated", self())
    schedule_detection()

    {:ok, %{
      total_conflicts_detected: 0, unresolved_conflicts: 0,
      detection_count: 0, last_detection_at: nil,
      healthy: true, started_at: DateTime.utc_now()
    }}
  end

  @impl true
  def handle_call(:detect_all, _from, state) do
    conflicts = run_all_detections()
    Enum.each(conflicts, fn conflict ->
      ConflictResolutionEngine.record_conflict(conflict)
    end)

    new_state = %{state |
      total_conflicts_detected: state.total_conflicts_detected + length(conflicts),
      unresolved_conflicts: state.unresolved_conflicts + length(conflicts),
      detection_count: state.detection_count + 1,
      last_detection_at: DateTime.utc_now()
    }

    schedule_detection()
    {:reply, {:ok, conflicts}, new_state}
  end

  @impl true
  def handle_call(:stats, _from, state), do: {:reply, state, state}

  @impl true
  def handle_info({:executive_bus_message, %{type: "world.entity.created", payload: payload}}, state) do
    entity_id = payload.entity_id
    conflicts = detect_conflicts_for_entity(entity_id)
    Enum.each(conflicts, fn c -> ConflictResolutionEngine.record_conflict(c) end)
    {:noreply, %{state |
      total_conflicts_detected: state.total_conflicts_detected + length(conflicts),
      unresolved_conflicts: state.unresolved_conflicts + length(conflicts)
    }}
  end

  @impl true
  def handle_info({:executive_bus_message, %{type: "world.entity.updated", payload: payload}}, state) do
    entity_id = payload.entity_id
    conflicts = detect_conflicts_for_entity(entity_id)
    Enum.each(conflicts, fn c -> ConflictResolutionEngine.record_conflict(c) end)
    {:noreply, %{state |
      total_conflicts_detected: state.total_conflicts_detected + length(conflicts),
      unresolved_conflicts: state.unresolved_conflicts + length(conflicts)
    }}
  end

  @impl true
  def handle_info(:run_detection, state) do
    {:reply, _, new_state} = handle_call(:detect_all, nil, state)
    schedule_detection()
    {:noreply, new_state}
  end

  @impl true
  def handle_info(_msg, state), do: {:noreply, state}

  defp run_all_detections do
    []
    |> detect_logical_contradictions()
    |> detect_duplicates()
    |> detect_ontology_violations()
    |> detect_confidence_anomalies()
  end

  defp detect_conflicts_for_entity(_entity_id) do
    []
  end

  defp detect_logical_contradictions(conflicts) do
    {:ok, result} = WorldQueryEngine.find(type: :knowledge_entity, status: :active, limit: 10_000)

    contradictions =
      result.results
      |> Enum.flat_map(fn entity ->
        case UnifiedWorldModel.get_relationships(entity.id, type: :refutes, direction: :out) do
          {:ok, relationships} ->
            Enum.map(relationships, fn rel ->
              %{
                entity_ids: [entity.id, rel.to_id], domain: :knowledge,
                description: "Logical contradiction: #{entity.id} refutes #{rel.to_id}",
                severity: :high,
                evidence: [%{type: :refutes_relationship, relationship_id: rel.id}],
                requires_human_review: false
              }
            end)
          _ -> []
        end
      end)

    conflicts ++ contradictions
  end

  defp detect_duplicates(conflicts) do
    {:ok, result} = WorldQueryEngine.find(status: :active, limit: 10_000)

    grouped = Enum.group_by(result.results, fn entity ->
      {entity.type, Map.get(entity.attributes, :statement) || Map.get(entity.attributes, :content)}
    end)

    duplicates =
      grouped
      |> Enum.filter(fn {_key, entities} -> length(entities) > 1 end)
      |> Enum.flat_map(fn {_key, entities} ->
        entity_ids = Enum.map(entities, & &1.id)
        [%{
          entity_ids: entity_ids, domain: :knowledge,
          description: "Duplicate entities: #{length(entities)} with identical attributes",
          severity: :medium,
          evidence: [%{type: :duplicate_detection, entity_ids: entity_ids}],
          requires_human_review: false
        }]
      end)

    conflicts ++ duplicates
  end

  defp detect_ontology_violations(conflicts) do
    {:ok, result} = WorldQueryEngine.find(limit: 10_000)

    violations =
      result.results
      |> Enum.filter(fn entity ->
        not Map.has_key?(entity, :provenance) or
        not Map.has_key?(entity, :confidence) or
        not Map.has_key?(entity, :uncertainty)
      end)
      |> Enum.map(fn entity ->
        %{
          entity_ids: [entity.id], domain: :ontology,
          description: "Violation: #{entity.id} missing required fields",
          severity: :high,
          evidence: [%{type: :ontology_violation, entity_id: entity.id}],
          requires_human_review: false
        }
      end)

    conflicts ++ violations
  end

  defp detect_confidence_anomalies(conflicts) do
    {:ok, result} = WorldQueryEngine.find(status: :active, limit: 10_000)

    anomalies =
      result.results
      |> Enum.filter(fn entity ->
        conf = entity.confidence || 0.5
        unc = entity.uncertainty || 0.5
        abs(conf + unc - 1.0) > 0.01
      end)
      |> Enum.map(fn entity ->
        %{
          entity_ids: [entity.id], domain: :knowledge,
          description: "Confidence anomaly: #{entity.id} has confidence + uncertainty != 1.0",
          severity: :medium,
          evidence: [%{type: :confidence_anomaly, entity_id: entity.id}],
          requires_human_review: false
        }
      end)

    conflicts ++ anomalies
  end

  defp schedule_detection do
    Process.send_after(self(), :run_detection, @detection_interval)
  end
end
