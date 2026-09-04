defmodule TiannaraOS.Kernel.ConstitutionFingerprint do
  @moduledoc """
  ConstitutionFingerprint - Cryptographic digest derived exclusively from ConstitutionManifest.

  This module owns ONLY a single hash value: SHA256(SerializedManifest).
  It does NOT compute component hashes independently. It does NOT store individual hashes.
  All component hashes are owned exclusively by ConstitutionManifest.

  ## Constitutional Role

  ConstitutionFingerprint provides:
  1. Compact cryptographic identity for the entire constitution
  2. Quick comparison for drift detection (compare fingerprints, not full manifests)
  3. Certificate binding (certificates reference fingerprint)
  4. Immutable execution records (GenerationHistory stores fingerprint)

  ## Ownership Hierarchy

  ```
  ConstitutionIdentity (metadata only)
        │
        ▼
  ConstitutionManifest (owns all component hashes)
        │
        ▼
  ConstitutionFingerprint = SHA256(SerializedManifest)
        │
        ▼
  ConstitutionCertificate (references fingerprint)
  ```

  ## Critical Constraints

  ✅ DOES: Compute SHA256 of serialized manifest JSON
  ✅ DOES: Store single hash value
  ✅ DOES: Reference manifest_id for traceability

  ❌ DOES NOT: Compute component hashes independently
  ❌ DOES NOT: Store individual component hashes
  ❌ DOES NOT: Hash modules or BEAM metadata
  ❌ DOES NOT: Duplicate any data from Manifest

  ## Usage

      # Build manifest first
      manifest = ConstitutionManifest.build()

      # Derive fingerprint from manifest
      fingerprint = ConstitutionFingerprint.compute(manifest)

      # Compare fingerprints for drift detection
      if fingerprint.fingerprint != previous_fingerprint.fingerprint do
        raise "Constitutional Drift Detected"
      end

      # Store in certificate
      %ConstitutionCertificate{
        ...,
        fingerprint: fingerprint.fingerprint,
        manifest_id: manifest.manifest_id
      }
  """

  alias TiannaraOS.Kernel.ConstitutionManifest

  @type t :: %__MODULE__{
          fingerprint: String.t(),
          manifest_id: String.t(),
          computed_at: DateTime.t()
        }

  defstruct [
    :fingerprint,
    :manifest_id,
    :computed_at
  ]

  @doc """
  Compute ConstitutionFingerprint from a ConstitutionManifest.

  Fingerprint is derived EXCLUSIVELY from the serialized manifest JSON.
  No independent component hashing occurs here.

  ## Parameters

  - `manifest`: ConstitutionManifest to fingerprint

  ## Returns

  - ConstitutionFingerprint struct with single hash value

  ## Examples

      iex> manifest = ConstitutionManifest.build()
      iex> fingerprint = ConstitutionFingerprint.compute(manifest)
      iex> String.length(fingerprint.fingerprint)
      64
      iex> fingerprint.manifest_id == manifest.manifest_id
      true
  """
  @spec compute(ConstitutionManifest.t()) :: t()
  def compute(%ConstitutionManifest{} = manifest) do
    # Serialize manifest to canonical JSON
    serialized = ConstitutionManifest.to_json(manifest)

    # Compute SHA256 of entire serialized manifest
    fingerprint =
      :crypto.hash(:sha256, serialized)
      |> Base.encode16(case: :lower)

    %__MODULE__{
      fingerprint: fingerprint,
      manifest_id: manifest.manifest_id,
      computed_at: DateTime.utc_now()
    }
  end

  @doc """
  Verify that a fingerprint matches a manifest.

  Recomputes fingerprint from manifest and compares with stored fingerprint.

  ## Parameters

  - `fingerprint`: ConstitutionFingerprint to verify
  - `manifest`: ConstitutionManifest to verify against

  ## Returns

  - `:valid` if fingerprint matches manifest
  - `:invalid` if mismatch detected

  ## Examples

      iex> manifest = ConstitutionManifest.build()
      iex> fingerprint = ConstitutionFingerprint.compute(manifest)
      iex> ConstitutionFingerprint.verify(fingerprint, manifest)
      :valid
  """
  @spec verify(t(), ConstitutionManifest.t()) :: :valid | :invalid
  def verify(%__MODULE__{} = fingerprint, %ConstitutionManifest{} = manifest) do
    expected = compute(manifest)

    if fingerprint.fingerprint == expected.fingerprint and
       fingerprint.manifest_id == expected.manifest_id do
      :valid
    else
      :invalid
    end
  end

  @doc """
  Compare two fingerprints for drift detection.

  ## Parameters

  - `current`: Current ConstitutionFingerprint
  - `previous`: Previous ConstitutionFingerprint

  ## Returns

  - `:no_drift` if identical
  - `:drift_detected` if different

  ## Examples

      iex> manifest = ConstitutionManifest.build()
      iex> fp1 = ConstitutionFingerprint.compute(manifest)
      iex> fp2 = ConstitutionFingerprint.compute(manifest)
      iex> ConstitutionFingerprint.compare(fp1, fp2)
      :no_drift
  """
  @spec compare(t(), t()) :: :no_drift | :drift_detected
  def compare(%__MODULE__{} = current, %__MODULE__{} = previous) do
    if current.fingerprint == previous.fingerprint do
      :no_drift
    else
      :drift_detected
    end
  end

  @doc """
  Format fingerprint as human-readable string.

  ## Parameters

  - `fingerprint`: ConstitutionFingerprint to format

  ## Returns

  - Formatted string

  ## Examples

      iex> manifest = ConstitutionManifest.build()
      iex> fp = ConstitutionFingerprint.compute(manifest)
      iex> str = ConstitutionFingerprint.format(fp)
      iex> String.contains?(str, fp.fingerprint)
      true
  """
  @spec format(t()) :: String.t()
  def format(%__MODULE__{} = fingerprint) do
    """
    ConstitutionFingerprint:
      Fingerprint: #{fingerprint.fingerprint}
      Manifest ID: #{fingerprint.manifest_id}
      Computed At: #{DateTime.to_iso8601(fingerprint.computed_at)}
    """
  end

  @doc """
  Serialize fingerprint to canonical JSON.

  ## Parameters

  - `fingerprint`: ConstitutionFingerprint to serialize

  ## Returns

  - Canonical JSON string
  """
  @spec to_json(t()) :: String.t()
  def to_json(%__MODULE__{} = fingerprint) do
    data = %{
      fingerprint: fingerprint.fingerprint,
      manifest_id: fingerprint.manifest_id,
      computed_at: DateTime.to_iso8601(fingerprint.computed_at)
    }

    Jason.encode!(data, pretty: false, sort_keys: true)
  end

  @doc """
  Deserialize fingerprint from canonical JSON.

  ## Parameters

  - `json_string`: Canonical JSON string

  ## Returns

  - ConstitutionFingerprint struct
  """
  @spec from_json(String.t()) :: t()
  def from_json(json_string) when is_binary(json_string) do
    data = Jason.decode!(json_string, keys: :atoms)

    %__MODULE__{
      fingerprint: data.fingerprint,
      manifest_id: data.manifest_id,
      computed_at: case DateTime.from_iso8601(data.computed_at) do
        {:ok, dt} -> dt
        _ -> DateTime.utc_now()
      end
    }
  end
end
