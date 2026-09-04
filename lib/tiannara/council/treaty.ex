defmodule Tiannara.Council.Treaty do
  @moduledoc """
  Phase 20: A long-horizon, cross-civilizational contract.
  Tracks the interdependent milestones of sovereign nodes working toward a unified goal.
  """
  
  defstruct [
    :id,
    :objective,
    :signatories,      # List of node_ids (e.g., ["asc_alpha", "infra_omega"])
    :milestones,       # Interdependent deliverables
    :status,           # :negotiating, :active, :fulfilled, :breached
    :economic_impact,  # Real-world revenue generated vs cost incurred
    :created_at
  ]
end
