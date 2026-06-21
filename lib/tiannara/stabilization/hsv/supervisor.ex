defmodule Tiannara.Stabilization.HSV.Supervisor do
  @moduledoc """
  HSV (Holographic Singularity Vent) supervisor.

  Coordinates singularity detection, event horizon spawning, and archival systems.
  """

  use Supervisor
  require Logger

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      # Main HSV system
      {Tiannara.Stabilization.HSV, []},
      
      # Singularity detector
      {Tiannara.Stabilization.HSV.Detector, []},
      
      # Event horizon manager
      {Tiannara.Stabilization.HSV.EventHorizon, []},
      
      # Cold storage controller
      {Tiannara.Stabilization.HSV.ColdStorage, []},
      
      # Archive manager
      {Tiannara.Stabilization.HSV.ArchiveManager, []}
    ]

    Logger.info("Initializing HSV supervisor")

    Supervisor.init(children, strategy: :one_for_all, max_restarts: 3, max_seconds: 5)
  end
end