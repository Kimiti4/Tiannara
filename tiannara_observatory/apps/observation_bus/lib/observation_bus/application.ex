defmodule ObservationBus.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ObservationBus.Supervisor,
      ObservationBus.TiannaraBridge
    ]

    opts = [strategy: :one_for_one, name: ObservationBus.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
