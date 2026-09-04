defmodule Tiannara.Sentinel.EpistemicEvent do
  @moduledoc """
  A structured epistemic event — the unit of meaning published on the
  runtime EventBus and routed to the Omega subsystem (research, sandbox,
  certification, governance).

  Fields:
      type       — event kind (e.g. :anomaly_detected, :contradiction_detected,
                   :knowledge_updated, :improvement_proposed)
      payload    — event-specific data
      severity   — :low | :medium | :high
      confidence — 0.0..1.0
      evidence   — supporting evidence items
      source     — originating subsystem/component
      context    — free-form routing or provenance context

  Constitutional basis: "Every architectural decision should remain
  traceable" — events carry provenance from creation to consumption.
  """

  @enforce_keys [:type]
  defstruct [
    :id,
    :type,
    :payload,
    :severity,
    :confidence,
    :uncertainty,
    :source,
    :context,
    evidence: [],
    timestamp: nil
  ]

  @type t :: %__MODULE__{
    id: String.t() | nil,
    type: atom(),
    payload: map(),
    severity: :low | :medium | :high | nil,
    confidence: float() | nil,
    uncertainty: float() | nil,
    source: atom() | nil,
    context: map() | nil,
    evidence: list(),
    timestamp: DateTime.t() | nil
  }

  @doc "Build an event from a type and keyword options."
  def new(type, opts \\ []) do
    %__MODULE__{
      id: Keyword.get(opts, :id) || "evt-#{System.unique_integer([:positive])}",
      type: type,
      payload: Keyword.get(opts, :payload, %{}),
      severity: Keyword.get(opts, :severity),
      confidence: Keyword.get(opts, :confidence),
      uncertainty: Keyword.get(opts, :uncertainty),
      source: Keyword.get(opts, :source),
      context: Keyword.get(opts, :context),
      evidence: Keyword.get(opts, :evidence, []),
      timestamp: Keyword.get(opts, :timestamp) || DateTime.utc_now()
    }
  end
end