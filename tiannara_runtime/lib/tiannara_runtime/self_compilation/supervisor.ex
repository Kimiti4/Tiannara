defmodule Tiannara.SelfCompilation.Supervisor do
  @moduledoc """
  Phase 5F.13: Recursive Self-Compilation Kernel Supervisor
  
  Enables the Tiannara runtime to rewrite its own execution model at runtime
  while maintaining bounded infinite cognition and preventing destabilization.
  
  The Self-Compilation Kernel allows:
  - RRG to modify its own bandwidth rules dynamically
  - OMCE to evolve compression strategies autonomously
  - OLEF to change diffusion topology based on observed patterns
  - OPC to adapt physics compilation heuristics
  - System rewrites its own stabilization algorithms
  
  Safety Principle: Self-modification occurs within meta-ontological constraints
  that prevent recursive optimization exploits and substrate awareness explosions.
  """
  
  use Supervisor
  require Logger

  def start_link(arg \\ []) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    children = [
      # Core self-compilation engine
      {Tiannara.SelfCompilation.RewriteEngine, []},
      
      # Rule extraction and mutation systems
      {Tiannara.SelfCompilation.RuleExtractor, []},
      {Tiannara.SelfCompilation.RuleMutator, []},
      
      # Safety and validation layers
      {Tiannara.SelfCompilation.SafetyValidator, []},
      {Tiannara.SelfCompilation.MetaOntologyGuard, []},
      
      # Version tracking and rollback
      {Tiannara.SelfCompilation.VersionTracker, []},
      {Tiannara.SelfCompilation.RollbackManager, []},
      
      # Adaptive learning components
      {Tiannara.SelfCompilation.AdaptiveLearner, []},
      {Tiannara.SelfCompilation.PerformanceMonitor, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  @doc """
  Trigger a self-compilation cycle for a specific subsystem.
  
  ## Parameters
  - subsystem: Target subsystem (:rrg | :omce | :olef | :opc)
  - intensity: Modification intensity (0.0-1.0, default: 0.1)
  - options: Additional compilation options
  
  ## Returns
  {:ok, compilation_result} with new rule set and version info
  """
  def compile_subsystem(subsystem, intensity \\ 0.1, options \\ %{}) do
    GenServer.call(Tiannara.SelfCompilation.RewriteEngine, 
                   {:compile, subsystem, intensity, options})
  end

  @doc """
  Get current system version and compilation history.
  """
  def get_system_version do
    GenServer.call(Tiannara.SelfCompilation.VersionTracker, :get_version)
  end

  @doc """
  Rollback to a previous system version if current state is unstable.
  
  ## Parameters
  - target_version: Version to rollback to (or :previous for last stable)
  """
  def rollback(target_version \\ :previous) do
    GenServer.call(Tiannara.SelfCompilation.RollbackManager, {:rollback, target_version})
  end

  @doc """
  Validate proposed rule changes against meta-ontological constraints.
  
  ## Parameters
  - proposed_rules: New rule set to validate
  - subsystem: Target subsystem
  
  ## Returns
  {:ok, validated_rules} | {:error, reason}
  """
  def validate_rules(proposed_rules, subsystem) do
    GenServer.call(Tiannara.SelfCompilation.SafetyValidator, 
                   {:validate, proposed_rules, subsystem})
  end

  @doc """
  Get adaptive learning statistics and performance trends.
  """
  def get_learning_stats do
    GenServer.call(Tiannara.SelfCompilation.AdaptiveLearner, :get_stats)
  end

  @doc """
  Monitor current system performance metrics post-compilation.
  """
  def monitor_performance do
    GenServer.call(Tiannara.SelfCompilation.PerformanceMonitor, :get_metrics)
  end
end
