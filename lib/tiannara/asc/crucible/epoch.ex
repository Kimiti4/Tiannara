defmodule Tiannara.ASC.Crucible.Epoch do
  @moduledoc """
  Crucible Epoch — aggregates observations from a complete Alpha Campaign run.

  Law discovery consumes epochs rather than raw observations, enabling
  cross-epoch comparison and knowledge compression analysis.

  Just as REA learned from civilizations rather than individual organisms,
  ASC learns from engineering epochs rather than isolated failures.

  ## Example

      iex> epoch = %Tiannara.ASC.Crucible.Epoch{
      ...>   epoch_id: "alpha_001",
      ...>   projects_tested: 25,
      ...>   failures: 500,
      ...>   exploits: 100,
      ...>   repairs: 50,
      ...>   survival_rate: 0.72,
      ...>   repair_success_rate: 0.81,
      ...>   exploit_recurrence_rate: 0.11,
      ...>   candidate_laws: [...],
      ...>   established_laws: [...]
      ...> }

  """

  @derive Jason.Encoder
  defstruct [
    # Identity
    epoch_id: nil,                    # Unique epoch identifier (e.g., "alpha_001")
    started_at: nil,                  # When epoch began
    completed_at: nil,                # When epoch ended

    # Campaign Scale
    projects_tested: 0,               # Number of projects tested
    total_observations: 0,            # Total observations collected

    # Failure Statistics
    failures: 0,                      # Total failures observed
    exploits: 0,                      # Total exploits discovered
    repairs: 0,                       # Total repair attempts
    recoveries: 0,                    # Total successful recoveries

    # Survival Metrics
    survival_rate: 0.0,               # 1 - failure_rate
    failure_rate: 0.0,                # failures / total_observations
    exploit_rate: 0.0,                # exploits / total_observations
    repair_rate: 0.0,                 # repairs / total_observations
    recovery_rate: 0.0,               # recoveries / total_observations

    # Adaptation Metrics
    repair_success_rate: 0.0,         # successful_repairs / total_repairs
    adaptation_velocity: 0.0,         # successful_repairs / total_failures
    mean_time_to_failure: 0.0,        # Average time until first failure
    mean_time_to_repair: 0.0,         # Average repair duration
    mean_time_to_recovery: 0.0,       # Average recovery duration

    # Knowledge Metrics
    exploit_recurrence_rate: 0.0,     # recurring_exploits / total_exploits
    knowledge_reuse_rate: 0.0,        # reused_patterns / total_patterns
    patch_stability: 0.0,             # Average patch confidence
    learning_yield: 0.0,              # candidate_laws / 1000 observations
    knowledge_compression_ratio: 0.0, # observations / established_laws
    principle_stability: 0.0,         # epochs_supporting_principle / epochs_evaluating_principle

    # Law Discovery
    candidate_laws: [],               # Generated law candidates
    established_laws: [],             # Validated laws
    falsified_laws: [],               # Laws proven false (scientific rigor)
    canonical_principles: [],         # Established canonical principles

    # Metadata
    timestamp: nil                    # When epoch was recorded
  ]

  @typedoc "Crucible epoch record"
  @type t :: %__MODULE__{
          epoch_id: String.t() | nil,
          started_at: DateTime.t() | nil,
          completed_at: DateTime.t() | nil,
          projects_tested: non_neg_integer(),
          total_observations: non_neg_integer(),
          failures: non_neg_integer(),
          exploits: non_neg_integer(),
          repairs: non_neg_integer(),
          recoveries: non_neg_integer(),
          survival_rate: float(),
          failure_rate: float(),
          exploit_rate: float(),
          repair_rate: float(),
          recovery_rate: float(),
          repair_success_rate: float(),
          adaptation_velocity: float(),
          mean_time_to_failure: float(),
          mean_time_to_repair: float(),
          mean_time_to_recovery: float(),
          exploit_recurrence_rate: float(),
          knowledge_reuse_rate: float(),
          patch_stability: float(),
          learning_yield: float(),
          knowledge_compression_ratio: float(),
          principle_stability: float(),
          candidate_laws: [map()],
          established_laws: [map()],
          falsified_laws: [map()],
          canonical_principles: [map()],
          timestamp: DateTime.t() | nil
        }

  @doc """
  Create a new epoch from observatory metrics.
  """
  def from_observatory_metrics(epoch_id, observatory_metrics, projects_tested) do
    %__MODULE__{
      epoch_id: epoch_id,
      projects_tested: projects_tested,
      total_observations: Map.get(observatory_metrics, :total_observations, 0),
      failures: calculate_count(observatory_metrics, :failure),
      exploits: calculate_count(observatory_metrics, :exploit),
      repairs: calculate_count(observatory_metrics, :repair),
      recoveries: calculate_count(observatory_metrics, :recovery),
      survival_rate: Map.get(observatory_metrics, :survival_rate, 0.0),
      failure_rate: Map.get(observatory_metrics, :failure_rate, 0.0),
      exploit_rate: Map.get(observatory_metrics, :exploit_rate, 0.0),
      repair_rate: Map.get(observatory_metrics, :repair_rate, 0.0),
      recovery_rate: Map.get(observatory_metrics, :recovery_rate, 0.0),
      repair_success_rate: calculate_repair_success_rate(observatory_metrics),
      adaptation_velocity: calculate_adaptation_velocity(observatory_metrics),
      mean_time_to_failure: Map.get(observatory_metrics, :mean_time_to_failure, 0.0),
      mean_time_to_repair: Map.get(observatory_metrics, :mean_time_to_repair, 0.0),
      mean_time_to_recovery: Map.get(observatory_metrics, :mean_time_to_recovery, 0.0),
      exploit_recurrence_rate: Map.get(observatory_metrics, :exploit_recurrence_rate, 0.0),
      knowledge_reuse_rate: Map.get(observatory_metrics, :knowledge_reuse_rate, 0.0),
      patch_stability: Map.get(observatory_metrics, :patch_stability, 0.0),
      learning_yield: calculate_learning_yield(observatory_metrics),
      knowledge_compression_ratio: calculate_knowledge_compression(observatory_metrics),
      principle_stability: calculate_principle_stability(Map.get(observatory_metrics, :law_candidates, [])),
      candidate_laws: Map.get(observatory_metrics, :law_candidates, []),
      established_laws: filter_established_laws(Map.get(observatory_metrics, :law_candidates, [])),
      canonical_principles: [],
      started_at: Map.get(observatory_metrics, :started_at),
      completed_at: DateTime.utc_now(),
      timestamp: DateTime.utc_now()
    }
  end

  @doc """
  Calculate epoch summary statistics.
  """
  def summarize(%__MODULE__{} = epoch) do
    %{
      epoch_id: epoch.epoch_id,
      scale: %{
        projects_tested: epoch.projects_tested,
        total_observations: epoch.total_observations,
        failures: epoch.failures,
        exploits: epoch.exploits,
        repairs: epoch.repairs
      },
      survival: %{
        survival_rate: epoch.survival_rate,
        failure_rate: epoch.failure_rate,
        exploit_rate: epoch.exploit_rate,
        repair_rate: epoch.repair_rate,
        recovery_rate: epoch.recovery_rate
      },
      adaptation: %{
        repair_success_rate: epoch.repair_success_rate,
        adaptation_velocity: epoch.adaptation_velocity,
        mean_time_to_failure: epoch.mean_time_to_failure,
        mean_time_to_repair: epoch.mean_time_to_repair,
        mean_time_to_recovery: epoch.mean_time_to_recovery
      },
      knowledge: %{
        exploit_recurrence_rate: epoch.exploit_recurrence_rate,
        knowledge_reuse_rate: epoch.knowledge_reuse_rate,
        patch_stability: epoch.patch_stability,
        learning_yield: epoch.learning_yield,
        knowledge_compression_ratio: epoch.knowledge_compression_ratio
      },
      discoveries: %{
        candidate_laws: length(epoch.candidate_laws),
        established_laws: length(epoch.established_laws),
        canonical_principles: length(epoch.canonical_principles)
      }
    }
  end

  @doc """
  Check if epoch meets Alpha Campaign success criteria.
  """
  def meets_alpha_criteria?(%__MODULE__{} = epoch) do
    # Minimum scale requirements
    scale_ok = epoch.projects_tested >= 25 &&
               epoch.failures >= 500 &&
               epoch.exploits >= 100 &&
               epoch.repairs >= 50

    # Quality requirements
    quality_ok = epoch.repair_success_rate > 0.7 &&
                 epoch.knowledge_reuse_rate > 0.4 &&
                 length(epoch.candidate_laws) >= 8

    scale_ok && quality_ok
  end

  @doc """
  Extract law candidates from epoch for cross-epoch comparison.
  """
  def extract_law_candidates(%__MODULE__{} = epoch) do
    Enum.map(epoch.candidate_laws, fn candidate ->
      %{
        id: Map.get(candidate, :id),
        title: Map.get(candidate, :title),
        confidence: Map.get(candidate, :confidence),
        evidence: Map.get(candidate, :evidence),
        epoch_id: epoch.epoch_id
      }
    end)
  end

  @doc """
  Compare two epochs to identify trends.
  """
  def compare_epochs(%__MODULE__{} = epoch1, %__MODULE__{} = epoch2) do
    %{
      survival_trend: compare_metric(epoch1.survival_rate, epoch2.survival_rate),
      failure_trend: compare_metric(epoch1.failure_rate, epoch2.failure_rate),
      repair_success_trend: compare_metric(epoch1.repair_success_rate, epoch2.repair_success_rate),
      knowledge_reuse_trend: compare_metric(epoch1.knowledge_reuse_rate, epoch2.knowledge_reuse_rate),
      learning_yield_trend: compare_metric(epoch1.learning_yield, epoch2.learning_yield),
      improvement_areas: identify_improvements(epoch1, epoch2)
    }
  end

  # Private helpers

  defp calculate_count(metrics, type) do
    observation_counts = Map.get(metrics, :observation_count_by_type, %{})
    Map.get(observation_counts, type, 0)
  end

  defp calculate_repair_success_rate(metrics) do
    repairs = calculate_count(metrics, :repair)
    regressions = calculate_count(metrics, :regression)
    total = repairs + regressions

    if total > 0 do
      Float.round(repairs / total, 3)
    else
      0.0
    end
  end

  defp calculate_adaptation_velocity(metrics) do
    successful_repairs = calculate_count(metrics, :repair)
    failures = calculate_count(metrics, :failure)

    if failures > 0 do
      Float.round(successful_repairs / failures, 3)
    else
      0.0
    end
  end

  defp calculate_learning_yield(metrics) do
    total_obs = Map.get(metrics, :total_observations, 0)
    law_candidates = length(Map.get(metrics, :law_candidates, []))

    if total_obs > 0 do
      Float.round((law_candidates / total_obs) * 1000, 3)
    else
      0.0
    end
  end

  defp calculate_knowledge_compression(metrics) do
    total_obs = Map.get(metrics, :total_observations, 0)
    established = length(filter_established_laws(Map.get(metrics, :law_candidates, [])))

    if established > 0 do
      Float.round(total_obs / established, 1)
    else
      0.0
    end
  end

  defp filter_established_laws(candidates) do
    Enum.filter(candidates, fn candidate ->
      confidence = Map.get(candidate, :confidence, 0.0)
      confidence >= 0.8
    end)
  end

  defp compare_metric(value1, value2) do
    cond do
      value2 > value1 -> :improving
      value2 < value1 -> :declining
      true -> :stable
    end
  end

  defp identify_improvements(epoch1, epoch2) do
    improvements = []

    improvements = if epoch2.survival_rate > epoch1.survival_rate do
      [:survival_rate | improvements]
    else
      improvements
    end

    improvements = if epoch2.repair_success_rate > epoch1.repair_success_rate do
      [:repair_success_rate | improvements]
    else
      improvements
    end

    improvements = if epoch2.knowledge_reuse_rate > epoch1.knowledge_reuse_rate do
      [:knowledge_reuse_rate | improvements]
    else
      improvements
    end

    improvements = if epoch2.learning_yield > epoch1.learning_yield do
      [:learning_yield | improvements]
    else
      improvements
    end

    improvements
  end

  defp calculate_principle_stability(law_candidates) do
    # Calculate average stability across all established laws
    # Stability = epochs_supporting / epochs_evaluating
    
    established_laws = filter_established_laws(law_candidates)
    
    if length(established_laws) == 0 do
      0.0
    else
      # For now, use confidence as proxy for stability
      # In future epochs, this will track actual epoch support/contradiction counts
      avg_confidence = Enum.sum_by(established_laws, &Map.get(&1, :confidence, 0.0)) / length(established_laws)
      Float.round(avg_confidence, 3)
    end
  end
end
