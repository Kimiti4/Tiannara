defmodule ObservationBus.CIL.Futures.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      ObservationBus.CIL.Futures.FutureGenerator,
      ObservationBus.CIL.Futures.CounterfactualEngine,
      ObservationBus.CIL.Futures.BranchExplorer,
      ObservationBus.CIL.Futures.FitnessEvaluator,
      ObservationBus.CIL.Futures.FutureOpportunityEngine,
      ObservationBus.CIL.Futures.CatastrophicRiskEngine,
      ObservationBus.CIL.Futures.FutureArchive,
    ]

    Supervisor.init(children, strategy: :one_for_one, name: __MODULE__)
  end
end
