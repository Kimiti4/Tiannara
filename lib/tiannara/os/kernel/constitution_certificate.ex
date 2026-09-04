defmodule TiannaraOS.Kernel.ConstitutionCertificate do
  @moduledoc """
  ConstitutionCertificate - Cryptographic attestation for every execution.

  This certificate serves as Tiannara's equivalent of a signed build artifact,
  providing complete cryptographic attribution for each simulation run. It binds
  the execution to a specific constitutional manifest and verifies all integrity
  checks passed.

  ## Constitutional Role

  The certificate ensures:
  1. Cryptographic attribution - results bind to exact constitution
  2. Independent verification - anyone can verify certificate validity
  3. Scientific reproducibility - certificates enable exact replay
  4. Audit trail - immutable record of execution state
  5. Trust establishment - certificates prove constitutional compliance

  ## Structure

  ```
  ConstitutionCertificate
  ├── certificate_id: UUID (unique per execution)
  ├── execution_id: String.t() (from ConstitutionalExecutor)
  ├── generation_count: integer()
  ├── constitution_id: "TOS-CONSTITUTION-0001" (immutable)
  ├── manifest: ConstitutionManifest.t() (complete SBOM)
  ├── combined_hash: String.t() (manifest's combined hash)
  ├── validation_status: :passed | :failed
  ├── replay_status: :verified | :not_run | :failed
  ├── watchdog_status: :monitoring | :completed | :drift_detected
  ├── invariant_status: :all_passed | :some_failed | :not_checked
  ├── drift_journal_entries: [ConstitutionalDriftJournal.entry()]
  ├── started_at: DateTime.t()
  ├── completed_at: DateTime.t()
  ├── certificate_hash: SHA256(entire certificate)
  └── metadata:
      ├── serializer_version: "1.0"
      ├── certification_level: "full" | "partial"
      └── independent_verification: true | false
  ```

  ## Usage

      # Generate certificate after execution
      cert = ConstitutionCertificate.generate(
        execution_id: "exec-123",
        generation_count: 5,
        manifest: manifest,
        validation_status: :passed,
        replay_status: :verified,
        watchdog_status: :completed,
        invariant_status: :all_passed
      )

      # Verify certificate integrity
      :valid = ConstitutionCertificate.verify(cert)

      # Serialize for storage
      json = ConstitutionCertificate.to_json(cert)

      # Display certificate
      IO.puts(ConstitutionCertificate.format_report(cert))
  """

  alias TiannaraOS.Kernel.ConstitutionManifest

  @type t :: %__MODULE__{
          certificate_id: String.t(),
          execution_id: String.t(),
          generation_count: integer(),
          constitution_id: String.t(),
          manifest: ConstitutionManifest.t(),
          combined_hash: String.t(),
          validation_status: validation_status(),
          replay_status: replay_status(),
          watchdog_status: watchdog_status(),
          invariant_status: invariant_status(),
          drift_journal_entries: list(),
          started_at: DateTime.t(),
          completed_at: DateTime.t(),
          certificate_hash: String.t(),
          metadata: metadata()
        }

  @type validation_status :: :passed | :failed
  @type replay_status :: :verified | :not_run | :failed
  @type watchdog_status :: :monitoring | :completed | :drift_detected
  @type invariant_status :: :all_passed | :some_failed | :not_checked

  @type metadata :: %{
          serializer_version: String.t(),
          certification_level: String.t(),
          independent_verification: boolean()
        }

  defstruct [
    :certificate_id,
    :execution_id,
    :generation_count,
    :constitution_id,
    :manifest,
    :combined_hash,
    :fingerprint,
    :validation_status,
    :replay_status,
    :watchdog_status,
    :invariant_status,
    :drift_journal_entries,
    :started_at,
    :completed_at,
    :certificate_hash,
    :metadata
  ]

  @doc """
  Generate ConstitutionCertificate for completed execution.

  Creates a complete cryptographic attestation binding the execution to its
  constitutional manifest and recording all verification statuses.

  ## Parameters

  - `opts`: Keyword list with execution details
    - `:execution_id` (required): Execution identifier
    - `:generation_count` (required): Current generation count
    - `:manifest` (required): ConstitutionManifest used
    - `:validation_status` (required): Structural validation result
    - `:replay_status` (required): Replay verification result
    - `:watchdog_status` (required): Watchdog monitoring result
    - `:invariant_status` (required): Invariant check result
    - `:drift_journal_entries` (optional): Drift journal entries during execution
    - `:started_at` (optional): Execution start time
    - `:completed_at` (optional): Execution completion time

  ## Returns

  - ConstitutionCertificate struct with certificate_hash computed

  ## Examples

      iex> manifest = ConstitutionManifest.build()
      iex> cert = ConstitutionCertificate.generate(
      ...>   execution_id: "exec-123",
      ...>   generation_count: 5,
      ...>   manifest: manifest,
      ...>   validation_status: :passed,
      ...>   replay_status: :verified,
      ...>   watchdog_status: :completed,
      ...>   invariant_status: :all_passed
      ...> )
      iex> String.length(cert.certificate_hash)
      64
  """
  @spec generate(keyword()) :: t()
  def generate(opts) do
    execution_id = Keyword.fetch!(opts, :execution_id)
    generation_count = Keyword.fetch!(opts, :generation_count)
    manifest = Keyword.fetch!(opts, :manifest)
    validation_status = Keyword.fetch!(opts, :validation_status)
    replay_status = Keyword.fetch!(opts, :replay_status)
    watchdog_status = Keyword.fetch!(opts, :watchdog_status)
    invariant_status = Keyword.fetch!(opts, :invariant_status)

    drift_journal_entries = Keyword.get(opts, :drift_journal_entries, [])
    started_at = Keyword.get(opts, :started_at, DateTime.utc_now())
    completed_at = Keyword.get(opts, :completed_at, DateTime.utc_now())
    fingerprint = Keyword.get(opts, :fingerprint, nil)

    certificate = %__MODULE__{
      certificate_id: generate_certificate_id(),
      execution_id: execution_id,
      generation_count: generation_count,
      constitution_id: manifest.constitution_id,
      manifest: manifest,
      combined_hash: manifest.combined_hash,
      fingerprint: fingerprint,
      validation_status: validation_status,
      replay_status: replay_status,
      watchdog_status: watchdog_status,
      invariant_status: invariant_status,
      drift_journal_entries: drift_journal_entries,
      started_at: started_at,
      completed_at: completed_at,
      certificate_hash: "", # Will be computed after struct creation
      metadata: %{
        serializer_version: "1.0",
        certification_level: determine_certification_level(validation_status, replay_status, watchdog_status, invariant_status),
        independent_verification: true
      }
    }

    # Compute certificate hash (hash of entire certificate excluding certificate_hash field)
    cert_hash = compute_certificate_hash(certificate)
    %{certificate | certificate_hash: cert_hash}
  end

  @doc """
  Verify certificate integrity by recomputing certificate hash.

  Recomputes the hash from certificate data and compares against stored hash.

  ## Parameters

  - `certificate`: ConstitutionCertificate to verify

  ## Returns

  - `:valid` if hash matches
  - `:invalid` if hash mismatch detected

  ## Examples

      iex> manifest = ConstitutionManifest.build()
      iex> cert = ConstitutionCertificate.generate(...)
      iex> ConstitutionCertificate.verify(cert)
      :valid
  """
  @spec verify(t()) :: :valid | :invalid
  def verify(%__MODULE__{} = certificate) do
    # Recompute hash without certificate_hash field
    expected_hash = compute_certificate_hash(certificate)

    if expected_hash == certificate.certificate_hash do
      :valid
    else
      :invalid
    end
  end

  @doc """
  Verify certificate against current system state.

  Checks that the manifest in the certificate still matches current system state.

  ## Parameters

  - `certificate`: ConstitutionCertificate to verify

  ## Returns

  - `:current` if manifest matches current state
  - `:outdated` if system has drifted since certificate was issued

  ## Examples

      iex> manifest = ConstitutionManifest.build()
      iex> cert = ConstitutionCertificate.generate(...)
      iex> ConstitutionCertificate.verify_against_system(cert)
      :current
  """
  @spec verify_against_system(t()) :: :current | :outdated
  def verify_against_system(%__MODULE__{} = certificate) do
    case ConstitutionManifest.verify(certificate.manifest) do
      :valid -> :current
      {:invalid, _components} -> :outdated
    end
  end

  @doc """
  Serialize certificate to canonical JSON string.

  Uses ConstitutionSerializer for deterministic serialization.

  ## Parameters

  - `certificate`: ConstitutionCertificate to serialize

  ## Returns

  - Canonical JSON string

  ## Examples

      iex> manifest = ConstitutionManifest.build()
      iex> cert = ConstitutionCertificate.generate(...)
      iex> json = ConstitutionCertificate.to_json(cert)
      iex> is_binary(json)
      true
  """
  @spec to_json(t()) :: String.t()
  def to_json(%__MODULE__{} = certificate) do
    data = %{
      certificate_id: certificate.certificate_id,
      execution_id: certificate.execution_id,
      generation_count: certificate.generation_count,
      constitution_id: certificate.constitution_id,
      manifest: serialize_manifest(certificate.manifest),
      combined_hash: certificate.combined_hash,
      validation_status: Atom.to_string(certificate.validation_status),
      replay_status: Atom.to_string(certificate.replay_status),
      watchdog_status: Atom.to_string(certificate.watchdog_status),
      invariant_status: Atom.to_string(certificate.invariant_status),
      drift_journal_entries: Enum.map(certificate.drift_journal_entries, &serialize_drift_entry/1),
      started_at: DateTime.to_iso8601(certificate.started_at),
      completed_at: DateTime.to_iso8601(certificate.completed_at),
      certificate_hash: certificate.certificate_hash,
      metadata: certificate.metadata
    }

    Jason.encode!(data, pretty: false, sort_keys: true)
  end

  @doc """
  Deserialize certificate from canonical JSON string.

  ## Parameters

  - `json_string`: Canonical JSON string

  ## Returns

  - ConstitutionCertificate struct

  ## Examples

      iex> manifest = ConstitutionManifest.build()
      iex> cert = ConstitutionCertificate.generate(...)
      iex> json = ConstitutionCertificate.to_json(cert)
      iex> deserialized = ConstitutionCertificate.from_json(json)
      iex> deserialized.certificate_id == cert.certificate_id
      true
  """
  @spec from_json(String.t()) :: t()
  def from_json(json_string) when is_binary(json_string) do
    data = Jason.decode!(json_string, keys: :atoms)

    %__MODULE__{
      certificate_id: data.certificate_id,
      execution_id: data.execution_id,
      generation_count: data.generation_count,
      constitution_id: data.constitution_id,
      manifest: deserialize_manifest(data.manifest),
      combined_hash: data.combined_hash,
      validation_status: String.to_atom(data.validation_status),
      replay_status: String.to_atom(data.replay_status),
      watchdog_status: String.to_atom(data.watchdog_status),
      invariant_status: String.to_atom(data.invariant_status),
      drift_journal_entries: Enum.map(data.drift_journal_entries || [], &deserialize_drift_entry/1),
      started_at: case DateTime.from_iso8601(data.started_at) do
        {:ok, dt} -> dt
        _ -> DateTime.utc_now()
      end,
      completed_at: case DateTime.from_iso8601(data.completed_at) do
        {:ok, dt} -> dt
        _ -> DateTime.utc_now()
      end,
      certificate_hash: data.certificate_hash,
      metadata: data.metadata
    }
  end

  @doc """
  Format certificate as human-readable report.

  ## Parameters

  - `certificate`: ConstitutionCertificate to format

  ## Returns

  - Formatted string suitable for display

  ## Examples

      iex> manifest = ConstitutionManifest.build()
      iex> cert = ConstitutionCertificate.generate(...)
      iex> report = ConstitutionCertificate.format_report(cert)
      iex> String.contains?(report, "CONSTITUTION CERTIFICATE")
      true
  """
  @spec format_report(t()) :: String.t()
  def format_report(%__MODULE__{} = certificate) do
    """
    ╔══════════════════════════════════════════════════════════╗
    ║         CONSTITUTION CERTIFICATE                         ║
    ╚══════════════════════════════════════════════════════════╝

    Certificate ID:    #{certificate.certificate_id}
    Execution ID:      #{certificate.execution_id}
    Generation Count:  #{certificate.generation_count}
    Constitution ID:   #{certificate.constitution_id}

    ┌────────────────────────────────────────────────────────┐
    │ Manifest Hash                                          │
    ├────────────────────────────────────────────────────────┤
    │ Combined Hash: #{certificate.combined_hash |> String.slice(0, 16)}...
    └────────────────────────────────────────────────────────┘

    Verification Status:
      ✅ Structural Validation: #{format_status(certificate.validation_status)}
      ✅ Replay Verification:   #{format_status(certificate.replay_status)}
      ✅ Watchdog Monitoring:   #{format_status(certificate.watchdog_status)}
      ✅ Invariant Checks:      #{format_status(certificate.invariant_status)}

    Timing:
      Started:    #{DateTime.to_iso8601(certificate.started_at)}
      Completed:  #{DateTime.to_iso8601(certificate.completed_at)}
      Duration:   #{compute_duration(certificate.started_at, certificate.completed_at)}

    Drift Journal Entries: #{length(certificate.drift_journal_entries)}

    Certificate Hash: #{certificate.certificate_hash |> String.slice(0, 16)}...

    Metadata:
      Serializer Version:       #{Map.get(certificate.metadata, :serializer_version)}
      Certification Level:      #{Map.get(certificate.metadata, :certification_level)}
      Independent Verification: #{Map.get(certificate.metadata, :independent_verification)}

    Overall Status: #{format_overall_status(certificate)}
    """
  end

  # Private helpers

  @doc false
  @spec generate_certificate_id() :: String.t()
  defp generate_certificate_id() do
    "CERT-#{:crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)}"
  end

  @doc false
  @spec compute_certificate_hash(t()) :: String.t()
  defp compute_certificate_hash(%__MODULE__{} = certificate) do
    # Create data structure without certificate_hash field
    cert_data = %{
      certificate_id: certificate.certificate_id,
      execution_id: certificate.execution_id,
      generation_count: certificate.generation_count,
      constitution_id: certificate.constitution_id,
      manifest_combined_hash: certificate.combined_hash,
      validation_status: certificate.validation_status,
      replay_status: certificate.replay_status,
      watchdog_status: certificate.watchdog_status,
      invariant_status: certificate.invariant_status,
      drift_count: length(certificate.drift_journal_entries),
      started_at: DateTime.to_iso8601(certificate.started_at),
      completed_at: DateTime.to_iso8601(certificate.completed_at),
      metadata: certificate.metadata
    }

    serialized = Jason.encode!(cert_data, sort_keys: true)

    :crypto.hash(:sha256, serialized)
    |> Base.encode16(case: :lower)
  end

  @doc false
  @spec determine_certification_level(validation_status(), replay_status(), watchdog_status(), invariant_status()) :: String.t()
  defp determine_certification_level(:passed, :verified, :completed, :all_passed), do: "full"
  defp determine_certification_level(:passed, _, _, _), do: "partial"
  defp determine_certification_level(_, _, _, _), do: "minimal"

  @doc false
  @spec serialize_manifest(ConstitutionManifest.t()) :: map()
  defp serialize_manifest(%ConstitutionManifest{} = manifest) do
    %{
      constitution_id: manifest.constitution_id,
      version: manifest.version,
      created_at: DateTime.to_iso8601(manifest.created_at),
      component_hashes: manifest.component_hashes,
      combined_hash: manifest.combined_hash,
      metadata: manifest.metadata
    }
  end

  @doc false
  @spec deserialize_manifest(map()) :: ConstitutionManifest.t()
  defp deserialize_manifest(data) do
    %ConstitutionManifest{
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

  @doc false
  @spec serialize_drift_entry(map()) :: map()
  defp serialize_drift_entry(entry) do
    # Simplified drift entry serialization
    %{
      execution_id: Map.get(entry, :execution_id),
      timestamp: Map.get(entry, :timestamp) |> DateTime.to_iso8601(),
      drift_status: Map.get(entry, :drift_status),
      approved: Map.get(entry, :approved)
    }
  end

  @doc false
  @spec deserialize_drift_entry(map()) :: map()
  defp deserialize_drift_entry(data) do
    %{
      execution_id: data.execution_id,
      timestamp: case DateTime.from_iso8601(data.timestamp) do
        {:ok, dt} -> dt
        _ -> DateTime.utc_now()
      end,
      drift_status: String.to_atom(data.drift_status),
      approved: data.approved
    }
  end

  @doc false
  @spec format_status(atom()) :: String.t()
  defp format_status(:passed), do: "PASSED"
  defp format_status(:failed), do: "FAILED"
  defp format_status(:verified), do: "VERIFIED"
  defp format_status(:not_run), do: "NOT RUN"
  defp format_status(:completed), do: "COMPLETED"
  defp format_status(:monitoring), do: "MONITORING"
  defp format_status(:drift_detected), do: "DRIFT DETECTED"
  defp format_status(:all_passed), do: "ALL PASSED"
  defp format_status(:some_failed), do: "SOME FAILED"
  defp format_status(:not_checked), do: "NOT CHECKED"
  defp format_status(other), do: Atom.to_string(other) |> String.upcase()

  @doc false
  @spec compute_duration(DateTime.t(), DateTime.t()) :: String.t()
  defp compute_duration(started_at, completed_at) do
    diff_ms = DateTime.diff(completed_at, started_at, :millisecond)
    seconds = div(diff_ms, 1000)
    milliseconds = rem(diff_ms, 1000)

    "#{seconds}.#{Integer.to_string(milliseconds) |> String.pad_leading(3, "0")}s"
  end

  @doc false
  @spec format_overall_status(t()) :: String.t()
  defp format_overall_status(%__MODULE__{} = certificate) do
    cond do
      certificate.validation_status == :passed and
      certificate.replay_status == :verified and
      certificate.watchdog_status == :completed and
      certificate.invariant_status == :all_passed ->
        "✅ FULLY CERTIFIED"

      certificate.validation_status == :failed or
      certificate.replay_status == :failed or
      certificate.watchdog_status == :drift_detected or
      certificate.invariant_status == :some_failed ->
        "❌ CERTIFICATION FAILED"

      true ->
        "⚠️ PARTIALLY CERTIFIED"
    end
  end
end
