defmodule EventStore.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    children = [
      EventStore.Writer,
      EventStore.Reader,
      EventStore.Deduplicator,
      EventStore.Orderer,
      EventStore.Publisher
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
