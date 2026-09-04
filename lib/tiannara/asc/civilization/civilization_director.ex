defmodule Tiannara.ASC.Civilization.Director do
  use GenServer
  require Logger

  @civilization_interval :timer.hours(24)

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def optimize, do: GenServer.cast(__MODULE__, :optimize)
  def stats, do: GenServer.call(__MODULE__, :stats)
  def current_plan, do: GenServer.call(__MODULE__, :current_plan)
  def decisions, do: GenServer.call(__MODULE__, :decisions)

  @impl true
  def init(_opts) do
    subscribe_to_inputs()
    schedule_optimization()
    {:ok, %{
      cycles: 0, current_plan: nil, decisions: [], risk_assessments: [],
      forecasts: [], feedback_sent: 0, started_at: DateTime.utc_now()
    }}
  end

  @impl true
  def handle_cast(:optimize, state) do
    {:noreply, run_civilization_cycle(state)}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    {:reply, %{
      cycles: state.cycles, decisions_made: length(state.decisions),
      risk_assessments: length(state.risk_assessments),
      forecasts_generated: length(state.forecasts),
      feedback_sent: state.feedback_sent, started_at: state.started_at
    }, state}
  end

  def handle_call(:current_plan, _from, state), do: {:reply, state.current_plan, state}
  def handle_call(:decisions, _from, state), do: {:reply, state.decisions, state}

  @impl true
  def handle_info(:scheduled_optimization, state) do
    new_state = run_civilization_cycle(state)
    schedule_optimization()
    {:noreply, new_state}
  end

  @impl true
  def handle_info({:executive_bus_message, %{type: "campaign.phase10.input", payload: _payload}}, state) do
    Logger.info("CivilizationDirector: Received Phase 10 campaign input")
    new_state = run_civilization_cycle(state)
    {:noreply, new_state}
  end

  def handle_info(_, state), do: {:noreply, state}

  defp run_civilization_cycle(state) do
    Logger.info("CivilizationDirector: Starting cycle #{state.cycles + 1}")

    world_state = Tiannara.ASC.Civilization.WorldModel.current_state()
    {:ok, risk_assessment} = Tiannara.ASC.Civilization.GlobalRiskEngine.assess(world_state)
    {:ok, sustainability} = Tiannara.ASC.Civilization.SustainabilityEngine.evaluate(world_state)
    {:ok, equity} = Tiannara.ASC.Civilization.IntergenerationalEquityEngine.evaluate(world_state)
    {:ok, policy_results} = Tiannara.ASC.Civilization.PolicySimulationEngine.simulate(world_state, risk_assessment)
    {:ok, forecast} = Tiannara.ASC.Civilization.LongTermForecastEngine.forecast(world_state, policy_results)
    {:ok, plan} = Tiannara.ASC.Civilization.Planner.generate_plan(world_state, risk_assessment, sustainability, equity, forecast)
    {:ok, decisions} = Tiannara.ASC.Civilization.DecisionEngine.decide(plan, risk_assessment, sustainability)
    {:ok, governance} = Tiannara.ASC.Civilization.ConstitutionalGovernanceEngine.review(decisions)

    Tiannara.ASC.Civilization.KnowledgePreservationEngine.preserve(%{
      cycle: state.cycles + 1, plan: plan, decisions: decisions,
      risk: risk_assessment, sustainability: sustainability, forecast: forecast
    })

    Tiannara.ASC.Civilization.FeedbackAggregator.aggregate_and_feed_back(%{
      plan: plan, decisions: governance.approved_decisions,
      risk: risk_assessment, sustainability: sustainability,
      forecast: forecast, cycle: state.cycles + 1
    })

    Tiannara.ASC.Civilization.Metrics.record_cycle(%{
      cycle: state.cycles + 1, risk_level: risk_assessment.overall_risk,
      sustainability_score: sustainability.score, equity_score: equity.score,
      decisions: length(decisions), forecast_horizon: forecast.horizon_years
    })

    Logger.info("CivilizationDirector: Cycle #{state.cycles + 1} complete — loop closed")

    %{state |
      cycles: state.cycles + 1, current_plan: plan,
      decisions: (governance.approved_decisions ++ state.decisions) |> Enum.take(500),
      risk_assessments: [risk_assessment | state.risk_assessments] |> Enum.take(100),
      forecasts: [forecast | state.forecasts] |> Enum.take(100),
      feedback_sent: state.feedback_sent + 1
    }
  end

  defp subscribe_to_inputs do
    try do
      Tiannara.CEL.Services.EventBus.subscribe("campaign.phase10.input")
    rescue
      _ -> :ok
    end
  end

  defp schedule_optimization do
    Process.send_after(self(), :scheduled_optimization, @civilization_interval)
  end
end
