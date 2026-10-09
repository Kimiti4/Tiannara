defmodule TiannaraOS.Governance.Validation.EvidenceVerifierTest do
  use ExUnit.Case, async: true

  alias TiannaraOS.Governance.Validation.EvidenceVerifier

  @demo_key "tiannara-governance-validation-signing-key-2026"

  defp signed_artifact do
    timestamp = DateTime.utc_now()
    content = %{result: "candidate", evidence_class: "simulated"}
    content_hash = :crypto.hash(:sha256, :erlang.term_to_binary(content)) |> Base.encode16(case: :lower)
    campaign_id = "test-campaign"
    signature_data = "#{campaign_id}:#{timestamp}:#{content_hash}"
    signature = :crypto.mac(:hmac, :sha256, @demo_key, signature_data) |> Base.encode16(case: :lower)

    %{
      campaign_id: campaign_id,
      timestamp: timestamp,
      content: content,
      content_hash: content_hash,
      signature: signature,
      input_fingerprint: "input-fingerprint",
      output_fingerprint: "output-fingerprint"
    }
  end

  test "accepts content with a matching hash and HMAC" do
    assert :valid == EvidenceVerifier.verify_artifact(signed_artifact())
  end

  test "rejects changed content even when original hash and signature remain" do
    artifact = signed_artifact()
    tampered = put_in(artifact, [:content, :result], "validated")
    assert {:invalid, "content hash mismatch"} = EvidenceVerifier.verify_artifact(tampered)
  end

  test "rejects a modified signature" do
    artifact = signed_artifact()
    tampered = Map.put(artifact, :signature, String.duplicate("0", byte_size(artifact.signature)))
    assert {:invalid, "signature mismatch"} = EvidenceVerifier.verify_artifact(tampered)
  end

  test "does not claim replay succeeded when replay is unimplemented" do
    assert :failed == EvidenceVerifier.replay_and_verify(%{}, signed_artifact())
  end

  test "rejects incomplete fingerprints" do
    artifact = Map.put(signed_artifact(), :output_fingerprint, nil)
    assert {:invalid, "missing input/output fingerprint"} = EvidenceVerifier.verify_artifact(artifact)
  end
end
