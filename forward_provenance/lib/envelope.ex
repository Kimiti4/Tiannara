defmodule TiannaraOS.Provenance.Envelope do
  @moduledoc """
  Immutable provenance envelope.

  One envelope per verifiable event. An envelope is created once, hash-bound at
  creation, and never mutated (immutable-envelope principle from the minimum
  model). `payload_hash` covers the canonical bytes of the FULL envelope body,
  so tampering with any field breaks the hash.
  """

  alias TiannaraOS.Provenance.Canon
  alias TiannaraOS.Provenance.Identity

  @envelope_schema "1.0.0"
  @event_types [
    "execution_started",
    "execution_ended",
    "result_produced",
    "metric_computed",
    "decision_recorded",
    "edge_created"
  ]

  @doc """
  Build a signed envelope.

  opts:
  * event_type (required)
  * producer (module string + version)
  * produced_at (ISO8601)
  * parent_envelope_id (nil allowed)
  * bindings map of identity_ref -> object (the identity objects this event
    depends on; each is hashed into bindings hash)
  * body (event-specific plain fields)
  """
  def build(opts) do
    event_type = Keyword.fetch!(opts, :event_type)

    unless event_type in @event_types do
      raise ArgumentError, "unknown event_type: #{inspect(event_type)}"
    end

    bindings = Keyword.get(opts, :bindings, %{})

    bindings_rendered =
      bindings
      |> Enum.sort_by(fn {k, _} -> to_string(k) end)
      |> Map.new(fn {k, v} -> {to_string(k), render_binding(v)} end)

    produced_at = Keyword.get(opts, :produced_at, DateTime.utc_now()) |> dt_to_iso()

    envelope = %{
      "schema_version" => @envelope_schema,
      "envelope_id" => "env_" <> Identity.uuid(),
      "event_type" => event_type,
      "parent_envelope_id" => Keyword.get(opts, :parent_envelope_id),
      "producer" => Keyword.get(opts, :producer),
      "produced_at" => produced_at,
      "bindings" => bindings_rendered,
      "verification_status" => Keyword.get(opts, :verification_status, "unverified"),
      "canonical_serialization_spec" => "tiannara-fp-canon-v1",
      "payload_hash" => nil,
      "body" => Keyword.get(opts, :body, %{})
    }

    %{envelope | "payload_hash" => Canon.sha256(Map.delete(envelope, "payload_hash"))}
  end

  defp dt_to_iso(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
  defp dt_to_iso(iso) when is_binary(iso), do: iso

  defp render_binding(%{"kind" => _, "object_hash" => _} = obj), do: obj
  defp render_binding(v) when is_map(v) or is_list(v), do: v
  defp render_binding(v) when is_binary(v), do: v
  defp render_binding(v), do: "#{v}"
end