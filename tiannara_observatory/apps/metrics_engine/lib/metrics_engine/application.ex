defmodule MetricsEngine.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [MetricsEngine.Repo, MetricsEngine.Supervisor]
    opts = [strategy: :rest_for_one, name: MetricsEngine.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
