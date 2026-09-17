defmodule Tiannara.Sentinel.Supervisor do
  @moduledoc """
  The standalone top-level supervisor for Tiannara Sentinel.
  """
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      Tiannara.Sentinel.TelemetryHub,
      Tiannara.Sentinel.EventClassifier,
      Tiannara.Sentinel.AnomalyDetector,
      Tiannara.Sentinel.AlertRouter,
      Tiannara.Sentinel.MonitorSupervisor,
      Tiannara.Sentinel.ForecastSupervisor,
      Tiannara.Sentinel.BaselineSupervisor,
      Tiannara.Sentinel.ImmuneSupervisor,
      Tiannara.Sentinel.Observatories.EpistemicDiversityTracker,
      Tiannara.Sentinel.Validation.ValidationState,
      Tiannara.Sentinel.Observatories.Supervisor,
      Tiannara.Sentinel.ShadowSupervisor
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
