defmodule TelemetryGateway.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [TelemetryGateway.Supervisor]
    opts = [strategy: :one_for_one, name: TelemetryGateway.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
