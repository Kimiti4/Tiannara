defmodule Tiannara.CEL.Services.ExecutiveStateManager do
  @moduledoc """
  Executive State Manager — aggregates and publishes the canonical ExecutiveState.

  Periodically queries all Executive Services to build a unified, immutable snapshot
  of the system's operating condition. This snapshot is:
    - Published to the EventBus for dashboard/observability consumers
    - Stored in ExecutiveMemory for historical trend analysis
    - Queried by the Constitutional Council for governance oversight

  Constitutional Alignment (rules.md):
    - "Observability": Provides a single, consistent view of executive state.
    - "Continuous Self-Evaluation": Enables systemic review of bottlenecks and health.
    - "Maintain audit trails": Every state snapshot is versioned and recorded.
  """
  use GenServer
  use Tiannara.ExecutiveService.Base
  require Logger

  alias Tiannara.CEL.State.ExecutiveState
  alias Tiannara.CEL.Services.{EventBus, ExecutiveMemory, CapabilityGraph, ResourceManager}
  alias Tiannara.Council

  @snapshot_interval :timer.seconds(15)

  # ── ExecutiveService Behaviour ────────────────────────────────────

  @impl true
  def id, do: :executive_state_manager

  @impl true
  def version, do: "1.0.0"

  @impl true
  def capabilities, do: [:state_aggregation, :system_observability, :trend_analysis]

  @impl true
  def dependencies, do: [:executive_memory, :event_store, :executive_service_bus]

  @impl true
  def constitutional_score do
    stats = if Process.whereis(__MODULE__), do: GenServer.call(__MODULE__, :stats), else: %{}
    %Tiannara.CEL.Kernel.ConstitutionalScore{
      service_id: id(),
      health: if(stats[:snapshots_generated] && stats[:snapshots_generated] > 0, do: 1.0, else: 0.5),
      constitutional_alignment: 1.0,
      transparency: 1.0,
      explainability: 1.0,
      evidence_quality: 1.0,
      human_oversight: 1.0,
      computed_at: DateTime.utc_now()
    }
  end

  # ── Client API ────────────────────────────────────────────────────

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def current_state, do: GenServer.call(__MODULE__, :current_state)

  def force_snapshot, do: GenServer.call(__MODULE__, :force_snapshot)

  def stats, do: GenServer.call(__MODULE__, :stats)

  # ── Init ──────────────────────────────────────────────────────────

  @impl true
  def init(_opts) do
    schedule_snapshot()
    {:ok, %{
      current_snapshot: ExecutiveState.new(),
      snapshots_generated: 0,
      last_snapshot_at: nil,
      healthy: true
    }}
  end

  # ── handle_call ───────────────────────────────────────────────────

  @impl true
  def handle_call(:current_state, _from, state) do
    {:reply, state.current_snapshot, state}
  end

  @impl true
  def handle_call(:force_snapshot, _from, state) do
    new_snapshot = build_snapshot(state.current_snapshot)
    {:reply, :ok, %{state |
      current_snapshot: new_snapshot,
      snapshots_generated: state.snapshots_generated + 1,
      last_snapshot_at: DateTime.utc_now()
    }}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    {:reply, %{
      healthy: state.healthy,
      snapshots_generated: state.snapshots_generated,
      last_snapshot_at: state.last_snapshot_at
    }, state}
  end

  # ── handle_info ───────────────────────────────────────────────────

  @impl true
  def handle_info(:generate_snapshot, state) do
    new_snapshot = build_snapshot(state.current_snapshot)
    agg_health = ExecutiveState.aggregate_health(new_snapshot)

    EventBus.publish("executive.state.updated", %{
      snapshot_id: new_snapshot.snapshot_id,
      aggregate_health: agg_health,
      kernel_state: new_snapshot.kernel_state,
      constitutional_status: new_snapshot.constitutional_status
    })

    ExecutiveMemory.record_event(:executive_state, :snapshot_generated, %{
      snapshot_id: new_snapshot.snapshot_id,
      aggregate_health: agg_health,
      anomalies: length(new_snapshot.anomalies_detected)
    })

    schedule_snapshot()

    {:noreply, %{state |
      current_snapshot: new_snapshot,
      snapshots_generated: state.snapshots_generated + 1,
      last_snapshot_at: DateTime.utc_now()
    }}
  end

  # ── Private: State Aggregation ────────────────────────────────────

  defp build_snapshot(previous) do
    base = %{previous |
      snapshot_id: "snap_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}",
      generated_at: DateTime.utc_now()
    }

    base = %{base |
      constitution_version: get_constitution_version(),
      kernel_state: get_kernel_state(),
      constitutional_status: get_constitutional_status(),
      active_human_reviews: get_human_review_count(),
      policy_version: "1.0.0",
      service_health: get_service_health(),
      resource_allocation: get_resource_allocation(),
      scheduling_state: get_scheduling_state(),
      active_missions: get_mission_state(),
      active_workflows: get_workflow_state(),
      workflow_bottlenecks: get_workflow_bottlenecks(),
      capability_snapshot: get_capability_snapshot(),
      knowledge_ingestion_rate: get_knowledge_ingestion_rate(),
      anomalies_detected: detect_anomalies(base),
      confidence: calculate_snapshot_confidence(base)
    }

    base
  end

  defp get_constitution_version do
    case Council.constitution() do
      %{version: v} -> v
      _ -> "unknown"
    end
  rescue
    _ -> "unknown"
  end

  defp get_kernel_state do
    Tiannara.CEL.Kernel.runtime_state()
  rescue
    _ -> :unknown
  end

  defp get_constitutional_status do
    case Council.constitutional_health() do
      %{aggregate_constitutional_score: score} when score < 0.5 -> :violated
      %{aggregate_constitutional_score: score} when score < 0.8 -> :degraded
      _ -> :compliant
    end
  rescue
    _ -> :unknown
  end

  defp get_human_review_count do
    length(Council.HumanApprovalQueue.pending())
  rescue
    _ -> 0
  end

  defp get_service_health do
    scores = Tiannara.CEL.Services.ConstitutionalScorePipeline.all_scores()
    Map.new(scores, fn {service_id, score} ->
      {service_id, %{
        status: score.health > 0.8 and score.evidence_quality > 0.5,
        constitutional_score: score_to_aggregate(score)
      }}
    end)
  rescue
    _ -> %{}
  end

  defp get_resource_allocation do
    pool = ResourceManager.pool()

    pool
    |> Map.new(fn {resource, details} ->
      capacity = details.total || 100.0
      allocated = details.used || 0.0
      {resource, %{capacity: capacity, allocated: allocated, bottleneck_flag: allocated / max(1, capacity) > 0.8}}
    end)
  rescue
    _ -> %{}
  end

  defp get_scheduling_state do
    stats = Tiannara.CEL.Services.ExecutiveScheduler.stats()
    %{
      queue_depth: stats.queue_length || 0,
      active_jobs: stats.running_count || 0,
      starvation_warnings: stats.starved_missions || 0
    }
  rescue
    _ -> %{queue_depth: 0, active_jobs: 0, starvation_warnings: 0}
  end

  defp get_mission_state do
    missions = Tiannara.CEL.Services.MissionDirector.active_missions()
    %{
      count: length(missions),
      status_summary: missions |> Enum.group_by(& &1.status) |> Map.new(fn {k, v} -> {k, length(v)} end)
    }
  rescue
    _ -> %{count: 0, status_summary: %{}}
  end

  defp get_workflow_state do
    workflows = Tiannara.CEL.Services.WorkflowEngine.active_workflows()
    %{
      count: length(workflows),
      status_summary: workflows |> Enum.group_by(& &1.status) |> Map.new(fn {k, v} -> {k, length(v)} end)
    }
  rescue
    _ -> %{count: 0, status_summary: %{}}
  end

  defp get_workflow_bottlenecks do
    stats = Tiannara.CEL.Services.WorkflowEngine.stats()
    Map.get(stats, :bottleneck_steps, [])
  rescue
    _ -> []
  end

  defp get_capability_snapshot do
    stats = CapabilityGraph.stats()
    %{
      total: stats.capability_count || 0,
      spof: stats.single_points_of_failure || 0,
      deprecated: stats.deprecated_count || 0
    }
  rescue
    _ -> %{total: 0, spof: 0, deprecated: 0}
  end

  defp get_knowledge_ingestion_rate, do: 0.0

  defp detect_anomalies(state) do
    []
    |> maybe_add_anomaly(state.scheduling_state.starvation_warnings > 0,
      fn -> %{type: :scheduling_starvation, severity: :high, details: state.scheduling_state.starvation_warnings} end)
    |> maybe_add_anomaly(state.capability_snapshot.spof > 5,
      fn -> %{type: :high_spof_count, severity: :medium, details: state.capability_snapshot.spof} end)
    |> maybe_add_anomaly(
      state.resource_allocation |> Map.values() |> Enum.any?(& &1.bottleneck_flag),
      fn -> %{type: :resource_bottleneck, severity: :high, details: "One or more resources > 80% utilized"} end)
  end

  defp maybe_add_anomaly(list, true, anomaly_fn), do: [anomaly_fn.() | list]
  defp maybe_add_anomaly(list, false, _), do: list

  defp calculate_snapshot_confidence(state) do
    missing = [:resource_manager, :capability_graph, :workflow_engine]
               |> Enum.count(fn svc -> not Map.has_key?(state.service_health, svc) end)
    max(0.0, 1.0 - (missing * 0.2))
  end

  defp score_to_aggregate(%{health: h, constitutional_alignment: ca, evidence_quality: eq}) do
    h * 0.4 + ca * 0.3 + eq * 0.3
  end
  defp score_to_aggregate(_), do: 0.5

  defp schedule_snapshot do
    Process.send_after(self(), :generate_snapshot, @snapshot_interval)
  end
end
