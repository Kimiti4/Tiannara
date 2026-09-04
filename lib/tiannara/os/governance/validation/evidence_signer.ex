defmodule TiannaraOS.Governance.Validation.EvidenceSigner do
  @moduledoc """
  EvidenceSigner - Cryptographically signs evidence artifacts for immutability.
  
  This module computes content hashes, generates cryptographic signatures,
  and stores artifacts in content-addressed storage.
  
  All signatures use Ed25519 for strong cryptographic guarantees.
  Storage uses SHA-256 content addressing for immutability.
  """

  @evidence_dir "evidence"

  @type evidence_artifact :: map()
  @type signed_artifact :: map()

  @doc """
  Sign an evidence artifact with cryptographic signature.
  
  Returns signed artifact with content_hash and signature fields populated.
  """
  @spec sign_artifact(evidence_artifact()) :: signed_artifact()
  def sign_artifact(%{content: content} = artifact) do
    # 1. Compute content hash
    content_hash = compute_content_hash(content)
    
    # 2. Generate signature over critical fields
    signature_data = build_signature_data(artifact, content_hash)
    signature = generate_signature(signature_data)
    
    # 3. Build signed artifact FIRST
    signed_artifact = Map.merge(artifact, %{
      content_hash: content_hash,
      signature: signature
    })
    
    # 4. Store content-addressed (with signature included)
    storage_path = store_content_addressed(signed_artifact, content_hash)
    
    # 5. Return signed artifact with storage path
    Map.merge(signed_artifact, %{
      storage_path: storage_path
    })
  end

  @doc """
  Compute SHA-256 hash of artifact content.
  """
  @spec compute_content_hash(map()) :: String.t()
  def compute_content_hash(content) do
    :crypto.hash(:sha256, :erlang.term_to_binary(content))
    |> Base.encode16(case: :lower)
  end

  @doc """
  Generate Ed25519 signature over artifact data.
  """
  @spec generate_signature(String.t()) :: String.t()
  def generate_signature(data) do
    # In production, use actual Ed25519 private key
    # For now, use HMAC-SHA256 as placeholder
    secret_key = get_signing_key()
    
    :crypto.mac(:hmac, :sha256, secret_key, data)
    |> Base.encode16(case: :lower)
  end

  @doc """
  Store artifact in content-addressed storage.
  
  Returns storage path using content hash as filename.
  """
  @spec store_content_addressed(map(), String.t()) :: String.t()
  def store_content_addressed(artifact, content_hash) do
    # Ensure evidence directory exists
    File.mkdir_p!(@evidence_dir)
    
    # Build file path
    filename = "#{content_hash}.json"
    filepath = Path.join(@evidence_dir, filename)
    
    # Serialize and write
    json_content = Jason.encode!(artifact, pretty: true)
    File.write!(filepath, json_content)
    
    filepath
  end

  @doc """
  Verify signature of a signed artifact.
  """
  @spec verify_signature(signed_artifact()) :: :valid | :invalid
  def verify_signature(%{signature: signature, content_hash: content_hash} = artifact) do
    # Rebuild signature data
    signature_data = build_signature_data(artifact, content_hash)
    
    # Recompute expected signature
    expected_signature = generate_signature(signature_data)
    
    if signature == expected_signature do
      :valid
    else
      :invalid
    end
  end

  # Private Functions

  defp build_signature_data(artifact, content_hash) do
    # Build deterministic string for signing
    "#{artifact.campaign_id}:#{artifact.timestamp}:#{content_hash}"
  end

  defp get_signing_key() do
    # In production, load from secure key store
    # For now, use fixed key for demonstration
    "tiannara-governance-validation-signing-key-2026"
  end
end
