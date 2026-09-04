defmodule Tiannara.REA.Supervisor do
  @moduledoc """
  Supervisor for the Research Evolution Architecture (REA).

  Starts all REA processes: registries, causal engines, epistemic
  memory, topology, and observability.
  """

  use Supervisor
  require Logger

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      # Causal infrastructure
      Tiannara.REA.Causal.CausalConstitution,
      Tiannara.REA.Causal.ChannelMonitor,
      Tiannara.REA.Causal.Graph,

      # Registries
      Tiannara.REA.LineageRegistry,
      Tiannara.REA.ArchaeologyRegistry,
      Tiannara.REA.Topo.ReplacementRegistry,

      # Epistemic memory and ecology
      Tiannara.REA.Epistemic.CivilizationMemory,
      Tiannara.REA.Epistemic.GoalRegistry,
      Tiannara.REA.Epistemic.ImmuneMemoryEcology,
      Tiannara.REA.Epistemic.InstitutionRegistry,

      # Observability and runtime atlas
      Tiannara.REA.Observability.ContinuityTracker,
      Tiannara.REA.Observatory.RuntimeAtlas
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
