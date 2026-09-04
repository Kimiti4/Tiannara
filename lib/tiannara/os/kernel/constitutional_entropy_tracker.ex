defmodule TiannaraOS.Kernel.ConstitutionalEntropyTracker do
  @moduledoc """
  ConstitutionalEntropyTracker - Measure how much "disorder" each amendment adds.

  Entropy represents the complexity and potential instability introduced by constitutional changes.
  High entropy indicates the constitution is becoming too complex to maintain safely.

  ## Metrics Tracked

  - `module_count`: Total kernel modules
  - `dependency_count`: Inter-module dependencies
  - `invariant_count`: Total INV-* rules
  - `migration_path_count`: Possible upgrade paths
  - `review_complexity`: Average review time × reviewer count
  - `replay_complexity`: Replay engine complexity
  - `total_entropy`: Weighted sum of all metrics

  ## Thresholds

  - Maximum acceptable entropy: 0.8
  - If exceeded, require simplification proposal before accepting new amendments

  ## API

      @spec measure_entropy() :: t()
      @spec check_entropy_threshold(t()) :: :acceptable | :critical
  """

  alias TiannaraOS.Kernel.ConstitutionalInvariantRegistry

  defstruct [
    :module_count,
    :dependency_count,
    :invariant_count,
    :migration_path_count,
    :review_complexity,
    :replay_complexity,
    :total_entropy
  ]

  @type t :: %__MODULE__{
          module_count: non_neg_integer(),
          dependency_count: non_neg_integer(),
          invariant_count: non_neg_integer(),
          migration_path_count: non_neg_integer(),
          review_complexity: float(),
          replay_complexity: float(),
          total_entropy: float()
        }

  @entropy_threshold 0.8

  @doc """
  Measure current constitutional entropy.

  Computes weighted sum of all entropy metrics.
  """
  @spec measure_entropy() :: t()
  def measure_entropy() do
    module_count = count_kernel_modules()
    dependency_count = count_dependencies()
    invariant_count = count_invariants()
    migration_path_count = estimate_migration_paths()
    review_complexity = compute_review_complexity()
    replay_complexity = compute_replay_complexity()

    # Normalize each metric to [0, 1] range
    normalized_module_count = normalize(module_count, 20, 50)
    normalized_dependency_count = normalize(dependency_count, 30, 100)
    normalized_invariant_count = normalize(invariant_count, 10, 50)
    normalized_migration_paths = normalize(migration_path_count, 5, 20)
    normalized_review_complexity = min(1.0, review_complexity / 10.0)
    normalized_replay_complexity = min(1.0, replay_complexity / 5.0)

    # Weighted sum (weights sum to 1.0)
    total_entropy =
      0.20 * normalized_module_count +
      0.20 * normalized_dependency_count +
      0.20 * normalized_invariant_count +
      0.15 * normalized_migration_paths +
      0.15 * normalized_review_complexity +
      0.10 * normalized_replay_complexity

    # Clamp to [0, 1]
    total_entropy = max(0.0, min(1.0, total_entropy))

    %__MODULE__{
      module_count: module_count,
      dependency_count: dependency_count,
      invariant_count: invariant_count,
      migration_path_count: migration_path_count,
      review_complexity: Float.round(review_complexity, 2),
      replay_complexity: Float.round(replay_complexity, 2),
      total_entropy: Float.round(total_entropy, 4)
    }
  end

  @doc """
  Check if entropy is within acceptable threshold.

  Returns :acceptable if entropy ≤ 0.8, :critical if exceeded.
  """
  @spec check_entropy_threshold(t()) :: :acceptable | :critical
  def check_entropy_threshold(%__MODULE__{total_entropy: entropy}) do
    if entropy <= @entropy_threshold do
      :acceptable
    else
      :critical
    end
  end

  # Private helper functions

  defp count_kernel_modules() do
    # Count modules in lib/tiannara/os/kernel/
    # For now, use hardcoded baseline (will be dynamic in production)
    9  # ConstitutionManifest, ConstitutionFingerprint, etc.
  end

  defp count_dependencies() do
    # TODO: Analyze module dependencies using mix xref
    # Placeholder estimate
    25
  end

  defp count_invariants() do
    # Count registered invariants
    case ConstitutionalInvariantRegistry.list_invariants() do
      invariants when is_list(invariants) -> length(invariants)
      _ -> 10  # Baseline for Phase 13
    end
  end

  defp estimate_migration_paths() do
    # Estimate number of possible upgrade paths between versions
    # For n versions, there are n*(n-1)/2 possible paths
    # Assume ~5 historical versions for now
    10
  end

  defp compute_review_complexity() do
    # TODO: Compute average review time × reviewer count
    # Placeholder
    6.0  # 6 hours average
  end

  defp compute_replay_complexity() do
    # TODO: Measure replay engine complexity (time, resources)
    # Placeholder
    3.0  # Moderate complexity
  end

  defp normalize(value, min_val, max_val) do
    # Normalize value to [0, 1] range
    normalized = (value - min_val) / (max_val - min_val)
    max(0.0, min(1.0, normalized))
  end
end
