defmodule Tiannara.PhaseOmega.WiringEngine do
  alias Tiannara.PhaseOmega.SubsystemRegistry
  @moduledoc """
  Ω.4 — Runtime Wiring Engine.

  Defines every dark subsystem with its supervisor, dependencies, children,
  and health probes, then registers them with the BootSequencer.

  The wiring engine maintains the authoritative dependency graph:

    Core → Stabilization → Physics → Topology → Sentinel
      ↓        ↓
      REA ─────┤
      SOPL ────┤
      UCC ─────┤
      CIS ─────┤
      MSG ─────┤
      OED ─────┤
      CTL ─────┤
      OMCE ────┘
  """

  require Logger

  @doc """
  Define all dark subsystems and register them with the BootSequencer.
  Returns the count of subsystems defined.
  """
  def wire_all do
    Logger.info("[PhaseΩ:Wiring] Defining dark subsystem specifications...")
    register_runtime_already_running()

    dark = subsystem_specs()
    Enum.each(dark, &Tiannara.PhaseOmega.BootSequencer.define_subsystem/1)

    Logger.info("[PhaseΩ:Wiring] Defined #{length(dark)} dark subsystems")
    :ok
  end

  @doc """
  Return defined specs as a list of maps (for reporting).
  """
  def defined_specs do
    subsystem_specs()
  end

  @doc """
  Return the complete list of dark subsystem specs.
  """
  def subsystem_specs do
    [
      rea_spec(),
      p9x_spec(),
      cis_spec(),
      a10_spec(),
      ucc_spec(),
      msg_spec(),
      oed_spec(),
      omce_spec(),
      sopl_spec()
    ]
  end

  # --------------------------------------------------------------------------
  # Subsystem specs
  # --------------------------------------------------------------------------

  defp rea_spec do
    %{
      name: :rea,
      module: Tiannara.REA,
      supervisor: Tiannara.REA.Supervisor,
      deps: [:core, :stabilization, :sentinel, :rel],
      children: [
        Tiannara.REA.Causal.CausalConstitution,
        Tiannara.REA.Causal.ChannelMonitor,
        Tiannara.REA.Causal.Graph,
        Tiannara.REA.LineageRegistry,
        Tiannara.REA.ArchaeologyRegistry,
        Tiannara.REA.Topo.ReplacementRegistry,
        Tiannara.REA.Epistemic.CivilizationMemory,
        Tiannara.REA.Epistemic.GoalRegistry,
        Tiannara.REA.Epistemic.ImmuneMemoryEcology,
        Tiannara.REA.Epistemic.InstitutionRegistry,
        Tiannara.REA.Observability.ContinuityTracker,
        Tiannara.REA.Observatory.RuntimeAtlas
      ],
      health_probe: {__MODULE__, :rea_healthy?, []},
      description: "Research Evolution Architecture"
    }
  end

  defp p9x_spec do
    %{
      name: :p9x_ecosystem,
      module: Tiannara.P9XEcosystem.Supervisor,
      supervisor: Tiannara.P9XEcosystem.Supervisor,
      deps: [:core, :stabilization, :rea],
      children: [Tiannara.P9X.Supervisor],
      health_probe: {__MODULE__, :p9x_healthy?, []},
      description: "P9X Ecological Governance"
    }
  end

  defp cis_spec do
    %{
      name: :cis,
      module: Tiannara.CIS.Supervisor,
      supervisor: Tiannara.CIS.Supervisor,
      deps: [:sentinel, :core],
      children: [
        Tiannara.CIS.CISRegistry,
        Tiannara.CIS.CollapsePredictor,
        Tiannara.CIS.ImmuneDecisionEngine,
        Tiannara.CIS.RegulationExecutor
      ],
      health_probe: {__MODULE__, :cis_healthy?, []},
      description: "Cognitive Immune System — collapse prediction, immune response, regulation"
    }
  end

  defp a10_spec do
    %{
      name: :a10,
      module: Tiannara.A10.Supervisor,
      supervisor: Tiannara.A10.Supervisor,
      deps: [:p9x_ecosystem],
      children: [
        Tiannara.A10.AttractorMemory,
        Tiannara.A10.DriftTensor,
        Tiannara.A10.AttractorAnalyzer,
        Tiannara.A10.Sampler,
        Tiannara.A10.AdvisoryEmitter
      ],
      health_probe: {__MODULE__, :a10_healthy?, []},
      description: "Attractor Dynamics — attractor memory, drift tensor, analysis, sampling"
    }
  end

  defp ucc_spec do
    %{
      name: :ucc,
      module: Tiannara.UCC.UCCSupervisor,
      supervisor: Tiannara.UCC.UCCSupervisor,
      deps: [:core, :physics],
      children: [
        Tiannara.UCC.MacroStateRegistry,
        Tiannara.UCC.ConstitutionAttractorRegistry
      ],
      health_probe: {__MODULE__, :ucc_healthy?, []},
      description: "Universal Causal Compiler — macro state and constitution attractor registries"
    }
  end

  defp msg_spec do
    %{
      name: :msg,
      module: Tiannara.MSG.Supervisor,
      supervisor: Tiannara.MSG.Supervisor,
      deps: [:core, :stabilization],
      children: [],
      health_probe: {__MODULE__, :msg_healthy?, []},
      description: "Meta-Stability Governor — prevents overregulation"
    }
  end

  defp omce_spec do
    %{
      name: :omce,
      module: Tiannara.OMCE.Supervisor,
      supervisor: Tiannara.OMCE.Supervisor,
      deps: [:core, :omcs],
      children: [
        Tiannara.OMCE.MemoryContinuity,
        Tiannara.OMCE.ContinuityIndex
      ],
      health_probe: {__MODULE__, :omce_healthy?, []},
      description: "Ontological Memory Continuity Extension — extended memory and continuity services"
    }
  end

  defp sopl_spec do
    %{
      name: :sopl,
      module: Tiannara.SOPL.Supervisor,
      supervisor: Tiannara.SOPL.Supervisor,
      deps: [:core, :stabilization],
      children: [
        Tiannara.SOPL.LawAttractorRegistry,
        Tiannara.SOPL.LawArchaeology,
        Tiannara.SOPL.LawUnknownRegistry
      ],
      health_probe: {__MODULE__, :sopl_healthy?, []},
      description: "Self-Organizing Principle Layer — law evolution, archetype discovery"
    }
  end

  defp oed_spec do
    %{
      name: :oed,
      module: Tiannara.OED.Supervisor,
      supervisor: Tiannara.OED.Supervisor,
      deps: [:core, :sentinel, :rea],
      children: [
        Tiannara.OED.BudgetController,
        Tiannara.OED.Quarantine.ContradictionTracker,
        Tiannara.OED.Quarantine.SuspendedTheories,
        Tiannara.OED.Quarantine.QuarantineRegistry,
        Tiannara.OED.Rollback.OntologySnapshots,
        Tiannara.OED.Rollback.RollbackController,
        Tiannara.OED.UMSC.StabilityController,
        Tiannara.OED.ACM.CrucibleSupervisor,
        Tiannara.OED.OAVL.ValidationSupervisor
      ],
      health_probe: {__MODULE__, :oed_healthy?, []},
      description: "Ontological Evolution & Defense — quarantine, rollback, ACM crucible"
    }
  end

  # --------------------------------------------------------------------------
  # Health probes
  # --------------------------------------------------------------------------

  def rea_healthy? do
    all_alive?([
      Tiannara.REA.Causal.CausalConstitution,
      Tiannara.REA.Causal.ChannelMonitor,
      Tiannara.REA.Causal.Graph,
      Tiannara.REA.LineageRegistry,
      Tiannara.REA.ArchaeologyRegistry,
      Tiannara.REA.Topo.ReplacementRegistry,
      Tiannara.REA.Epistemic.CivilizationMemory,
      Tiannara.REA.Epistemic.GoalRegistry,
      Tiannara.REA.Epistemic.ImmuneMemoryEcology,
      Tiannara.REA.Epistemic.InstitutionRegistry,
      Tiannara.REA.Observability.ContinuityTracker,
      Tiannara.REA.Observatory.RuntimeAtlas
    ])
  end

  def p9x_healthy? do
    all_alive?([
      Tiannara.P9XEcosystem.Supervisor,
      Tiannara.P9X.Supervisor
    ])
  end

  def cis_healthy? do
    all_alive?([
      Tiannara.CIS.Supervisor,
      Tiannara.CIS.CollapsePredictor,
      Tiannara.CIS.ImmuneDecisionEngine,
      Tiannara.CIS.RegulationExecutor
    ])
  end

  def omce_healthy? do
    all_alive?([
      Tiannara.OMCE.Supervisor,
      Tiannara.OMCE.MemoryContinuity,
      Tiannara.OMCE.ContinuityIndex
    ])
  end

  def sopl_healthy? do
    all_alive?([
      Tiannara.SOPL.Supervisor,
      Tiannara.SOPL.LawAttractorRegistry,
      Tiannara.SOPL.LawArchaeology,
      Tiannara.SOPL.LawUnknownRegistry
    ])
  end

  def a10_healthy? do
    all_alive?([
      Tiannara.A10.Supervisor,
      Tiannara.A10.AttractorMemory,
      Tiannara.A10.DriftTensor,
      Tiannara.A10.AttractorAnalyzer,
      Tiannara.A10.Sampler,
      Tiannara.A10.AdvisoryEmitter
    ])
  end

  def ucc_healthy? do
    all_alive?([
      Tiannara.UCC.UCCSupervisor,
      Tiannara.UCC.MacroStateRegistry,
      Tiannara.UCC.ConstitutionAttractorRegistry
    ])
  end

  def msg_healthy? do
    pid = Process.whereis(Tiannara.MSG.Supervisor)
    pid != nil && Process.alive?(pid)
  end

  def oed_healthy? do
    all_alive?([
      Tiannara.OED.Supervisor,
      Tiannara.OED.BudgetController,
      Tiannara.OED.Quarantine.QuarantineRegistry,
      Tiannara.OED.Rollback.RollbackController,
      Tiannara.OED.ACM.CrucibleSupervisor,
      Tiannara.OED.OAVL.ValidationSupervisor
    ])
  end

  # --------------------------------------------------------------------------
  # Internal helpers
  # --------------------------------------------------------------------------

  defp register_runtime_already_running do
    already_running = [
      %{name: :grcc, module: Tiannara.GRCC.StateGeneratorSupervisor, deps: [:core], description: "Genetic Recursive Causal Core — state generation"},
      %{name: :world_model, module: Tiannara.Core.WorldModel.Supervisor, deps: [:core, :ros], description: "World Model — entity registry, belief system, causal engine"},
      %{name: :ctl, module: Tiannara.Stabilization.CTL, deps: [:core, :physics], description: "Causal Tensor Lattice — causal consistency, branch reconciliation"}
    ]

    Enum.each(already_running, fn spec ->
      SubsystemRegistry.register(spec.name, %{
        module: spec.module,
        deps: spec.deps,
        description: spec.description,
        app: :tiannara
      })
      SubsystemRegistry.transition(spec.name, :healthy)
    end)
  end

  defp all_alive?(modules) do
    alive = Enum.all?(modules, fn mod ->
      pid = Process.whereis(mod)
      pid != nil && Process.alive?(pid)
    end)

    if alive, do: :ok, else: {:error, "some children not alive"}
  end
end
