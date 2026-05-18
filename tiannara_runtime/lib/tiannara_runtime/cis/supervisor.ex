defmodule TiannaraRuntime.CIS.Supervisor do
  @moduledoc """
  ARCHITECTURAL BREAKTHROUGH v20: CIS Immune System Supervisor
  
  The Cognitive Immune System (CIS) acts as the runtime immune system,
  NOT a monitoring dashboard but a true active regulator.
  
  Responsibilities:
  1. Entropy Monitoring - Detect monoculture, collapse, instability
  2. Adaptive Recovery - Apply suppression, restart, diversification
  3. Ecological Regulation - Maintain diversity and bounded instability
  
  This extends OTP supervision into higher-order cognitive immune architecture.
  OTP supervision trees are already computational immune systems - we're
  making them explicitly aware of ecological dynamics.
  """
  
  use Supervisor
  
  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @impl true
  def init(_opts) do
    children = [
      # Entropy Monitor - tracks Shannon diversity across identity population
      {TiannaraRuntime.CIS.EntropyMonitor, name: :entropy_monitor},
      
      # Diversity Regulator - applies anti-monoculture pressure
      {TiannaraRuntime.CIS.DiversityRegulator, name: :diversity_regulator},
      
      # Collapse Detector - identifies ecological failure modes
      {TiannaraRuntime.CIS.CollapseDetector, name: :collapse_detector},
      
      # Recovery Orchestrator - coordinates immune interventions
      {TiannaraRuntime.CIS.RecoveryOrchestrator, name: :recovery_orchestrator}
    ]
    
    Supervisor.init(children, strategy: :one_for_one)
  end
end
