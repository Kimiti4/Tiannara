defmodule Tiannara.Core.WorldModel.Belief do
  @moduledoc """
  Belief representation - confidence-weighted statements about reality.

  Instead of storing facts, the World Model stores beliefs with confidence scores.
  This allows for epistemic uncertainty and belief revision.

  Example:
    %Belief{
      statement: "Prediction Domain is strongest in finance",
      confidence: 0.84,
      evidence: ["backtested_results", "expert_consensus"],
      source: :prediction_domain,
      last_verified: ~U[2026-05-30 01:10:00Z]
    }
  """

  defstruct [
    :statement,
    :confidence,
    :evidence,
    :source,
    :last_verified,
    :created_at
  ]

  @doc "Create a new belief."
  def new(statement, confidence \\ 0.5, source \\ :observation) do
    %__MODULE__{
      statement: statement,
      confidence: confidence,
      evidence: [],
      source: source,
      last_verified: DateTime.utc_now(),
      created_at: DateTime.utc_now()
    }
  end

  @doc "Add evidence supporting this belief."
  def add_evidence(belief, evidence_item) do
    %{belief | evidence: [evidence_item | belief.evidence]}
  end

  @doc "Update belief confidence."
  def update_confidence(belief, new_confidence) do
    %{belief | confidence: new_confidence, last_verified: DateTime.utc_now()}
  end

  @doc "Check if belief meets confidence threshold."
  def is_trusted?(belief, threshold \\ 0.7) do
    belief.confidence >= threshold
  end
end
