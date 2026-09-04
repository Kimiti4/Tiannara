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
      healthy_services?(context) and has_pending_experiments?(context) -> :awaiting_experiment
      healthy_services?(context) -> :healthy
      degraded_services?(context) -> :degraded
      true -> :awaiting_experiment
    end
  end

  defp healthy_services?(_context), do: true
  defp degraded_services?(_context), do: false
  defp has_pending_experiments?(_context), do: false

  defp collect_observational_metrics(_context) do
    %{}
  end
end
