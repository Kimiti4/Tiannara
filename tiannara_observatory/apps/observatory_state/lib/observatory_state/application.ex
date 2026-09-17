defmodule ObservatoryState.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [ObservatoryState.Supervisor]
    opts = [strategy: :one_for_one, name: ObservatoryState.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
