defmodule Tiannara.ASC.Civilization.Supervisor do
  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      {Tiannara.ASC.Civilization.Director, []},
      {Tiannara.ASC.Civilization.WorldModel, []},
      {Tiannara.ASC.Civilization.Planner, []},
      {Tiannara.ASC.Civilization.PolicySimulationEngine, []},
      {Tiannara.ASC.Civilization.LongTermForecastEngine, []},
      {Tiannara.ASC.Civilization.SustainabilityEngine, []},
      {Tiannara.ASC.Civilization.GlobalRiskEngine, []},
      {Tiannara.ASC.Civilization.Metrics, []},
      {Tiannara.ASC.Civilization.DecisionEngine, []},
      {Tiannara.ASC.Civilization.ConstitutionalGovernanceEngine, []},
      {Tiannara.ASC.Civilization.IntergenerationalEquityEngine, []},
      {Tiannara.ASC.Civilization.KnowledgePreservationEngine, []},
      {Tiannara.ASC.Civilization.FeedbackAggregator, []}
    ]

    Supervisor.init(children, strategy: :one_for_one, max_restarts: 5, max_seconds: 60)
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :supervisor
    }
  end
end
