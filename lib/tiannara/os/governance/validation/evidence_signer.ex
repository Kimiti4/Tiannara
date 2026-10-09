defmodule TiannaraOS.Governance.Validation.EvidenceSigner do
  @moduledoc """
  EvidenceSigner - Development-stage evidence integrity helper.

  Content is hashed with SHA-256 and the signature field currently contains
  an HMAC-SHA256 generated with a hard-coded demonstration key. This is NOT
  Ed25519, does not provide public-key verification, and is NOT safe for
  production trust decisions. The fixed key must be replaced with managed
  secrets and a configured signing/trust policy before certification use.

  Storage uses SHA-256-derived filenames for content addressing. A content
  hash alone does not prove who produced an artifact or whether it is true.
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
    # Demonstration-only HMAC. The fixed key below is not production-safe;
    # do not use this output as a production identity or certification proof.
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
    # Fixed demonstration key retained only for compatibility with existing
    # development artifacts. Replace with managed key storage before release.
    "tiannara-governance-validation-signing-key-2026"
  end
end
