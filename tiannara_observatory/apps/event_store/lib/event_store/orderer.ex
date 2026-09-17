defmodule EventStore.Orderer do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def enqueue(event) do
    GenServer.cast(__MODULE__, {:enqueue, event})
  end

  @impl true
  def init(_opts) do
    {:ok, %{queue: :queue.new(), sequence: 0}}
  end

  @impl true
  def handle_cast({:enqueue, event}, %{queue: q, sequence: seq} = state) do
    ordered = Map.put(event, :sequence_number, seq + 1)
    {:noreply, %{state | queue: :queue.in(ordered, q), sequence: seq + 1}}
  end
end
