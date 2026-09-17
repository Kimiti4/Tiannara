defmodule ReplayStore.Lineage do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def record(parent_id, child_id) do
    GenServer.cast(__MODULE__, {:record, parent_id, child_id})
  end

  def ancestors(event_id) do
    GenServer.call(__MODULE__, {:ancestors, event_id})
  end

  @impl true
  def init(_opts) do
    {:ok, %{edges: %{}}}
  end

  @impl true
  def handle_cast({:record, parent, child}, %{edges: e} = state) do
    children = Map.get(e, parent, [])
    {:noreply, %{state | edges: Map.put(e, parent, [child | children])}}
  end

  @impl true
  def handle_call({:ancestors, _id}, _from, %{edges: e} = state) do
    {:reply, e, state}
  end
end
