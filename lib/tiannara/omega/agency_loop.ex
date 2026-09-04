defmodule Tiannara.Omega.AgencyLoop do
  @moduledoc """
  Agency Loop — unified continuous cognitive cycle.

  Orchestrates the Ω agency loop through a deterministic phase sequence:
  Heartbeat → Observe → Analyze → Investigate → Communicate → Improve → Learn → Repeat

  Each phase delegates to the appropriate subsystem.
  """

  use GenServer
  require Logger

  alias Tiannara.Executive.Cognitive.{ExecutiveBlackboard, ReflectionEngine, WorkingMemory}

  @phases [:observe, :analyze, :investigate, :communicate, :improve, :learn]

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec current_phase() :: atom()
  def current_phase do
    GenServer.call(__MODULE__, :current_phase)
  end

  @spec status() :: map()
  def status do
    GenServer.call(__MODULE__, :status)
  end

  @spec advance() :: :ok
  def advance do
    GenServer.cast(__MODULE__, :advance)
  end

  @spec loops_completed() :: non_neg_integer()
  def loops_completed do
    GenServer.call(__MODULE__, :loops_completed)
  end

  @impl true
  def init(_opts) do
    Logger.info("[AgencyLoop] Initialized. Phases: #{inspect(@phases)}")

    :telemetry.attach("agency-loop-heartbeat", [:tiannara, :ecr, :heartbeat], &__MODULE__.handle_heartbeat/4, nil)

    {:ok, %{current_phase_index: 0, loops_completed: 0, phase_history: [], last_phase_at: nil, started_at: DateTime.utc_now(), errors: []}}
  end

  @impl true
  def handle_cast(:advance, state) do
    phase = Enum.at(@phases, state.current_phase_index)
    start_time = System.monotonic_time(:microsecond)
    result = execute_phase(phase, state)
    duration_us = System.monotonic_time(:microsecond) - start_time

    ExecutiveBlackboard.post(:agency_loop, %{phase: phase, result: result, duration_us: duration_us, loop: state.loops_completed, timestamp: DateTime.utc_now()})

    :telemetry.execute([:tiannara, :omega, :agency_phase], %{duration_us: duration_us}, %{phase: phase, loop: state.loops_completed, status: normalize_result(result)})

    next_index = rem(state.current_phase_index + 1, length(@phases))
    completed_loop = next_index == 0

    if completed_loop do
      Logger.debug("[AgencyLoop] Loop #{state.loops_completed + 1} completed.")
      :telemetry.execute([:tiannara, :omega, :loop_completed], %{count: state.loops_completed + 1}, %{})
    end

    {:noreply, %{state | current_phase_index: next_index, loops_completed: if(completed_loop, do: state.loops_completed + 1, else: state.loops_completed), last_phase_at: DateTime.utc_now(), phase_history: [{phase, result, duration_us} | Enum.take(state.phase_history, 99)]}}
  end

  @impl true
  def handle_call(:current_phase, _from, state) do
    {:reply, Enum.at(@phases, state.current_phase_index), state}
  end

  @impl true
  def handle_call(:status, _from, state) do
    {:reply, %{current_phase: Enum.at(@phases, state.current_phase_index), loops_completed: state.loops_completed, last_phase_at: state.last_phase_at, started_at: state.started_at, uptime_seconds: DateTime.diff(DateTime.utc_now(), state.started_at, :second), recent_phases: Enum.take(state.phase_history, 12)}, state}
  end

  @impl true
  def handle_call(:loops_completed, _from, state) do
    {:reply, state.loops_completed, state}
  end

  def handle_heartbeat(_event, _measurements, _metadata, _config) do
    if Process.whereis(__MODULE__) do
      GenServer.cast(__MODULE__, :advance)
    end
  end

  defp execute_phase(:observe, _state) do
    observations = safe_call(Tiannara.Sentinel.SentinelRuntime, fn -> Tiannara.Sentinel.SentinelRuntime.recent_observations(50) end, [])
    WorkingMemory.store(:agency_observations, observations)
    {:ok, %{observations: length(observations)}}
  end

  defp execute_phase(:analyze, _state) do
    priorities = safe_call(Tiannara.Sentinel.SentinelRuntime, fn -> Tiannara.Sentinel.SentinelRuntime.research_priorities() end, [])
    WorkingMemory.store(:agency_priorities, priorities)
    {:ok, %{priorities: length(priorities)}}
  end

  defp execute_phase(:investigate, _state) do
    priorities = WorkingMemory.retrieve(:agency_priorities) || []
    if length(priorities) > 0 do
      safe_call(Tiannara.Research.ResearchDirector, fn ->
        Tiannara.Research.ResearchDirector.ingest_priorities(priorities)
        Tiannara.Research.ResearchDirector.advance()
      end, :ok)
    end
    {:ok, %{priorities_ingested: length(priorities)}}
  end

  defp execute_phase(:communicate, _state) do
    knowledge = safe_call(Tiannara.Research.ResearchDirector, fn -> Tiannara.Research.ResearchDirector.validated_knowledge() end, [])
    surfaced = knowledge |> Enum.filter(fn k -> (k[:confidence] || 0) >= 0.85 end) |> Enum.take(3)
    Enum.each(surfaced, fn item ->
      safe_call(Tiannara.Interface.CognitiveInterface, fn -> Tiannara.Interface.CognitiveInterface.surface_discovery(item) end, :ok)
    end)
    {:ok, %{surfaced: length(surfaced)}}
  end

  defp execute_phase(:improve, state) do
    loops_completed = state.loops_completed
    if rem(loops_completed, 5) == 0 and loops_completed > 0 do
      safe_call(Tiannara.Autonomy.ConstitutionalAutonomy, fn -> Tiannara.Autonomy.ConstitutionalAutonomy.run_cycle() end, {:ok, :skipped})
    end
    {:ok, :improvement_phase}
  end

  defp execute_phase(:learn, _state) do
    safe_call(Tiannara.Executive.Cognitive.ReflectionEngine, fn -> ReflectionEngine.reflect() end, :ok)
    ExecutiveBlackboard.post(:constitutional_self_evaluation, %{
      timestamp: DateTime.utc_now(),
      questions: [
        "What assumptions am I making?",
        "What evidence contradicts me?",
        "What is my largest bottleneck?",
        "What scales poorly?",
        "What could fail under larger workloads?",
        "What knowledge am I missing?",
        "What experiment should I perform next?",
        "What architecture would replace me?",
        "What would a more advanced version of Tiannara do?",
        "Does this increase Tiannara's ability to help humanity?"
      ],
      status: :evaluated
    })
    {:ok, :learned}
  end

  defp safe_call(module, fun, default) do
    case Process.whereis(module) do
      nil -> default
      _pid ->
        try do
          fun.()
        catch
          kind, reason ->
            Logger.warning("[AgencyLoop] #{module} call failed: #{kind} #{inspect(reason)}")
            default
        end
    end
  end

  defp normalize_result({:ok, _}), do: :ok
  defp normalize_result(:ok), do: :ok
  defp normalize_result(_), do: :error
end
