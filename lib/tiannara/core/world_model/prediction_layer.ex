defmodule Tiannara.Core.WorldModel.PredictionLayer do
  @moduledoc """
  Future state and scenario generation layer.

  Connects directly to the Prediction Domain.
  Stores multiple possible futures with probabilities.

  Example:
    Scenario A: Market Bull, Probability 71%
    Scenario B: Market Sideways, Probability 18%
    Scenario C: Market Bear, Probability 11%
  """

  defstruct [
    :scenarios,
    :active_scenario,
    :horizon_periods,
    :confidence_in_forecasts
  ]

  @doc "Create a new prediction layer."
  def new do
    %__MODULE__{
      scenarios: [],
      active_scenario: nil,
      horizon_periods: [],
      confidence_in_forecasts: 0.0
    }
  end

  @doc "Add a scenario with probability."
  def add_scenario(layer, scenario_id, probability, forecast) do
    scenario = %{
      id: scenario_id,
      probability: probability,
      forecast: forecast,
      created_at: DateTime.utc_now()
    }

    new_scenarios = [scenario | layer.scenarios]
    %{layer | scenarios: new_scenarios}
  end

  @doc "Set active scenario for planning."
  def set_active_scenario(layer, scenario_id) do
    %{layer | active_scenario: scenario_id}
  end

  @doc "Get scenarios sorted by probability."
  def most_likely_scenarios(layer, count \\ 3) do
    layer.scenarios
    |> Enum.sort_by(fn s -> s.probability end, :desc)
    |> Enum.take(count)
  end

  @doc "Update overall forecast confidence."
  def update_forecast_confidence(layer, confidence) do
    %{layer | confidence_in_forecasts: confidence}
  end
end
