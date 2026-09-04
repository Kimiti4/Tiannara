defmodule TiannaraOS.StructuralValidationResult do
  @moduledoc """
  StructuralValidationResult - Immutable canonical transaction recording structural validation outcomes.

  This module defines the canonical transaction structure for structural validation results.
  Every execution of ConstitutionalExecutor produces exactly one StructuralValidationResult,
  which becomes part of the immutable generation history.

  ## Constitutional Role

  StructuralValidationResult transforms structural validation from ephemeral reports into
  permanent, auditable, replayable constitutional records. It captures:

  - All constitutional hashes at time of validation
  - Status of every invariant check
  - Any violations detected
  - Approval decision
  - Timestamp of validation

  ## Architecture

  ```
  ConstitutionalExecutor.execute()
          │
          ▼
  StructuralValidationGate.run()
          │
          ▼
  StructuralValidationResult.new(result_data)
          │
          ▼
  Append to GenerationHistory.validation_results (immutable)
  ```

  ## Fields

  - `gate_id`: Unique identifier for this validation gate execution
  - `generation`: Generation number being validated
  - `constitution_hash`: Combined hash of all constitutional artifacts
  - `policy_hash`: Hash of active ScientificCapitalPolicy
  - `definition_hash`: Hash of ScientificCapitalDefinition
  - `ledger_hash`: Hash of ScientificCapitalLedger
  - `invariant_hash`: Hash of ConstitutionalInvariantRegistry
  - `replay_status`: Status of replay determinism check
  - `conservation_status`: Status of conservation law checks
  - `temporal_status`: Status of temporal separation check
  - `reward_status`: Status of reward leakage check
  - `seed_status`: Status of seed independence check
  - `metric_status`: Status of metric independence check
  - `lifecycle_status`: Status of lifecycle completeness check
  - `rollback_status`: Status of rollback completeness check
  - `violations`: List of constitutional violations detected
  - `approval`: Boolean indicating whether validation passed
  - `timestamp`: UTC timestamp when validation occurred

  ## Usage

      result = %StructuralValidationResult{
        gate_id: "GATE-2026-06-13T12:00:00Z-abc123",
        generation: 42,
        constitution_hash: "sha256...",
        policy_hash: "sha256...",
        definition_hash: "sha256...",
        ledger_hash: "sha256...",
        invariant_hash: "sha256...",
        replay_status: :pass,
        conservation_status: :pass,
        temporal_status: :pass,
        reward_status: :pass,
        seed_status: :pass,
        metric_status: :pass,
        lifecycle_status: :pass,
        rollback_status: :pass,
        violations: [],
        approval: true,
        timestamp: DateTime.utc_now()
      }

  ## Immutability Guarantee

  Once created, a StructuralValidationResult is NEVER modified. It becomes part of
  the permanent historical record and can be used for future replay and audit.
  """

  @type status :: :pass | :fail | :not_checked
  @type violation :: %{
    id: String.t(),
    reason: String.t(),
    severity: :critical | :high | :medium | :low
  }

  @type t :: %__MODULE__{
    gate_id: String.t(),
    generation: non_neg_integer(),
    constitution_hash: String.t(),
    policy_hash: String.t(),
    definition_hash: String.t(),
    ledger_hash: String.t(),
    invariant_hash: String.t(),
    replay_status: status(),
    conservation_status: status(),
    temporal_status: status(),
    reward_status: status(),
    seed_status: status(),
    metric_status: status(),
    lifecycle_status: status(),
    rollback_status: status(),
    violations: [violation()],
    approval: boolean(),
    timestamp: DateTime.t()
  }

  defstruct [
    :gate_id,
    :generation,
    :constitution_hash,
    :policy_hash,
    :definition_hash,
    :ledger_hash,
    :invariant_hash,
    :replay_status,
    :conservation_status,
    :temporal_status,
    :reward_status,
    :seed_status,
    :metric_status,
    :lifecycle_status,
    :rollback_status,
    :violations,
    :approval,
    :timestamp
  ]

  @doc """
  Create a new StructuralValidationResult with validation.

  Ensures all required fields are present and valid before creating the struct.

  ## Parameters

  - `data`: Map containing validation result data

  ## Returns

  - `StructuralValidationResult` struct

  ## Raises

  - `ArgumentError` if required fields are missing or invalid
  """
  @spec new(map()) :: t()
  def new(data) do
    # Validate required fields
    validate_required_fields(data)

    # Validate status values
    validate_status_fields(data)

    # Validate violations structure
    validate_violations(data)

    %__MODULE__{
      gate_id: data.gate_id,
      generation: data.generation,
      constitution_hash: data.constitution_hash,
      policy_hash: data.policy_hash,
      definition_hash: data.definition_hash,
      ledger_hash: data.ledger_hash,
      invariant_hash: data.invariant_hash,
      replay_status: Map.get(data, :replay_status, :not_checked),
      conservation_status: Map.get(data, :conservation_status, :not_checked),
      temporal_status: Map.get(data, :temporal_status, :not_checked),
      reward_status: Map.get(data, :reward_status, :not_checked),
      seed_status: Map.get(data, :seed_status, :not_checked),
      metric_status: Map.get(data, :metric_status, :not_checked),
      lifecycle_status: Map.get(data, :lifecycle_status, :not_checked),
      rollback_status: Map.get(data, :rollback_status, :not_checked),
      violations: Map.get(data, :violations, []),
      approval: Map.get(data, :approval, false),
      timestamp: Map.get(data, :timestamp, DateTime.utc_now())
    }
  end

  @doc """
  Check if validation passed (no violations).

  ## Parameters

  - `result`: StructuralValidationResult struct

  ## Returns

  - `true` if approval is true and no violations
  - `false` otherwise
  """
  @spec passed?(t()) :: boolean()
  def passed?(%__MODULE__{} = result) do
    result.approval == true and length(result.violations) == 0
  end

  @doc """
  Get list of critical violations.

  ## Parameters

  - `result`: StructuralValidationResult struct

  ## Returns

  - List of violations with severity :critical
  """
  @spec critical_violations(t()) :: [violation()]
  def critical_violations(%__MODULE__{} = result) do
    Enum.filter(result.violations, fn v -> v.severity == :critical end)
  end

  @doc """
  Format validation result as human-readable report.

  ## Parameters

  - `result`: StructuralValidationResult struct

  ## Returns

  - Formatted string report
  """
  @spec format_report(t()) :: String.t()
  def format_report(%__MODULE__{} = result) do
    """
    ╔═══════════════════════════════════════════════════════════╗
    ║         STRUCTURAL VALIDATION RESULT                     ║
    ╚═══════════════════════════════════════════════════════════╝

    Gate ID:           #{result.gate_id}
    Generation:        #{result.generation}
    Timestamp:         #{DateTime.to_iso8601(result.timestamp)}
    Approval:          #{if result.approval, do: "✅ PASS", else: "❌ FAIL"}

    ───────────────────────────────────────────────────────────
    Constitutional Hashes:
    ───────────────────────────────────────────────────────────
    Constitution:      #{truncate_hash(result.constitution_hash)}
    Policy:            #{truncate_hash(result.policy_hash)}
    Definition:        #{truncate_hash(result.definition_hash)}
    Ledger:            #{truncate_hash(result.ledger_hash)}
    Invariant Registry: #{truncate_hash(result.invariant_hash)}

    ───────────────────────────────────────────────────────────
    Invariant Status:
    ───────────────────────────────────────────────────────────
    Replay Determinism:     #{format_status(result.replay_status)}
    Conservation Laws:      #{format_status(result.conservation_status)}
    Temporal Separation:    #{format_status(result.temporal_status)}
    Reward Leakage:         #{format_status(result.reward_status)}
    Seed Independence:      #{format_status(result.seed_status)}
    Metric Independence:    #{format_status(result.metric_status)}
    Lifecycle Completeness: #{format_status(result.lifecycle_status)}
    Rollback Completeness:  #{format_status(result.rollback_status)}

    ───────────────────────────────────────────────────────────
    Violations: #{length(result.violations)}
    ───────────────────────────────────────────────────────────
    #{format_violations(result.violations)}
    """
  end

  # Private helper functions

  @spec validate_required_fields(map()) :: :ok | no_return()
  defp validate_required_fields(data) do
    required_fields = [
      :gate_id,
      :generation,
      :constitution_hash,
      :policy_hash,
      :definition_hash,
      :ledger_hash,
      :invariant_hash
    ]

    missing_fields = Enum.filter(required_fields, fn field ->
      Map.get(data, field) == nil
    end)

    if length(missing_fields) > 0 do
      raise ArgumentError, "Missing required fields: #{inspect(missing_fields)}"
    end

    :ok
  end

  @spec validate_status_fields(map()) :: :ok | no_return()
  defp validate_status_fields(data) do
    status_fields = [
      :replay_status,
      :conservation_status,
      :temporal_status,
      :reward_status,
      :seed_status,
      :metric_status,
      :lifecycle_status,
      :rollback_status
    ]

    valid_statuses = [:pass, :fail, :not_checked]

    Enum.each(status_fields, fn field ->
      value = Map.get(data, field, :not_checked)

      if value not in valid_statuses do
        raise ArgumentError,
              "Invalid status for #{field}: #{inspect(value)}. Must be one of: #{inspect(valid_statuses)}"
      end
    end)

    :ok
  end

  @spec validate_violations(map()) :: :ok | no_return()
  defp validate_violations(data) do
    violations = Map.get(data, :violations, [])

    if not is_list(violations) do
      raise ArgumentError, "Violations must be a list"
    end

    Enum.each(violations, fn v ->
      if not is_map(v) or not Map.has_key?(v, :id) or not Map.has_key?(v, :reason) do
        raise ArgumentError, "Each violation must have :id and :reason fields"
      end
    end)

    :ok
  end

  @spec truncate_hash(String.t()) :: String.t()
  defp truncate_hash(hash) when is_binary(hash) do
    if String.length(hash) > 16 do
      String.slice(hash, 0, 8) <> "..." <> String.slice(hash, -8, 8)
    else
      hash
    end
  end

  @spec format_status(status()) :: String.t()
  defp format_status(:pass), do: "✅ PASS"
  defp format_status(:fail), do: "❌ FAIL"
  defp format_status(:not_checked), do: "⚪ NOT CHECKED"

  @spec format_violations([violation()]) :: String.t()
  defp format_violations([]), do: "  No violations detected ✅\n"

  defp format_violations(violations) do
    Enum.map_join(violations, "\n", fn v ->
      severity_icon =
        case v.severity do
          :critical -> "🔴"
          :high -> "🟠"
          :medium -> "🟡"
          :low -> "🔵"
        end

      "  #{severity_icon} #{v.id}: #{v.reason} (#{v.severity})"
    end) <> "\n"
  end
end
