defmodule Tiannara.Topology.Supervisor do
  @moduledoc """
  Topology and manifold supervisor.

  Manages topological folding and persistent homology systems.
  """

  use Supervisor
  require Logger

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      # ACF - Axiomatic Conservation Framework
      {Tiannara.Topology.ACF.Supervisor, []},

      # CCR - Cosmological Compiler Reflection
      {Tiannara.Topology.CCR.Supervisor, []},

      # DFG - Dimensional Folding Geometry
      {Tiannara.Topology.DFG.Supervisor, []},

      # OSL - Ontological Sandbox Layer
      {Tiannara.Topology.OSL.Supervisor, []},

      # RRG - Recursive Resonance Governance
      {Tiannara.Topology.RRG.Supervisor, []}
    ]

    Logger.info("Initializing topology supervisor")

    Supervisor.init(children, strategy: :one_for_one, max_restarts: 8, max_seconds: 30)
  end
end
