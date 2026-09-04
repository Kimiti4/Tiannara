defmodule Tiannara.ASC.Executive.Mission do
  @moduledoc """
  Phase 10: A governed, terminable objective.
  Includes Guardrail Metrics to prevent Metric Hacking (Goodhart's Law).
  """
  
  defstruct [
    :id,
    :name,
    :category,           # :product_delivery, :internal_research, :infrastructure
    
    # The Objective Hierarchy
    :primary_metric,     # e.g., "Transfer Success Rate"
    :target_value,       # e.g., 0.25
    :secondary_metrics,  # e.g., ["Adaptation Velocity"]
    :guardrail_metrics,  # e.g., %{transfer_attempts: :must_not_decrease, test_coverage: :must_not_drop_below_80}
    
    # Constraints
    :compute_budget,
    :deadline_epochs,
    
    # State
    mode: :mission,
    status: :active,     # :active, :achieved, :aborted, :hacking_suspected
    current_epoch: 0,
    compute_spent: 0
  ]

  @type t :: %__MODULE__{}
end
