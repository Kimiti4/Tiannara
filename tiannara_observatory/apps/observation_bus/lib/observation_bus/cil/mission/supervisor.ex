defmodule ObservationBus.CIL.Mission.Supervisor do
  @moduledoc """
  Supervisor for the Constitutional Scientific Mission Control (CSMC) — M13.
  """
  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      ObservationBus.CIL.Mission.MissionRegistry,
      ObservationBus.CIL.Mission.MissionScheduler,
      ObservationBus.CIL.Mission.MissionCoordinator,
      ObservationBus.CIL.Mission.MissionTimeline,
      ObservationBus.CIL.Mission.MissionReplay,
      ObservationBus.CIL.Mission.MissionHealth,
      ObservationBus.CIL.Mission.MissionCertification,
      ObservationBus.CIL.Mission.MissionPortfolio,
      ObservationBus.CIL.Mission.MissionAnalytics,
      ObservationBus.CIL.Mission.CampaignTracker
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end
end
