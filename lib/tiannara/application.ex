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
    children = [
      # Telemetry and monitoring
      Tiannara.Telemetry,

      # Civilization Kernel (Top-level State Substrate)
      Supervisor.child_spec({TiannaraOS.CivilizationKernel, [:tiannara_civilization, %{}]}, id: :civilization_kernel),

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

      # Sentinel Unified Ecosystem
      Tiannara.Sentinel.Supervisor,

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
      TiannaraWeb.Endpoint
    ]

    # Autonomous Software Civilization — gated behind feature flag.
    # Default: disabled. Enable via: config :tiannara, :asc, enabled: true
    asc_config = Application.get_env(:tiannara, :asc, [])
    children =
      if Keyword.get(asc_config, :enabled, false) do
        Logger.info("[ASC] Feature flag enabled — starting Autonomous Software Civilization")
        children ++ [Tiannara.ASC.Supervisor]
      else
        Logger.info("[ASC] Feature flag disabled — ASC supervision tree not started")
        children
      end

    opts = [strategy: :one_for_one, name: Tiannara.Application]
    Logger.info("Starting Tiannara cosmological runtime")

    case Supervisor.start_link(children, opts) do
      {:ok, pid} ->
        Logger.info("Tiannara started successfully")
        {:ok, pid}
      {:error, reason} ->
        Logger.error("Failed to start Tiannara: #{inspect(reason)}")
        {:error, reason}
    end
  end
end