defmodule ReplayStore.Timeline do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def record_checkpoint(checkpoint) do
    GenServer.cast(__MODULE__, {:checkpoint, checkpoint})
  end

  def list_checkpoints(domain) do
    GenServer.call(__MODULE__, {:list, domain})
  end

  @impl true
  def init(_opts) do
    {:ok, %{timeline: %{}}}
  end

  @impl true
  def handle_cast({:checkpoint, cp}, %{timeline: t} = state) do
    entries = Map.get(t, cp.domain, [])
    {:noreply, %{state | timeline: Map.put(t, cp.domain, [cp | entries])}}
  end

  @impl true
  def handle_call({:list, domain}, _from, %{timeline: t} = state) do
    {:reply, Map.get(t, domain, []), state}
  end
end
