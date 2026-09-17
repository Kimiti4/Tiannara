defmodule ObservationBus.CIL.Federation.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      ObservationBus.CIL.Federation.ObservatoryFederation,
      ObservationBus.CIL.Federation.KnowledgeExchange,
      ObservationBus.CIL.Federation.ConsensusEngine,
      ObservationBus.CIL.Federation.ScientificFederation,
      ObservationBus.CIL.Federation.DistributedReplay,
      ObservationBus.CIL.Federation.CivilizationMemory,
      ObservationBus.CIL.Federation.TrustPropagation,
    ]

    Supervisor.init(children, strategy: :one_for_one, name: __MODULE__)
  end
end
