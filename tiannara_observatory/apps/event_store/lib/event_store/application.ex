defmodule EventStore.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [EventStore.Repo, EventStore.Supervisor]
    opts = [strategy: :rest_for_one, name: EventStore.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
