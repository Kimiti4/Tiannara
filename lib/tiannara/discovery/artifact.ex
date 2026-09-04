defmodule Tiannara.Discovery.Artifact do
  @moduledoc """
  A provenance-bearing node in the discovery DAG.

  Every scientific artifact (observation, gap, hypothesis, prediction,
  experiment, evidence, knowledge, discovery) carries its lineage, confidence,
  assumptions, unknowns, contradictions, disposition, responsible subsystem,
  and the constitutional checks applied to it — so Tiannara's reasoning is
  auditable rather than opaque.

  Constitutional basis: Explainability, "Every architectural decision should
  remain traceable", Evidence Before Confidence.
  """

  @enforce_keys [:id, :stage, :content]
  defstruct [
    :id,
    :stage,
    :content,
    :timestamp,
    :subsystem,
    :disposition,
    lineage: [],
    confidence: 0.0,
    assumptions: [],
    unknowns: [],
    contradictions: [],
    checks: []
  ]

  def new(stage, content, opts \\ []) do
    %__MODULE__{
      id: Keyword.get(opts, :id) || gen_id(stage),
      stage: stage,
      content: content,
      lineage: Keyword.get(opts, :lineage, []),
      confidence: Keyword.get(opts, :confidence, 0.0),
      assumptions: Keyword.get(opts, :assumptions, []),
      unknowns: Keyword.get(opts, :unknowns, []),
      contradictions: Keyword.get(opts, :contradictions, []),
      disposition: Keyword.get(opts, :disposition),
      subsystem: Keyword.get(opts, :subsystem),
      timestamp: System.system_time(:millisecond),
      checks: Keyword.get(opts, :checks, [])
    }
  end

  defp gen_id(stage) do
    "#{stage}-#{Base.encode16(:crypto.strong_rand_bytes(5), case: :lower)}"
  end
end
