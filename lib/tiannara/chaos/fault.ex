defmodule Tiannara.Chaos.Fault do
  @moduledoc """
  A single injectable fault specification.

  Constitutional basis:
    * Safety & Reliability -- "Capability must never outpace verification"
    * Verification First  -- "Failure recovery testing"
    * Core chaos invariant -- "A subsystem failure must not silently
      destroy epistemic history."

  A Fault is declarative. It describes WHAT to break and the EXPECTED
  7-phase trajectory. Execution is owned by `Tiannara.Chaos.Runner`,
  which is hard-gated to isolated environments only.
  """

  @enforce_keys [:id, :target, :kind]
  defstruct [
    :id,
    :target,
    :kind,
    :description,
    detection: [],
    containment: [],
    recovery: [],
    evidence_preservation: [],
    verification: []
  ]

  @type t :: %__MODULE__{}

  def new(id, target, kind, opts \\ []) do
    %__MODULE__{
      id: id,
      target: target,
      kind: kind,
      description: Keyword.get(opts, :description, ""),
      detection: Keyword.get(opts, :detection, []),
      containment: Keyword.get(opts, :containment, []),
      recovery: Keyword.get(opts, :recovery, []),
      evidence_preservation: Keyword.get(opts, :evidence_preservation, []),
      verification: Keyword.get(opts, :verification, [])
    }
  end
end
