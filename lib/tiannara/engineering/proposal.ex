defmodule Tiannara.Engineering.Proposal do
  @moduledoc """
  L4 Engineering Proposal artifact.

  Constitutional mandate: "Capability must never outpace verification."
  "Augments human intelligence rather than replaces human judgment."

  This struct represents a *candidate repair* proposed by the autonomous
  system in response to an observed failure. It is IMMUTABLE once minted
  and is NEVER executable. A Proposal is a description of a change,
  not the change itself.

  Lifecycle:
    :observed              -- anomaly detected, proposal created
    :reproduced           -- failure deterministically reproduced
    :candidate_generated  -- suggested_repair populated
    :verification_passed  -- VerificationAuthority signed off
    :queued              -- human review requested
    :human_review         -- under human review
    :approved             -- human approved; ready for Phase-8
    :phase8              -- handed to Phase-8 Deployment Authority
    :observed_outcome    -- post-deployment observation recorded
    :archived            -- concluded (approved+successful, rejected, or expired)

  Authority boundary:
    This module has NO authority to modify runtime code, deploy patches,
    hot-reload, or alter constitutional state. It can only *propose*.
  """
  require Logger

  alias Tiannara.Executive.Types
  alias Tiannara.Engineering.Events

  @enforce_keys [:id, :observed_failure, :affected_module, :created_at]
  defstruct [
    :id,
    :observed_failure,
    :root_cause_hypothesis,
    :affected_module,
    :contract_violation,
    :suggested_repair,
    :repair_complexity_score,
    :side_effect_assessment,
    :confidence_vector,
    :verification,
    :lineage,
    :status,
    :reviewer_id,
    :human_review_notes,
    :phase8_ticket_id,
    :observed_outcome,
    :created_at,
    :updated_at,
    :archived_at
  ]

  @type t :: %__MODULE__{}

  @lifecycle_order [
    :observed, :reproduced, :candidate_generated,
    :verification_passed, :queued, :human_review,
    :approved, :phase8, :observed_outcome, :archived
  ]

  @doc """
  Create a new proposal in the :observed state from a recorded failure.

  The `observed_failure` map should contain:
    %{exception: term, stacktrace_ref: String.t, task_id: term, phase: atom, timestamp: DateTime}
  """
  def new(observed_failure, affected_module, opts \\ []) do
    now = DateTime.utc_now()

    %__MODULE__{
      id: Types.new_id(),
      observed_failure: observed_failure,
      affected_module: affected_module,
      root_cause_hypothesis: opts[:root_cause_hypothesis],
      contract_violation: opts[:contract_violation],
      suggested_repair: nil,
      repair_complexity_score: nil,
      side_effect_assessment: nil,
      confidence_vector: %{
        evidence_strength: opts[:confidence] || 0.0,
        reproducibility: 0.0,
        simplicity: 1.0,
        cross_domain_support: 0.0,
        human_verification: 0.0
      },
      verification: nil,
      lineage: %{
        observed_in_soak: opts[:soak_run_id],
        parent_artifacts: opts[:parent_artifacts] || [],
        theory_refs: opts[:theory_refs] || []
      },
      status: :observed,
      reviewer_id: nil,
      human_review_notes: [],
      phase8_ticket_id: nil,
      observed_outcome: nil,
      created_at: now,
      updated_at: now,
      archived_at: nil
    }
  end

  @doc "Valid lifecycle transition?"
  def valid_transition?(from, to) do
    from_idx = Enum.find_index(@lifecycle_order, &(&1 == from))
    to_idx = Enum.find_index(@lifecycle_order, &(&1 == to))
    to_idx == from_idx + 1
  end

  @doc "Advance proposal to a new lifecycle state. Returns {:ok, proposal} or {:error, reason}."
  def advance(%__MODULE__{status: from} = proposal, to) when is_atom(to) do
    if valid_transition?(from, to) do
      updated = %{proposal | status: to, updated_at: DateTime.utc_now()}
      Events.emit(:proposal_advanced, proposal.id, %{from: from, to: to})
      {:ok, updated}
    else
      {:error, {:invalid_transition, from, to}}
    end
  end

  @doc "Record a suggested repair expression. Sets status to :candidate_generated."
  def set_repair(%__MODULE__{status: :observed} = proposal, repair_expr, complexity) do
    proposal
    |> Map.put(:suggested_repair, repair_expr)
    |> Map.put(:repair_complexity_score, complexity)
    |> Map.put(:status, :candidate_generated)
    |> Map.put(:updated_at, DateTime.utc_now())
  end

  def set_repair(%__MODULE__{} = proposal, _repair_expr, _complexity) do
    {:error, {:invalid_state_for_repair, proposal.status}}
  end

  @doc "Attach verification result. Transitions to :verification_passed."
  def set_verification(%__MODULE__{status: :candidate_generated} = proposal, verification_result) do
    proposal
    |> Map.put(:verification, verification_result)
    |> then(fn p -> advance(p, :verification_passed) end)
  end

  @doc "Request human review. Transitions to :queued."
  def request_review(%__MODULE__{status: :verification_passed} = proposal) do
    advance(proposal, :queued)
  end

  @doc "Record human review. Transitions to :human_review."
  def record_review(%__MODULE__{status: :queued} = proposal, reviewer_id, notes) do
    proposal
    |> Map.put(:reviewer_id, reviewer_id)
    |> Map.put(:human_review_notes, [%{reviewer: reviewer_id, notes: notes, at: DateTime.utc_now()} | proposal.human_review_notes])
    |> then(fn p -> advance(p, :human_review) end)
  end

  @doc "Record approval. Transitions to :approved."
  def approve(%__MODULE__{status: :human_review} = proposal) do
    advance(proposal, :approved)
  end

  @doc "Record rejection. Transitions directly to :archived with rejection rationale."
  def reject(%__MODULE__{} = proposal, reason) do
    proposal
    |> Map.put(:status, :archived)
    |> Map.put(:updated_at, DateTime.utc_now())
    |> Map.put(:observed_outcome, %{decision: :rejected, reason: reason, at: DateTime.utc_now()})
  end

  @doc "Hand off to Phase-8. Transitions to :phase8."
  def handoff_to_phase8(%__MODULE__{status: :approved} = proposal, ticket_id) do
    proposal
    |> Map.put(:phase8_ticket_id, ticket_id)
    |> then(fn p -> advance(p, :phase8) end)
  end

  @doc "Record observed outcome. Transitions to :observed_outcome."
  def record_outcome(%__MODULE__{status: :phase8} = proposal, outcome) do
    proposal
    |> Map.put(:observed_outcome, outcome)
    |> then(fn p -> advance(p, :observed_outcome) end)
  end

  @doc "Archive proposal. Final state."
  def archive(%__MODULE__{status: :observed_outcome} = proposal, outcome) do
    proposal
    |> Map.put(:status, :archived)
    |> Map.put(:updated_at, DateTime.utc_now())
    |> Map.put(:archived_at, DateTime.utc_now())
    |> Map.put(:observed_outcome, Map.put(outcome, :archived_at, DateTime.utc_now()))
  end
end
