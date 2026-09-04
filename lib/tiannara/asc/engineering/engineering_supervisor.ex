defmodule Tiannara.ASC.Engineering.Supervisor do
  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      {Tiannara.ASC.Engineering.Director, []},
      {Tiannara.ASC.Engineering.DesignSynthesisEngine, []},
      {Tiannara.ASC.Engineering.CADGenerationEngine, []},
      {Tiannara.ASC.Engineering.SystemsEngineeringEngine, []},
      {Tiannara.ASC.Engineering.OptimizationEngine, []},
      {Tiannara.ASC.Engineering.ManufacturingPlanner, []},
      {Tiannara.ASC.Engineering.DigitalTwinManager, []},
      {Tiannara.ASC.Engineering.ValidationEngine, []},
      {Tiannara.ASC.Engineering.KnowledgeBase, []}
    ]

    Supervisor.init(children, strategy: :one_for_one, max_restarts: 5, max_seconds: 60)
  end
end
