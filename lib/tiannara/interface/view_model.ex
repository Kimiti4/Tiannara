defmodule Tiannara.Interface.ViewModel do
  @moduledoc """
  Aggregates Tiannara's verification + knowledge state into one model any
  renderer (console, HTML, LiveView) can present to humans.

  Sources composed:
    * Discovery funnel       (Track B) — scientific activity + dispositions
    * Recovery attestation   (Track F) — is this evidence trustworthy?
    * Bottleneck observatory (Track G) — scaling-law bottlenecks
    * Knowledge store        (Track H) — promoted engineering knowledge

  Constitutional basis: Explainability, Observability, Human collaboration,
  and the augmentation clause (transparent reasoning for better-informed
  human decisions).
  """

  defstruct [:funnel, :manifest, :observatory, :knowledge, :generated_at]

  def build(opts \\ []) do
    %__MODULE__{
      funnel: Keyword.get(opts, :funnel),
      manifest: Keyword.get(opts, :manifest),
      observatory: Keyword.get(opts, :observatory),
      knowledge: Keyword.get(opts, :knowledge, []),
      generated_at: DateTime.utc_now()
    }
  end
end
