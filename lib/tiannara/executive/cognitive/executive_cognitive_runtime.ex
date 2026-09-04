defmodule Tiannara.Executive.Cognitive.ExecutiveCognitiveRuntime do
  @moduledoc """
  Executive Cognitive Runtime (ECR) — TIA-ECR-001

  The continuously running cognitive substrate for Tiannara's Ω agency loop.
  Orchestrates the heartbeat, cognitive cycle, attention, reflection, and
  blackboard into a unified autonomous executive process.

  ## Core Loop

      Observe → Interpret → Prioritize → Investigate →
      Plan → Execute → Validate → Learn → Repeat

  ## Constitutional Alignment

    - Continuous Self-Evaluation: Reflection engine runs every cycle.
    - Verification First: Every execution is validated before learning.
    - Safety: Capability never outpaces verification; rollback is always available.
    - Observability: Every cycle phase emits telemetry.
    - Modularity: Each cognitive function is an isolated, replaceable module.
    - Architecture Philosophy: Many specialized components cooperating through
      well-defined interfaces, not a single monolithic intelligence.
  """

  use Supervisor

  require Logger

  alias Tiannara.Executive.Cognitive.{
    HeartbeatEngine,
    ExecutiveCycle,
    ContextManager,
    AttentionScheduler,
    WorkingMemory,
    ReflectionEngine,
    ExecutiveBlackboard
  }

  @spec start_link(keyword()) :: Supervisor.on_start()
  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Returns the current cognitive runtime status."
  @spec status() :: map()
  def status do
    %{
      heartbeat: HeartbeatEngine.status(),
      cycle: ExecutiveCycle.status(),
      attention: AttentionScheduler.status(),
      working_memory: WorkingMemory.status(),
      reflection: ReflectionEngine.status(),
      blackboard: ExecutiveBlackboard.status()
    }
  end

  @doc "Returns runtime health for Sentinel integration."
  @spec health() :: map()
  def health do
    %{
      status: :healthy,
      uptime_seconds: HeartbeatEngine.uptime_seconds(),
      cycles_completed: ExecutiveCycle.cycles_completed(),
      last_reflection: ReflectionEngine.last_reflection(),
      active_attentions: AttentionScheduler.active_count()
    }
  end

  @impl true
  def init(opts) do
    Logger.info("[ECR] Starting Executive Cognitive Runtime...")

    heartbeat_interval = Keyword.get(opts, :heartbeat_interval_ms, 5_000)

    children = [
      %{id: ExecutiveBlackboard, start: {ExecutiveBlackboard, :start_link, [[]]}, restart: :permanent, shutdown: 5_000, type: :worker},
      %{id: WorkingMemory, start: {WorkingMemory, :start_link, [[]]}, restart: :permanent, shutdown: 5_000, type: :worker},
      %{id: ContextManager, start: {ContextManager, :start_link, [[]]}, restart: :permanent, shutdown: 5_000, type: :worker},
      %{id: AttentionScheduler, start: {AttentionScheduler, :start_link, [[]]}, restart: :permanent, shutdown: 5_000, type: :worker},
      %{id: ReflectionEngine, start: {ReflectionEngine, :start_link, [[]]}, restart: :permanent, shutdown: 5_000, type: :worker},
      %{id: ExecutiveCycle, start: {ExecutiveCycle, :start_link, [[]]}, restart: :permanent, shutdown: 10_000, type: :worker},
      %{id: HeartbeatEngine, start: {HeartbeatEngine, :start_link, [[interval_ms: heartbeat_interval]]}, restart: :permanent, shutdown: 5_000, type: :worker}
    ]

    Supervisor.init(children, strategy: :one_for_one, max_restarts: 5, max_seconds: 30)
  end
end
