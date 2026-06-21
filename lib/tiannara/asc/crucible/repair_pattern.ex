defmodule Tiannara.ASC.Crucible.RepairPattern do
  @moduledoc """
  Repair Pattern — reusable repair strategy discovered through successful repairs.

  Each pattern represents a proven solution to a specific failure signature,
  enabling knowledge reuse across projects and generations.

  ## Fields

  - `id` — Unique pattern identifier
  - `failure_signature` — Deterministic signature of the failure this pattern fixes
  - `failure_type` — Type of failure (:validation, :constraint, :authentication, etc.)
  - `repair_strategy` — Description of the repair approach
  - `repair_category` — Category of repair (:validation, :security, :configuration, etc.)
  - `success_rate` — Historical success rate (0.0-1.0)
  - `reuse_count` — Number of times this pattern has been reused
  - `transferability` — Cross-project transferability score (0.0-1.0)
  - `confidence` — Confidence in pattern effectiveness (0.0-1.0)
  - `projects_used` — List of project IDs where pattern was applied
  - `created_at` — When pattern was first discovered
  - `updated_at` — Last time pattern statistics were updated

  ## Example

      iex> pattern = %Tiannara.ASC.Crucible.RepairPattern{
      ...>   failure_signature: "validation_missing:user_id",
      ...>   repair_strategy: "Add input validation for user_id field",
      ...>   repair_category: :validation,
      ...>   success_rate: 0.85,
      ...>   reuse_count: 5
      ...> }

  """

  @derive Jason.Encoder
  defstruct [
    # Identity
    id: nil,
    failure_signature: nil,
    failure_classification: nil,  # Phase 5 - Hierarchical classification
    failure_type: nil,

    # Strategy
    repair_strategy: nil,
    repair_category: nil,

    # Statistics
    success_rate: 0.0,
    reuse_count: 0,
    transferability: 0.0,
    confidence: 0.5,

    # Provenance
    projects_used: [],
    created_at: nil,
    updated_at: nil,

    # Phase 4.8 - Repair Ecology Fields
    repair_fitness: 0.0,           # Composite fitness score (0.0-1.0)
    stability_score: 0.0,          # Patch stability across generations
    last_used_generation: 0,       # Last generation this pattern was used
    consecutive_failures: 0,       # Number of consecutive failed attempts
    total_successes: 0,            # Total successful applications
    total_failures: 0,             # Total failed applications
    avg_recovery_time_ms: 0.0,     # Average time to recover using this pattern
    regression_rate: 0.0,          # Rate of regressions introduced
    specialization_index: 0.0,     # How specialized vs generalizable (0=specialized, 1=general)
    ecosystem_role: :unknown,      # :dominant, :emerging, :declining, :extinct
    birth_epoch: nil,              # Epoch when pattern was discovered
    extinction_epoch: nil,         # Epoch when pattern was retired (if extinct)

    # Phase 5C.9 Evolutionary DNA Fields
    domain: nil,
    steps: [],
    constraints: [],
    lineage: [],
    generation: 0
  ]

  @typedoc "Repair pattern structure"
  @type t :: %__MODULE__{
          id: String.t() | nil,
          failure_signature: String.t() | nil,
          failure_type: atom() | nil,
          repair_strategy: String.t() | nil,
          repair_category: atom() | nil,
          success_rate: float(),
          reuse_count: non_neg_integer(),
          transferability: float(),
          confidence: float(),
          projects_used: [String.t()],
          created_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil,
          # Phase 4.8 Ecology fields
          repair_fitness: float(),
          stability_score: float(),
          last_used_generation: non_neg_integer(),
          consecutive_failures: non_neg_integer(),
          total_successes: non_neg_integer(),
          total_failures: non_neg_integer(),
          avg_recovery_time_ms: float(),
          regression_rate: float(),
          specialization_index: float(),
          ecosystem_role: atom(),
          birth_epoch: String.t() | nil,
          extinction_epoch: String.t() | nil,
          domain: atom() | nil,
          steps: [map()],
          constraints: [atom()],
          lineage: [String.t()],
          generation: non_neg_integer()
        }

  @doc """
  Create a new repair pattern from a successful repair.

  ## Parameters

  - `failure_observation` — The failure that was repaired
  - `repair_result` — The successful repair result
  - `project_id` — Project where repair succeeded

  ## Returns

  - New RepairPattern struct
  """
  def from_successful_repair(failure_obs, repair_result, project_id) do
    now = DateTime.utc_now()
    
    # Use FailureClassifier for semantic failure classification
    classification = Tiannara.ASC.Crucible.FailureClassifier.classify(failure_obs, project_id)

    %__MODULE__{
      id: generate_pattern_id(),
      failure_signature: classification.signature,
      failure_classification: classification,
      failure_type: classify_failure_type(failure_obs),
      repair_strategy: extract_repair_strategy(repair_result),
      repair_category: classify_repair_category(failure_obs),
      success_rate: 1.0,  # Starts at 100% after first success
      reuse_count: 1,
      transferability: 0.5,  # Initial transferability estimate
      confidence: 0.6,  # Moderate confidence after single success
      projects_used: [project_id],
      created_at: now,
      updated_at: now
    }
  end

  @doc """
  Update pattern statistics after reuse attempt.

  ## Parameters

  - `pattern` — Existing repair pattern
  - `success?` — Whether reuse was successful
  - `project_id` — Project where pattern was reused

  ## Returns

  - Updated RepairPattern with new statistics
  """
  def update_statistics(%__MODULE__{} = pattern, success?, project_id) do
    now = DateTime.utc_now()

    # Calculate new success rate using exponential moving average
    total_attempts = pattern.reuse_count + 1
    old_successes = round(pattern.success_rate * pattern.reuse_count)
    new_successes = if success?, do: old_successes + 1, else: old_successes
    new_success_rate = new_successes / total_attempts

    # Update confidence based on consistency
    new_confidence = calculate_confidence(new_success_rate, total_attempts)

    # Update transferability if used in new project
    new_projects = if project_id not in pattern.projects_used do
      [project_id | pattern.projects_used]
    else
      pattern.projects_used
    end

    new_transferability = calculate_transferability(length(new_projects))

    %__MODULE__{
      pattern
      | success_rate: Float.round(new_success_rate, 3),
        reuse_count: total_attempts,
        transferability: Float.round(new_transferability, 3),
        confidence: Float.round(new_confidence, 3),
        projects_used: Enum.uniq(new_projects),
        updated_at: now
    }
  end

  # Private helpers

  defp generate_pattern_id do
    "pattern_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}"
  end

  defp generate_failure_signature(observation) do
    # Generate deterministic failure signature from observation
    # Format: "category:specific_issue"

    category = case observation.origin do
      :requirements -> "requirement"
      :architecture -> "architecture"
      :interface -> "interface"
      :implementation -> "implementation"
      :deployment -> "deployment"
      :operations -> "operations"
      _ -> "unknown"
    end

    # Extract specific issue from evidence
    specific = case observation.evidence do
      [first_evidence | _] when is_binary(first_evidence) ->
        first_evidence
        |> String.downcase()
        |> String.replace(~r/[^a-z0-9_]/, "_")
        |> String.slice(0..30)
      _ ->
        "unknown"
    end

    "#{category}:#{specific}"
  end

  defp classify_failure_type(observation) do
    # Classify failure into repair categories
    case {observation.source, observation.observation_type} do
      {:validator, :failure} ->
        cond do
          String.contains?(inspect(observation.evidence), ["invariant", "missing"]) ->
            :validation
          String.contains?(inspect(observation.evidence), ["constraint", "limit"]) ->
            :constraint
          true ->
            :validation
        end

      {:breaker, :failure} ->
        case observation.severity do
          :critical -> :security
          :high -> :performance
          _ -> :implementation
        end

      {:attacker, :exploit} ->
        :security

      _ ->
        :implementation
    end
  end

  defp extract_repair_strategy(repair_result) do
    # Extract human-readable repair strategy from repair result
    repair_result.repair_description || "Generic repair applied"
  end

  defp classify_repair_category(observation) do
    # Map failure origin to repair category
    case observation.origin do
      :requirements -> :validation
      :architecture -> :configuration
      :interface -> :schema
      :implementation -> :implementation
      :deployment -> :dependency
      :operations -> :performance
      _ -> :implementation
    end
  end

  defp calculate_confidence(success_rate, attempts) do
    # Confidence increases with more attempts and higher success rate
    # Formula: confidence = success_rate * (1 - e^(-attempts/10))
    base_confidence = success_rate
    experience_factor = 1 - :math.exp(-attempts / 10)
    base_confidence * experience_factor
  end

  defp calculate_transferability(project_count) do
    # Transferability increases with number of different projects
    # Saturates at 1.0 after ~10 projects
    1 - :math.exp(-project_count / 5)
  end

  # Phase 4.8 - Repair Ecology Functions

  @doc """
  Calculate repair fitness score based on multiple ecological factors.

  Fitness = weighted combination of:
  - Success rate (40%)
  - Stability (25%)
  - Transferability (20%)
  - Low regression rate (15%)

  ## Parameters

  - `pattern` — Repair pattern to evaluate

  ## Returns

  - Updated pattern with calculated fitness score
  """
  def calculate_fitness(%__MODULE__{} = pattern) do
    success_weight = 0.40
    stability_weight = 0.25
    transfer_weight = 0.20
    low_regression_weight = 0.15

    fitness = (
      success_weight * pattern.success_rate +
      stability_weight * pattern.stability_score +
      transfer_weight * pattern.transferability +
      low_regression_weight * (1.0 - pattern.regression_rate)
    )

    %__MODULE__{
      pattern
      | repair_fitness: Float.round(fitness, 3)
    }
  end

  @doc """
  Update pattern ecology after a repair attempt.

  Tracks successes, failures, consecutive failures, and ecosystem role.

  ## Parameters

  - `pattern` — Existing repair pattern
  - `success?` — Whether repair succeeded
  - `regression?` — Whether regression was introduced
  - `recovery_time_ms` — Time taken to recover
  - `generation` — Current generation number
  - `epoch_id` — Current epoch identifier

  ## Returns

  - Updated pattern with ecology metrics
  """
  def update_ecology(%__MODULE__{} = pattern, success?, regression?, recovery_time_ms, generation, epoch_id) do
    now = DateTime.utc_now()

    # Update total counts
    new_total_successes = if success?, do: pattern.total_successes + 1, else: pattern.total_successes
    new_total_failures = if !success?, do: pattern.total_failures + 1, else: pattern.total_failures

    # Update consecutive failures
    new_consecutive_failures = if !success? do
      pattern.consecutive_failures + 1
    else
      0  # Reset on success
    end

    # Update average recovery time (exponential moving average)
    alpha = 0.3  # EMA smoothing factor
    new_avg_recovery = if pattern.avg_recovery_time_ms == 0.0 do
      recovery_time_ms
    else
      alpha * recovery_time_ms + (1 - alpha) * pattern.avg_recovery_time_ms
    end

    # Update regression rate
    total_attempts = new_total_successes + new_total_failures
    new_regression_count = if regression?, do: pattern.total_failures * pattern.regression_rate + 1, else: pattern.total_failures * pattern.regression_rate
    new_regression_rate = if total_attempts > 0 do
      new_regression_count / total_attempts
    else
      0.0
    end

    # Determine ecosystem role
    ecosystem_role = determine_ecosystem_role(pattern, success?, new_consecutive_failures, total_attempts)

    %__MODULE__{
      pattern
      | total_successes: new_total_successes,
        total_failures: new_total_failures,
        consecutive_failures: new_consecutive_failures,
        avg_recovery_time_ms: Float.round(new_avg_recovery, 2),
        regression_rate: Float.round(new_regression_rate, 3),
        last_used_generation: generation,
        ecosystem_role: ecosystem_role,
        updated_at: now
    }
  end

  @doc """
  Check if pattern should be retired (extinct).

  Retirement criteria:
  - Consecutive failures >= 5
  - OR success_rate < 0.3 AND reuse_count >= 10
  - OR not used for 20+ generations

  ## Parameters

  - `pattern` — Repair pattern to check
  - `current_generation` — Current generation number

  ## Returns

  - `true` if pattern should be retired, `false` otherwise
  """
  def should_retire?(%__MODULE__{} = pattern, current_generation) do
    consecutive_failure_threshold = 5
    low_success_threshold = 0.3
    minimum_reuse_for_retirement = 10
    inactive_generation_threshold = 20

    consecutive_failures_exceeded = pattern.consecutive_failures >= consecutive_failure_threshold

    low_success_with_usage =
      pattern.success_rate < low_success_threshold and
      pattern.reuse_count >= minimum_reuse_for_retirement

    inactive_too_long =
      pattern.last_used_generation > 0 and
      (current_generation - pattern.last_used_generation) >= inactive_generation_threshold

    consecutive_failures_exceeded or low_success_with_usage or inactive_too_long
  end

  @doc """
  Mark pattern as extinct.

  ## Parameters

  - `pattern` — Pattern to retire
  - `epoch_id` — Epoch when extinction occurred

  ## Returns

  - Retired pattern with extinction metadata
  """
  def mark_extinct(%__MODULE__{} = pattern, epoch_id) do
    %__MODULE__{
      pattern
      | ecosystem_role: :extinct,
        extinction_epoch: epoch_id,
        updated_at: DateTime.utc_now()
    }
  end

  @doc """
  Calculate specialization index (how project-specific vs generalizable).

  Specialization = 1 - (unique_projects / total_uses)
  - 0.0 = perfectly generalizable (used equally across all projects)
  - 1.0 = perfectly specialized (only used in one project)

  ## Parameters

  - `pattern` — Repair pattern

  ## Returns

  - Updated pattern with specialization index
  """
  def calculate_specialization(%__MODULE__{} = pattern) do
    unique_projects = length(Enum.uniq(pattern.projects_used))
    total_uses = pattern.reuse_count

    specialization = if total_uses == 0 do
      0.0
    else
      1.0 - (unique_projects / total_uses)
    end

    %__MODULE__{
      pattern
      | specialization_index: Float.round(specialization, 3)
    }
  end

  # Private helpers for ecology

  defp determine_ecosystem_role(pattern, _latest_success?, consecutive_failures, total_attempts) do
    cond do
      # Extinct patterns stay extinct
      pattern.ecosystem_role == :extinct ->
        :extinct

      # Declining: many consecutive failures or very low success rate
      consecutive_failures >= 3 or (total_attempts >= 10 and pattern.success_rate < 0.4) ->
        :declining

      # Dominant: high success rate and many uses
      total_attempts >= 15 and pattern.success_rate >= 0.7 ->
        :dominant

      # Emerging: recent pattern with good early performance
      total_attempts < 10 and pattern.success_rate >= 0.6 ->
        :emerging

      # Stable: moderate performance
      true ->
        :stable
    end
  end
end
