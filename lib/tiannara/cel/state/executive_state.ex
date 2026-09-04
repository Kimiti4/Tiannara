defmodule Tiannara.CEL.State.ExecutiveState do
  @moduledoc """
  Executive State — the canonical, immutable snapshot of the Executive Layer's runtime condition.

  Instead of querying 10 different services to understand system health, the Executive Layer
  maintains this unified state model. It serves as the single source of truth for:
    - The Constitutional Council (for governance oversight)
    - The Executive Kernel (for orchestration decisions)
    - The Executive Dashboard (for human observability)
    - Phase 3 World Model (as the bridge to civilizational state)

  Constitutional Alignment (rules.md):
    - "Observability": Provides a unified, consistent view of executive state.
    - "Uncertainty should never be hidden": Includes confidence scores and degradation flags.
    - "Continuous Self-Evaluation": Aggregates bottleneck and health metrics for systemic review.
    - "Modularity": Decouples state consumers from individual service implementations.
  """

  defstruct [
    :snapshot_id,
    :generated_at,
    :constitution_version,
    :boot_phase,
    :kernel_state,
    :constitutional_status,
    :active_human_reviews,
    :policy_version,
    :service_health,
    :resource_allocation,
    :scheduling_state,
    :active_missions,
    :active_workflows,
    :workflow_bottlenecks,
    :capability_snapshot,
    :knowledge_ingestion_rate,
    :confidence,
    :anomalies_detected
  ]

  @type t :: %__MODULE__{
          snapshot_id: String.t(),
          generated_at: DateTime.t(),
          constitution_version: String.t(),
          boot_phase: atom(),
          kernel_state: atom(),
          constitutional_status: atom(),
          active_human_reviews: non_neg_integer(),
          policy_version: String.t(),
          service_health: map(),
          resource_allocation: map(),
          scheduling_state: map(),
          active_missions: map(),
          active_workflows: map(),
          workflow_bottlenecks: [map()],
          capability_snapshot: map(),
          knowledge_ingestion_rate: float(),
          confidence: float(),
          anomalies_detected: [map()]
        }

  def new do
    %__MODULE__{
      snapshot_id: "snap_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}",
      generated_at: DateTime.utc_now(),
      constitution_version: "unknown",
      boot_phase: :initializing,
      kernel_state: :booting,
      constitutional_status: :compliant,
      active_human_reviews: 0,
      policy_version: "1.0.0",
      service_health: %{},
      resource_allocation: %{},
      scheduling_state: %{queue_depth: 0, active_jobs: 0, starvation_warnings: 0, bottlenecks: []},
      active_missions: %{count: 0, status_summary: %{}},
      active_workflows: %{count: 0, status_summary: %{}, bottlenecks: []},
      workflow_bottlenecks: [],
      capability_snapshot: %{total: 0, spof: 0, deprecated: 0},
      knowledge_ingestion_rate: 0.0,
      confidence: 1.0,
      anomalies_detected: []
    }
  end

  def aggregate_health(%__MODULE__{} = state) do
    service_score = average_service_health(state.service_health)
    resource_score = average_resource_headroom(state.resource_allocation)
    constitutional_score = constitutional_status_to_score(state.constitutional_status)

    penalty = (length(state.anomalies_detected) * 0.05) +
              ((state.scheduling_state.starvation_warnings || 0) * 0.1)

    max(0.0, min(1.0, (service_score * 0.4 + resource_score * 0.3 + constitutional_score * 0.3) - penalty))
  end

  defp average_service_health(health_map) do
    if map_size(health_map) == 0 do
      1.0
    else
      scores = health_map |> Map.values() |> Enum.map(& &1.constitutional_score)
      Enum.sum(scores) / map_size(health_map)
    end
  end

  defp average_resource_headroom(resource_map) do
    if map_size(resource_map) == 0 do
      1.0
    else
      resource_map
      |> Map.values()
      |> Enum.map(fn %{capacity: c, allocated: a} -> 1.0 - (a / max(1, c)) end)
      |> Enum.sum()
      |> Kernel./(map_size(resource_map))
    end
  end

  defp constitutional_status_to_score(:compliant), do: 1.0
  defp constitutional_status_to_score(:degraded), do: 0.7
  defp constitutional_status_to_score(:violated), do: 0.3
  defp constitutional_status_to_score(:emergency), do: 0.0
  defp constitutional_status_to_score(_), do: 0.5
end
