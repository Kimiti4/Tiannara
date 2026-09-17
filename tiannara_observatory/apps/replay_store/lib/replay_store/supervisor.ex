defmodule ReplayStore.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    children = [
      ReplayStore.Snapshot,
      ReplayStore.SnapshotManager,
      ReplayStore.Timeline,
      ReplayStore.TimelineIndex,
      ReplayStore.Replay,
      ReplayStore.ReplayEngine,
      ReplayStore.StateReconstruction,
      ReplayStore.CausalLineage,
      ReplayStore.ArchaeologyEngine,
      ReplayStore.DivergenceDetector,
      ReplayStore.ReplayCache,
      ReplayStore.Lineage
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
