defmodule Tiannara.Meta.Supervisor do
  @moduledoc """
  Meta-Evolution Supervisor - Orchestrates all Phase 5D systems.
  
  Coordinates the main Meta-Evolution processes and resources under a single
  supervision tree.
  """

  use Supervisor
  require Logger

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    Logger.info("🧬 Tiannara.Meta.Supervisor starting (Phase 5D orchestrator)")

    children = [
      # Law Archive - Thermodynamic memory repository
      {Tiannara.Meta.Memory.LawArchive, []},
      
      # Causal Graph - Mutable ontology engine
      {Tiannara.Causality.Graph, []},
      
      # Time Reverse Debugger - Entropy inversion
      {Tiannara.Debug.TimeReverse, []},
      
      # Lineage Tracker - Physics law evolution history
      {Tiannara.Physics.LineageTracker, []},
      
      # NATS Stream Manager - Meta-evolution event routing
      {Tiannara.NATS.MetaEvolutionStreamManager, []},

      # ── Phase 5F: Observer-Relative Ontological Compiler ──────────────────

      # MCK: Meta-Causal Compilation Kernel (replaces GCK)
      {TiannaraRuntime.MCK, []},

      # Mnesia DCG Topology Engine: CTN registry + elastic edge store
      {Tiannara.Meta.CausalDataLayer, []},

      # NATS consumer: routes loop_bound events into CausalDataLayer
      {Tiannara.Meta.CausalPipelineConsumer, []},

      # Paradox Battery: harvests CTN oscillatory friction for tau depression
      {Tiannara.Meta.ParadoxPowerGrid, []},

      # Subsidy Distributor: broadcasts redistributed global_tau back to GPU
      {Tiannara.Meta.ParadoxPowerGrid.Distributor, []},

      # ── Phase 5F.1: Meta-Stability Constraint Layer (MSCL) ────────────────
      # Must start before OCG — OCG.hydrate_msf/1 calls MSCL.get_msf/1
      {Tiannara.Meta.MSCL, []},

      # ── Phase 5F.2: Observer Collapse Governor (OCG) + Arbitration Layer (OCAL) ──

      # OCAL must start before OCG — OCG calls OCAL.resolve/5
      {Tiannara.Meta.ObserverArbitrationLayer, []},

      # OCG: continuous arbitration cycle over competing observer manifolds
      {Tiannara.Meta.ObserverCollapseGovernor, []},

      # ── Phase 5F.3: Observer Memory Reconciliation Layer (OMRL) ───────────
      # Must start after OCG/OCAL — OMRL hydrates OSS from OCG
      {Tiannara.Meta.ObserverMemoryReconciliation, []},

      # Periodic meta-evolution task scheduler (GenServer)
      {Tiannara.Meta.PeriodicScheduler, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
