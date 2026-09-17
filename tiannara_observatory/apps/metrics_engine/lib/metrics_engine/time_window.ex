defmodule MetricsEngine.TimeWindow do
  use GenServer

  @windows [1000, 5000, 30_000, 300_000, 3_600_000, 86_400_000]

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def record(name, value) do
    GenServer.cast(__MODULE__, {:record, name, value})
  end

  def query(name, window_ms) do
    GenServer.call(__MODULE__, {:query, name, window_ms})
  end

  @impl true
  def init(_opts) do
    {:ok, %{windows: %{}}}
  end

  @impl true
  def handle_cast({:record, name, value}, %{windows: w} = state) do
    now = System.monotonic_time(:millisecond)

    updates =
      Enum.reduce(@windows, w, fn win, acc ->
        key = {name, win}
        entries = Map.get(acc, key, %{values: [], cutoff: now})
        fresh = Enum.filter(entries.values, fn {t, _} -> now - t < win end)
        Map.put(acc, key, %{values: [{now, value} | fresh], cutoff: now})
      end)

    {:noreply, %{state | windows: updates}}
  end

  @impl true
  def handle_call({:query, name, window_ms}, _from, %{windows: w} = state) do
    key = {name, window_ms}

    case Map.get(w, key) do
      nil -> {:reply, [], state}
      %{values: vs} -> {:reply, Enum.map(vs, fn {_, v} -> v end), state}
    end
  end
end
