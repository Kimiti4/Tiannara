defmodule TiannaraOS.ScientificCapitalPolicy do
  @moduledoc """
  ScientificCapitalPolicy - Constitutional policy defining coefficient values for scientific capital.

  This module is responsible ONLY for:
  - Coefficient schedule (how much each contribution is worth)
  - Constitutional metadata (version, hash, effective date, approval)
  - Policy versioning and historical tracking

  IMPORTANT: This module NEVER defines what counts as capital. Definitions belong in
  ScientificCapitalDefinition. This module only defines HOW MUCH each contribution is worth.

  ## Constitutional Role

  Scientific Capital Policy is a versioned constitutional artifact that requires
  Phase 14 Constitutional Meta-Governance approval for changes. Each version includes:
  - SHA256 hash of complete policy (for replay verification)
  - Effective date when policy became active
  - Approving authority who authorized the change
  - Scientific justification based on empirical evidence
  - Experimental validation status

  ## Usage

      # Get current active policy
      policy = ScientificCapitalPolicy.current()

      # Verify policy integrity via hash
      :ok = ScientificCapitalPolicy.verify_hash(policy)

      # Get policy by version (for historical replay)
      policy_v1 = ScientificCapitalPolicy.get_version(1)

      # Calculate hash for verification
      hash = ScientificCapitalPolicy.calculate_hash(policy)

  ## Version History

  ### Version 1.0 (2026-06-30) - Initial Constitutional Definition

  **Hash**: Calculated from policy struct fields  
  **Effective Date**: 2026-06-30T00:00:00Z  
  **Approved By**: TiannaraOS.ConstitutionalGovernance (Phase 13.5A.3 Freeze)  
  **Justification**: Establish scientific capital as constitutional conserved quantity derived exclusively from canonical transactions. Coefficients chosen to reflect relative epistemic value:
  - Discoveries represent validated empirical observations (highest immediate value)
  - Theories provide explanatory frameworks (moderate value, enables future discoveries)
  - Unknown resolution reduces research debt (partial credit for uncertainty reduction)

  **Coefficients**:
  - Discovery Value: 100 capital units
  - Theory Value: 250 capital units
  - Law Value: 500 capital units
  - Application Value: 150 capital units
  - Unknown Resolution Value: 200 capital units
  """

  @type t :: %__MODULE__{
          version: non_neg_integer(),
          policy_hash: String.t(),
          effective_date: DateTime.t(),
          approved_by: String.t(),
          justification: String.t(),
          coefficients: coefficients(),
          rules: list(),
          constraints: list()
        }

  @type coefficients :: %{
          discovery_value: non_neg_integer(),
          theory_value: non_neg_integer(),
          law_value: non_neg_integer(),
          application_value: non_neg_integer(),
          unknown_resolution_value: non_neg_integer()
        }

  @type policy_hash :: String.t()
  @type policy_version :: non_neg_integer()

  defstruct [
    :version,
    :policy_hash,
    :effective_date,
    :approved_by,
    :justification,
    :coefficients,
    :rules,
    :constraints
  ]

  @doc """
  Gets the currently active policy version.

  Returns version 1 (the only version currently defined).
  Future versions require Phase 14 governance approval.

  ## Examples

      iex> policy = ScientificCapitalPolicy.current()
      iex> policy.version
      1
  """
  @spec current() :: t()
  def current() do
    get_version(1)
  end

  @doc """
  Load the current active policy (alias for current/0).

  Used by ConstitutionSerializer to retrieve policy for manifest generation.

  ## Returns

  - Current ScientificCapitalPolicy struct

  ## Examples

      iex> policy = ScientificCapitalPolicy.load()
      iex> policy.version
      1
  """
  @spec load() :: t()
  def load() do
    current()
  end

  @doc """
  Gets a specific policy version by version number.

  Enables historical replay by retrieving the policy that was active at a specific time.

  Raises ArgumentError if version doesn't exist.
  """
  @spec get_version(policy_version()) :: t()
  def get_version(version) when version == 1 do
    policy = %__MODULE__{
      version: 1,
      policy_hash: "",  # Will be calculated after struct creation
      effective_date: ~U[2026-06-30 00:00:00Z],
      approved_by: "TiannaraOS.ConstitutionalGovernance",
      justification: "Establish scientific capital as constitutional conserved quantity derived exclusively from canonical transactions.",
      coefficients: %{
        discovery_value: 100,
        theory_value: 250,
        law_value: 500,
        application_value: 150,
        unknown_resolution_value: 200
      },
      rules: [
        "Capital must be conserved across generations",
        "All deltas must be non-negative",
        "Only canonical contributions count toward capital"
      ],
      constraints: [
        "No external injection of capital allowed",
        "No capital destruction permitted",
        "Policy changes require governance approval"
      ]
    }

    # Calculate and set hash
    hash = calculate_hash(policy)
    %{policy | policy_hash: hash}
  end

  def get_version(version) do
    raise ArgumentError, "Policy version #{version} does not exist"
  end

  @doc """
  Calculates SHA256 hash of policy for integrity verification.

  Hash is computed from all policy fields except the policy_hash itself.
  This ensures hash stability and prevents circular dependencies.

  ## Parameters

  - `policy`: ScientificCapitalPolicy struct

  ## Returns

  - SHA256 hex string (64 characters)

  ## Examples

      iex> policy = ScientificCapitalPolicy.current()
      iex> hash = ScientificCapitalPolicy.calculate_hash(policy)
      iex> String.length(hash)
      64
  """
  @spec calculate_hash(t()) :: policy_hash()
  def calculate_hash(policy) do
    # Create hash input excluding the policy_hash field itself
    hash_input = %{
      version: policy.version,
      effective_date: DateTime.to_iso8601(policy.effective_date),
      approved_by: policy.approved_by,
      justification: policy.justification,
      coefficients: policy.coefficients,
      rules: policy.rules,
      constraints: policy.constraints
    }
    |> :erlang.term_to_binary()

    :crypto.hash(:sha256, hash_input)
    |> Base.encode16(case: :lower)
  end

  @doc """
  Verifies policy integrity by recomputing and comparing hash.

  Checks that the stored policy_hash matches the hash calculated from
  the policy's actual content.

  ## Parameters

  - `policy`: ScientificCapitalPolicy struct to verify

  ## Returns

  - `:ok` if hash matches
  - `{:error, :hash_mismatch}` if hash mismatch detected

  ## Examples

      iex> policy = ScientificCapitalPolicy.current()
      iex> ScientificCapitalPolicy.verify_hash(policy)
      :ok
  """
  @spec verify_hash(t()) :: :ok | {:error, :hash_mismatch}
  def verify_hash(policy) do
    expected_hash = calculate_hash(policy)

    if expected_hash == policy.policy_hash do
      :ok
    else
      {:error, :hash_mismatch}
    end
  end

  @doc """
  Extracts policy metadata for logging and auditing.

  Useful for logging, auditing, and recording in GenerationHistory.

  ## Parameters

  - `policy`: ScientificCapitalPolicy struct

  ## Returns

  - Map containing policy metadata

  ## Examples

      iex> policy = ScientificCapitalPolicy.current()
      iex> meta = ScientificCapitalPolicy.metadata(policy)
      iex> meta.version
      1
  """
  @spec metadata(t()) :: map()
  def metadata(policy) do
    %{
      version: policy.version,
      policy_hash: policy.policy_hash,
      effective_date: policy.effective_date,
      approved_by: policy.approved_by,
      justification: policy.justification
    }
  end

  @doc """
  Validates a proposed policy change against constitutional constraints.

  Checks that proposed coefficients are within acceptable ranges and
  that required fields are present.

  ## Parameters

  - `proposed`: Proposed ScientificCapitalPolicy struct

  ## Returns

  - `{:ok}` if proposal is valid
  - `{:error, [reasons]}` if proposal has violations

  ## Examples

      iex> policy = ScientificCapitalPolicy.current()
      iex> ScientificCapitalPolicy.validate_proposal(policy)
      {:ok}
  """
  @spec validate_proposal(t()) :: {:ok} | {:error, [String.t()]}
  def validate_proposal(proposed) do
    violations = []

    # Check coefficients are non-negative
    violations = if proposed.coefficients.discovery_value < 0 do
      ["discovery_value must be non-negative" | violations]
    else
      violations
    end

    violations = if proposed.coefficients.theory_value < 0 do
      ["theory_value must be non-negative" | violations]
    else
      violations
    end

    violations = if proposed.coefficients.law_value < 0 do
      ["law_value must be non-negative" | violations]
    else
      violations
    end

    violations = if proposed.coefficients.application_value < 0 do
      ["application_value must be non-negative" | violations]
    else
      violations
    end

    violations = if proposed.coefficients.unknown_resolution_value < 0 do
      ["unknown_resolution_value must be non-negative" | violations]
    else
      violations
    end

    # Check required fields
    violations = if is_nil(proposed.approved_by) or proposed.approved_by == "" do
      ["approved_by is required" | violations]
    else
      violations
    end

    violations = if is_nil(proposed.justification) or proposed.justification == "" do
      ["justification is required" | violations]
    else
      violations
    end

    if length(violations) == 0 do
      {:ok}
    else
      {:error, Enum.reverse(violations)}
    end
  end

  @doc """
  Lists all available policy versions.

  Currently only version 1 exists. Future versions require Phase 14 governance approval.
  """
  @spec list_versions() :: [policy_version()]
  def list_versions() do
    [1]
  end

  @doc """
  Serialize policy to JSON for external reproducibility package.

  Exports policy coefficients, metadata, and hash in JSON format suitable
  for sharing with external researchers for independent verification.

  ## Parameters

  - `policy`: ScientificCapitalPolicy struct to serialize

  ## Returns

  - JSON string containing policy data

  ## Examples

      iex> policy = ScientificCapitalPolicy.current()
      iex> json = ScientificCapitalPolicy.to_json(policy)
      iex> String.contains?(json, "coefficients")
      true
  """
  @spec to_json(t()) :: String.t()
  def to_json(%__MODULE__{} = policy) do
    policy_data = %{
      version: policy.version,
      policy_hash: policy.policy_hash,
      effective_date: DateTime.to_iso8601(policy.effective_date),
      approved_by: policy.approved_by,
      justification: policy.justification,
      coefficients: %{
        discovery_value: policy.coefficients.discovery_value,
        theory_value: policy.coefficients.theory_value,
        law_value: policy.coefficients.law_value,
        application_value: policy.coefficients.application_value,
        unknown_resolution_value: policy.coefficients.unknown_resolution_value
      },
      rules: policy.rules,
      constraints: policy.constraints,
      metadata: %{
        serializer_version: "1.0",
        serialization_format: "canonical_json",
        hash_algorithm: "SHA256"
      }
    }

    Jason.encode!(policy_data, pretty: true)
  end
end
