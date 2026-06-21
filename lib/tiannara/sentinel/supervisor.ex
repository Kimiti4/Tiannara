defmodule Tiannara.Sentinel.Supervisor do
  @moduledoc """
  Supervisor for the Tiannara Sentinel ecosystem.
  """
  use Supervisor
  require Logger

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      Tiannara.Sentinel.TelemetryHub,
      Tiannara.Sentinel.AnomalyDetector,
      Tiannara.Sentinel.ImmuneCoordinator,
      
      # Other Sentinel components (if needed)
      Tiannara.Sentinel.EpistemologyArchive,
      Tiannara.Sentinel.EpistemologyAtlas,
      Tiannara.Sentinel.DiscoveryGenealogy,
      Tiannara.Sentinel.EpistemicArchaeology,
      Tiannara.Sentinel.DiseaseGenealogy
    ]

    Logger.info("🛡️ [SENTINEL] Initializing Sentinel supervisor.")

    Supervisor.init(children, strategy: :one_for_all)
  end
end
