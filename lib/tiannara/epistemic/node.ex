defmodule Tiannara.Epistemic.Node do
  @moduledoc """
  A single epistemic artifact in the scientific pipeline, carrying everything
  needed to audit it: provenance, timestamp, lineage, confidence, assumptions,
  unknowns, contradictions, responsible subsystem, disposition, and the
  constitutional checks applied.

  Constitutional basis: Explainability, Observability, "Every architectural
  decision should remain traceable", "Distinguish clearly between facts,
  evidence, assumptions, hypotheses, confidence levels, unknowns."
  """

  @enforce_keys [:id, :stage]
  defstruct [
    :id,
    :stage,
    :content,
    :timestamp,
    :confidence,
    :responsible_subsystem,
    :disposition,
    lineage: [],
    assumptions: [],
    unknowns: [],
    contradictions: [],
    constitutional_checks: []
  ]

  @type t :: %__MODULE__{}

  @stages [:observation, :gap, :hypothesis, :prediction, :experiment,
           :evidence, :validation, :knowledge, :discovery]


  def stages, do: @stages
end