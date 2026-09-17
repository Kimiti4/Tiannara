defmodule ObservatoryState.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    children = [
      ObservatoryState.Runtime,
      ObservatoryState.Scientific,
      ObservatoryState.Engineering,
      ObservatoryState.Knowledge,
      ObservatoryState.Planetary,
      ObservatoryState.Civilization,
      ObservatoryState.Evolution,
      ObservatoryState.Governance,
      ObservatoryState.Certification,
      ObservatoryState.SnapshotScheduler,
      ObservatoryState.Reconciliation
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
