defmodule TiannaraOS.Provenance.Certificate do
  @moduledoc """
  Certificate identity and decision envelope.

  A certificate binds a VALIDATED set of provenance edges to a decision. It
  carries no inline metric values (avoids the orphaned-FINAL-fingerprint
  failure where a certificate hash could not be recomputed), only the identity
  object hashes and envelope ids of the evidence it certifies.

  Fixes: certificate_hash pointing at nothing (test I), decision value drift,
  "certificate references emotion, not measurement" (the historical gap),
  capacity/verification-status becoming the certificate.
  """

  alias TiannaraOS.Provenance.Envelope
  alias TiannaraOS.Provenance.Identity

  def issue(opts) do
    decision = Keyword.fetch!(opts, :decision)        # "certified" | "failed" | "contested"
    reason = Keyword.fetch!(opts, :reason)
    authority = Keyword.fetch!(opts, :authority)      # e.g. "independent_verifier_v1"
    evidence = Keyword.fetch!(opts, :evidence)        # map of identity/envelope refs
    producer = Keyword.get(opts, :producer)
    parent_envelope_id = Keyword.get(opts, :parent_envelope_id)

    certificate_id = "cert_" <> String.replace(Identity.uuid(), "-", "")

    body = %{
      "certificate_id" => certificate_id,
      "decision" => decision,
      "reason" => reason,
      "authority" => authority,
      "validated_edges" => Keyword.get(opts, :validated_edges, []),
      "issuance_spec" => "tiannara-fp-cert-v1"
    }

    envelope = Envelope.build(
      event_type: "decision_recorded",
      producer: producer,
      parent_envelope_id: parent_envelope_id,
      body: body,
      bindings: evidence
    )

    %{
      "certificate_id" => certificate_id,
      "decision" => decision,
      "authority" => authority,
      "envelope" => envelope,
      "evidence_bindings" => evidence,
      "certificate_hash" => envelope["payload_hash"]
    }
  end
end