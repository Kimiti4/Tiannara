defmodule Tiannara.Sentinel.ObservationScheduler do
  @moduledoc """
  Observation Scheduler — drives continuous autonomous observation.

  At each interval, collects system observations and feeds them through
  the Sentinel pipeline: Buffer → PatternDetector → AnomalyClassifier → PriorityEngine.

  ## Constitutional Alignment

    - Determinism: Observation interval is fixed and predictable.
    - Observability: Every observation cycle is metered.
    - Bottleneck Discovery: Observations explicitly target bottleneck indicators.
    - Long-Term Optimization: Designed for decades of continuous operation.
  """

  use GenServer

  require Logger

  alias Tiannara.Sentinel.{ObservationBuffer, PatternDetector, AnomalyClassifier, PriorityEngine}

  @default_interval_ms 10_000

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec status() :: map()
  def status do
    GenServer.call(__MODULE__, :status)
  end

  @spec trigger() :: :ok
  def trigger do
    GenServer.cast(__MODULE__, :trigger)
  end

  @impl true
  def init(opts) do
    interval = Keyword.get(opts, :interval_ms, @default_interval_ms)
    started_at = DateTime.utc_now()
    schedule_observation(interval)

    Logger.info("[ObservationScheduler] Started. Interval: #{interval}ms")

    {:ok, %{interval_ms: interval, started_at: started_at, cycles: 0, last_cycle_at: nil, last_cycle_duration_us: 0}}
  end

  @impl true
  def handle_info(:observe, state) do
    start_time = System.monotonic_time(:microsecond)

    observations = collect_observations()

    Enum.each(observations, fn obs ->
      ObservationBuffer.append(obs)
    end)

    recent = ObservationBuffer.recent(100)
    patterns = PatternDetector.analyze(recent)
    anomalies = AnomalyClassifier.classify(recent, patterns)
    PriorityEngine.update(anomalies, patterns)

    duration_us = System.monotonic_time(:microsecond) - start_time

    :telemetry.execute(
      [:tiannara, :sentinel, :observation_cycle],
      %{duration_us: duration_us, observations: length(observations)},
      %{anomalies: length(anomalies), patterns: length(patterns)}
    )

    schedule_observation(state.interval_ms)

    {:noreply, %{state | cycles: state.cycles + 1, last_cycle_at: DateTime.utc_now(), last_cycle_duration_us: duration_us}}
  end

  @impl true
  def handle_call(:status, _from, state) do
    {:reply, %{interval_ms: state.interval_ms, cycles: state.cycles, last_cycle_at: state.last_cycle_at, last_cycle_duration_us: state.last_cycle_duration_us, started_at: state.started_at}, state}
  end

  @impl true
  def handle_cast(:trigger, state) do
    send(self(), :observe)
    {:noreply, state}
  end

  defp collect_observations do
    timestamp = DateTime.utc_now()

    [
      observe_vm_health(timestamp),
      observe_process_health(timestamp),
      observe_memory_pressure(timestamp),
      observe_executive_health(timestamp),
      observe_ecr_health(timestamp)
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp observe_vm_health(timestamp) do
    %{
      id: Tiannara.Executive.Types.new_id(), type: :vm_health, source: :beam_vm, timestamp: timestamp,
      value: %{
        total_memory: :erlang.memory(:total), processes_memory: :erlang.memory(:processes),
        ets_memory: :erlang.memory(:ets), atom_count: :erlang.system_info(:atom_count),
        atom_limit: :erlang.system_info(:atom_limit), process_count: :erlang.system_info(:process_count),
        process_limit: :erlang.system_info(:process_limit), run_queue: :erlang.statistics(:run_queue),
        uptime_seconds: :erlang.statistics(:wall_clock) |> elem(0) |> div(1000)
      }
    }
  end

  defp observe_process_health(timestamp) do
    %{
      id: Tiannara.Executive.Types.new_id(), type: :process_health, source: :process_monitor, timestamp: timestamp,
      value: %{total_processes: :erlang.system_info(:process_count), registered: length(Process.registered()), reductions: :erlang.statistics(:reductions) |> elem(0)}
    }
  end

  defp observe_memory_pressure(timestamp) do
    total = :erlang.memory(:total)
    processes = :erlang.memory(:processes)
    ratio = if total > 0, do: processes / total, else: 0.0

    %{
      id: Tiannara.Executive.Types.new_id(), type: :memory_pressure, source: :memory_monitor, timestamp: timestamp,
      value: %{total_bytes: total, process_bytes: processes, ets_bytes: :erlang.memory(:ets), binary_bytes: :erlang.memory(:binary), process_ratio: Float.round(ratio, 4)}
    }
  end

  defp observe_executive_health(timestamp) do
    case Process.whereis(Tiannara.Executive.ExecutiveMemory) do
      nil -> nil
      _pid ->
        try do
          health = Tiannara.Executive.ExecutiveMemory.health()
          %{id: Tiannara.Executive.Types.new_id(), type: :executive_memory_health, source: :executive_memory, timestamp: timestamp, value: health}
        catch
          _, _ -> nil
        end
    end
  end

  defp observe_ecr_health(timestamp) do
    case Process.whereis(Tiannara.Executive.Cognitive.ExecutiveCognitiveRuntime) do
      nil -> nil
      _pid ->
        try do
          health = Tiannara.Executive.Cognitive.ExecutiveCognitiveRuntime.health()
          %{id: Tiannara.Executive.Types.new_id(), type: :ecr_health, source: :executive_cognitive_runtime, timestamp: timestamp, value: health}
        catch
          _, _ -> nil
        end
    end
  end

  defp schedule_observation(interval) do
    Process.send_after(self(), :observe, interval)
  end
end
