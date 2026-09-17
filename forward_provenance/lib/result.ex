defmodule TiannaraOS.Provenance.Result do
  @moduledoc """
  Result identity with explicit DERIVED_FROM execution edge and payload hash
  over the raw result bytes under a named canonical spec.
  """

  alias TiannaraOS.Provenance.Canon
  alias TiannaraOS.Provenance.Envelope
  alias TiannaraOS.Provenance.Identity

  def produce(opts) do
    execution = Keyword.fetch!(opts, :execution)
    result_bytes = Keyword.fetch!(opts, :result_bytes)   # the payload, byte-for-byte
    result_id = Keyword.get(opts, :result_id, "result_" <> String.replace(Identity.uuid(), "-", ""))
    producer = Keyword.get(opts, :producer)
    created_at = Keyword.get(opts, :created_at, DateTime.utc_now())

    payload_hash = Canon.sha256_bytes(result_bytes)

    envelope = Envelope.build(
      event_type: "result_produced",
      producer: producer,
      parent_envelope_id: execution["ended"]["envelope_id"],
      body: %{
        "result_id" => result_id,
        "execution_id" => execution["execution_id"],
        "payload_hash" => payload_hash,
        "payload_bytes_sha256" => payload_hash,
        "canonical_serialization_spec" => "tiannara-fp-canon-v1",
        "created_at" => DateTime.to_iso8601(created_at)
      }
    )

    %{
      "result_id" => result_id,
      "execution_id" => execution["execution_id"],
      "payload_hash" => payload_hash,
      "result_bytes" => result_bytes,
      "parent_envelope_id" => execution["ended"]["envelope_id"],
      "envelope" => envelope
    }
  end
end