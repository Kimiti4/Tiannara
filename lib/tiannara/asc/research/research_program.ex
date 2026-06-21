defmodule Tiannara.ASC.Research.ResearchProgram do
  @moduledoc """
  Phase 6: Represents a competing scientific research program within the ASC civilization.
  Each program has its own methodology, budget, and fitness metrics.
  Programs evolve and compete for resources based on their civilizational utility.
  """
  
  defstruct [
    :id,
    :name,
    :domain,              # :transfer_physics, :repair_ecology, :architecture_evolution, etc.
    :methodology,         # :targeted_experimentation, :brute_force, :meta_learning, etc.
    
    # Resource Allocation
    budget: 1000,         # Compute cycles allocated per epoch
    compute_consumed: 0,
    
    # Scientific Output
    experiments_run: 0,
    laws_generated: 0,
    laws_survived: 0,
    
    # Civilizational Impact
    utility_generated: 0.0,
    fitness_contribution: 0.0,
    
    # Evolutionary Fitness
    program_fitness: 0.0,  # Composite score determining resource allocation
    generation: 1,
    
    # Temporal Tracking
    created_at: nil,
    last_active: nil
  ]

  @type t :: %__MODULE__{
    id: String.t(),
    name: String.t(),
    domain: atom(),
    methodology: atom(),
    budget: integer(),
    compute_consumed: integer(),
    experiments_run: integer(),
    laws_generated: integer(),
    laws_survived: integer(),
    utility_generated: float(),
    fitness_contribution: float(),
    program_fitness: float(),
    generation: integer(),
    created_at: integer(),
    last_active: integer()
  }
end
