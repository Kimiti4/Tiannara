defmodule ObservationBus.CIL.Prediction.Supervisor do
  @moduledoc """
  Supervisor for the Constitutional Predictive Observatory (CPO) — M11.

  Starts all CPO subsystems:
    1. ForecastRegistry — ETS-backed forecast storage
    2. ForecastEngine — multi-horizon forecast generation
    3. ScenarioSimulator — scenario-based outcome simulation
    4. RiskProjection — constitutional failure forecasting
    5. CapacityPlanner — resource capacity planning
    6. MissionForecast — milestone projection
    7. PreparednessEngine — readiness assessment
    8. PredictionValidator — forecast accuracy validation
  """
  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      ObservationBus.CIL.Prediction.ForecastRegistry,
      ObservationBus.CIL.Prediction.ForecastEngine,
      ObservationBus.CIL.Prediction.ScenarioSimulator,
      ObservationBus.CIL.Prediction.RiskProjection,
      ObservationBus.CIL.Prediction.CapacityPlanner,
      ObservationBus.CIL.Prediction.MissionForecast,
      ObservationBus.CIL.Prediction.PreparednessEngine,
      ObservationBus.CIL.Prediction.PredictionValidator
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
