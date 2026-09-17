defmodule ObservatoryCore.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ObservatoryCore.Repo,
      ObservatoryCore.Boot.Engine,
      ObservatoryCore.Lifecycle.StateMachine,
      ObservatoryCore.Supervisor
    ]

    opts = [strategy: :rest_for_one, name: ObservatoryCore.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
