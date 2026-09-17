defmodule MetricsEngine.Histogram do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def observe(name, value) do
    GenServer.cast(__MODULE__, {:observe, name, value})
  end

  def percentiles(name) do
    GenServer.call(__MODULE__, {:percentiles, name})
  end

  @impl true
  def init(_opts) do
    {:ok, %{histograms: %{}}}
  end

  @impl true
  def handle_cast({:observe, name, value}, %{histograms: h} = state) do
    entries = Map.get(h, name, [])
    {:noreply, %{state | histograms: Map.put(h, name, [value | entries])}}
  end

  @impl true
  def handle_call({:percentiles, name}, _from, %{histograms: h} = state) do
    values = Map.get(h, name, []) |> Enum.sort()
    total = length(values)

    p50 = if total > 0, do: Enum.at(values, div(total, 2)), else: 0
    p95 = if total > 0, do: Enum.at(values, div(total * 95, 100)), else: 0
    p99 = if total > 0, do: Enum.at(values, div(total * 99, 100)), else: 0

    {:reply, %{p50: p50, p95: p95, p99: p99, count: total}, state}
  end
end
