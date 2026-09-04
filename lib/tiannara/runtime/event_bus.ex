defmodule Tiannara.Runtime.EventBus do
  @moduledoc """
  The epistemic event bus connecting the Sentinel heartbeat, the constitutional
  monitor, and downstream consumers (Ω.2 Research Director, Ω.3 interface).
  Keeps an audit history of emitted events.

  Constitutional basis: "Maintain audit trails", Observability, Composability.
  """
  use GenServer

  def start_link(opts \\ []) do
    case Keyword.get(opts, :name) do
      nil -> GenServer.start_link(__MODULE__, opts)
      name -> GenServer.start_link(__MODULE__, opts, name: name)
    end
  end

  def publish(server \\ __MODULE__, event), do: GenServer.cast(server, {:publish, event})
  def subscribe(server \\ __MODULE__, pid), do: GenServer.call(server, {:subscribe, pid})
  def history(server \\ __MODULE__), do: GenServer.call(server, :history)
  def subscriber_count(server \\ __MODULE__), do: GenServer.call(server, :subscriber_count)

  @impl true
  def init(_opts), do: {:ok, %{subscribers: MapSet.new(), events: []}}

  @impl true
  def handle_cast({:publish, event}, state) do
    Enum.each(state.subscribers, fn pid -> send(pid, {:epistemic_event, event}) end)
    {:noreply, %{state | events: [event | state.events]}}
  end

  @impl true
  def handle_call({:subscribe, pid}, _from, state) do
    {:reply, :ok, %{state | subscribers: MapSet.put(state.subscribers, pid)}}
  end

  def handle_call(:history, _from, state) do
    {:reply, Enum.reverse(state.events), state}
  end

  def handle_call(:subscriber_count, _from, state) do
    {:reply, MapSet.size(state.subscribers), state}
  end
end