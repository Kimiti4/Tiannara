defmodule MetricsEngine.Counter do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def increment(name, by \\ 1) do
    GenServer.cast(__MODULE__, {:increment, name, by})
  end

  def value(name) do
    GenServer.call(__MODULE__, {:value, name})
  end

  def get_all do
    GenServer.call(__MODULE__, :get_all)
  end

  @impl true
  def init(_opts) do
    {:ok, %{counters: %{}}}
  end

  @impl true
  def handle_cast({:increment, name, by}, %{counters: c} = state) do
    {:noreply, %{state | counters: Map.update(c, name, by, &(&1 + by))}}
  end

  @impl true
  def handle_call({:value, name}, _from, %{counters: c} = state) do
    {:reply, Map.get(c, name, 0), state}
  end

  @impl true
  def handle_call(:get_all, _from, %{counters: c} = state) do
    {:reply, c, state}
  end
end
