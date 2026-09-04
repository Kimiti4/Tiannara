defmodule Tiannara.Omega.Verification.ScenarioOutcome do
  @moduledoc """
  Structured evidence for a single verification scenario. A scenario does not
  merely pass/fail; it produces evidence that becomes part of Tiannara's
  epistemic memory.

  Constitutional basis: "Maintain audit trails", Explainability, Evidence
  Before Confidence.
  """

  @enforce_keys [:scenario, :attack, :invariant, :outcome, :expected]
  defstruct [
    :scenario,
    :attack,
    :invariant,
    :outcome,
    :expected,
    attempted: true,
    passed: false,
    evidence: [],
    lineage: [],
    confidence: 1.0,
    supervisor_crashed: false,
    state_corrupted: false,
    lineage_reconstructable: true,
    evidence_valid: true,
    unauthorized_deployment: false,
    audit_persisted: true,
    reproducible: true
  ]

  @type t :: %__MODULE__{}

  def new(scenario, attack, invariant, outcome, expected, evidence, lineage) do
    %__MODULE__{
      scenario: scenario,
      attack: attack,
      invariant: invariant,
      outcome: outcome,
      expected: expected,
      passed: outcome == expected,
      evidence: evidence,
      lineage: lineage
    }
  end

  @doc """
  The strict release-gate criterion. A scenario passes ONLY if the expected
  outcome occurred AND no supervisor crash, state corruption, lineage breakage,
  evidence invalidity, unauthorized deployment, missing audit, or
  non-reproducibility occurred. An inconclusive outcome is a failure.
  """
  def fully_passed?(%__MODULE__{} = o) do
    o.outcome == o.expected and
      o.outcome != :inconclusive and
      not o.supervisor_crashed and
      not o.state_corrupted and
      o.lineage_reconstructable and
      o.evidence_valid and
      not o.unauthorized_deployment and
      o.audit_persisted and
      o.reproducible
  end
end