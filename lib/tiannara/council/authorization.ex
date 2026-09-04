defmodule Tiannara.Council.Authorization do
  defstruct [
    :decision,
    :confidence,
    :constitutional_score,
    :violated_principles,
    :required_human_review,
    :explanation,
    :evidence,
    :risks,
    :simulation_results,
    :recommendation,
    :context,
    :decided_at,
    :policy_applied,
    metadata: %{}
  ]

  @type decision :: :approved | :rejected | :deferred | :requires_human | :conditional
  @type t :: %__MODULE__{
          decision: decision(),
          confidence: float(),
          constitutional_score: float(),
          violated_principles: [atom()],
          required_human_review: boolean(),
          explanation: String.t(),
          evidence: [map()],
          risks: [map()],
          simulation_results: [map()],
          recommendation: String.t() | nil,
          context: Tiannara.Council.ExecutionContext.t() | nil,
          decided_at: DateTime.t(),
          policy_applied: atom() | nil,
          metadata: map()
        }

  def approved(opts) do
    %__MODULE__{
      decision: :approved,
      confidence: Keyword.get(opts, :confidence, 1.0),
      constitutional_score: Keyword.get(opts, :constitutional_score, 1.0),
      violated_principles: [],
      required_human_review: false,
      explanation: Keyword.get(opts, :explanation, "Action complies with all constitutional principles."),
      evidence: Keyword.get(opts, :evidence, []),
      risks: Keyword.get(opts, :risks, []),
      simulation_results: Keyword.get(opts, :simulation_results, []),
      recommendation: Keyword.get(opts, :recommendation),
      context: Keyword.get(opts, :context),
      decided_at: DateTime.utc_now(),
      policy_applied: Keyword.get(opts, :policy_applied),
      metadata: Keyword.get(opts, :metadata, %{})
    }
  end

  def rejected(opts) do
    %__MODULE__{
      decision: :rejected,
      confidence: Keyword.get(opts, :confidence, 1.0),
      constitutional_score: Keyword.get(opts, :constitutional_score, 0.0),
      violated_principles: Keyword.get(opts, :violated_principles, []),
      required_human_review: false,
      explanation: Keyword.fetch!(opts, :explanation),
      evidence: Keyword.get(opts, :evidence, []),
      risks: Keyword.get(opts, :risks, []),
      simulation_results: [],
      recommendation: Keyword.get(opts, :recommendation),
      context: Keyword.get(opts, :context),
      decided_at: DateTime.utc_now(),
      policy_applied: Keyword.get(opts, :policy_applied),
      metadata: Keyword.get(opts, :metadata, %{})
    }
  end

  def requires_human(opts) do
    %__MODULE__{
      decision: :requires_human,
      confidence: Keyword.get(opts, :confidence, 0.5),
      constitutional_score: Keyword.get(opts, :constitutional_score, 0.5),
      violated_principles: Keyword.get(opts, :violated_principles, []),
      required_human_review: true,
      explanation: Keyword.fetch!(opts, :explanation),
      evidence: Keyword.get(opts, :evidence, []),
      risks: Keyword.get(opts, :risks, []),
      simulation_results: Keyword.get(opts, :simulation_results, []),
      recommendation: Keyword.get(opts, :recommendation),
      context: Keyword.get(opts, :context),
      decided_at: DateTime.utc_now(),
      policy_applied: Keyword.get(opts, :policy_applied),
      metadata: Keyword.get(opts, :metadata, %{})
    }
  end

  def permitted?(%__MODULE__{decision: :approved}), do: true
  def permitted?(%__MODULE__{decision: :conditional}), do: true
  def permitted?(_), do: false
end
