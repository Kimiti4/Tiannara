defmodule Tiannara.Operations.AutonomousLoop do
  use GenServer
  require Logger

  @loop_interval :timer.minutes(5)

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def status, do: GenServer.call(__MODULE__, :status)

  @impl true
  def init(_opts) do
    Logger.info("AutonomousLoop: Starting Tiannara autonomous operations")
    schedule_loop()

    {:ok, %{
      cycles_completed: 0,
      last_cycle_at: nil,
      anomalies_detected: 0,
      recoveries_performed: 0,
      discoveries_triggered: 0,
      started_at: DateTime.utc_now()
    }}
  end

  @impl true
  def handle_call(:status, _from, state), do: {:reply, state, state}

  @impl true
  def handle_info(:run_loop, state) do
    schedule_loop()
    {:noreply, run_autonomous_cycle(state)}
  end

  @impl true
  def handle_info(_, state), do: {:noreply, state}

  defp run_autonomous_cycle(state) do
    cycle_start = System.monotonic_time(:millisecond)

    health = check_system_health()
    anomalies = detect_anomalies(health)
    recoveries = recover_failures(health)

    if rem(state.cycles_completed, 12) == 0 do
      Tiannara.ControlCenter.constitutional_audit()
    end

    discoveries =
      if rem(state.cycles_completed, 6) == 0 do
        trigger_discovery()
      else
        0
      end

    if rem(state.cycles_completed, 12) == 0 do
      Tiannara.ControlCenter.check_health()
    end

    cycle_duration = System.monotonic_time(:millisecond) - cycle_start

    if cycle_duration > 5000 do
      Logger.warning("AutonomousLoop: Cycle took #{cycle_duration}ms (> 5s)")
    end

    %{state |
      cycles_completed: state.cycles_completed + 1,
      last_cycle_at: DateTime.utc_now(),
      anomalies_detected: state.anomalies_detected + length(anomalies),
      recoveries_performed: state.recoveries_performed + length(recoveries),
      discoveries_triggered: state.discoveries_triggered + discoveries
    }
  end

  defp check_system_health do
    try do
      Tiannara.ControlCenter.status()
    rescue
      _ -> %{subsystems: %{}, healthy: 0, total: 0, autonomous: false}
    end
  end

  defp detect_anomalies(health) do
    anomalies = []

    anomalies =
      if health.healthy < health.total do
        [%{type: :unhealthy_subsystems, count: health.total - health.healthy} | anomalies]
      else
        anomalies
      end

    anomalies =
      if not health.autonomous do
        [%{type: :not_autonomous} | anomalies]
      else
        anomalies
      end

    if anomalies != [] do
      Logger.warning("AutonomousLoop: #{length(anomalies)} anomalies detected")
    end

    anomalies
  end

  defp recover_failures(health) do
    if health.healthy < health.total do
      Logger.info("AutonomousLoop: #{health.total - health.healthy} subsystems need recovery")
      Tiannara.ControlCenter.check_health()

      health.subsystems
      |> Enum.filter(fn {_id, s} -> not s.alive end)
      |> Enum.map(fn {id, _} -> id end)
    else
      []
    end
  end

  defp trigger_discovery do
    try do
      Tiannara.Discovery.DiscoveryScheduler.trigger_cycle()
      1
    rescue
      _ -> 0
    end
  end

  defp schedule_loop, do: Process.send_after(self(), :run_loop, @loop_interval)
end
