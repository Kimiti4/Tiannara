defmodule TiannaraOS.Governance.Validation.EvidenceVerifier do
  @moduledoc """
  Independently verifies evidence artifact integrity.

  Important: the current EvidenceSigner uses a fixed demonstration HMAC key.
  This verifier checks the HMAC mathematically, but that key is not suitable
  for production signer authentication. Do not treat :valid as a trusted
  production certificate until key management is replaced with a configured
  trust store and asymmetric signatures.
  """

  @type evidence_artifact :: map()
  @type verification_result :: :valid | {:invalid, String.t()}

  # Kept byte-for-byte compatible with EvidenceSigner while that module still
  # uses its documented demonstration-only key.
  @demo_signing_key "tiannara-governance-validation-signing-key-2026"

  @spec verify_artifact(evidence_artifact()) :: verification_result()
  def verify_artifact(artifact) when is_map(artifact) do
    with :valid <- verify_hash(artifact),
         :valid <- verify_signature(artifact),
         :match <- verify_fingerprint(artifact) do
      :valid
    else
      {:invalid, reason} -> {:invalid, reason}
      :mismatch -> {:invalid, "missing input/output fingerprint"}
      _ -> {:invalid, "malformed evidence artifact"}
    end
  end

  def verify_artifact(_), do: {:invalid, "evidence artifact must be a map"}

  @spec verify_signature(evidence_artifact()) :: verification_result()
  def verify_signature(%{
        signature: signature,
        content_hash: content_hash,
        campaign_id: campaign_id,
        timestamp: timestamp
      })
      when is_binary(signature) and byte_size(signature) > 0 and is_binary(content_hash) do
    signature_data = "#{campaign_id}:#{timestamp}:#{content_hash}"

    expected =
      :crypto.mac(:hmac, :sha256, @demo_signing_key, signature_data)
      |> Base.encode16(case: :lower)

    if secure_compare(signature, expected) do
      :valid
    else
      {:invalid, "signature mismatch"}
    end
  rescue
    _ -> {:invalid, "malformed signature fields"}
  end

  def verify_signature(_), do: {:invalid, "missing signature or signed fields"}

  @spec verify_hash(evidence_artifact()) :: verification_result()
  def verify_hash(%{content_hash: stored_hash, content: content})
      when is_binary(stored_hash) and is_map(content) do
    computed_hash =
      :crypto.hash(:sha256, :erlang.term_to_binary(content))
      |> Base.encode16(case: :lower)

    if secure_compare(String.downcase(stored_hash), computed_hash) do
      :valid
    else
      {:invalid, "content hash mismatch"}
    end
  end

  def verify_hash(_), do: {:invalid, "missing content or content hash"}

  @spec verify_fingerprint(evidence_artifact()) :: :match | :mismatch
  def verify_fingerprint(%{input_fingerprint: input_fp, output_fingerprint: output_fp}) do
    if is_binary(input_fp) and byte_size(input_fp) > 0 and
         is_binary(output_fp) and byte_size(output_fp) > 0 do
      :match
    else
      :mismatch
    end
  end

  def verify_fingerprint(_), do: :mismatch

  @doc """
  Campaign replay is not implemented by this verifier. It must never return
  :verified until the campaign is actually executed in an isolated context.
  """
  @spec replay_and_verify(map(), evidence_artifact()) :: :verified | :failed
  def replay_and_verify(_campaign_spec, _evidence), do: :failed

  defp secure_compare(left, right)
       when is_binary(left) and is_binary(right) and byte_size(left) == byte_size(right) do
    :crypto.hash_equals(left, right)
  rescue
    _ -> false
  end

  defp secure_compare(_, _), do: false
end
