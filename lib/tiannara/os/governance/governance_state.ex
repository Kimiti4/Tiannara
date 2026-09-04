defmodule TiannaraOS.Governance.GovernanceState do
  require Logger

  @moduledoc """
  GovernanceState - Single source of truth for entire governance system state.

  All governance metrics derive from this state snapshot. Nothing computes
  governance metrics independently - they all flow from GovernanceState.

  ## State Components

  - `institutions` - Current institutional composition
  - `roles` - Active role assignments
  - `appointments` - Current appointments (active/expired/removed)
  - `capabilities` - Capability graph structure
  - `active_proposals` - Proposals in various stages
  - `pending_reviews` - Reviews awaiting completion
  - `pending_deployments` - Approved migrations awaiting execution
  - `pending_rollbacks` - Rollbacks in progress
  - `budget` - Governance budget allocation
  - `fitness` - Constitutional fitness score
  - `entropy` - Constitutional entropy measurement
  - `health` - Overall governance health score
  - `timestamp` - When state was captured

  ## API

      @spec capture_state() :: t()
      @spec from_ledger(GovernanceLedger.events()) :: t()
      @spec get_institution(t(), String.t()) :: map() | nil
      @spec get_appointments(t(), String.t()) :: [map()]
      @spec compute_health(t()) :: float()
  """

  defstruct [
    :timestamp,
    :institutions,
    :roles,
    :appointments,
    :capabilities,
    :active_proposals,
    :pending_reviews,
    :pending_deployments,
    :pending_rollbacks,
    :budget,
    :fitness,
    :entropy,
    :health,
    :metadata
  ]

  @type t :: %__MODULE__{
          timestamp: DateTime.t(),
          institutions: map(),
          roles: map(),
          appointments: map(),
          capabilities: map(),
          active_proposals: non_neg_integer(),
          pending_reviews: non_neg_integer(),
          pending_deployments: non_neg_integer(),
          pending_rollbacks: non_neg_integer(),
          budget: map(),
          fitness: float(),
          entropy: float(),
          health: float(),
          metadata: map()
        }

  @doc """
  Capture current governance state from ledger replay.

  This is the primary function that reconstructs state deterministically
  from the GovernanceLedger event history.
  """
  @spec capture_state() :: t()
  def capture_state() do
    now = DateTime.utc_now()

    # Reconstruct state from ledger
    reconstructed = TiannaraOS.Governance.GovernanceLedger.reconstruct_state()

    # Compute derived metrics
    fitness = compute_fitness(reconstructed)
    entropy = compute_entropy(reconstructed)
    health = compute_health(fitness, entropy, reconstructed)

    %__MODULE__{
      timestamp: now,
      institutions: Map.get(reconstructed, :institutions, %{}),
      roles: Map.get(reconstructed, :roles, %{}),
      appointments: Map.get(reconstructed, :appointments, %{}),
      capabilities: Map.get(reconstructed, :capabilities, %{}),
      active_proposals: count_active_proposals(),
      pending_reviews: count_pending_reviews(),
      pending_deployments: count_pending_deployments(),
      pending_rollbacks: count_pending_rollbacks(),
      budget: get_governance_budget(),
      fitness: fitness,
      entropy: entropy,
      health: health,
      metadata: %{
        total_institutions: map_size(Map.get(reconstructed, :institutions, %{})),
        total_appointments: map_size(Map.get(reconstructed, :appointments, %{})),
        active_members: map_size(Map.get(reconstructed, :active_members, %{}))
      }
    }
  end

  @doc """
  Get current governance state (alias for capture_state/0).
  
  Reconstructs the entire governance state from the GovernanceLedger event history.
  """
  @spec get_current_state() :: t()
  def get_current_state() do
    capture_state()
  end

  @doc """
  Build state directly from ledger events (for testing/replay).
  """
  @spec from_ledger([TiannaraOS.Governance.GovernanceLedger.t()]) :: t()
  def from_ledger(events) do
    now = DateTime.utc_now()

    # Replay events to reconstruct state
    reconstructed = replay_events_to_state(events)

    fitness = compute_fitness(reconstructed)
    entropy = compute_entropy(reconstructed)
    health = compute_health(fitness, entropy, reconstructed)

    %__MODULE__{
      timestamp: now,
      institutions: Map.get(reconstructed, :institutions, %{}),
      roles: Map.get(reconstructed, :roles, %{}),
      appointments: Map.get(reconstructed, :appointments, %{}),
      capabilities: Map.get(reconstructed, :capabilities, %{}),
      active_proposals: 0,
      pending_reviews: 0,
      pending_deployments: 0,
      pending_rollbacks: 0,
      budget: %{},
      fitness: fitness,
      entropy: entropy,
      health: health,
      metadata: %{
        source: "ledger_replay",
        event_count: length(events)
      }
    }
  end

  @doc """
  Get institution by ID from state.
  """
  @spec get_institution(t(), String.t()) :: map() | nil
  def get_institution(%__MODULE__{institutions: institutions}, institution_id) do
    Map.get(institutions, institution_id)
  end

  @doc """
  Get all appointments for a member.
  """
  @spec get_appointments(t(), String.t()) :: [map()]
  def get_appointments(%__MODULE__{appointments: appointments}, member_id) do
    appointments
    |> Map.values()
    |> Enum.filter(fn appt -> appt.member_id == member_id end)
  end

  @doc """
  Get all active members of an institution.
  """
  @spec get_active_members(t(), String.t()) :: [String.t()]
  def get_active_members(%__MODULE__{appointments: appointments}, institution_id) do
    appointments
    |> Map.values()
    |> Enum.filter(fn appt ->
      appt.institution_id == institution_id and appt.status == :active
    end)
    |> Enum.map(fn appt -> appt.member_id end)
  end

  @doc """
  Check if member has specific capability through their roles.
  """
  @spec member_has_capability?(t(), String.t(), atom()) :: boolean()
  def member_has_capability?(%__MODULE__{} = state, member_id, capability) do
    case Map.get(state.roles, member_id) do
      nil -> false
      role_ids ->
        Enum.any?(role_ids, fn role_id ->
          role_has_capability?(role_id, capability)
        end)
    end
  end

  @doc """
  Compute overall governance health score.

  Formula:
    Health = 0.30 × Fitness + 0.25 × (1 - Entropy) + 0.20 × Replay Quality +
             0.15 × Auditability + 0.10 × Coverage

  Threshold: ≥ 0.7 healthy, < 0.6 critical
  """
  @spec compute_health(float(), float(), map()) :: float()
  def compute_health(fitness, entropy, _reconstructed) do
    # Placeholder values for components requiring runtime data
    replay_quality = 1.0  # TODO: Compute from replay success rate
    auditability = 0.9    # TODO: Compute from audit trail completeness
    coverage = 0.85       # TODO: Compute from domain coverage

    health =
      0.30 * fitness +
      0.25 * (1.0 - entropy) +
      0.20 * replay_quality +
      0.15 * auditability +
      0.10 * coverage

    Float.round(max(0.0, min(1.0, health)), 4)
  end

  @doc """
  Export state to JSON-serializable format.
  """
  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = state) do
    %{
      timestamp: DateTime.to_iso8601(state.timestamp),
      institutions: state.institutions,
      roles: state.roles,
      appointments: state.appointments,
      capabilities: state.capabilities,
      active_proposals: state.active_proposals,
      pending_reviews: state.pending_reviews,
      pending_deployments: state.pending_deployments,
      pending_rollbacks: state.pending_rollbacks,
      budget: state.budget,
      fitness: state.fitness,
      entropy: state.entropy,
      health: state.health,
      metadata: state.metadata
    }
  end

  @doc """
  Compare two states to detect changes.
  """
  @spec diff(t(), t()) :: map()
  def diff(%__MODULE__{} = old_state, %__MODULE__{} = new_state) do
    %{
      institutions_changed: old_state.institutions != new_state.institutions,
      appointments_changed: old_state.appointments != new_state.appointments,
      fitness_delta: Float.round(new_state.fitness - old_state.fitness, 4),
      entropy_delta: Float.round(new_state.entropy - old_state.entropy, 4),
      health_delta: Float.round(new_state.health - old_state.health, 4),
      timestamp_delta: DateTime.diff(new_state.timestamp, old_state.timestamp, :second)
    }
  end

  # Private helpers

  defp compute_fitness(_reconstructed) do
    # Delegate to ConstitutionFitnessEvaluator when available
    # For now, return baseline from Phase 14.0
    0.8525
  end

  defp compute_entropy(_reconstructed) do
    # Delegate to ConstitutionalEntropyTracker when available
    # For now, return baseline from Phase 14.0
    0.38
  end

  defp replay_events_to_state(_events) do
    # Simplified replay - delegates to GovernanceLedger.reconstruct_state/0
    # In production, this would be more sophisticated
    TiannaraOS.Governance.GovernanceLedger.reconstruct_state()
  end

  defp role_has_capability?(_role_id, _capability) do
    Logger.debug("CapabilityRegistry.get_role_capabilities/1 not available")
    false
  end

  defp count_active_proposals() do
    Logger.debug("ProposalRegistry.count_by_status/1 not available")
    0
  end

  defp count_pending_reviews() do
    Logger.debug("ReviewRegistry.count_by_status/1 not available")
    0
  end

  defp count_pending_deployments() do
    Logger.debug("DeploymentRegistry.count_by_status/1 not available")
    0
  end

  defp count_pending_rollbacks() do
    Logger.debug("RollbackRegistry.count_by_status/1 not available")
    0
  end

  defp get_governance_budget() do
    Logger.debug("GovernanceEconomicsLedger.get_budget/0 not available")
    %{simulation_cpu_hours: 0, reviewer_hours: 0, total_cost: 0.0}
  end
end
