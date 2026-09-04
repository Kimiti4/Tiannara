defmodule Tiannara.Executive.Cognitive.ExecutiveCycle do
  @moduledoc """
  Executive Cycle — the core cognitive state machine.

  Advances through eight phases on each heartbeat:

      Observe → Interpret → Prioritize → Investigate →
      Plan → Execute → Validate → Learn

  Each phase delegates to the appropriate cognitive module and records
  its outcome on the Executive Blackboard.
  """

  use GenServer

  require Logger

  alias Tiannara.Executive.Cognitive.{
    ContextManager, AttentionScheduler, WorkingMemory,
    ReflectionEngine, ExecutiveBlackboard
  }

  @phases [:observe, :interpret, :prioritize, :investigate, :plan, :execute, :validate, :learn]

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec advance() :: :ok
  def advance do
    GenServer.cast(__MODULE__, :advance)
  end

  @spec status() :: map()
  def status do
    GenServer.call(__MODULE__, :status)
  end

  @spec cycles_completed() :: non_neg_integer()
  def cycles_completed do
    GenServer.call(__MODULE__, :cycles_completed)
  end

  @impl true
  def init(_opts) do
    Logger.info("[ExecutiveCycle] Initialized. Phases: #{inspect(@phases)}")
    {:ok, %{current_phase_index: 0, cycles_completed: 0, phase_history: [], last_phase_at: nil, errors: []}}
  end

  @impl true
  def handle_cast(:advance, state) do
    phase = Enum.at(@phases, state.current_phase_index)
    start_time = System.monotonic_time(:microsecond)
    result = execute_phase(phase)
    duration_us = System.monotonic_time(:microsecond) - start_time

    :telemetry.execute(
      [:tiannara, :ecr, :phase],
      %{duration_us: duration_us},
      %{phase: phase, status: if(result == :ok, do: :ok, else: :error)}
    )

    ExecutiveBlackboard.post(:cycle_phase, %{phase: phase, result: result, duration_us: duration_us, timestamp: DateTime.utc_now()})

    next_index = rem(state.current_phase_index + 1, length(@phases))
    completed_cycle = next_index == 0

    new_state = %{state |
      current_phase_index: next_index,
      cycles_completed: if(completed_cycle, do: state.cycles_completed + 1, else: state.cycles_completed),
      last_phase_at: DateTime.utc_now(),
      phase_history: [{phase, result, duration_us} | Enum.take(state.phase_history, 99)]
    }

    if completed_cycle do
      Logger.debug("[ExecutiveCycle] Cycle #{new_state.cycles_completed} completed.")
    end

    {:noreply, new_state}
  end

  @impl true
  def handle_call(:status, _from, state) do
    current_phase = Enum.at(@phases, state.current_phase_index)
    {:reply, %{current_phase: current_phase, cycles_completed: state.cycles_completed, last_phase_at: state.last_phase_at, recent_phases: Enum.take(state.phase_history, 8)}, state}
  end

  @impl true
  def handle_call(:cycles_completed, _from, state) do
    {:reply, state.cycles_completed, state}
  end

  defp execute_phase(:observe) do
    observations = gather_observations()
    WorkingMemory.store(:observations, observations)
    :ok
  end

  defp execute_phase(:interpret) do
    observations = WorkingMemory.retrieve(:observations) || []
    context = ContextManager.interpret(observations)
    WorkingMemory.store(:context, context)
    :ok
  end

  defp execute_phase(:prioritize) do
    context = WorkingMemory.retrieve(:context) || %{}
    priorities = AttentionScheduler.prioritize(context)
    WorkingMemory.store(:priorities, priorities)
    :ok
  end

  defp execute_phase(:investigate) do
    # Feed Sentinel priorities to Research Director
    case Process.whereis(Tiannara.Sentinel.SentinelRuntime) do
      nil -> :ok
      _pid ->
        priorities = Tiannara.Sentinel.SentinelRuntime.research_priorities()
        if length(priorities) > 0 do
          Tiannara.Research.ResearchDirector.ingest_priorities(priorities)
        end
    end

    # Advance the research pipeline
    case Process.whereis(Tiannara.Research.ResearchDirector) do
      nil -> :ok
      _pid -> Tiannara.Research.ResearchDirector.advance()
    end

    :ok
  end

  defp execute_phase(:plan) do
    # Research Director handles its own planning; ECR observes
    case Process.whereis(Tiannara.Research.ResearchDirector) do
      nil -> :ok
      _pid ->
        research_status = Tiannara.Research.ResearchDirector.status()
        ExecutiveBlackboard.post(:research_status, %{status: research_status, timestamp: DateTime.utc_now()})
    end

    :ok
  end

  defp execute_phase(:execute) do
    plan = WorkingMemory.retrieve(:plan)
    if plan do
      # Truthful: the plan is NOT executed here. Only its pending status is
      # recorded; a real execution provider must produce evidence.
      ExecutiveBlackboard.post(:execution, %{
        plan_id: plan.id,
        status: :pending,
        note: :awaiting_real_execution_provider,
        timestamp: DateTime.utc_now()
      })
    end
    :ok
  end

  defp execute_phase(:validate) do
    executions = ExecutiveBlackboard.read(:execution) || []
    Enum.each(executions, fn exec ->
      validated =
        is_map(exec) and exec.status == :executed and map_size(exec) > 0

      ExecutiveBlackboard.post(:validation, %{
        plan_id: Map.get(exec, :plan_id, :unknown),
        valid: validated,
        reason: if(validated, do: :real_evidence, else: :no_real_execution_evidence),
        timestamp: DateTime.utc_now()
      })
    end)
    :ok
  end

  defp execute_phase(:learn) do
    ReflectionEngine.reflect()
    :ok
  end

  defp gather_observations do
    case Process.whereis(Tiannara.Sentinel.SentinelRuntime) do
      nil ->
        [%{id: Tiannara.Executive.Types.new_id(), type: :system_health, source: :fallback, value: %{status: :nominal}, timestamp: DateTime.utc_now()}]
      _pid ->
        Tiannara.Sentinel.SentinelRuntime.recent_observations(50)
    end
  end
end
