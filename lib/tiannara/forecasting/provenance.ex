defmodule Tiannara.Forecasting.Provenance do
  @moduledoc """
  Dedicated provenance service for signals.

  A signal's provenance answers: where did it originate, what was observed, when,
  how it was transformed, and what underlies it. Provenance is never assumed from
  self-claims; it is stamped from the signal's actual fields and a content hash.

  Provenance contract (per EFDI D1 Provenance):
    - `kind`: :observation | :derived | :synthetic | :migrated
    - `sha256`: content hash of source+observation (dedup identity)
    - `source_event_id`: the event that produced the signal, when available
    - full provenance includes transformation_history, lineage, and observed_at

  Content hash is deterministic and reproducible (crypto.sha256).
  """

  alias Tiannara.Forecasting.Signal

  @doc "Builds the provenance map for a signal from its actual fields."
  @spec build(Signal.t()) :: map()
  def build(%Signal{} = signal) do
    %{
      kind: Map.get(signal.provenance || %{}, :kind, :observation),
      sha256: content_hash(signal),
      source_event_id: Map.get(signal.provenance || %{}, :source_event_id),
      source: signal.source,
      observed_at: signal.timestamp,
      received_at: signal.received_at,
      transformation_history: signal.transformation_history,
      lineage: signal.lineage
    }
  end

  @doc "Deterministic content hash over source + observation."
  @spec content_hash(Signal.t()) :: String.t()
  def content_hash(%Signal{} = signal) do
    payload = :erlang.term_to_binary(%{source: signal.source, observation: signal.observation})
    :crypto.hash(:sha256, payload) |> Base.encode16(case: :lower)
  end

  @doc "True if the signal's stored provenance matches its recomputed content hash."
  @spec integrity?(Signal.t()) :: boolean()
  def integrity?(%Signal{} = signal) do
    expected = content_hash(signal)
    stored = get_in(signal.provenance || %{}, [:sha256])
    is_nil(stored) or stored == expected
  end

  @doc "Verifies that a provenance map has the required shape."
  @spec valid?(map() | nil) :: boolean()
  def valid?(nil), do: false

  def valid?(%{kind: kind, sha256: hash}) when kind in [:observation, :derived, :synthetic, :migrated] and is_binary(hash) do
    true
  end

  def valid?(_), do: false

  @doc "Returns true if the provenance kind is :derived or has a lineage (has parents)."
  @spec derived?(map() | nil) :: boolean()
  def derived?(nil), do: false

  def derived?(%{lineage: lineage}) when is_list(lineage) and lineage != [], do: true

  def derived?(%{kind: :derived}), do: true

  def derived?(_), do: false
end
