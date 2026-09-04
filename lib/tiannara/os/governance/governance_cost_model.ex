defmodule TiannaraOS.Governance.GovernanceCostModel do
  @moduledoc """
  GovernanceCostModel - Track computational and human cost of governance itself.

  This module measures the resource consumption of constitutional governance activities:
  - Simulation CPU hours and memory
  - Reviewer hours (human time)
  - Migration downtime
  - Rollback costs

  ## Purpose

  Enable decision-making based on governance efficiency. Reject proposals where
  governance cost exceeds scientific benefit.

  ## API

      @spec track_governance_cost(proposal_id()) :: t()
      @spec compute_net_utility(benefits :: float(), cost :: t()) :: float()
  """

  defstruct [
    :simulation_cpu_hours,
    :simulation_memory_gb,
    :reviewer_hours,
    :migration_downtime_ms,
    :rollback_cost,
    :total_governance_cost
  ]

  @type t :: %__MODULE__{
          simulation_cpu_hours: float(),
          simulation_memory_gb: float(),
          reviewer_hours: float(),
          migration_downtime_ms: non_neg_integer(),
          rollback_cost: float(),
          total_governance_cost: float()
        }

  # Cost weights for normalization
  @cpu_hour_cost 0.1       # $0.10 per CPU hour
  @memory_gb_cost 0.05     # $0.05 per GB
  @reviewer_hour_cost 1.0  # $1.00 per reviewer hour (normalized)
  @downtime_ms_cost 0.001  # $0.001 per ms downtime
  @rollback_base_cost 5.0  # Base cost for rollback capability

  @doc """
  Track governance cost for a specific proposal.

  Aggregates all costs from the economics ledger for this proposal.
  """
  @spec track_governance_cost(String.t()) :: t()
  def track_governance_cost(proposal_id) do
    # TODO: Query GovernanceEconomicsLedger for actual costs
    # For now, use estimates based on proposal type

    # Placeholder costs (would come from ledger in production)
    simulation_cpu_hours = estimate_simulation_cpu(proposal_id)
    simulation_memory_gb = estimate_simulation_memory(proposal_id)
    reviewer_hours = estimate_reviewer_hours(proposal_id)
    migration_downtime_ms = estimate_migration_downtime(proposal_id)
    rollback_cost = @rollback_base_cost

    total_governance_cost =
      simulation_cpu_hours * @cpu_hour_cost +
      simulation_memory_gb * @memory_gb_cost +
      reviewer_hours * @reviewer_hour_cost +
      migration_downtime_ms * @downtime_ms_cost +
      rollback_cost

    %__MODULE__{
      simulation_cpu_hours: Float.round(simulation_cpu_hours, 2),
      simulation_memory_gb: Float.round(simulation_memory_gb, 2),
      reviewer_hours: Float.round(reviewer_hours, 2),
      migration_downtime_ms: migration_downtime_ms,
      rollback_cost: Float.round(rollback_cost, 2),
      total_governance_cost: Float.round(total_governance_cost, 4)
    }
  end

  @doc """
  Compute net constitutional utility.

  Net Utility = Scientific Benefits - Governance Costs

  Positive value means benefits exceed costs (good proposal).
  Negative value means costs exceed benefits (reject proposal).
  """
  @spec compute_net_utility(float(), t()) :: float()
  def compute_net_utility(scientific_benefits, %__MODULE__{total_governance_cost: cost}) do
    Float.round(scientific_benefits - cost, 4)
  end

  @doc """
  Check if proposal is cost-effective.

  Returns true if net utility > 0 (benefits exceed costs).
  """
  @spec cost_effective?(scientific_benefits :: float(), cost :: t()) :: boolean()
  def cost_effective?(scientific_benefits, cost_model) do
    compute_net_utility(scientific_benefits, cost_model) > 0
  end

  # Private helper functions

  defp estimate_simulation_cpu(_proposal_id) do
    # TODO: Estimate based on proposal complexity
    # Simple proposals: ~10 CPU hours
    # Complex proposals: ~100+ CPU hours
    # Placeholder
    20.0
  end

  defp estimate_simulation_memory(_proposal_id) do
    # TODO: Estimate based on simulation scale
    # Placeholder
    8.0  # 8 GB
  end

  defp estimate_reviewer_hours(_proposal_id) do
    # TODO: Estimate based on review complexity
    # Minimum 3 reviewers × 2 hours each = 6 hours
    # Placeholder
    9.0  # 3 reviewers × 3 hours
  end

  defp estimate_migration_downtime(_proposal_id) do
    # TODO: Estimate based on migration complexity
    # Simple migrations: < 1 second
    # Complex migrations: minutes
    # Placeholder
    500  # 500ms
  end
end
