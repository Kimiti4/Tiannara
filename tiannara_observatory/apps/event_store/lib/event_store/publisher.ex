defmodule EventStore.Publisher do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def broadcast(event) do
    GenServer.cast(__MODULE__, {:broadcast, event})
  end

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:broadcast, _event}, state) do
    {:noreply, state}
  end
end
