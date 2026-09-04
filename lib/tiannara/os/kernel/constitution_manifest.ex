defmodule TiannaraOS.Kernel.ConstitutionManifest do
  @moduledoc """
  ConstitutionManifest - Software Bill of Materials (SBOM) for the constitutional substrate.

  This manifest provides a complete, cryptographically verifiable inventory of all
  constitutional components at a specific point in time. It serves as the immutable
  identity of the constitution, enabling independent verification and replay.

  ## Constitutional Role

  The manifest ensures:
  1. Complete transparency - every component is listed with its hash
  2. Independent verification - anyone can recompute hashes from source
  3. Reproducible execution - manifests enable exact replay
  4. Drift detection - comparing manifests reveals changes
  5. Cryptographic attribution - statistical results bind to manifests

  ## Structure

  ```
  ConstitutionManifest
  ├── manifest_id: "MANIFEST-abc123..." (unique identifier)
  ├── constitution_id: "TOS-CONSTITUTION-0001" (immutable)
  ├── version: "13.5B.3" (evolves)
  ├── created_at: DateTime.t()
  ├── component_hashes:
  │   ├── definition_hash: SHA256(ScientificCapitalDefinition)
  │   ├── policy_hash: SHA256(ScientificCapitalPolicy)
  │   ├── ledger_hash: SHA256(ScientificCapitalLedger)
  │   ├── registry_hash: SHA256(ConstitutionalInvariantRegistry)
  │   ├── gate_hash: SHA256(StructuralValidationGate)
  │   ├── executor_hash: SHA256(ConstitutionalExecutor)
  │   └── resolver_hash: SHA256(MetricProvenanceResolver)
  ├── combined_hash: SHA256(all_component_hashes)
  └── metadata:
      ├── serializer_version: "1.0"
      ├── serialization_format: "canonical_json"
      └── hash_algorithm: "SHA256"
  ```

  ## Usage

      # Build current manifest
      manifest = ConstitutionManifest.build()

      # Verify manifest integrity
      :valid = ConstitutionManifest.verify(manifest)

      # Compare two manifests
      {:drift_detected, changes} = ConstitutionManifest.compare(manifest1, manifest2)

      # Serialize for storage
      json = ConstitutionManifest.to_json(manifest)

      # Deserialize from storage
      manifest = ConstitutionManifest.from_json(json)
  """

  alias TiannaraOS.ConstitutionSerializer

  @type t :: %__MODULE__{
          manifest_id: String.t(),
          constitution_id: String.t(),
          version: String.t(),
          created_at: DateTime.t(),
          component_hashes: component_hashes(),
          combined_hash: String.t(),
          metadata: metadata()
        }

  @type component_hashes :: %{
          definition_hash: String.t(),
          policy_hash: String.t(),
          ledger_hash: String.t(),
          registry_hash: String.t(),
          gate_hash: String.t(),
          executor_hash: String.t(),
          resolver_hash: String.t()
        }

  @type metadata :: %{
          serializer_version: String.t(),
          serialization_format: String.t(),
          hash_algorithm: String.t()
        }

  defstruct [
    :manifest_id,
    :constitution_id,
    :version,
    :created_at,
    :component_hashes,
    :combined_hash,
    :metadata
  ]

  @doc """
  Build current ConstitutionManifest from live system state.

  Computes content-derived hashes for all 7 constitutional components using
  ConstitutionSerializer's canonical serialization.

  ## Returns

  - ConstitutionManifest struct with all component hashes and unique manifest_id

  ## Examples

      iex> manifest = ConstitutionManifest.build()
      iex> manifest.constitution_id
      "TOS-CONSTITUTION-0001"
      iex> String.length(manifest.combined_hash)
      64
      iex> String.starts_with?(manifest.manifest_id, "MANIFEST-")
      true
  """
  @spec build() :: t()
  def build() do
    # Get all component hashes from serializer
    hashes_map = ConstitutionSerializer.build_manifest()

    # Extract individual hashes
    component_hashes = %{
      definition_hash: Map.fetch!(hashes_map, :definition_hash),
      policy_hash: Map.fetch!(hashes_map, :policy_hash),
      ledger_hash: Map.fetch!(hashes_map, :ledger_hash),
      registry_hash: Map.fetch!(hashes_map, :registry_hash),
      gate_hash: Map.fetch!(hashes_map, :gate_hash),
      executor_hash: Map.fetch!(hashes_map, :executor_hash),
      resolver_hash: Map.fetch!(hashes_map, :resolver_hash)
    }

    %__MODULE__{
      manifest_id: generate_manifest_id(),
      constitution_id: "TOS-CONSTITUTION-0001",
      version: "13.5B.3",
      created_at: DateTime.utc_now(),
      component_hashes: component_hashes,
      combined_hash: Map.fetch!(hashes_map, :combined_hash),
      metadata: %{
        serializer_version: "1.0",
        serialization_format: "canonical_json",
        hash_algorithm: "SHA256"
      }
    }
  end

  @doc """
  Verify manifest integrity by recomputing all hashes.

  Recomputes hashes from current system state and compares against manifest.

  ## Parameters

  - `manifest`: ConstitutionManifest to verify

  ## Returns

  - `:valid` if all hashes match
  - `{:invalid, [atom()]}` listing mismatched components

  ## Examples

      iex> manifest = ConstitutionManifest.build()
      iex> ConstitutionManifest.verify(manifest)
      :valid
  """
  @spec verify(t()) :: :valid | {:invalid, [atom()]}
  def verify(%__MODULE__{} = manifest) do
    # Rebuild manifest from current state
    current_manifest = build()

    # Compare component hashes
    mismatches =
      [:definition_hash, :policy_hash, :ledger_hash, :registry_hash, :gate_hash, :executor_hash, :resolver_hash]
      |> Enum.filter(fn key ->
        Map.get(current_manifest.component_hashes, key) != Map.get(manifest.component_hashes, key)
      end)

    if length(mismatches) == 0 do
      :valid
    else
      {:invalid, mismatches}
    end
  end

  @doc """
  Compare two manifests to detect drift.

  Identifies which components changed between two constitutional states.

  ## Parameters

  - `current`: Current ConstitutionManifest
  - `previous`: Previous ConstitutionManifest

  ## Returns

  - `:no_drift` if identical
  - `{:drift_detected, [atom()]}` listing changed components

  ## Examples

      iex> manifest1 = ConstitutionManifest.build()
      iex> manifest2 = ConstitutionManifest.build()
      iex> ConstitutionManifest.compare(manifest1, manifest2)
      :no_drift
  """
  @spec compare(t(), t()) :: :no_drift | {:drift_detected, [atom()]}
  def compare(%__MODULE__{} = current, %__MODULE__{} = previous) do
    changed_components =
      [:definition_hash, :policy_hash, :ledger_hash, :registry_hash, :gate_hash, :executor_hash, :resolver_hash]
      |> Enum.filter(fn key ->
        Map.get(current.component_hashes, key) != Map.get(previous.component_hashes, key)
      end)

    if length(changed_components) == 0 do
      :no_drift
    else
      {:drift_detected, changed_components}
    end
  end

  @doc """
  Classify drift severity based on changed components.

  Different components have different criticality levels:
  - Critical: Definition, Ledger, Registry, Executor
  - High: Policy, Gate
  - Medium: Resolver

  ## Parameters

  - `changed_components`: List of changed component keys

  ## Returns

  - `:critical`, `:high`, or `:medium`

  ## Examples

      iex> ConstitutionManifest.classify_drift_severity([:definition_hash])
      :critical
      iex> ConstitutionManifest.classify_drift_severity([:resolver_hash])
      :medium
  """
  @spec classify_drift_severity([atom()]) :: :critical | :high | :medium
  def classify_drift_severity(changed_components) do
    critical_components = [:definition_hash, :ledger_hash, :registry_hash, :executor_hash]
    high_components = [:policy_hash, :gate_hash]

    cond do
      Enum.any?(changed_components, &(&1 in critical_components)) -> :critical
      Enum.any?(changed_components, &(&1 in high_components)) -> :high
      true -> :medium
    end
  end

  @doc """
  Determine drift type based on changed components.

  Categorizes drift into semantic types for governance:
  - STRUCTURAL: Definition, Registry, Gate changes
  - POLICY: Policy coefficient/rule changes
  - EXECUTION: Executor parameter changes
  - RUNTIME: Ledger transaction changes
  - DOCUMENTATION: Resolver metadata changes
  - APPROVED_MIGRATION: Governance-approved version upgrade

  ## Parameters

  - `changed_components`: List of changed component keys

  ## Returns

  - Atom representing drift type

  ## Examples

      iex> ConstitutionManifest.classify_drift_type([:definition_hash])
      :structural
      iex> ConstitutionManifest.classify_drift_type([:policy_hash])
      :policy
  """
  @spec classify_drift_type([atom()]) ::
          :structural | :policy | :execution | :runtime | :documentation | :approved_migration
  def classify_drift_type(changed_components) do
    structural_components = [:definition_hash, :registry_hash, :gate_hash]
    policy_components = [:policy_hash]
    execution_components = [:executor_hash]
    runtime_components = [:ledger_hash]
    documentation_components = [:resolver_hash]

    cond do
      Enum.any?(changed_components, &(&1 in structural_components)) -> :structural
      Enum.any?(changed_components, &(&1 in policy_components)) -> :policy
      Enum.any?(changed_components, &(&1 in execution_components)) -> :execution
      Enum.any?(changed_components, &(&1 in runtime_components)) -> :runtime
      Enum.any?(changed_components, &(&1 in documentation_components)) -> :documentation
      true -> :approved_migration
    end
  end

  @doc """
  Serialize manifest to canonical JSON string.

  Uses ConstitutionSerializer for deterministic serialization.

  ## Parameters

  - `manifest`: ConstitutionManifest to serialize

  ## Returns

  - Canonical JSON string

  ## Examples

      iex> manifest = ConstitutionManifest.build()
      iex> json = ConstitutionManifest.to_json(manifest)
      iex> is_binary(json)
      true
  """
  @spec to_json(t()) :: String.t()
  def to_json(%__MODULE__{} = manifest) do
    data = %{
      manifest_id: manifest.manifest_id,
      constitution_id: manifest.constitution_id,
      version: manifest.version,
      created_at: DateTime.to_iso8601(manifest.created_at),
      component_hashes: manifest.component_hashes,
      combined_hash: manifest.combined_hash,
      metadata: manifest.metadata
    }

    Jason.encode!(data, pretty: false, sort_keys: true)
  end

  @doc """
  Deserialize manifest from canonical JSON string.

  ## Parameters

  - `json_string`: Canonical JSON string

  ## Returns

  - ConstitutionManifest struct

  ## Examples

      iex> manifest = ConstitutionManifest.build()
      iex> json = ConstitutionManifest.to_json(manifest)
      iex> deserialized = ConstitutionManifest.from_json(json)
      iex> deserialized.constitution_id == manifest.constitution_id
      true
  """
  @spec from_json(String.t()) :: t()
  def from_json(json_string) when is_binary(json_string) do
    data = Jason.decode!(json_string, keys: :atoms)

    %__MODULE__{
      manifest_id: data.manifest_id,
      constitution_id: data.constitution_id,
      version: data.version,
      created_at: case DateTime.from_iso8601(data.created_at) do
        {:ok, dt} -> dt
        _ -> DateTime.utc_now()
      end,
      component_hashes: data.component_hashes,
      combined_hash: data.combined_hash,
      metadata: data.metadata
    }
  end

  @doc """
  Format manifest as human-readable report.

  ## Parameters

  - `manifest`: ConstitutionManifest to format

  ## Returns

  - Formatted string suitable for display

  ## Examples

      iex> manifest = ConstitutionManifest.build()
      iex> report = ConstitutionManifest.format_report(manifest)
      iex> String.contains?(report, "Constitution ID:")
      true
  """
  @spec format_report(t()) :: String.t()
  def format_report(%__MODULE__{} = manifest) do
    """
    ╔══════════════════════════════════════════════════════════╗
    ║         CONSTITUTION MANIFEST REPORT                     ║
    ╚══════════════════════════════════════════════════════════╝

    Manifest ID:     #{manifest.manifest_id}
    Constitution ID: #{manifest.constitution_id}
    Version:         #{manifest.version}
    Created At:      #{DateTime.to_iso8601(manifest.created_at)}

    ┌────────────────────────────────────────────────────────┐
    │ Component Hashes                                       │
    ├────────────────────────────────────────────────────────┤
    │ Definition:  #{Map.get(manifest.component_hashes, :definition_hash) |> String.slice(0, 16)}...
    │ Policy:      #{Map.get(manifest.component_hashes, :policy_hash) |> String.slice(0, 16)}...
    │ Ledger:      #{Map.get(manifest.component_hashes, :ledger_hash) |> String.slice(0, 16)}...
    │ Registry:    #{Map.get(manifest.component_hashes, :registry_hash) |> String.slice(0, 16)}...
    │ Gate:        #{Map.get(manifest.component_hashes, :gate_hash) |> String.slice(0, 16)}...
    │ Executor:    #{Map.get(manifest.component_hashes, :executor_hash) |> String.slice(0, 16)}...
    │ Resolver:    #{Map.get(manifest.component_hashes, :resolver_hash) |> String.slice(0, 16)}...
    ├────────────────────────────────────────────────────────┤
    │ Combined Hash: #{manifest.combined_hash |> String.slice(0, 16)}...
    └────────────────────────────────────────────────────────┘

    Metadata:
      Serializer Version: #{Map.get(manifest.metadata, :serializer_version)}
      Serialization:      #{Map.get(manifest.metadata, :serialization_format)}
      Hash Algorithm:     #{Map.get(manifest.metadata, :hash_algorithm)}

    Verification Status: #{case verify(manifest) do
      :valid -> "✅ VALID"
      {:invalid, components} -> "❌ INVALID (#{inspect(components)})"
    end}
    """
  end

  # Private helpers

  @doc false
  @spec generate_manifest_id() :: String.t()
  defp generate_manifest_id() do
    "MANIFEST-#{:crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)}"
  end
end
