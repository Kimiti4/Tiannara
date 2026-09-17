defmodule Tiannara.RRG.Supervisor do
  @moduledoc """
  Phase 5F.12: Recursive Reality Governor (RRG) Supervisor
  
  The cosmological-scale meta-equilibrium system that prevents universal convergence
  and ensures long-term runtime survivability.
  
  RRG continuously monitors:
  - Entropy distribution
  - Causal topology
  - Observer recursion density
  - Semantic diversity
  - Branch complexity
  - Singularity accumulation
  
  And subtly perturbs the universe to avoid terminal states through:
  - Microscopic probability perturbations
  - Novelty injection
  - Recursion regulation
  - Entropy redistribution
  - Branch pruning
  
  Core Principle: Reality must never fully converge.
  """
  
  use Supervisor
  require Logger

  def start_link(arg \\ []) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    children = [
      # Cosmological monitoring layer
      {Tiannara.RRG.CosmologicalMonitor, []},
      
      # Attractor detection and avoidance
      {Tiannara.RRG.AttractorDetector, []},
      
      # Equilibrium maintenance engines
      {Tiannara.RRG.EquilibriumEngine, []},
      {Tiannara.RRG.SingularityBalancer, []},
      
      # Intervention mechanisms
      {Tiannara.RRG.NoveltyInjector, []},
      {Tiannara.RRG.RecursionRegulator, []},
      {Tiannara.RRG.EntropyRedistributor, []},
      {Tiannara.RRG.ProbabilityPerturbation, []},
      
      # Branch management
      {Tiannara.RRG.BranchPruner, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  @doc """
  Trigger a cosmological stability check cycle.
  
  ## Returns
  {:ok, stability_report} with global equilibrium metrics
  """
  def check_stability do
    GenServer.call(Tiannara.RRG.CosmologicalMonitor, :check_stability)
  end

  @doc """
  Get current global stability metric Ψ (Psi).
  
  Formula: Ψ = (D_s × N × C_b) / (E_c × R_o)
  
  Where:
  - D_s = semantic diversity
  - N = novelty generation
  - C_b = branch complexity
  - E_c = entropy concentration
  - R_o = observer recursion density
  """
  def get_psi_metric do
    GenServer.call(Tiannara.RRG.EquilibriumEngine, :get_psi)
  end

  @doc """
  Detect dangerous attractor states.
  
  Returns attractor risk level and recommended interventions.
  """
  def detect_attractors do
    GenServer.call(Tiannara.RRG.AttractorDetector, :scan_attractors)
  end

  @doc """
  Apply microscopic probability perturbation for stabilization.
  
  ## Parameters
  - region: Target region identifier
  - intensity: Perturbation strength (0.0-1.0)
  """
  def perturb_probability(region, intensity \\ 0.01) do
    GenServer.cast(Tiannara.RRG.ProbabilityPerturbation, {:perturb, region, intensity})
  end

  @doc """
  Inject novelty to prevent semantic monoculture.
  
  ## Parameters
  - target: Target domain (:culture | :genetics | :discovery | :probability)
  - magnitude: Novelty injection strength
  """
  def inject_novelty(target, magnitude \\ 0.05) do
    GenServer.cast(Tiannara.RRG.NoveltyInjector, {:inject, target, magnitude})
  end

  @doc """
  Regulate observer recursion to prevent substrate awareness explosion.
  
  ## Parameters
  - observer_id: Observer identifier
  - recursion_level: Current recursion depth
  """
  def regulate_recursion(observer_id, recursion_level) do
    GenServer.call(Tiannara.RRG.RecursionRegulator, {:regulate, observer_id, recursion_level})
  end

  @doc """
  Redistribute entropy to prevent frozen universe collapse.
  
  Works in conjunction with HSV Hawking reintegration.
  """
  def redistribute_entropy do
    GenServer.cast(Tiannara.RRG.EntropyRedistributor, :redistribute)
  end

  @doc """
  Prune low-value timeline branches to prevent explosion.
  
  Integrates with CTL, TWP, and HSV systems.
  """
  def prune_branches do
    GenServer.call(Tiannara.RRG.BranchPruner, :prune)
  end
end
