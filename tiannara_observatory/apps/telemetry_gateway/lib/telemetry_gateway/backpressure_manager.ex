defmodule TelemetryGateway.BackpressureManager do
  use GenServer

  @high_water_mark 50_000
  @low_water_mark 10_000

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def pressure_level do
    GenServer.call(__MODULE__, :pressure)
  end

  def throttled? do
    GenServer.call(__MODULE__, :throttled?)
  end

  def record_queue_depth(depth) do
    GenServer.cast(__MODULE__, {:queue_depth, depth})
  end

  @impl true
  def init(_opts) do
    {:ok, %{current_depth: 0, peak_depth: 0, pressure: :normal}}
  end

  @impl true
  def handle_cast({:queue_depth, depth}, state) do
    pressure =
      cond do
        depth >= @high_water_mark -> :critical
        depth >= div(@high_water_mark, 2) -> :elevated
        depth <= @low_water_mark -> :normal
        true -> state.pressure
      end

    {:noreply,
     %{state | current_depth: depth, peak_depth: max(state.peak_depth, depth), pressure: pressure}}
  end

  @impl true
  def handle_call(:pressure, _from, %{pressure: p} = state), do: {:reply, p, state}
  @impl true
  def handle_call(:throttled?, _from, %{pressure: p} = state), do: {:reply, p != :normal, state}
end
