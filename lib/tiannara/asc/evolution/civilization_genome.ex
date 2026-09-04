defmodule Tiannara.ASC.Evolution.CivilizationGenome do
  @moduledoc """
  Phase 12: The DNA of the AI R&D Organization.
  Defines the Guild roles, governance weights, and operational tolerances.
  """
  
  defstruct [
    :id,
    
    # Organizational Structure
    guild_roles: [:architect, :coder, :auditor, :tester],
    
    # Governance & Constitution Weights
    value_weights: %{
      alignment: 1.0,
      utility: 1.0,
      complexity: -1.5,
      risk: -2.0
    },
    
    # Operational Parameters
    loopback_tolerance: 3,
    guardrail_strictness: 0.8,
    
    # Evolutionary Metrics
    generation: 1,
    fitness: 0.0
  ]

  @type t :: %__MODULE__{}
end
