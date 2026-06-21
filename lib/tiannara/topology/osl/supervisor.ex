defmodule Tiannara.Topology.OSL.Supervisor do
  @moduledoc """
  OSL (Ontological Sandbox Layer) supervisor.

  Coordinates sandbox management, isolation mechanisms, and controlled experimentation.
  """

  use Supervisor
  require Logger

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      # Main OSL system
      {Tiannara.Topology.OSL, []},
      
      # Sandbox manager
      {Tiannara.Topology.OSL.SandboxManager, []},
      
      # Operation executor
      {Tiannara.Topology.OSL.OperationExecutor, []},
      
      # Change isolator
      {Tiannara.Topology.OSL.ChangeIsolator, []},
      
      # Sandbox validator
      {Tiannara.Topology.OSL.SandboxValidator, []}
    ]

    Logger.info("Initializing OSL supervisor")

    Supervisor.init(children, strategy: :one_for_all, max_restarts: 5, max_seconds: 10)
  end
end