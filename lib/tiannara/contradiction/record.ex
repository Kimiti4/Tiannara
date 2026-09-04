defmodule Tiannara.Contradiction.Record do
  @moduledoc """
  A structured contradiction between two claims. Carries everything needed to
  investigate and resolve it: the claims, their evidence, type, severity,
  confidence, temporal context, affected knowledge, and resolution status.

  Constitutional basis: "Distinguish clearly between facts, evidence,
  assumptions, hypotheses, confidence levels, unknowns"; "Uncertainty should
  never be hidden"; "Every architectural decision should remain traceable."
  """

  @enforce_keys [:id, :claim_a, :claim_b]
  defstruct [
    :id,
    :claim_a,
    :claim_b,
    :evidence_a,
    :evidence_b,
    :type,
    :severity,
    :confidence,
    :temporal_context,
    :affected_knowledge,
    :resolution_status,
    :resolution,
    :detected_at,
    lineage: []
  ]

  @type t :: %__MODULE__{}

  @types [:value_conflict, :logical_inconsistency, :temporal_conflict, :scope_conflict]
  @severities [:low, :medium, :high, :critical]
  @statuses [:detected, :investigating, :experiment_proposed,
             :experiment_running, :resolved, :dismissed]

  def types, do: @types
  def severities, do: @severities
  def statuses, do: @statuses
end