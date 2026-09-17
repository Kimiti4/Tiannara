defmodule ReplayStore.Replay do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def replay_at(timestamp) do
    GenServer.call(__MODULE__, {:replay_at, timestamp})
  end

  @impl true
  def init(_opts) do
    {:ok, %{replays: %{}}}
  end

  @impl true
  def handle_call({:replay_at, timestamp}, _from, state) do
    events = EventStore.Reader.list_by_time_range(~U[2020-01-01 00:00:00Z], timestamp)
    reconstructed = Enum.reduce(events, %{}, fn e, acc -> Map.put(acc, e.domain, e) end)

    {:reply,
     %{timestamp: timestamp, domains: map_size(reconstructed), events_count: length(events)},
     state}
  end
end
