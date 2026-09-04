defmodule Tiannara.Sentinel.Supervisor do
  @moduledoc """
  Supervisor for the Tiannara Sentinel ecosystem.
  """
  use Supervisor
  require Logger

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      # Universal Observation System (must start before TelemetryHub)
      Tiannara.Sentinel.Observatory,

      # Scientific Verification Layer
      Tiannara.Sentinel.Verification,
      # Causal Intelligence
      Tiannara.Sentinel.CausalIntelligence,
      # Evolutionary Oversight
      Tiannara.Sentinel.EvolutionaryOversight,
      # Archaeology Management
      Tiannara.Sentinel.ArchaeologyManagement,
      # SOPL/REA Governance
      Tiannara.Sentinel.Governance,
      # Human Collaboration Interface
      Tiannara.Sentinel.HumanCollaboration,
      # Sentinel Activation Engine — the continuous epistemic awareness loop
      Tiannara.Sentinel.Activation.Engine,

      # Sentinel Cognition Layer — scientific reasoning, context, and investigation
      Tiannara.Sentinel.Cognition.Supervisor,

      # Research Director — hypothesis generation and experiment planning
      Tiannara.Research.Director,

      # Execution Sandbox — isolated experiment execution
      Tiannara.Sandbox,

      # Core Sentinel analysis modules
      Tiannara.Sentinel.TelemetryHub,
      Tiannara.Sentinel.AnomalyDetector,
      Tiannara.Sentinel.ImmuneCoordinator,

      # Epistemic tracking and archaeology
      Tiannara.Sentinel.EpistemologyArchive,
      Tiannara.Sentinel.EpistemologyAtlas,
      Tiannara.Sentinel.DiscoveryGenealogy,
      Tiannara.Sentinel.EpistemicArchaeology,
      Tiannara.Sentinel.DiseaseGenealogy
    ]

    Logger.info("Sentinel supervisor initialized.")

    Supervisor.init(children, strategy: :one_for_all)
  end
end
