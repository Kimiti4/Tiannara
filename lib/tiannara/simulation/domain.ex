defmodule Tiannara.Simulation.Domain do
  defmodule SimulationScenario do
    defstruct [:id, :design_id, :name, :description, :baseline_snapshot_id,
      :injected_changes, :parameters, :horizons, :status, :created_at]

    @type t :: %__MODULE__{}
    @horizons [10, 50, 100]

    def default_horizons, do: @horizons

    def new(attrs) do
      %__MODULE__{
        id: "sim_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}",
        injected_changes: [], parameters: %{}, horizons: @horizons,
        status: :proposed, created_at: DateTime.utc_now()
      } |> struct(attrs)
    end
  end

  defmodule HorizonForecast do
    defstruct [:id, :scenario_id, :horizon_years, :predicted_state, :confidence,
      :uncertainty, :key_changes, :risks, :opportunities, :computed_at]

    @type t :: %__MODULE__{}

    def new(attrs) do
      %__MODULE__{
        id: "forecast_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}",
        key_changes: [], risks: [], opportunities: [], computed_at: DateTime.utc_now()
      } |> struct(attrs)
    end
  end

  defmodule ImpactAssessment do
    defstruct [:id, :scenario_id, :design_id, :scientific_impact, :engineering_impact,
      :civilizational_impact, :sustainability_impact, :safety_impact, :economic_impact,
      :composite_score, :recommendation, :confidence, :uncertainty, :horizon_forecasts,
      :created_at]

    @type t :: %__MODULE__{}

    @dimensions [:scientific_impact, :engineering_impact, :civilizational_impact,
      :sustainability_impact, :safety_impact, :economic_impact]

    def dimensions, do: @dimensions

    def new(attrs) do
      %__MODULE__{
        id: "impact_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}",
        horizon_forecasts: [], created_at: DateTime.utc_now()
      } |> struct(attrs)
    end
  end

  defmodule SimulationResult do
    defstruct [:id, :scenario_id, :design_id, :status, :impact_assessment,
      :baseline_comparison, :duration_ms, :error, :completed_at]

    @type t :: %__MODULE__{}

    def new(attrs) do
      %__MODULE__{
        id: "result_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}",
        status: :pending, completed_at: nil
      } |> struct(attrs)
    end
  end
end
