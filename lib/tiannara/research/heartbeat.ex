defmodule Tiannara.Research.Heartbeat do
  @moduledoc """
  Quarantined heartbeat — replaces the previous heartbeat that fabricated
  experiment results using randomness.

  The new heartbeat:
    - Observes system state (queue depth, service health)
    - Does NOT generate fake experimental outcomes
    - Does NOT persist random values as scientific evidence
    - Emits explicit :not_executed or :awaiting_experiment states
    - Carries provenance marking any synthetic output

  Constitutional basis:
    - "Evidence Before Confidence"
    - "Uncertainty should never be hidden"
    - "Truth has priority over confidence"
  """

  require Logger

  @type heartbeat_state ::
          :healthy
          | :awaiting_experiment
          | :simulation_only
          | :degraded
          | :unknown

  @doc """
  Execute an observational heartbeat.

  Returns a heartbeat status with NO fabricated scientific results.
  The previous behavior (random result generation + persistence) is
  explicitly REMOVED.
  """
  @spec beat(map()) :: {:ok, map()}
  def beat(context) do
    status = assess_system_state(context)

    heartbeat_record = %{
      timestamp: DateTime.utc_now(),
      state: status,
      experiment_result: :not_executed,
      provenance: Tiannara.Evidence.Provenance.unknown("heartbeat_observational_only"),
      metrics: collect_observational_metrics(context)
    }

    Logger.info("[R0-heartbeat] observational beat completed", state: status)
    {:ok, heartbeat_record}
  end

  @doc """
  Assess system state without fabricating scientific outcomes.
  """
  @spec assess_system_state(map()) :: heartbeat_state()
  def assess_system_state(context) do
    cond do
      has_verified_health?(context) and has_pending_experiments?(context) -> :awaiting_experiment
      has_verified_health?(context) -> :healthy
      has_verified_degradation?(context) -> :degraded
      simulation_only?(context) -> :simulation_only
      true -> :unknown
    end
  end

  defp has_verified_health?(context) do
    case Map.get(context, :service_health) || Map.get(context, "service_health") do
      health when is_map(health) and map_size(health) > 0 ->
        Enum.all?(Map.values(health), &(&1 in [:healthy, :operational, true]))
      _ -> false
    end
  end

  defp has_verified_degradation?(context) do
    case Map.get(context, :service_health) || Map.get(context, "service_health") do
      health when is_map(health) and map_size(health) > 0 ->
        Enum.any?(Map.values(health), &(&1 in [:degraded, :failed, :unavailable, false]))
      _ -> false
    end
  end

  defp has_pending_experiments?(context) do
    case Map.get(context, :pending_experiments) || Map.get(context, "pending_experiments") do
      value when is_integer(value) -> value > 0
      value when is_list(value) -> value != []
      _ -> false
    end
  end

  defp simulation_only?(context) do
    Map.get(context, :execution_mode) in [:simulation, :simulated] or
      Map.get(context, "execution_mode") in ["simulation", "simulated"]
  end

  defp collect_observational_metrics(context) do
    Map.take(context, [:service_health, :pending_experiments, :execution_mode, :queue_depth, :last_execution])
  end
end
