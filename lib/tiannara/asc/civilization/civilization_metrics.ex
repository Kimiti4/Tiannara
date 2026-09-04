defmodule Tiannara.ASC.Civilization.Metrics do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def record_cycle(data), do: GenServer.cast(__MODULE__, {:record, data})
  def snapshot, do: GenServer.call(__MODULE__, :snapshot)
  def trend(metric, window \\ 10), do: GenServer.call(__MODULE__, {:trend, metric, window})

  @impl true
  def init(_opts), do: {:ok, %{history: [], started_at: DateTime.utc_now()}}

  @impl true
  def handle_cast({:record, data}, state) do
    entry = Map.put(data, :recorded_at, DateTime.utc_now())
    {:noreply, %{state | history: [entry | state.history] |> Enum.take(1000)}}
  end

  @impl true
  def handle_call(:snapshot, _from, state) do
    {:reply, %{latest: List.first(state.history) || %{}, total_cycles: length(state.history), started_at: state.started_at}, state}
  end

  def handle_call({:trend, metric, window}, _from, state) do
    {:reply, state.history |> Enum.take(window) |> Enum.map(&Map.get(&1, metric, 0)) |> Enum.reverse(), state}
  end

  def handle_info(_, state), do: {:noreply, state}
end
