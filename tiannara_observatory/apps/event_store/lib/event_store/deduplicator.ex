defmodule EventStore.Deduplicator do
  use GenServer

  @recent_window 5_000

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def seen?(event_id) do
    GenServer.call(__MODULE__, {:seen?, event_id})
  end

  def mark_seen(event_id) do
    GenServer.cast(__MODULE__, {:mark, event_id})
  end

  @impl true
  def init(_opts) do
    {:ok, %{seen: %{}}}
  end

  @impl true
  def handle_call({:seen?, id}, _from, %{seen: seen} = state) do
    {:reply, Map.has_key?(seen, id), state}
  end

  @impl true
  def handle_cast({:mark, id}, %{seen: seen} = state) do
    now = System.monotonic_time(:millisecond)
    pruned = Map.filter(seen, fn {_, ts} -> now - ts < @recent_window end)
    {:noreply, %{state | seen: Map.put(pruned, id, now)}}
  end
end
