defmodule ObservationBus.CIL.Meta.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      ObservationBus.CIL.Meta.MetaObservatory,
      ObservationBus.CIL.Meta.InstrumentationEvolution,
      ObservationBus.CIL.Meta.ArchitectureEvolution,
      ObservationBus.CIL.Meta.ConstitutionalGovernance,
      ObservationBus.CIL.Meta.ObservatoryImmuneSystem,
      ObservationBus.CIL.Meta.SelfCertification,
      ObservationBus.CIL.Meta.ObservatoryLineage,
    ]

    Supervisor.init(children, strategy: :one_for_one, name: __MODULE__)
  end
end
