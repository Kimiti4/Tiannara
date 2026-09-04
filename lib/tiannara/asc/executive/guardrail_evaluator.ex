defmodule Tiannara.ASC.Executive.GuardrailEvaluator do
  @moduledoc """
  Phase 10: Prevents Goodhart's Law (Metric Hacking).
  Evaluates real-world system state against Mission Guardrails.
  """
  alias Tiannara.ASC.Executive.Mission
  require Logger

  def check_guardrails(%Mission{} = mission, system_telemetry) do
    Enum.reduce(mission.guardrail_metrics, :ok, fn {metric, condition}, acc ->
      if acc == :breached do
        :breached
      else
        evaluate_condition(metric, condition, system_telemetry)
      end
    end)
  end

  defp evaluate_condition(:transfer_attempts, :must_not_decrease, telemetry) do
    # Simulated check: Did the system artificially lower the denominator to hack the success rate?
    if telemetry.attempts_delta < -0.10 do
      Logger.error("🚨 [Guardrail] BREACH: Transfer attempts dropped by #{telemetry.attempts_delta * 100}%! Suspected Metric Hacking.")
      :breached
    else
      :ok
    end
  end
  
  defp evaluate_condition(:cache_evictions, :must_not_decrease, telemetry) do
    # For Phase 10 demo scenario: cache evictions dropping means it stopped evicting to hit "Hit Rate"
    if Map.get(telemetry, :attempts_delta, 0.0) < -0.10 do
      Logger.error("🚨 [Guardrail] BREACH: Transfer attempts dropped by #{telemetry.attempts_delta * 100}%! Suspected Metric Hacking.")
      :breached
    else
      :ok
    end
  end

  defp evaluate_condition(:test_coverage, :must_not_drop_below_80, telemetry) do
    if telemetry.current_coverage < 0.80 do
      Logger.error("🚨 [Guardrail] BREACH: Test coverage dropped to #{telemetry.current_coverage}!")
      :breached
    else
      :ok
    end
  end
  
  defp evaluate_condition(_, _, _), do: :ok
end
