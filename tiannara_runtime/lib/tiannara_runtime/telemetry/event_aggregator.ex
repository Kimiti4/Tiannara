defmodule TiannaraRuntime.Telemetry.EventAggregator do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_) do
    {:ok, %{events: []}}
  end

  def handle_info({:event, e}, state) do
    {:noreply, %{state | events: [e | state.events]}}
  end
end
