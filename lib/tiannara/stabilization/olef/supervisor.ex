defmodule Tiannara.Stabilization.OLEF.Supervisor do
  @moduledoc """
  OLEF (Ontological Load Entropy Field) supervisor.

  Coordinates the entropy field system and load balancing.
  """

  use Supervisor
  require Logger

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      # Main OLEF field manager
      {Tiannara.Stabilization.OLEF, []},
      
      # Pressure field cache
      {Tiannara.Stabilization.OLEF.Cache, []},
      
      # Entropy distribution tracker
      {Tiannara.Stabilization.OLEF.EntropyTracker, []},
      
      # Load harmonics controller
      {Tiannara.Stabilization.OLEF.Harmonics, []}
    ]

    Logger.info("Initializing OLEF supervisor")

    Supervisor.init(children, strategy: :one_for_all, max_restarts: 5, max_seconds: 10)
  end
end