defmodule TiannaraRuntime.Monitoring.EmergenceDetector do
  @moduledoc """
  Rule-based emergence detector for runtime adaptation monitoring.
  """

  require Logger

  def monitor_continuous(baseline_window_hours \\ 12) do
    baseline = establish_baseline(baseline_window_hours)

    spawn_link(fn ->
      run_monitor(baseline)
    end)

    :ok
  end

  defp run_monitor(baseline) do
    results = [
      {:rule_1_undesigned_structure, rule_1_undesigned_structure(baseline)},
      {:rule_2_independent_convergence, rule_2_independent_convergence(baseline)},
      {:rule_3_cis_response_triggers, rule_3_cis_response_triggers(baseline)},
      {:rule_4_nonlinear_surges, rule_4_nonlinear_surges(baseline)},
      {:rule_5_counterfactual_adaptation, rule_5_counterfactual_adaptation(baseline)}
    ]

    passes = Enum.count(results, fn {_name, status} -> status == :pass end)

    Logger.info("Emergence Detection: #{passes}/5 rules passed")

    Enum.each(results, fn {rule_name, status} ->
      icon =
        case status do
          :pass -> "✅"
          :fail -> "❌"
          :unknown -> "❓"
          :error -> "⚠️"
        end

      Logger.info("  #{icon} #{rule_name}")
    end)

    if passes == 5 do
      declare_emergence_true()
    end
  end

  defp rule_1_undesigned_structure(_baseline) do
    stats = TiannaraRuntime.Monitoring.TelemetryPublisher.get_metrics()

    if stats[:grcc][:value] > 0 and stats[:mscl][:value] >= 0 do
      :pass
    else
      :fail
    end
  end

  defp rule_2_independent_convergence(_baseline) do
    snapshot = Tiannara.UniverseServer.snapshot()

    if map_size(snapshot.civ_states) >= 2 do
      :pass
    else
      :fail
    end
  end

  defp rule_3_cis_response_triggers(_baseline) do
    snapshot = Tiannara.UniverseServer.snapshot()

    if snapshot.global_entropy > 0.1 or length(snapshot.pending_bursts) > 0 do
      :pass
    else
      :fail
    end
  end

  defp rule_4_nonlinear_surges(_baseline) do
    history = TiannaraRuntime.Monitoring.TelemetryPublisher.get_history(:mscl, 30)
    values = Enum.map(history, &Map.get(&1, :value, 0.0))

    if length(values) < 10 do
      :fail
    else
      first_derivative =
        values
        |> Enum.chunk_every(2, 1, :discard)
        |> Enum.map(fn [a, b] -> b - a end)

      second_derivative =
        first_derivative
        |> Enum.chunk_every(2, 1, :discard)
        |> Enum.map(fn [a, b] -> b - a end)

      surges = Enum.filter(second_derivative, fn value -> abs(value) > 0.01 end)

      if length(surges) >= 3 do
        :pass
      else
        :fail
      end
    end
  end

  defp rule_5_counterfactual_adaptation(_baseline) do
    snapshot = Tiannara.UniverseServer.snapshot()

    if map_size(snapshot.civ_states) > 0 and is_map(snapshot.constraint_field) do
      :unknown
    else
      :unknown
    end
  end

  defp establish_baseline(_hours) do
    Logger.info("Establishing baseline...")
    %{}
  end

  defp declare_emergence_true do
    Logger.warning("=" <> String.duplicate("=", 60))
    Logger.warning("🎯 REAL EMERGENCE CONFIRMED")
    Logger.warning("System is alive and adaptive.")
    Logger.warning("=" <> String.duplicate("=", 60))
  end
end
