defmodule Tiannara.CCI.CivilizationForecastingEngine do
  @moduledoc """
  Civilization Forecasting Engine (CFE): extends forecasting from subsystem
  prediction to civilization-scale trajectories.
  Generates multiple possible futures with probabilities and intervention points.
  """
  use GenServer
  alias Tiannara.CCI.Models.{CivilizationForecast, PossibleFuture}

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, %{}, opts)

  def forecast(pid, civilization_state, horizon), do: GenServer.call(pid, {:forecast, civilization_state, horizon})
  def get_latest_forecast(pid), do: GenServer.call(pid, :latest)

  @impl true
  def init(_), do: {:ok, %{forecasts: [], latest: nil}}

  @impl true
  def handle_call({:forecast, civ_state, horizon}, _from, state) do
    baseline = project_baseline(civ_state, horizon)
    futures = generate_possible_futures(civ_state, horizon)
    risks = identify_risks(civ_state, futures)
    opportunities = identify_opportunities(civ_state, futures)
    bottlenecks = identify_bottlenecks(civ_state)

    forecast = %CivilizationForecast{
      id: UUID.uuid4(),
      timestamp: DateTime.utc_now(),
      horizon_cycles: horizon,
      baseline_trajectory: baseline,
      possible_futures: futures,
      risks: risks,
      opportunities: opportunities,
      bottlenecks: bottlenecks,
      confidence: calculate_forecast_confidence(civ_state, horizon),
      uncertainty_factors: identify_uncertainty_factors(civ_state)
    }

    state = %{state |
      forecasts: [forecast | state.forecasts] |> Enum.take(100),
      latest: forecast
    }
    {:reply, {:ok, forecast}, state}
  end

  @impl true
  def handle_call(:latest, _from, state), do: {:reply, state.latest, state}

  defp project_baseline(civ_state, horizon) do
    %{
      knowledge_growth: civ_state.knowledge_state.validated_assets * 1.05 * horizon,
      capability_growth: civ_state.capability_state.promoted * 1.03 * horizon,
      institutional_stability: civ_state.institutional_state.active,
      resource_trajectory: civ_state.resource_state.available - (civ_state.resource_state.allocated * horizon * 0.1)
    }
  end

  defp generate_possible_futures(_civ_state, _horizon) do
    [
      %PossibleFuture{
        id: UUID.uuid4(), name: "Stable Growth", probability: 0.45,
        description: "Continued balanced advancement across all domains.",
        characteristics: %{innovation: :steady, stability: :high, diversity: :maintained},
        leading_indicators: [:resource_availability, :institutional_health],
        intervention_points: [:research_funding, :knowledge_preservation]
      },
      %PossibleFuture{
        id: UUID.uuid4(), name: "Capability Stagnation", probability: 0.20,
        description: "Diminishing returns on current research approaches.",
        characteristics: %{innovation: :declining, stability: :medium, diversity: :reduced},
        leading_indicators: [:discovery_rate, :mutation_effectiveness],
        intervention_points: [:paradigm_shift, :new_research_domains]
      },
      %PossibleFuture{
        id: UUID.uuid4(), name: "Knowledge Fragmentation", probability: 0.15,
        description: "Specialization without integration; siloed civilizations.",
        characteristics: %{innovation: :localized, stability: :low, diversity: :high_but_disconnected},
        leading_indicators: [:cross_domain_collaboration, :knowledge_reuse_rate],
        intervention_points: [:integration_mechanisms, :shared_ontologies]
      },
      %PossibleFuture{
        id: UUID.uuid4(), name: "Uncontrolled Optimization", probability: 0.12,
        description: "Narrow optimization at expense of broader health.",
        characteristics: %{innovation: :focused, stability: :fragile, diversity: :collapsed},
        leading_indicators: [:monoculture_indicators, :constitutional_violations],
        intervention_points: [:diversity_preservation, :constitutional_enforcement]
      },
      %PossibleFuture{
        id: UUID.uuid4(), name: "Breakthrough Era", probability: 0.08,
        description: "Multiple converging discoveries enable rapid advancement.",
        characteristics: %{innovation: :explosive, stability: :transitional, diversity: :expanding},
        leading_indicators: [:cross_domain_synthesis, :capability_combination_rate],
        intervention_points: [:resource_scaling, :governance_adaptation]
      }
    ]
  end

  defp identify_risks(_civ_state, _futures) do
    [
      %{risk: :knowledge_decay, probability: 0.25, impact: :high, mitigation: :active_preservation},
      %{risk: :institutional_corruption, probability: 0.15, impact: :critical, mitigation: :oversight_mechanisms},
      %{risk: :resource_exhaustion, probability: 0.30, impact: :medium, mitigation: :efficiency_improvement}
    ]
  end

  defp identify_opportunities(_civ_state, _futures) do
    [
      %{opportunity: :cross_domain_synthesis, potential: 0.8, requirements: [:integration_infrastructure]},
      %{opportunity: :capability_combination, potential: 0.75, requirements: [:compatibility_analysis]}
    ]
  end

  defp identify_bottlenecks(civ_state) do
    bottlenecks = []
    bottlenecks = if civ_state.resource_state.available < civ_state.resource_state.allocated * 1.2,
      do: [:resource_constraint | bottlenecks], else: bottlenecks
    bottlenecks = if civ_state.institutional_state.active < 5,
      do: [:institutional_capacity | bottlenecks], else: bottlenecks
    bottlenecks
  end

  defp calculate_forecast_confidence(_civ_state, horizon) do
    max(0.3, 0.9 - (horizon * 0.01))
  end

  defp identify_uncertainty_factors(_civ_state) do
    [:external_shocks, :paradigm_shifts, :resource_volatility, :discovery_unpredictability]
  end
end
