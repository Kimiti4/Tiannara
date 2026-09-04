defmodule TiannaraOS.ConstitutionIdentity do
  @moduledoc """
  ConstitutionIdentity - Immutable identity of the Tiannara Constitution.

  This module owns ONLY metadata about the constitution. It NEVER owns hashes.
  All component hashes are owned exclusively by ConstitutionManifest.

  ## Constitutional Role

  ConstitutionIdentity provides:
  1. Stable identity across versions (constitution_id never changes)
  2. Version tracking (version evolves with constitutional changes)
  3. Temporal scope (effective_from/effective_until)
  4. Governance approval tracking (approved_by)

  ## Ownership Hierarchy

  ```
  ConstitutionIdentity (metadata only)
        │
        ▼
  ConstitutionManifest (owns all hashes)
        │
        ├── ConstitutionFingerprint (derived from Manifest)
        ├── ConstitutionCertificate (references Manifest)
        └── ConstitutionalDriftJournal (stores Certificates)
  ```

  ## Usage

      # Create new identity for constitutional version
      identity = ConstitutionIdentity.create(
        constitution_id: "TOS-CONSTITUTION-0001",
        version: "13.5B.3",
        approved_by: "TiannaraOS.Governance"
      )

      # Get current identity
      identity = ConstitutionIdentity.current()

      # Verify identity matches manifest
      :ok = ConstitutionIdentity.verify_match(identity, manifest)
  """

  @type t :: %__MODULE__{
          constitution_id: String.t(),
          version: String.t(),
          created_at: DateTime.t(),
          effective_from: DateTime.t(),
          effective_until: DateTime.t() | nil,
          approved_by: String.t()
        }

  defstruct [
    :constitution_id,
    :version,
    :created_at,
    :effective_from,
    :effective_until,
    :approved_by
  ]

  @doc """
  Create new ConstitutionIdentity for a constitutional version.

  ## Parameters

  - `opts`: Keyword list with identity metadata
    - `:constitution_id` (required): Immutable constitution identifier
    - `:version` (required): Version string (e.g., "13.5B.3")
    - `:approved_by` (required): Governance authority
    - `:effective_from` (optional): When this version takes effect (defaults to now)
    - `:effective_until` (optional): When superseded (nil if current)

  ## Returns

  - ConstitutionIdentity struct

  ## Examples

      iex> identity = ConstitutionIdentity.create(
      ...>   constitution_id: "TOS-CONSTITUTION-0001",
      ...>   version: "13.5B.3",
      ...>   approved_by: "TiannaraOS.Governance"
      ...> )
      iex> identity.constitution_id
      "TOS-CONSTITUTION-0001"
  """
  @spec create(keyword()) :: t()
  def create(opts) do
    constitution_id = Keyword.fetch!(opts, :constitution_id)
    version = Keyword.fetch!(opts, :version)
    approved_by = Keyword.fetch!(opts, :approved_by)
    effective_from = Keyword.get(opts, :effective_from, DateTime.utc_now())
    effective_until = Keyword.get(opts, :effective_until, nil)

    %__MODULE__{
      constitution_id: constitution_id,
      version: version,
      created_at: DateTime.utc_now(),
      effective_from: effective_from,
      effective_until: effective_until,
      approved_by: approved_by
    }
  end

  @doc """
  Get current active ConstitutionIdentity.

  Returns the most recent identity with effective_until == nil.

  ## Returns

  - Current ConstitutionIdentity struct

  ## Examples

      iex> identity = ConstitutionIdentity.current()
      iex> is_nil(identity.effective_until)
      true
  """
  @spec current() :: t()
  def current() do
    # In production, this would query a database or configuration
    # For now, return hardcoded current identity
    create(
      constitution_id: "TOS-CONSTITUTION-0001",
      version: "13.5B.3",
      approved_by: "TiannaraOS.Governance",
      effective_from: ~U[2026-06-13 00:00:00Z],
      effective_until: nil
    )
  end

  @doc """
  Verify that a ConstitutionManifest matches this Identity.

  Checks that manifest's constitution_id and version match identity.

  ## Parameters

  - `identity`: ConstitutionIdentity to verify against
  - `manifest`: ConstitutionManifest to verify

  ## Returns

  - `:ok` if match
  - `{:mismatch, reason}` if mismatch

  ## Examples

      iex> identity = ConstitutionIdentity.current()
      iex> manifest = ConstitutionManifest.build()
      iex> ConstitutionIdentity.verify_match(identity, manifest)
      :ok
  """
  @spec verify_match(t(), map()) :: :ok | {:mismatch, String.t()}
  def verify_match(%__MODULE__{} = identity, %{} = manifest) do
    cond do
      identity.constitution_id != Map.get(manifest, :constitution_id) ->
        {:mismatch, "constitution_id mismatch: #{identity.constitution_id} vs #{Map.get(manifest, :constitution_id)}"}

      identity.version != Map.get(manifest, :version) ->
        {:mismatch, "version mismatch: #{identity.version} vs #{Map.get(manifest, :version)}"}

      true ->
        :ok
    end
  end

  @doc """
  Check if this identity is currently effective.

  Returns true if effective_from <= now and (effective_until is nil or effective_until > now).

  ## Parameters

  - `identity`: ConstitutionIdentity to check
  - `now`: Optional DateTime for comparison (defaults to utc_now)

  ## Returns

  - boolean indicating if identity is currently effective

  ## Examples

      iex> identity = ConstitutionIdentity.current()
      iex> ConstitutionIdentity.is_effective?(identity)
      true
  """
  @spec is_effective?(t(), DateTime.t()) :: boolean()
  def is_effective?(%__MODULE__{} = identity, now \\ DateTime.utc_now()) do
    effective_from = identity.effective_from
    effective_until = identity.effective_until

    from_passed = DateTime.compare(now, effective_from) in [:gt, :eq]
    until_not_reached = is_nil(effective_until) or DateTime.compare(now, effective_until) == :lt

    from_passed and until_not_reached
  end

  @doc """
  Supersede this identity with a new version.

  Sets effective_until to now and returns new identity.

  ## Parameters

  - `identity`: Current ConstitutionIdentity to supersede
  - `new_version`: New version string
  - `approved_by`: Governance authority approving new version

  ## Returns

  - {updated_identity, new_identity}

  ## Examples

      iex> {old, new} = ConstitutionIdentity.supersede(current_identity, "13.5B.4", "Governance")
      iex> is_nil(old.effective_until)
      false
      iex> is_nil(new.effective_until)
      true
  """
  @spec supersede(t(), String.t(), String.t()) :: {t(), t()}
  def supersede(%__MODULE__{} = identity, new_version, approved_by) do
    now = DateTime.utc_now()

    updated_identity = %{identity | effective_until: now}

    new_identity = create(
      constitution_id: identity.constitution_id,
      version: new_version,
      approved_by: approved_by,
      effective_from: now,
      effective_until: nil
    )

    {updated_identity, new_identity}
  end

  @doc """
  Serialize identity to canonical JSON.

  ## Parameters

  - `identity`: ConstitutionIdentity to serialize

  ## Returns

  - Canonical JSON string

  ## Examples

      iex> identity = ConstitutionIdentity.current()
      iex> json = ConstitutionIdentity.to_json(identity)
      iex> is_binary(json)
      true
  """
  @spec to_json(t()) :: String.t()
  def to_json(%__MODULE__{} = identity) do
    data = %{
      constitution_id: identity.constitution_id,
      version: identity.version,
      created_at: DateTime.to_iso8601(identity.created_at),
      effective_from: DateTime.to_iso8601(identity.effective_from),
      effective_until: if(identity.effective_until, do: DateTime.to_iso8601(identity.effective_until), else: nil),
      approved_by: identity.approved_by
    }

    Jason.encode!(data, pretty: false, sort_keys: true)
  end

  @doc """
  Deserialize identity from canonical JSON.

  ## Parameters

  - `json_string`: Canonical JSON string

  ## Returns

  - ConstitutionIdentity struct

  ## Examples

      iex> identity = ConstitutionIdentity.current()
      iex> json = ConstitutionIdentity.to_json(identity)
      iex> deserialized = ConstitutionIdentity.from_json(json)
      iex> deserialized.constitution_id == identity.constitution_id
      true
  """
  @spec from_json(String.t()) :: t()
  def from_json(json_string) when is_binary(json_string) do
    data = Jason.decode!(json_string, keys: :atoms)

    %__MODULE__{
      constitution_id: data.constitution_id,
      version: data.version,
      created_at: case DateTime.from_iso8601(data.created_at) do
        {:ok, dt} -> dt
        _ -> DateTime.utc_now()
      end,
      effective_from: case DateTime.from_iso8601(data.effective_from) do
        {:ok, dt} -> dt
        _ -> DateTime.utc_now()
      end,
      effective_until: if(data.effective_until) do
        case DateTime.from_iso8601(data.effective_until) do
          {:ok, dt} -> dt
          _ -> nil
        end
      else
        nil
      end,
      approved_by: data.approved_by
    }
  end

  @doc """
  Format identity as human-readable report.

  ## Parameters

  - `identity`: ConstitutionIdentity to format

  ## Returns

  - Formatted string suitable for display

  ## Examples

      iex> identity = ConstitutionIdentity.current()
      iex> report = ConstitutionIdentity.format_report(identity)
      iex> String.contains?(report, "Constitution ID:")
      true
  """
  @spec format_report(t()) :: String.t()
  def format_report(%__MODULE__{} = identity) do
    """
    ╔══════════════════════════════════════════════════════════╗
    ║         CONSTITUTION IDENTITY                            ║
    ╚══════════════════════════════════════════════════════════╝

    Constitution ID: #{identity.constitution_id}
    Version:         #{identity.version}
    Approved By:     #{identity.approved_by}

    Created At:      #{DateTime.to_iso8601(identity.created_at)}
    Effective From:  #{DateTime.to_iso8601(identity.effective_from)}
    Effective Until: #{if identity.effective_until, do: DateTime.to_iso8601(identity.effective_until), else: "CURRENT"}

    Status: #{if is_effective?(identity), do: "✅ ACTIVE", else: "⏸️ SUPERSEDED"}
    """
  end
end
