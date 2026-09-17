defmodule TiannaraRuntime.CrossDimensional.Supervisor do
  @moduledoc """
  Phase 5F.12 — Cross-Dimensional Compiler Supervisor

  Supervises the bridge that translates OPC physics rules into DFG latent
  meta-ops while enforcing causal and topological safety.
  """

  use Supervisor
  require Logger

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    Logger.info("🔗 [CrossDimensional] Compiler bridge supervisor starting")

    children = [
      {TiannaraRuntime.CrossDimensional.Compiler, []},
      {TiannaraRuntime.CrossDimensional.BoundaryValidator, []},
      {TiannaraRuntime.CrossDimensional.MetaOpBytecode, []},
      {TiannaraRuntime.CrossDimensional.PortalProtocol, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
