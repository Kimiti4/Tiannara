defmodule Tiannara.Application do
  @moduledoc """
  Main Tiannara application supervisor.

  Coordinates all the core subsystems:
  - Core ontology management
  - Stabilization layers
  - Physics compilation
  - Metrics and monitoring
  """

  use Application
  require Logger

  def start(_type, _args) do
    children =
      core_children() ++
        loop_children() ++
        asc_children(asc_enabled?())

    Logger.info(
      "Tiannara boot: asc_enabled=#{asc_enabled?()}, #{length(children)} top-level children"
    )

    opts = [strategy: :one_for_one, name: Tiannara.Application]

    case Supervisor.start_link(children, opts) do
      {:ok, pid} ->
        Logger.info("Tiannara started successfully")

        # Register subsystems for PhaseΩ runtime verification
        register_subsystems()

        # Boot the CEL Executive Kernel
        # Test mode: synchronous — ensures services available before tests run
        # Production: non-blocking — services start under DynamicSupervisor
        boot_fn = fn ->
          case Tiannara.CEL.Kernel.boot() do
            {:ok, report} ->
              Logger.warning(
                "[CEL] EOS boot complete. Status: #{report.status} (#{report.duration_ms}ms)"
              )

              Enum.each(report.services, fn {id, result} ->
                Logger.warning("  service #{id}: #{result}")
              end)

            {:error, reason} ->
              Logger.error("[CEL] EOS boot failed: #{inspect(reason)}")
          end
        end

        if Application.get_env(:tiannara, :test_mode, false) or Mix.env() == :test do
          boot_fn.()
        else
          Task.start(boot_fn)
        end

        {:ok, pid}

      {:error, reason} ->
        Logger.error("Failed to start Tiannara: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc "Whether the ASC subsystem (Phases 6–10) is enabled."
  def asc_enabled? do
    Application.get_env(:tiannara, :asc, []) |> Keyword.get(:enabled, false)
  end

  # Foundation, World layer, Phase 4, Phase 5 control — always on.
  defp core_children do
    [
      # Tier 0: Constitutional Runtime — must boot first
      Tiannara.Council.Supervisor,

      # Tier 1: Service Registry — used by Kernel during boot
      Tiannara.CEL.Kernel.ServiceRegistry,

      # Tier 2: Executive Kernel — Runtime Orchestrator
      Tiannara.CEL.Kernel,

      # Storage lifecycle — DETS size-bound rotation + retention (stores
      # register with it at boot; must start before CEL services)
      Tiannara.Storage.DetsLifecycle,

      # Telemetry and monitoring
      Tiannara.Telemetry,

      # Discovery pipeline audit (instrument-first build — Stage 1)
      Tiannara.Discovery.PipelineTelemetry,

      # Phase Ω — Runtime Constitutional Activation
      Tiannara.PhaseOmega.SubsystemRegistry,
      Tiannara.PhaseOmega.BootSequencer,
      Tiannara.PhaseOmega.RuntimeVerifier,

      # Observatory Validation Campaign Infrastructure
      {Registry, keys: :unique, name: Tiannara.Observatory.ValidationRegistry},
      Tiannara.Observatory.ValidationSupervisor,

      # Civilization Kernel (Top-level State Substrate)
      Supervisor.child_spec({TiannaraOS.CivilizationKernel, [:tiannara_civilization, %{}]},
        id: :civilization_kernel
      ),

      # LEOC LatentVault
      Tiannara.LEOC.LatentVault,

      # ROS Dynamic Shard Architecture (Must start before Core since Reality Ontological Shards (ROS)
      Tiannara.ROS.Registry,
      Tiannara.ROS.ShardSupervisor,
      Tiannara.ROS.ShardManager,
      Tiannara.ROS.EvolutionEngine,

      # Reality Economics Layer (REL)
      Tiannara.REL.EconomyEngine,
      Tiannara.REL.DiscoveryLedger,
      Tiannara.REL.ProductionEngine,

      # Ontological Memory Continuity System
      Tiannara.OMCS.Supervisor,

      # Core subsystem supervisors
      Tiannara.Core.Supervisor,
      Tiannara.Stabilization.Supervisor,
      Tiannara.Physics.Supervisor,
      Tiannara.Topology.Supervisor,

      # AC-001-B: Canonical domain identity registry (frozen 20-domain ontology)
      Tiannara.Domains.CanonicalRegistry,

      # Sentinel Unified Ecosystem
      Tiannara.Sentinel.Supervisor,

      # Cognitive Immune System — F11 residency (AE-007)
      Tiannara.CIS.Supervisor,

      # Sentinel D.2 (The Science of Science)
      Tiannara.Sentinel.D2.EpistemologyGraph,
      Tiannara.Sentinel.D2.OperatorGenealogy,
      Tiannara.Sentinel.D2.TruthRetentionMatrix,
      Tiannara.Sentinel.D2.BreakthroughAnalyzer,
      Tiannara.Sentinel.D2.FailedMetaArchive,

      # The dedicated Task Supervisor for parallel multiverse queries
      {Task.Supervisor, name: Tiannara.ExtrusionTaskSupervisor},

      # The Jarvis Command Loom
      Tiannara.AAL.CommandLoom,

      # ==========================================
      # Phase 6F.4 Event Horizon Tensor Cores
      # ==========================================
      Tiannara.Meta.Hardware.Supervisor,

      # Phoenix PubSub and Endpoint for the Interactive REA Research Workbench
      {Phoenix.PubSub, name: Tiannara.PubSub},
      TiannaraWeb.Endpoint,

      # Phase 5: Control Center + Autonomous Operations
      Tiannara.Operations.OperationsSupervisor,

      # Research Domains Framework
      Tiannara.Domains.ResearchDirector,

      # Agency Foundation — epistemic loop
      Tiannara.ASC.Agency.Sentinel,

      # Executive Memory — DETS-backed persistent knowledge store
      Tiannara.Executive.Supervisor,

      # Sentinel Runtime (Artifact 12) — continuous autonomous monitoring
      Tiannara.Sentinel.SentinelRuntime,

      # Research Director (Artifact 13) — autonomous scientific investigation
      Tiannara.Research.ResearchDirector,

      # Executive Cognitive Runtime (ECR) — Ω agency loop substrate
      Tiannara.Executive.Cognitive.ExecutiveCognitiveRuntime,

      # Cognitive Interface (Ω.3) — proactive scientific dialogue with operators
      Tiannara.Interface.CognitiveInterface,

      # Constitutional Autonomy (Ω.4) — safe self-improvement under constitutional governance
      Tiannara.Autonomy.ConstitutionalAutonomy,

      # Omega Integration (Artifact 16) — AgencyLoop, HealthAggregator, ComplianceMonitor, Observatory
      Tiannara.Omega.OmegaRuntime
    ]
  end

  # Autonomous-loop plumbing — ALWAYS on, independent of the ASC flag.
  # The loop must remain intact even when ASC executors are disabled.
  def loop_children do
    [
      {Tiannara.Operations.CampaignIntegration, []},
      {Tiannara.Operations.FeedbackLoop, []},
      {Tiannara.Operations.CampaignScheduler, []},
      {Tiannara.Operations.Phase5FeedbackListener, []},
      {Tiannara.Operations.CampaignTelemetry, []}
    ]
  end

  # ASC phase executors (Phases 6–10) — gated by the feature flag.
  def asc_children(false), do: []

  def asc_children(true) do
    [
      # Phase 6: Autonomous Scientific Civilization subsystem architecture
      {Tiannara.ASC.Core.Supervisor, []},

      # Phase 7: Meta-Science — improves the scientific process itself
      {Tiannara.ASC.MetaScienceEngine, []},

      # Phase 8: Autonomous Engineering — 9 specialized services
      {Tiannara.ASC.Engineering.Supervisor, []},

      # Phase 9: Reality Engineering — 13 specialized services
      {Tiannara.ASC.Reality.Supervisor, []},

      # Phase 10: Civilizational Intelligence — 13 specialized services
      {Tiannara.ASC.Civilization.Supervisor, []},

      # ASC root supervisor
      {Tiannara.ASC.Supervisor, []},

      # Phase 6: Tool Self-Engineering — Tiannara builds its own tools
      {Tiannara.ToolForge.ToolForgeSupervisor, []}
    ]
  end

  defp register_subsystems do
    alias Tiannara.PhaseOmega.{BootSequencer, SubsystemRegistry}

    subsystems = [
      %{
        name: :council,
        module: Tiannara.Council.Supervisor,
        supervisor: Tiannara.Council.Supervisor,
        deps: [],
        start_opts: []
      },
      %{
        name: :service_registry,
        module: Tiannara.CEL.Kernel.ServiceRegistry,
        supervisor: Tiannara.CEL.Kernel.ServiceRegistry,
        deps: [:council],
        start_opts: []
      },
      %{
        name: :executive_kernel,
        module: Tiannara.CEL.Kernel,
        supervisor: Tiannara.CEL.Kernel,
        deps: [:service_registry],
        start_opts: []
      },
      %{
        name: :civilization_kernel,
        module: TiannaraOS.CivilizationKernel,
        supervisor: TiannaraOS.CivilizationKernel,
        deps: [:executive_kernel],
        start_opts: [:tiannara_civilization, %{}]
      },
      %{
        name: :rel_economy,
        module: Tiannara.REL.EconomyEngine,
        supervisor: Tiannara.REL.EconomyEngine,
        deps: [],
        start_opts: []
      },
      %{
        name: :omcs,
        module: Tiannara.OMCS.Supervisor,
        supervisor: Tiannara.OMCS.Supervisor,
        deps: [],
        start_opts: []
      },
      %{
        name: :core,
        module: Tiannara.Core.Supervisor,
        supervisor: Tiannara.Core.Supervisor,
        deps: [],
        start_opts: []
      },
      %{
        name: :stabilization,
        module: Tiannara.Stabilization.Supervisor,
        supervisor: Tiannara.Stabilization.Supervisor,
        deps: [],
        start_opts: []
      },
      %{
        name: :physics,
        module: Tiannara.Physics.Supervisor,
        supervisor: Tiannara.Physics.Supervisor,
        deps: [],
        start_opts: []
      },
      %{
        name: :topology,
        module: Tiannara.Topology.Supervisor,
        supervisor: Tiannara.Topology.Supervisor,
        deps: [],
        start_opts: []
      },
      %{
        name: :sentinel,
        module: Tiannara.Sentinel.Supervisor,
        supervisor: Tiannara.Sentinel.Supervisor,
        deps: [],
        start_opts: []
      },
      %{
        name: :operations,
        module: Tiannara.Operations.OperationsSupervisor,
        supervisor: Tiannara.Operations.OperationsSupervisor,
        deps: [],
        start_opts: []
      },
      %{
        name: :validation_supervisor,
        module: Tiannara.Observatory.ValidationSupervisor,
        supervisor: Tiannara.Observatory.ValidationSupervisor,
        deps: [],
        start_opts: []
      },
      %{
        name: :soak_checkpointer,
        module: Tiannara.CRAV.SoakCheckpointer,
        supervisor: Tiannara.CRAV.SoakCheckpointer,
        deps: [],
        start_opts: []
      }
    ]

    # ToolForge is a Phase 6 (ASC) executor — registered only when ASC is enabled,
    # since PhaseΩ boot starts every registered subsystem.
    tool_forge_subsystem = %{
      name: :tool_forge,
      module: Tiannara.ToolForge.ToolForgeSupervisor,
      supervisor: Tiannara.ToolForge.ToolForgeSupervisor,
      deps: [],
      start_opts: []
    }

    subsystems =
      if asc_enabled?() do
        subsystems ++ [tool_forge_subsystem]
      else
        subsystems
      end

    Enum.each(subsystems, fn opts ->
      BootSequencer.define_subsystem(opts)
    end)

    case BootSequencer.boot() do
      :ok ->
        Logger.info(
          "[PhaseΩ] Boot sequence completed — #{length(SubsystemRegistry.all())} subsystems registered"
        )

      {:error, reason} ->
        Logger.error("[PhaseΩ] Boot sequence failed: #{reason}")
    end

    SubsystemRegistry.register(:ros_registry, %{
      module: Tiannara.ROS.Registry,
      supervisor: nil,
      deps: [],
      status: :healthy,
      version: 1
    })
  end
end
