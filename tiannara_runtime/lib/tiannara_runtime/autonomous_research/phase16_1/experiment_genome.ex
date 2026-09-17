defmodule TiannaraRuntime.AutonomousResearch.Phase16_1.ExperimentGenome do
  @moduledoc """
  Phase 16.1 Module 4 — Experiment Genome (Pure Implementation)

  Defines the parameter space for experiment design:
  - variables to manipulate
  - controls to hold fixed
  - treatments to apply
  - metrics to observe
  - predictions to test
  - sample size and termination conditions
  """

  @enforce_keys [:variables, :metrics]
  defstruct [
    :variables,
    :controls,
    :treatments,
    :metrics,
    :predictions,
    :sample_size,
    :termination_conditions
  ]

  @type t :: %__MODULE__{
    variables: map(),
    controls: map(),
    treatments: list(map()),
    metrics: list(map()),
    predictions: list(map()),
    sample_size: non_neg_integer(),
    termination_conditions: list(map())
  }

  @doc "Build a new experiment genome with defaults"
  @spec new(map()) :: t()
  def new(fields \\ %{}) do
    %__MODULE__{
      variables: Map.get(fields, :variables, %{}),
      controls: Map.get(fields, :controls, %{}),
      treatments: Map.get(fields, :treatments, []),
      metrics: Map.get(fields, :metrics, [%{"measurement_key" => "outcome", "observable" => "result", "units" => "dimensionless"}]),
      predictions: Map.get(fields, :predictions, []),
      sample_size: Map.get(fields, :sample_size, 1000),
      termination_conditions: Map.get(fields, :termination_conditions, [%{"criterion_type" => "CONFIDENCE", "threshold" => 0.95}])
    }
  end

  @doc "Serialize genome to canonical map"
  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = genome) do
    %{
      "variables" => genome.variables,
      "controls" => genome.controls,
      "treatments" => genome.treatments,
      "metrics" => genome.metrics,
      "predictions" => genome.predictions,
      "sample_size" => genome.sample_size,
      "termination_conditions" => genome.termination_conditions
    }
  end
end
