defmodule ObservationBus.CIL.Strategy.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      ObservationBus.CIL.Strategy.StrategicPlanner,
      ObservationBus.CIL.Strategy.CapabilityGraph,
      ObservationBus.CIL.Strategy.TechnologyRoadmap,
      ObservationBus.CIL.Strategy.ResourcePlanner,
      ObservationBus.CIL.Strategy.BottleneckEngine,
      ObservationBus.CIL.Strategy.OpportunityEngine,
      ObservationBus.CIL.Strategy.StrategicRisk,
    ]

    Supervisor.init(children, strategy: :one_for_one, name: __MODULE__)
  end
end
