defmodule TelemetryGateway.Deduplicator do
  use GenServer

  @recent_window_ms 10_000

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def seen?(event) do
    GenServer.call(__MODULE__, {:seen?, event})
  end

  def mark_seen(event) do
    GenServer.cast(__MODULE__, {:mark, event})
  end

  @impl true
  def init(_opts) do
    {:ok, %{seen: %{}, count: 0}}
  end

  @impl true
  def handle_call({:seen?, event}, _from, %{seen: seen} = state) do
    key = dedup_key(event)
    {:reply, Map.has_key?(seen, key), state}
  end

  @impl true
  def handle_cast({:mark, event}, %{seen: seen, count: c} = state) do
    key = dedup_key(event)
    now = System.monotonic_time(:millisecond)
    pruned = Map.filter(seen, fn {_, ts} -> now - ts < @recent_window_ms end)
    {:noreply, %{state | seen: Map.put(pruned, key, now), count: c + 1}}
  end

  defp dedup_key(event) do
    id = event[:id] || event.id
    seq = event[:sequence_number] || event.sequence_number || 0
    rh = event[:replay_hash] || event.replay_hash || "none"
    "#{id}:#{seq}:#{rh}"
  end
end
