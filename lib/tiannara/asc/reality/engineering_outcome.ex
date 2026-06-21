defmodule Tiannara.ASC.Reality.EngineeringOutcome do
  @moduledoc """
  Phase 8B: The multi-dimensional measurement of an applied patch.
  Allows the RegressionAnalyzer to evaluate trade-offs (e.g., performance vs coverage).
  """
  
  defstruct [
    :proposal_id,
    
    # Core Gates
    compilation_success: false,
    tests_passed: false,
    
    # Deltas (Experimental - Baseline)
    coverage_delta: 0.0,
    performance_delta_ms: 0,
    complexity_delta: 0,
    
    # Abstract Value
    calculated_roi: 0.0
  ]

  @type t :: %__MODULE__{
    proposal_id: String.t(),
    compilation_success: boolean(),
    tests_passed: boolean(),
    coverage_delta: float(),
    performance_delta_ms: integer(),
    complexity_delta: integer(),
    calculated_roi: float()
  }
end
