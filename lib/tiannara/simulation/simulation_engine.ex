defmodule Tiannara.Simulation.SimulationEngine do
  use GenServer
  use Tiannara.ExecutiveService.Base
  require Logger

  alias Tiannara.Simulation.{ScenarioBuilder, ImpactForecaster, HorizonPlanner, Events}
  alias Tiannara.Simulation.Domain.{SimulationScenario, SimulationResult}
  alias Tiannara.Engineering.Domain.EngineeringDesign

  @impl Tiannara.ExecutiveService
  def id, do: :simulation_engine

  @impl Tiannara.ExecutiveService
  def version, do: "1.0.0"

  @impl Tiannara.ExecutiveService
  def capabilities do
    [:civilizational_simulation, :impact_forecasting, :multi_horizon_planning, :scenario_comparison]
  end

  @impl Tiannara.ExecutiveService
  def dependencies, do: [:persistent_memory, :event_transport]

  @impl Tiannara.ExecutiveService
  def priority, do: :low

  @impl Tiannara.ExecutiveService
  def constitutional_score do
    stats = GenServer.call(__MODULE__, :stats)
    %Tiannara.CEL.Kernel.ConstitutionalScore{
      service_id: id(), health: if(stats.healthy, do: 1.0, else: 0.0),
      constitutional_alignment: 1.0, transparency: 1.0, explainability: 1.0,
      evidence_quality: stats.completion_rate, human_oversight: 1.0,
      computed_at: DateTime.utc_now()
    }
  end

  @impl Tiannara.ExecutiveService
  def health do
    GenServer.call(__MODULE__, :health)
  end

  @impl Tiannara.ExecutiveService
  def boot(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl Tiannara.ExecutiveService
  def shutdown(reason), do: GenServer.stop(__MODULE__, reason)

  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def simulate_design(%EngineeringDesign{} = design) do
    GenServer.call(__MODULE__, {:simulate, design}, 30_000)
  end

  def compare_designs(%EngineeringDesign{} = a, %EngineeringDesign{} = b) do
    GenServer.call(__MODULE__, {:compare, a, b}, 30_000)
  end

  def completed_simulations do
    GenServer.call(__MODULE__, :completed)
  end

  def stats do
    GenServer.call(__MODULE__, :stats)
  end

  @impl true
  def init(_opts) do
    {:ok, %{active_simulations: %{}, completed_results: [], simulations_run: 0,
      simulations_completed: 0, designs_rejected: 0, completion_rate: 1.0,
      healthy: true, started_at: DateTime.utc_now()}}
  end

  @impl true
  def handle_call({:simulate, design}, _from, state) do
    start_time = System.monotonic_time(:millisecond)
    scenario = ScenarioBuilder.build(design)

    case ScenarioBuilder.validate(scenario) do
      {:error, reason} ->
        {:reply, {:error, {:invalid_scenario, reason}}, state}
      :ok ->
        Events.emit(:scenario_created, scenario.id, %{design_id: design.id,
          horizons: scenario.horizons, changes: length(scenario.injected_changes)})

        assessment = ImpactForecaster.forecast(scenario)

        Enum.each(assessment.horizon_forecasts, fn forecast ->
          Events.emit(:horizon_forecasted, scenario.id, %{
            horizon_years: forecast.horizon_years, confidence: forecast.confidence,
            composite: assessment.composite_score})
        end)

        Events.emit(:impact_assessed, scenario.id, %{design_id: design.id,
          composite_score: assessment.composite_score,
          recommendation: assessment.recommendation, confidence: assessment.confidence})

        deployment_plan = HorizonPlanner.plan(scenario, assessment.horizon_forecasts)
        optimal_window = HorizonPlanner.optimal_deployment_window(assessment.horizon_forecasts)

        duration = System.monotonic_time(:millisecond) - start_time

        result = SimulationResult.new(%{scenario_id: scenario.id, design_id: design.id,
          status: :completed, impact_assessment: assessment,
          baseline_comparison: %{optimal_deployment_window: optimal_window,
            deployment_plan: deployment_plan},
          duration_ms: duration, completed_at: DateTime.utc_now()})

        Events.emit(:simulation_completed, scenario.id, %{design_id: design.id,
          recommendation: assessment.recommendation,
          composite_score: assessment.composite_score, duration_ms: duration})

        rejected_increment = if assessment.recommendation == :reject, do: 1, else: 0
        new_state = %{state | completed_results: [result | state.completed_results] |> Enum.take(200),
          simulations_run: state.simulations_run + 1,
          simulations_completed: state.simulations_completed + 1,
          designs_rejected: state.designs_rejected + rejected_increment,
          completion_rate: safe_div(state.simulations_completed + 1, state.simulations_run + 1)}

        {:reply, {:ok, result}, new_state}
    end
  end

  @impl true
  def handle_call({:compare, design_a, design_b}, _from, state) do
    scenario_a = ScenarioBuilder.build(design_a)
    scenario_b = ScenarioBuilder.build(design_b)
    assessment_a = ImpactForecaster.forecast(scenario_a)
    assessment_b = ImpactForecaster.forecast(scenario_b)
    comparison = ImpactForecaster.compare(assessment_a, assessment_b)

    Events.emit(:comparison_completed, scenario_a.id, %{
      design_a: design_a.id, design_b: design_b.id, winner: comparison.overall_winner})

    {:reply, {:ok, comparison}, state}
  end

  @impl true
  def handle_call(:completed, _from, state) do
    {:reply, state.completed_results, state}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    {:reply, %{healthy: state.healthy, simulations_run: state.simulations_run,
      simulations_completed: state.simulations_completed,
      designs_rejected: state.designs_rejected, completion_rate: state.completion_rate,
      active_simulations: map_size(state.active_simulations)}, state}
  end

  @impl true
  def handle_call(:health, _from, state) do
    {:reply, if(state.healthy, do: :healthy, else: :degraded), state}
  end

  @impl true
  def handle_info(_, state), do: {:noreply, state}

  defp safe_div(_n, 0), do: 1.0
  defp safe_div(n, d), do: n / d
end
