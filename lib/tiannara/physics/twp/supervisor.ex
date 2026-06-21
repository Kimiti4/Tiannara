defmodule Tiannara.Physics.TWP.Supervisor do
  @moduledoc """
  TWP (Temporal Wavefunction Pruning) supervisor.

  Coordinates temporal state management, pruning algorithms, and temporal coherence maintenance.
  """

  use Supervisor
  require Logger

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      # Main TWP system
      {Tiannara.Physics.TWP, []},
      
      # Temporal coherence manager
      {Tiannara.Physics.TWP.CoherenceManager, []},
      
      # State pruning engine
      {Tiannara.Physics.TWP.PruningEngine, []},
      
      # Temporal validator
      {Tiannara.Physics.TWP.TemporalValidator, []},
      
      # Wavefunction collapse handler
      {Tiannara.Physics.TWP.CollapseHandler, []}
    ]

    Logger.info("Initializing TWP supervisor")

    Supervisor.init(children, strategy: :one_for_all, max_restarts: 5, max_seconds: 10)
  end
end