defmodule TiannaraRuntime.Legacy.Tiannara.MSCL.ConstraintEngine do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_) do
    {:ok, %{constraints: %{}, pressure: 0.0}}
  end

  def handle_cast({:update_constraint, key, value}, state) do
    new = Map.put(state.constraints, key, value)
    {:noreply, %{state | constraints: new}}
  end

  def handle_info({:tick}, state) do
    # MSCL.Telemetry.emit(:constraint_snapshot, state)
    {:noreply, state}
  end
end
