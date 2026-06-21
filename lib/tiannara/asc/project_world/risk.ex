defmodule Tiannara.ASC.ProjectWorld.Risk do
  @moduledoc """
  A risk extracted from project requirements.

  Risks are potential failure modes that the system should defend against.
  High-severity risks (score > 0.6) become inputs to the Crucible
  adversarial phase and spawn `:security` TestContracts.

  ## Risk Score

      risk_score = probability × severity   (0.0–1.0)

  ## Examples

      "authentication tokens may be stolen if not rotated"
      "third-party payment gateway could be unavailable"
      "large file uploads risk memory exhaustion"

  ## Lifecycle

  Requirements.Extractor → ProjectWorld.risks →
  Testing.Civilization (→ :security TestContracts for risk_score > 0.4) →
  Crucible.Attacker (adversarial simulation for risk_score > 0.6)
  """

  @derive Jason.Encoder

  defstruct [
    :id,
    :description,
    :category,         # :security | :reliability | :data_loss | :compliance | :performance | :external | :general
    :probability,      # 0.0–1.0
    :severity,         # 0.0–1.0
    :risk_score,       # probability × severity
    :mitigation,       # suggested mitigation strategy
    :source_fragment,
    tags: []
  ]

  @type category ::
    :security | :reliability | :data_loss | :compliance
    | :performance | :external | :general

  @type t :: %__MODULE__{
    id: String.t(),
    description: String.t(),
    category: category(),
    probability: float(),
    severity: float(),
    risk_score: float(),
    mitigation: String.t() | nil,
    source_fragment: String.t(),
    tags: [String.t()]
  }

  @spec new(String.t(), keyword()) :: t()
  def new(description, opts \\ []) do
    probability = Keyword.get(opts, :probability, 0.5)
    severity    = Keyword.get(opts, :severity, 0.5)

    %__MODULE__{
      id: "risk_#{:erlang.unique_integer([:positive, :monotonic])}",
      description: description,
      category: Keyword.get(opts, :category, :general),
      probability: probability,
      severity: severity,
      risk_score: Float.round(probability * severity, 4),
      mitigation: Keyword.get(opts, :mitigation),
      source_fragment: Keyword.get(opts, :source_fragment, description),
      tags: Keyword.get(opts, :tags, [])
    }
  end

  @doc "True if this risk warrants a security test contract."
  @spec requires_test?(t()) :: boolean()
  def requires_test?(%__MODULE__{risk_score: rs}), do: rs > 0.4

  @doc "True if this risk warrants Crucible adversarial simulation."
  @spec requires_adversarial?(t()) :: boolean()
  def requires_adversarial?(%__MODULE__{risk_score: rs}), do: rs > 0.6
end
