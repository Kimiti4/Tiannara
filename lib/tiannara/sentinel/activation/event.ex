defmodule Tiannara.Sentinel.Activation.Event do
  @moduledoc """
  Defines the Epistemic Event schema for the Sentinel Activation Layer.
  Converts raw observations into structured, meaningful state transitions.
  """

  @type category :: :runtime | :scientific | :constitutional | :security | :discovery
  @type severity :: :info | :warning | :critical

  @enforce_keys [:id, :timestamp, :source, :category, :severity, :observation]
  defstruct [
    :id,
    :timestamp,
    :source,
    :category,
    :severity,
    :observation,
    :interpretation,
    :confidence,
    evidence: [],
    causal_links: [],
    recommended_actions: [],
    requires_human: false,
    metadata: %{}
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          timestamp: DateTime.t(),
          source: atom(),
          category: category(),
          severity: severity(),
          observation: String.t(),
          interpretation: String.t() | nil,
          confidence: float() | nil,
          evidence: list(),
          causal_links: list(),
          recommended_actions: list(),
          requires_human: boolean(),
          metadata: map()
        }

  @doc """
  Creates a new Sentinel Event from raw observation data.
  """
  @spec new(map()) :: t()
  def new(attrs) do
    attrs = Map.put_new(attrs, :id, UUID.uuid4())
    attrs = Map.put_new(attrs, :timestamp, DateTime.utc_now())
    attrs = if attrs[:severity] == :critical do
      Map.put_new(attrs, :requires_human, true)
    else
      attrs
    end
    struct!(__MODULE__, attrs)
  end
end
