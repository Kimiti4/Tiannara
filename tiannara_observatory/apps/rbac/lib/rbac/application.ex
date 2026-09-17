defmodule Rbac.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [Rbac.Repo, Rbac.Supervisor]
    opts = [strategy: :rest_for_one, name: Rbac.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
