defmodule ObservatoryApiWeb.Hub.MissionBroadcast do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def broadcast(message, destinations \\ :all) do
    GenServer.cast(__MODULE__, {:broadcast, message, destinations})
  end

  def register_destination(name, handler_fn) do
    GenServer.cast(__MODULE__, {:register, name, handler_fn})
  end

  def broadcast_stats do
    GenServer.call(__MODULE__, :stats)
  end

  @impl true
  def init(_opts) do
    {:ok, %{destinations: %{}, sent: 0, failed: 0}}
  end

  @impl true
  def handle_cast({:broadcast, message, dests}, state) do
    targets = if dests == :all, do: Map.keys(state.destinations), else: List.wrap(dests)

    Enum.each(targets, fn dest ->
      case Map.get(state.destinations, dest) do
        nil ->
          :ok

        handler_fn ->
          try do
            handler_fn.(message)

            :telemetry.execute([:observatory, :broadcast, :sent], %{count: 1}, %{
              destination: dest
            })
          rescue
            _ ->
              :telemetry.execute([:observatory, :broadcast, :failed], %{count: 1}, %{
                destination: dest
              })
          end
      end
    end)

    {:noreply, %{state | sent: state.sent + 1}}
  end

  @impl true
  def handle_cast({:register, name, handler_fn}, %{destinations: d} = state) do
    {:noreply, %{state | destinations: Map.put(d, name, handler_fn)}}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    {:reply,
     %{
       destinations: Map.keys(state.destinations),
       sent: state.sent,
       failed: state.failed,
       registered: map_size(state.destinations)
     }, state}
  end
end
