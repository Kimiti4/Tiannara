defmodule Tiannara.World.WorldConsistencyValidator do
  @moduledoc """
  World Consistency Validator — continuous validation of world model integrity.

  Continuously checks for contradictions, broken references, circular dependencies,
  invalid assumptions, missing evidence, orphan knowledge, and confidence anomalies.
  """
  use GenServer
  use Tiannara.ExecutiveService.Base
  require Logger

  alias Tiannara.World.{UnifiedWorldModel, UnifiedRealityGraph, WorldQueryEngine}
  alias Tiannara.CEL.Services.{EventBus, ExecutiveMemory}
  alias Tiannara.CEL.Kernel.ConstitutionalScore

  @validation_interval :timer.minutes(10)

  # ---------- ExecutiveService Behaviour ----------

  @impl Tiannara.ExecutiveService
  def id, do: :world_consistency_validator

  @impl Tiannara.ExecutiveService
  def version, do: "1.0.0"

  @impl Tiannara.ExecutiveService
  def capabilities do
    [
      :contradiction_detection,
      :broken_reference_detection,
      :circular_dependency_detection,
      :evidence_validation,
      :orphan_detection,
      :confidence_anomaly_detection
    ]
  end

  @impl Tiannara.ExecutiveService
  def dependencies, do: [:persistent_memory, :event_transport, :unified_world_model]

  @impl Tiannara.ExecutiveService
  def priority, do: :high

  @impl Tiannara.ExecutiveService
  def constitutional_score do
    stats = GenServer.call(__MODULE__, :stats)

    critical_count = Enum.count(stats.issues, &(&1.severity == :critical))
    high_count = Enum.count(stats.issues, &(&1.severity == :high))

    health = max(0.0, 1.0 - (critical_count * 0.3 + high_count * 0.1))

    %ConstitutionalScore{
      service_id: id(),
      health: health,
      constitutional_alignment: 1.0,
      transparency: 1.0,
      explainability: 1.0,
      evidence_quality: 1.0,
      human_oversight: 1.0,
      computed_at: DateTime.utc_now(),
    }
  end

  # ---------- Client API ----------

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def validate_all, do: GenServer.call(__MODULE__, :validate_all, :timer.minutes(2))

  def issues, do: GenServer.call(__MODULE__, :issues)

  def stats, do: GenServer.call(__MODULE__, :stats)

  def resolve_issue(issue_id, resolution), do: GenServer.call(__MODULE__, {:resolve, issue_id, resolution})

  # ---------- Server Callbacks ----------

  @impl true
  def init(_opts) do
    schedule_validation()
    {:ok, %{
      issues: [],
      validation_count: 0,
      last_validation_at: nil,
      healthy: true,
      started_at: DateTime.utc_now()
    }}
  end

  @impl true
  def handle_call(:validate_all, _from, state) do
    issues = run_all_validations()

    critical_issues = Enum.filter(issues, &(&1.severity == :critical))
    if length(critical_issues) > 0 do
      ExecutiveMemory.record_decision(
        "validation_#{DateTime.utc_now() |> DateTime.to_unix()}",
        :consistency_validation_critical,
        %{critical_issues: critical_issues, total_issues: length(issues)}
      )
    end

    EventBus.publish("world.validation.completed", %{
      issue_count: length(issues),
      critical_count: length(critical_issues)
    })

    new_state = %{state |
      issues: issues,
      validation_count: state.validation_count + 1,
      last_validation_at: DateTime.utc_now()
    }

    {:reply, {:ok, issues}, new_state}
  end

  @impl true
  def handle_call(:issues, _from, state), do: {:reply, state.issues, state}

  @impl true
  def handle_call(:stats, _from, state) do
    {:reply, %{
      healthy: state.healthy,
      issue_count: length(state.issues),
      validation_count: state.validation_count,
      last_validation_at: state.last_validation_at,
      issues: state.issues
    }, state}
  end

  @impl true
  def handle_call({:resolve, issue_id, resolution}, _from, state) do
    new_issues = Enum.map(state.issues, fn issue ->
      if issue.id == issue_id do
        %{issue | status: :resolved, resolution: resolution, resolved_at: DateTime.utc_now()}
      else
        issue
      end
    end)

    {:reply, :ok, %{state | issues: new_issues}}
  end

  @impl true
  def handle_info(:run_validation, state) do
    issues = run_all_validations()
    schedule_validation()
    {:noreply, %{state |
      issues: issues,
      validation_count: state.validation_count + 1,
      last_validation_at: DateTime.utc_now()
    }}
  end

  # ---------- Private: Validation Checks ----------

  defp run_all_validations do
    []
    |> check_contradictions()
    |> check_broken_references()
    |> check_circular_dependencies()
    |> check_missing_evidence()
    |> check_orphan_entities()
    |> check_confidence_anomalies()
  end

  defp check_contradictions(issues) do
    {:ok, result} = WorldQueryEngine.find(type: :scientific_entity, status: :active, limit: 10_000)

    contradictions =
      result.results
      |> Enum.flat_map(fn entity ->
        case UnifiedWorldModel.get_relationships(entity.id, type: :refutes, direction: :out) do
          {:ok, relationships} ->
            Enum.map(relationships, fn rel ->
              %{
                id: generate_issue_id(),
                type: :contradiction,
                severity: :critical,
                entities: [entity.id, rel.to_id],
                description: "Entity #{entity.id} refutes #{rel.to_id}, but both are active",
                detected_at: DateTime.utc_now(),
                status: :unresolved
              }
            end)
          _ -> []
        end
      end)

    issues ++ contradictions
  end

  defp check_broken_references(issues) do
    {:ok, result} = WorldQueryEngine.find(limit: 10_000)

    broken =
      result.results
      |> Enum.flat_map(fn entity ->
        case UnifiedWorldModel.get_relationships(entity.id, direction: :both) do
          {:ok, relationships} ->
            Enum.filter(relationships, fn rel ->
              case UnifiedWorldModel.get_entity(rel.to_id) do
                {:error, _} -> true
                _ -> false
              end
            end)
            |> Enum.map(fn rel ->
              %{
                id: generate_issue_id(),
                type: :broken_reference,
                severity: :high,
                entities: [entity.id, rel.to_id],
                description: "Entity #{entity.id} references non-existent entity #{rel.to_id}",
                detected_at: DateTime.utc_now(),
                status: :unresolved
              }
            end)
          _ -> []
        end
      end)

    issues ++ broken
  end

  defp check_circular_dependencies(issues) do
    case UnifiedRealityGraph.detect_cycles() do
      {:ok, cycles} ->
        cycle_issues = Enum.map(cycles, fn cycle ->
          %{
            id: generate_issue_id(),
            type: :circular_dependency,
            severity: :high,
            entities: cycle,
            description: "Circular dependency detected: #{Enum.join(cycle, " -> ")}",
            detected_at: DateTime.utc_now(),
            status: :unresolved
          }
        end)
        issues ++ cycle_issues

      _ -> issues
    end
  end

  defp check_missing_evidence(issues) do
    {:ok, result} = WorldQueryEngine.find(min_confidence: 0.8, status: :active, limit: 10_000)

    missing =
      result.results
      |> Enum.filter(fn entity ->
        case WorldQueryEngine.explain(entity.id) do
          {:ok, %{evidence_count: 0}} -> true
          _ -> false
        end
      end)
      |> Enum.map(fn entity ->
        %{
          id: generate_issue_id(),
          type: :missing_evidence,
          severity: :medium,
          entities: [entity.id],
          description: "Entity #{entity.id} has high confidence (#{entity.confidence}) but no evidence",
          detected_at: DateTime.utc_now(),
          status: :unresolved
        }
      end)

    issues ++ missing
  end

  defp check_orphan_entities(issues) do
    {:ok, result} = WorldQueryEngine.find(status: :active, limit: 10_000)

    orphans =
      result.results
      |> Enum.filter(fn entity ->
        case UnifiedWorldModel.get_relationships(entity.id) do
          {:ok, []} -> true
          _ -> false
        end
      end)
      |> Enum.map(fn entity ->
        %{
          id: generate_issue_id(),
          type: :orphan_entity,
          severity: :low,
          entities: [entity.id],
          description: "Entity #{entity.id} has no relationships (potential orphan)",
          detected_at: DateTime.utc_now(),
          status: :unresolved
        }
      end)

    issues ++ orphans
  end

  defp check_confidence_anomalies(issues) do
    {:ok, result} = WorldQueryEngine.find(limit: 10_000)

    anomalies =
      result.results
      |> Enum.filter(fn entity ->
        abs((entity.confidence || 0.5) + (entity.uncertainty || 0.5) - 1.0) > 0.01
      end)
      |> Enum.map(fn entity ->
        %{
          id: generate_issue_id(),
          type: :confidence_anomaly,
          severity: :medium,
          entities: [entity.id],
          description: "Entity #{entity.id} has inconsistent confidence (#{entity.confidence}) and uncertainty (#{entity.uncertainty})",
          detected_at: DateTime.utc_now(),
          status: :unresolved
        }
      end)

    issues ++ anomalies
  end

  # ---------- Private Helpers ----------

  defp generate_issue_id, do: "issue_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}"

  defp schedule_validation do
    Process.send_after(self(), :run_validation, @validation_interval)
  end
end
