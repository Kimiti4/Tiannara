defmodule Tiannara.Sentinel.SentinelRuntime do
  @moduledoc """
  Sentinel Runtime — TIA-OMEGA-1

  The continuously running autonomous monitoring subsystem for Tiannara.
  Observes system health, runtime behavior, knowledge integrity, and
  environmental signals without manual invocation.

  ## Architecture

      ObservationScheduler
              │
              ▼
      ObservationBuffer ←── PatternDetector
              │                    │
              ▼                    ▼
      AnomalyClassifier ──→ PriorityEngine
                                   │
                                   ▼
                          Executive Runtime
                          (Research Queue)

  ## Constitutional Alignment

    - Continuous Self-Evaluation: Sentinel IS the system's self-awareness.
    - Bottleneck Discovery: Actively searches for performance and knowledge gaps.
    - Safety: Detects uncertainty, anomalies, degraded performance.
    - Observability: Every observation is metered and inspectable.
    - Verification First: Anomalies trigger validation before action.
    - Evidence Before Confidence: Classifications carry confidence scores.
    - Scientific Method: Observation → Pattern → Hypothesis → Investigation.
  """

  use Supervisor

  require Logger

  alias Tiannara.Sentinel.{
    ObservationScheduler,
    ObservationBuffer,
    PatternDetector,
    AnomalyClassifier,
    PriorityEngine
  }

  @spec start_link(keyword()) :: Supervisor.on_start()
  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec status() :: map()
  def status do
    %{
      scheduler: ObservationScheduler.status(),
      buffer: ObservationBuffer.status(),
      patterns: PatternDetector.status(),
      anomalies: AnomalyClassifier.status(),
      priorities: PriorityEngine.status()
    }
  end

  @spec health() :: map()
  def health do
    %{
      status: :healthy,
      observations_total: ObservationBuffer.total_observations(),
      anomalies_detected: AnomalyClassifier.total_detected(),
      active_priorities: PriorityEngine.active_count(),
      patterns_tracked: PatternDetector.tracked_count()
    }
  end

  @spec recent_observations(non_neg_integer()) :: [map()]
  def recent_observations(count \\ 50) do
    ObservationBuffer.recent(count)
  end

  @spec research_priorities() :: [map()]
  def research_priorities do
    PriorityEngine.priorities()
  end

  @impl true
  def init(opts) do
    Logger.info("[Sentinel] Starting Sentinel Runtime...")

    observation_interval = Keyword.get(opts, :observation_interval_ms, 10_000)
    buffer_size = Keyword.get(opts, :buffer_size, 10_000)

    children = [
      %{id: ObservationBuffer, start: {ObservationBuffer, :start_link, [[max_size: buffer_size]]}, restart: :permanent, shutdown: 5_000, type: :worker},
      %{id: PatternDetector, start: {PatternDetector, :start_link, [[]]}, restart: :permanent, shutdown: 5_000, type: :worker},
      %{id: AnomalyClassifier, start: {AnomalyClassifier, :start_link, [[]]}, restart: :permanent, shutdown: 5_000, type: :worker},
      %{id: PriorityEngine, start: {PriorityEngine, :start_link, [[]]}, restart: :permanent, shutdown: 5_000, type: :worker},
      %{id: ObservationScheduler, start: {ObservationScheduler, :start_link, [[interval_ms: observation_interval]]}, restart: :permanent, shutdown: 5_000, type: :worker}
    ]

    Supervisor.init(children, strategy: :one_for_one, max_restarts: 5, max_seconds: 30)
  end
end
