defmodule Tiannara.World.EpistemicIntegrityService do
  use GenServer
  use Tiannara.ExecutiveService.Base
  require Logger

  alias Tiannara.World.{UnifiedWorldModel, WorldQueryEngine, ConflictDetector, BeliefState}
  alias Tiannara.CEL.Services.{EventBus, ExecutiveMemory}
  alias Tiannara.CEL.Kernel.ConstitutionalScore

  @monitoring_interval :timer.hours(1)

  @impl Tiannara.ExecutiveService
  def id, do: :epistemic_integrity_service

  @impl Tiannara.ExecutiveService
  def version, do: "1.0.0"

  @impl Tiannara.ExecutiveService
  def capabilities do
    [
      :contradiction_rate_monitoring, :evidence_quality_measurement,
      :provenance_completeness_tracking, :stale_theory_detection,
      :experiment_recommendation, :epistemic_drift_detection
    ]
  end

  @impl Tiannara.ExecutiveService
  def dependencies do
    [:persistent_memory, :event_transport, :unified_world_model, :conflict_detector]
  end

  @impl Tiannara.ExecutiveService
  def priority, do: :high

  @impl Tiannara.ExecutiveService
  def constitutional_score do
    stats = GenServer.call(__MODULE__, :stats)
    health = (
      stats.provenance_completeness * 0.3 +
      stats.evidence_quality * 0.3 +
      (1.0 - stats.contradiction_rate) * 0.2 +
      (1.0 - stats.stale_theory_rate) * 0.2
    )

    %ConstitutionalScore{
      service_id: id(), health: health,
      constitutional_alignment: 1.0, transparency: 1.0,
      explainability: 1.0, evidence_quality: stats.evidence_quality,
      human_oversight: 1.0, computed_at: DateTime.utc_now()
    }
  end

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def check_integrity, do: GenServer.call(__MODULE__, :check_integrity, :timer.minutes(2))

  def integrity_report, do: GenServer.call(__MODULE__, :integrity_report)

  def stats, do: GenServer.call(__MODULE__, :stats)

  @impl true
  def init(_opts) do
    schedule_monitoring()

    {:ok, %{
      contradiction_rate: 0.0, evidence_quality: 1.0,
      provenance_completeness: 1.0, stale_theory_rate: 0.0,
      experiment_recommendations: [],
      last_check_at: nil, healthy: true, started_at: DateTime.utc_now()
    }}
  end

  @impl true
  def handle_call(:check_integrity, _from, state) do
    report = run_integrity_check()

    new_state = %{state |
      contradiction_rate: report.contradiction_rate,
      evidence_quality: report.evidence_quality,
      provenance_completeness: report.provenance_completeness,
      stale_theory_rate: report.stale_theory_rate,
      experiment_recommendations: report.experiment_recommendations,
      last_check_at: DateTime.utc_now()
    }

    ExecutiveMemory.record_decision(
      "integrity_check_#{DateTime.utc_now() |> DateTime.to_unix()}",
      :epistemic_integrity_checked, report
    )

    schedule_monitoring()
    {:reply, {:ok, report}, new_state}
  end

  @impl true
  def handle_call(:integrity_report, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call(:stats, _from, state), do: {:reply, state, state}

  @impl true
  def handle_info(:run_monitoring, state) do
    {:reply, _, new_state} = handle_call(:check_integrity, nil, state)
    schedule_monitoring()
    {:noreply, new_state}
  end

  defp run_integrity_check do
    {:ok, conflicts} = ConflictDetector.stats()
    total_entities = count_entities()
    contradiction_rate = if total_entities > 0, do: conflicts.unresolved_conflicts / total_entities, else: 0.0
    evidence_quality = compute_evidence_quality()
    provenance_completeness = compute_provenance_completeness()
    stale_theory_rate = compute_stale_theory_rate()
    experiment_recommendations = generate_experiment_recommendations(contradiction_rate, evidence_quality, stale_theory_rate)

    %{
      contradiction_rate: contradiction_rate,
      evidence_quality: evidence_quality,
      provenance_completeness: provenance_completeness,
      stale_theory_rate: stale_theory_rate,
      experiment_recommendations: experiment_recommendations,
      checked_at: DateTime.utc_now()
    }
  end

  defp count_entities do
    {:ok, result} = WorldQueryEngine.find(limit: 100_000)
    length(result.results)
  end

  defp compute_evidence_quality do
    {:ok, result} = WorldQueryEngine.find(type: :knowledge_entity, status: :active, limit: 10_000)
    if length(result.results) == 0 do
      1.0
    else
      avg = Enum.sum(Enum.map(result.results, fn e ->
        Map.get(e.attributes, :evidence_quality, 0.5)
      end))
      avg / length(result.results)
    end
  end

  defp compute_provenance_completeness do
    {:ok, result} = WorldQueryEngine.find(limit: 10_000)
    if length(result.results) == 0 do
      1.0
    else
      with_provenance = Enum.count(result.results, &Map.has_key?(&1, :provenance))
      with_provenance / length(result.results)
    end
  end

  defp compute_stale_theory_rate do
    cutoff = DateTime.add(DateTime.utc_now(), -180, :day)
    {:ok, result} = WorldQueryEngine.find(type: :knowledge_entity, subtype: :theory, status: :active, limit: 10_000)
    if length(result.results) == 0 do
      0.0
    else
      stale = Enum.count(result.results, fn e -> DateTime.compare(e.updated_at, cutoff) == :lt end)
      stale / length(result.results)
    end
  end

  defp generate_experiment_recommendations(contradiction_rate, evidence_quality, stale_theory_rate) do
    recs = []

    recs = if contradiction_rate > 0.05 do
      [%{type: :resolve_contradictions, priority: :high,
         reason: "High contradiction rate (#{Float.round(contradiction_rate, 3)})",
         estimated_effort: :medium} | recs]
    else
      recs
    end

    recs = if evidence_quality < 0.7 do
      [%{type: :strengthen_evidence, priority: :high,
         reason: "Low evidence quality (#{Float.round(evidence_quality, 3)})",
         estimated_effort: :high} | recs]
    else
      recs
    end

    recs = if stale_theory_rate > 0.3 do
      [%{type: :refresh_stale_theories, priority: :medium,
         reason: "High stale theory rate (#{Float.round(stale_theory_rate, 3)})",
         estimated_effort: :medium} | recs]
    else
      recs
    end

    recs
  end

  defp schedule_monitoring do
    Process.send_after(self(), :run_monitoring, @monitoring_interval)
  end
end
