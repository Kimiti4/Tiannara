defmodule ReplayStore.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [ReplayStore.Repo, ReplayStore.Supervisor]
    opts = [strategy: :rest_for_one, name: ReplayStore.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
