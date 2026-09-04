defmodule TiannaraOS.PredictionAssessment do
  @moduledoc """
  PredictionAssessment - Canonical constitutional value object for prediction quality measurement.

  This immutable object captures the comparison between predicted and observed outcomes
  across all adaptive capabilities (Method Evolution, Institution Adaptation, Civilization Adaptation).

  ## Constitutional Role

  Prediction Assessment provides a standardized way to measure how well the civilization
  can predict its own improvements. This becomes a permanent civilizational metric tracked
  across recursive generations.

  ## Usage Across Capabilities

  - MethodEvolutionResult: Assesses simulation accuracy before adoption
  - InstitutionAdaptationResult: Compares pilot results vs predictions
  - CivilizationAdaptationResult: Evaluates cross-institution forecast quality
  - Mission Control: Aggregates prediction quality metrics
  - Executive Dashboard: Displays prediction reliability trends

  ## Canonical Structure

  Every PredictionAssessment contains:
  - predicted_value: What was forecast
  - observed_value: What actually occurred
  - absolute_error: |predicted - observed|
  - relative_error: absolute_error / |predicted| (when predicted ≠ 0)
  - confidence: How confident the predictor was
  - calibration: confidence vs actual accuracy ratio
  - timestamp: When assessment was made
  - episode_ids: Supporting evidence episodes
  - generation: Which recursive generation produced this

  ## Engineering Rules

  1. **Immutable**: Once created, never modified
  2. **Canonical**: Single source of truth for prediction quality
  3. **Composable**: All capabilities use identical structure
  4. **Traceable**: References supporting episodes
  5. **Measurable**: Enables longitudinal tracking

  ## Example

      # Create prediction assessment from simulation and pilot
      assessment = PredictionAssessment.new(%{
        predicted_value: 0.18,
        observed_value: 0.12,
        confidence: 0.85,
        episode_ids: [:episode_1, :episode_2],
        generation: 1
      })

      # Access metrics
      assessment.absolute_error      # => 0.06
      assessment.relative_error      # => 33.33%
      assessment.calibration         # => 0.94 (well-calibrated)
      assessment.prediction_reliable # => true (< 15% error)
  """

  defstruct [
    # Core identification
    :id,
    :assessment_timestamp,

    # Prediction values
    :predicted_value,
    :observed_value,

    # Error metrics
    :absolute_error,
    :relative_error,

    # Confidence and calibration
    :confidence,
    :calibration,

    # Provenance
    :episode_ids,
    :generation,
    :source_capability,

    # Quality indicators
    :prediction_reliable,
    :assessment_metadata
  ]

  @type t :: %__MODULE__{
    id: String.t(),
    assessment_timestamp: DateTime.t(),
    predicted_value: float(),
    observed_value: float(),
    absolute_error: float(),
    relative_error: float() | nil,
    confidence: float() | nil,
    calibration: float() | nil,
    episode_ids: [atom()] | nil,
    generation: integer() | nil,
    source_capability: atom() | nil,
    prediction_reliable: boolean(),
    assessment_metadata: map() | nil
  }

  @doc """
  Create a new PredictionAssessment.

  Automatically calculates all derived metrics (errors, calibration, reliability).

  ## Parameters
  - `opts`: keyword list or map with required fields:
    - :predicted_value - float() what was forecast
    - :observed_value - float() what actually occurred
    - Optional: :confidence, :episode_ids, :generation, :source_capability, :metadata

  ## Returns
  PredictionAssessment.t()
  """
  def new(opts \\ []) do
    opts = if is_map(opts), do: Map.to_list(opts), else: opts

    predicted = Keyword.get(opts, :predicted_value)
    observed = Keyword.get(opts, :observed_value)

    if predicted == nil or observed == nil do
      raise ArgumentError, message: "PredictionAssessment requires :predicted_value and :observed_value"
    end

    # Calculate error metrics
    absolute_error = abs(predicted - observed)
    relative_error = if predicted != 0 do
      Float.round(absolute_error / abs(predicted) * 100, 2)
    else
      nil
    end

    # Calculate calibration if confidence provided
    confidence = Keyword.get(opts, :confidence)
    calibration = if confidence != nil and confidence > 0 do
      # Calibration = expected_accuracy / confidence
      # expected_accuracy = 1.0 - normalized_error (capped at 1.0)
      normalized_error = min(absolute_error, 1.0)
      expected_accuracy = 1.0 - normalized_error
      Float.round(expected_accuracy / confidence, 3)
    else
      nil
    end

    # Determine reliability (< 15% absolute error is considered reliable)
    prediction_reliable = absolute_error < 0.15

    %__MODULE__{
      id: Keyword.get(opts, :id, "prediction_#{System.monotonic_time(:millisecond)}"),
      assessment_timestamp: DateTime.utc_now(),
      predicted_value: Float.round(predicted, 4),
      observed_value: Float.round(observed, 4),
      absolute_error: Float.round(absolute_error, 4),
      relative_error: relative_error,
      confidence: confidence,
      calibration: calibration,
      episode_ids: Keyword.get(opts, :episode_ids),
      generation: Keyword.get(opts, :generation),
      source_capability: Keyword.get(opts, :source_capability),
      prediction_reliable: prediction_reliable,
      assessment_metadata: Keyword.get(opts, :metadata)
    }
  end

  @doc """
  Create PredictionAssessment from simulation and pilot results.

  Convenience function for Institution Adaptation pipeline.

  ## Parameters
  - `simulation_results`: map() with :average_success_rate_increase or similar
  - `pilot_results`: map() with :success_rate or similar
  - `baseline_success_rate`: float() historical baseline
  - `opts`: additional options (confidence, episode_ids, etc.)

  ## Returns
  PredictionAssessment.t()
  """
  def from_simulation_and_pilot(simulation_results, pilot_results, baseline_success_rate, opts \\ []) do
    predicted = simulation_results[:average_success_rate_increase] || 0
    actual_improvement = pilot_results[:success_rate] - baseline_success_rate

    opts = Keyword.merge(opts, [
      predicted_value: predicted,
      observed_value: actual_improvement
    ])

    new(opts)
  end

  @doc """
  Aggregate multiple PredictionAssessments into summary statistics.

  Computes civilization-level prediction quality metrics.

  ## Parameters
  - `assessments`: [PredictionAssessment.t()] list of assessments

  ## Returns
  map() with aggregate metrics:
    - total_assessments: count
    - average_absolute_error: mean absolute error
    - average_relative_error: mean relative error (%)
    - prediction_reliability_rate: % of reliable predictions
    - average_calibration: mean calibration score
    - best_prediction: assessment with lowest error
    - worst_prediction: assessment with highest error
  """
  def aggregate(assessments) when is_list(assessments) do
    if length(assessments) == 0 do
      %{
        total_assessments: 0,
        average_absolute_error: nil,
        average_relative_error: nil,
        prediction_reliability_rate: nil,
        average_calibration: nil,
        best_prediction: nil,
        worst_prediction: nil
      }
    else
      total = length(assessments)

      # Calculate averages
      avg_absolute = Enum.sum(Enum.map(assessments, fn a -> a.absolute_error end)) / total
      avg_relative_values = Enum.filter(assessments, fn a -> a.relative_error != nil end)
      avg_relative = if length(avg_relative_values) > 0 do
        Enum.sum(Enum.map(avg_relative_values, fn a -> a.relative_error end)) / length(avg_relative_values)
      else
        nil
      end

      reliability_count = Enum.count(assessments, fn a -> a.prediction_reliable end)
      reliability_rate = Float.round(reliability_count / total, 3)

      calibration_values = Enum.filter(assessments, fn a -> a.calibration != nil end)
      avg_calibration = if length(calibration_values) > 0 do
        Float.round(Enum.sum(Enum.map(calibration_values, fn a -> a.calibration end)) / length(calibration_values), 3)
      else
        nil
      end

      # Find best and worst
      best = Enum.min_by(assessments, fn a -> a.absolute_error end)
      worst = Enum.max_by(assessments, fn a -> a.absolute_error end)

      %{
        total_assessments: total,
        average_absolute_error: Float.round(avg_absolute, 4),
        average_relative_error: avg_relative && Float.round(avg_relative, 2),
        prediction_reliability_rate: reliability_rate,
        average_calibration: avg_calibration,
        best_prediction: %{
          id: best.id,
          absolute_error: best.absolute_error,
          predicted: best.predicted_value,
          observed: best.observed_value
        },
        worst_prediction: %{
          id: worst.id,
          absolute_error: worst.absolute_error,
          predicted: worst.predicted_value,
          observed: worst.observed_value
        }
      }
    end
  end

  @doc """
  Check if prediction is within acceptable error bounds.

  ## Parameters
  - `assessment`: PredictionAssessment.t()
  - `threshold`: float() maximum acceptable absolute error (default: 0.15)

  ## Returns
  boolean()
  """
  def within_threshold?(assessment, threshold \\ 0.15) do
    assessment.absolute_error < threshold
  end

  @doc """
  Format prediction assessment for display.

  ## Parameters
  - `assessment`: PredictionAssessment.t()

  ## Returns
  String.t() human-readable summary
  """
  def to_string(assessment) do
    """
    Prediction Assessment #{assessment.id}
    ──────────────────────────────────────
    Predicted: #{Float.round(assessment.predicted_value, 4)}
    Observed:  #{Float.round(assessment.observed_value, 4)}
    
    Absolute Error: #{Float.round(assessment.absolute_error, 4)}
    Relative Error: #{if assessment.relative_error, do: "#{Float.round(assessment.relative_error, 2)}%", else: "N/A"}
    
    Confidence: #{if assessment.confidence, do: Float.round(assessment.confidence, 3), else: "N/A"}
    Calibration: #{if assessment.calibration, do: Float.round(assessment.calibration, 3), else: "N/A"}
    
    Reliable: #{assessment.prediction_reliable}
    Generation: #{assessment.generation || "N/A"}
    Source: #{inspect(assessment.source_capability)}
    """
  end
end
