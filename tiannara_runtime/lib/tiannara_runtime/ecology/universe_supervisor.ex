defmodule Tiannara.UniverseSupervisor do
  @moduledoc """
  Supervisor for the Tiannara Cognitive Ecology.
  Supervises the UniverseServer, which in turn manages WorldServers.
  """
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      {Tiannara.UniverseServer, [id: :alpha_universe, event_bus: TiannaraRuntime.PubSub]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
