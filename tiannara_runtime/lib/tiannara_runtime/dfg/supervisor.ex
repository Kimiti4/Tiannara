defmodule TiannaraRuntime.DFG.Supervisor do
  @moduledoc """
  Phase 5F.12 — Dimensional Folding Genesis (DFG) Supervisor

  Supervises the DFG pipeline that folds stable world slices into latent
  manifolds while preserving causal topology.
  """

  use Supervisor
  require Logger

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    Logger.info("🌀 [DFG] Dimensional Folding Genesis supervisor starting")

    children = [
      {TiannaraRuntime.DFG.PlateauDetector, []},
      {TiannaraRuntime.DFG.TopologicalFold, []},
      {TiannaraRuntime.DFG.MetaRealitySpawner, []},
      {TiannaraRuntime.DFG.PortalRenderer, []},
      {TiannaraRuntime.DFG.LatentRuntime, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
