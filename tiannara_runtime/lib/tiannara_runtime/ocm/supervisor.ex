defmodule TiannaraRuntime.OCM.Supervisor do
  @moduledoc """
  Phase 5F.7 — Ontological Consensus Mesh (OCM) Supervisor

  Boots the ontology registry and consensus engine responsible for
  semantic drift analysis and controlled convergence.
  """

  use Supervisor
  require Logger

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    Logger.info("🕸️ [OCM] Ontological Consensus Mesh supervisor starting")

    children = [
      {TiannaraRuntime.OCM.Registry, []},
      {TiannaraRuntime.OCM.ConsensusEngine, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
