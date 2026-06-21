defmodule Tiannara.Stabilization.OCM.Supervisor do
  @moduledoc """
  OCM (Ontological Consensus Mesh) supervisor.

  Coordinates consensus management, voting systems, and reconciliation processes.
  """

  use Supervisor
  require Logger

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      # Main OCM system
      {Tiannara.Stabilization.OCM, []},
      
      # Consensus manager
      {Tiannara.Stabilization.OCM.ConsensusManager, []},
      
      # Voting system
      {Tiannara.Stabilization.OCM.VotingSystem, []},
      
      # Reconciliation engine
      {Tiannara.Stabilization.OCM.ReconciliationEngine, []},
      
      # Conflict resolver
      {Tiannara.Stabilization.OCM.ConflictResolver, []}
    ]

    Logger.info("Initializing OCM supervisor")

    Supervisor.init(children, strategy: :one_for_all, max_restarts: 5, max_seconds: 10)
  end
end