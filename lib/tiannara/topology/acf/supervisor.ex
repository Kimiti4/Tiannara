defmodule Tiannara.Topology.ACF.Supervisor do
  @moduledoc """
  ACF (Axiomatic Conservation Framework) supervisor.

  Coordinates conservation law enforcement, axiomatic integrity management, and conservation frameworks.
  """

  use Supervisor
  require Logger

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      # Main ACF system
      {Tiannara.Topology.ACF, []},
      
      # Conservation law manager
      {Tiannara.Topology.ACF.LawManager, []},
      
      # Integrity enforcer
      {Tiannara.Topology.ACF.IntegrityEnforcer, []},
      
      # Violation detector
      {Tiannara.Topology.ACF.ViolationDetector, []},
      
      # Repair system
      {Tiannara.Topology.ACF.RepairSystem, []}
    ]

    Logger.info("Initializing ACF supervisor")

    Supervisor.init(children, strategy: :one_for_all, max_restarts: 5, max_seconds: 10)
  end
end