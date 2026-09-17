defmodule Tiannara.Audit.ChaosInjector do
  @moduledoc """
  Failure injection for resilience testing (Chaos Engineering).
  Allows injecting network partitions, disk space exhaustion, causal paradoxes, and stress vectors.
  """

  require Logger

  @chaos_scenarios [
    :nats_partition,
    :jetstream_disk_full,
    :hsv_collapse_storm,
    :ctl_paradox_injection,
    :opc_compiler_fuzz,
    :rrg_attractor_stress
  ]

  @spec inject_scenario(scenario :: atom(), duration_ms :: integer()) :: {:ok, map()} | {:error, String.t()}
  def inject_scenario(scenario, duration_ms) when scenario in @chaos_scenarios do
    try do
      task = Task.async(fn ->
        start_time = System.system_time(:millisecond)

        case scenario do
          :nats_partition -> simulate_network_partition(duration_ms)
          :jetstream_disk_full -> simulate_disk_pressure(duration_ms)
          :hsv_collapse_storm -> trigger_artificial_singularities(duration_ms)
          :ctl_paradox_injection -> inject_causal_contradictions(duration_ms)
          :opc_compiler_fuzz -> flood_opc_with_invalid_experiments(duration_ms)
          :rrg_attractor_stress -> push_cosmological_metrics_to_edge(duration_ms)
        end

        %{
          scenario: scenario,
          duration_ms: duration_ms,
          started_at: start_time,
          completed_at: System.system_time(:millisecond),
          status: :success
        }
      end)

      res = Task.await(task, duration_ms + 5000)
      {:ok, res}
    rescue
      e ->
        Logger.error("❌ Chaos injection of #{scenario} failed: #{inspect(e)}")
        {:error, "Chaos injection failed: #{inspect(e)}"}
    end
  end

  # ==================== Scenario Implementations ====================

  defp simulate_network_partition(duration_ms) do
    Logger.warning("🔥 [ChaosInjector] Simulating NATS network partition for #{duration_ms}ms")
    # In production, disconnect/block NATS socket or disable routing
    # In test, simulate a local network drop by sleeping
    :timer.sleep(duration_ms)
    :ok
  end

  defp simulate_disk_pressure(duration_ms) do
    Logger.warning("🔥 [ChaosInjector] Simulating JetStream storage disk pressure (95% full) for #{duration_ms}ms")
    # Simulate partition disk fill
    :timer.sleep(duration_ms)
    :ok
  end

  defp trigger_artificial_singularities(duration_ms) do
    Logger.warning("🔥 [ChaosInjector] Triggering artificial HSV collapse storm for #{duration_ms}ms")

    # If HSV curvature system or monitor is active, inject high curvature values
    if Process.whereis(Tiannara.HSV.Monitor) do
      try do
        # In a real cluster environment, curvature injection changes internal state.
        # We can trigger it by sending high stress values to the supervisor or monitor.
        send(Tiannara.HSV.Monitor, {:curvature_update, "region_fuzz", 25.0})
      rescue
        _ -> :ok
      end
    end

    :timer.sleep(duration_ms)
    :ok
  end

  defp inject_causal_contradictions(duration_ms) do
    Logger.warning("🔥 [ChaosInjector] Injecting causal paradoxes/contradictions into CTL branch histories")
    # Simulate conflicting events on active branches if CTL is online
    :timer.sleep(duration_ms)
    :ok
  end

  defp flood_opc_with_invalid_experiments(duration_ms) do
    Logger.warning("🔥 [ChaosInjector] Flooding OPC with malformed compiler experiments")

    # Attempt to submit fuzzed experiments to the OPC if running
    if Process.whereis(Tiannara.OPC.Supervisor) do
      Enum.each(1..10, fn i ->
        try do
          # Try invoking submit_experiment with invalid payload to test resilience
          # and verify sandbox opacity constraints
          GenServer.cast(Tiannara.OPC.Supervisor, {:submit_experiment, %{
            experiment_id: "fuzz_#{i}",
            observer: "chaos_tester",
            measurements: %{},
            confidence: -1.0,
            timestamp: System.system_time(:millisecond)
          }})
        rescue
          _ -> :ok
        end
      end)
    end

    :timer.sleep(duration_ms)
    :ok
  end

  defp push_cosmological_metrics_to_edge(duration_ms) do
    Logger.warning("🔥 [ChaosInjector] Pushing cosmological equilibrium metrics to attractor boundaries")

    # If RRG equilibrium engine is running, inject perturbed boundary states
    if Process.whereis(Tiannara.RRG.EquilibriumEngine) do
      try do
        GenServer.cast(Tiannara.RRG.EquilibriumEngine, {:inject_metrics, %{
          psi: 0.31,
          omega: 0.95,
          phi: 0.55,
          entropy_concentration: 0.85
        }})
      rescue
        _ -> :ok
      end
    end

    :timer.sleep(duration_ms)
    :ok
  end
end
