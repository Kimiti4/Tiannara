defmodule TiannaraRuntime.NATS.Supervisor do
  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      {TiannaraRuntime.NATS.Bus, []},
      {TiannaraRuntime.NATS.Connection, []},
      {TiannaraRuntime.NATS.Publisher, []},
      {TiannaraRuntime.NATS.Subscriber, []}
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end
end
