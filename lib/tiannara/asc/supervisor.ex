defmodule Tiannara.ASC.Supervisor do
  @moduledoc """
  Root supervisor for the Autonomous Software Civilization (ASC).

  Strategy: `:rest_for_one` — if a downstream supervisor crashes,
  everything started after it in the list is restarted, but
  processes started before it (CivilizationKernel, KnowledgeArchive)
  remain alive and hold their state.

  Gated behind `config :tiannara, :asc, enabled: true`. When the flag
  is false this module is never started, so it has zero impact on the
  running REA simulation.
  """

  use Supervisor
  require Logger

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    Logger.info("[ASC] Autonomous Software Civilization supervisor starting")

    children = [
      # Core state store — must come first
      Tiannara.ASC.CivilizationKernel,

      # Layer 1 — Persistence
      Tiannara.ASC.KnowledgeArchive,
      Tiannara.ASC.Crucible.RepairLibrary,

      # Layer 2 — Evolution Infrastructure
      Tiannara.ASC.Crucible.TransferEcology,
      Tiannara.ASC.Crucible.AdaptationVelocity,
      Tiannara.ASC.Crucible.RepairReuseEngine,

      # Layer 3 — Scientific Instrumentation
      Tiannara.ASC.Crucible.Observatory,

      # Research integration — reads Research.Director, bridges Domain Registry
      Tiannara.ASC.ResearchBridge,

      # PubSub subscriber — forwards domain discoveries into ASC context
      Tiannara.ASC.DomainObserver,

      # Software Engineering Laws registry
      Tiannara.ASC.Laws.Registry,

      # Pipeline — spawns one worker GenServer per active project
      Tiannara.ASC.Pipeline.Supervisor,

      # Sub-civilization DynamicSupervisor — started on demand
      Tiannara.ASC.SubCiv.Supervisor,

      # Phase 6 & 8: Research Registry for tracking methodologies
      Tiannara.ASC.Research.ResearchRegistry,

      # Phase Ω.3 — Civilizational Systems
      {Tiannara.ASC.CivilizationManager, name: :asc_civilization_manager},
      {Tiannara.ASC.KnowledgeEconomy, name: :asc_knowledge_economy},
      {Tiannara.ASC.CapabilityEvolution, name: :asc_capability_evolution},
      {Tiannara.ASC.InstitutionEngine, name: :asc_institution_engine},
      {Tiannara.ASC.ResourceAllocator, name: :asc_resource_allocator},
      {Tiannara.ASC.ResearchPlanner, name: :asc_research_planner},
      {Tiannara.ASC.CivilizationMemory, name: :asc_civilization_memory},
      {Tiannara.ASC.CivilizationMetrics, name: :asc_civilization_metrics},
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
