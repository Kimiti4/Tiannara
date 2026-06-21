defmodule Tiannara.Physics.OPC.Supervisor do
  @moduledoc """
  OPC (Observer Physics Compiler) supervisor.

  Coordinates observer physics compilation, deterministic stability management, and observer-effect systems.
  """

  use Supervisor
  require Logger

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      # Main OPC system
      {Tiannara.Physics.OPC, []},
      
      # Observer manager
      {Tiannara.Physics.OPC.ObserverManager, []},
      
      # Physics compiler
      {Tiannara.Physics.OPC.PhysicsCompiler, []},
      
      # Determinism validator
      {Tiannara.Physics.OPC.DeterminismValidator, []},
      
      # Stability monitor
      {Tiannara.Physics.OPC.StabilityMonitor, []}
    ]

    Logger.info("Initializing OPC supervisor")

    Supervisor.init(children, strategy: :one_for_all, max_restarts: 5, max_seconds: 10)
  end
end