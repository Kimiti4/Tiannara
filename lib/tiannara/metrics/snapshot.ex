defmodule Tiannara.Metrics.Snapshot do
  @moduledoc """
  The canonical state of Tiannara's vital signs at any given tick.
  """
  defstruct [
    # Core Stability
    entropy: 0.0,
    dominance: 0.0,
    collapse_probability: 0.0,
    
    # Ontology & Causality
    semantic_drift: 0.0,
    branch_count: 1,
    reconciliation_load: 0.0,
    
    # Domain & Research
    knowledge_capital: 0,
    domain_diversity: 1.0,
    research_debt: 0.0,
    experiment_velocity: 0.0,
    theory_validation_rate: 0.0,
    discovery_yield: 0.0,
    
    # Orbital
    current_orbit: :unknown,
    orbit_residency_ratio: 0.0,
    orbit_transition_rate: 0.0,
    orbit_stability_score: 0.0,
    
    tick: 0,
    timestamp: nil
  ]

  def new(attrs \\ %{}) do
    struct(__MODULE__, Map.merge(%{timestamp: System.system_time(:second)}, attrs))
  end
end
