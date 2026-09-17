defmodule ObservationBus.CIL.Ops.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      ObservationBus.CIL.Ops.OperationsPlanner,
      ObservationBus.CIL.Ops.ExecutionOrchestrator,
      ObservationBus.CIL.Ops.ResourceCommander,
      ObservationBus.CIL.Ops.AuthorizationEngine,
      ObservationBus.CIL.Ops.SafetySupervisor,
      ObservationBus.CIL.Ops.RecoveryCommander,
      ObservationBus.CIL.Ops.OperationalReplay,
    ]

    Supervisor.init(children, strategy: :one_for_one, name: __MODULE__)
  end
end
