defmodule MetricsEngine.Gauge do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def set(name, value) do
    GenServer.cast(__MODULE__, {:set, name, value})
  end

  def get(name) do
    GenServer.call(__MODULE__, {:get, name})
  end

  @impl true
  def init(_opts) do
    {:ok, %{gauges: %{}}}
  end

  @impl true
  def handle_cast({:set, name, value}, %{gauges: g} = state) do
    {:noreply, %{state | gauges: Map.put(g, name, value)}}
  end

  @impl true
  def handle_call({:get, name}, _from, %{gauges: g} = state) do
    {:reply, Map.get(g, name), state}
  end
end
