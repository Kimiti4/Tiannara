defmodule MetricsEngine.WindowManager do
  use GenServer

  @windows [
    {:second, 1_000},
    {:five_seconds, 5_000},
    {:thirty_seconds, 30_000},
    {:minute, 60_000},
    {:five_minutes, 300_000},
    {:thirty_minutes, 1_800_000},
    {:hour, 3_600_000},
    {:six_hours, 21_600_000},
    {:day, 86_400_000},
    {:seven_days, 604_800_000},
    {:thirty_days, 2_592_000_000},
    {:year, 31_536_000_000}
  ]

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def record(name, value) do
    GenServer.cast(__MODULE__, {:record, name, value})
  end

  def query(name, window_key) do
    GenServer.call(__MODULE__, {:query, name, window_key})
  end

  def available_windows do
    GenServer.call(__MODULE__, :windows)
  end

  @impl true
  def init(_opts) do
    {:ok, %{buckets: %{}}}
  end

  @impl true
  def handle_cast({:record, name, value}, %{buckets: b} = state) do
    now = System.monotonic_time(:millisecond)

    updates =
      Enum.reduce(@windows, b, fn {key, window_ms}, acc ->
        points = Map.get(acc, {name, key}, [])
        fresh = Enum.filter(points, fn {t, _} -> now - t < window_ms end)
        Map.put(acc, {name, key}, [{now, value} | fresh])
      end)

    {:noreply, %{state | buckets: updates}}
  end

  @impl true
  def handle_call({:query, name, window_key}, _from, %{buckets: b} = state) do
    points = Map.get(b, {name, window_key}, [])
    values = Enum.map(points, fn {_, v} -> v end)

    stats =
      cond do
        values == [] ->
          %{count: 0, sum: 0.0, mean: 0.0, min: 0, max: 0}

        true ->
          sorted = Enum.sort(values)
          n = length(values)

          %{
            count: n,
            sum: Enum.sum(values),
            mean: Enum.sum(values) / n,
            min: List.first(sorted),
            max: List.last(sorted),
            p50: percentile(sorted, 50),
            p95: percentile(sorted, 95),
            p99: percentile(sorted, 99),
            last: List.last(values)
          }
      end

    window_info = Enum.find(@windows, fn {k, _} -> k == window_key end)

    {:reply,
     %{
       window: window_key,
       window_ms: elem(window_info || {window_key, 0}, 1),
       points: length(points),
       stats: stats
     }, state}
  end

  @impl true
  def handle_call(:windows, _from, state) do
    {:reply, @windows, state}
  end

  defp percentile(sorted, p) when length(sorted) > 0 do
    index = ceil(p / 100.0 * length(sorted)) - 1
    Enum.at(sorted, max(0, min(index, length(sorted) - 1)))
  end

  defp percentile(_, _), do: 0.0
end
