defmodule Tiannara.Topology.DFG.Supervisor do
  @moduledoc """
  DFG (Dimensional Folding Genesis) supervisor.

  Coordinates dimensional folding, persistent homology computation, and dimensional genesis mechanisms.
  """

  use Supervisor
  require Logger

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      # Main DFG system
      {Tiannara.Topology.DFG, []},
      
      # Dimensional folder
      {Tiannara.Topology.DFG.Folder, []},
      
      # Homology computer
      {Tiannara.Topology.DFG.HomologyComputer, []},
      
      # Transformation engine
      {Tiannara.Topology.DFG.TransformationEngine, []},
      
      # Integrity validator
      {Tiannara.Topology.DFG.IntegrityValidator, []}
    ]

    Logger.info("Initializing DFG supervisor")

    Supervisor.init(children, strategy: :one_for_all, max_restarts: 5, max_seconds: 10)
  end
end