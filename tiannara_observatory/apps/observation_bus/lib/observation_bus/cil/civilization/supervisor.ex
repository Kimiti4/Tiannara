defmodule ObservationBus.CIL.Civilization.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      ObservationBus.CIL.Civilization.CivilizationState,
      ObservationBus.CIL.Civilization.TechnologyDiffusion,
      ObservationBus.CIL.Civilization.InfrastructureEvolution,
      ObservationBus.CIL.Civilization.KnowledgeEconomy,
      ObservationBus.CIL.Civilization.SocietalDynamics,
      ObservationBus.CIL.Civilization.ResilienceEngine,
      ObservationBus.CIL.Civilization.KardashevEngine,
    ]

    Supervisor.init(children, strategy: :one_for_one, name: __MODULE__)
  end
end
