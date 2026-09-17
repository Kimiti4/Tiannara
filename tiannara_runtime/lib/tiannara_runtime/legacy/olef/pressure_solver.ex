defmodule TiannaraRuntime.Legacy.Tiannara.OLEF.PressureSolver do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_) do
    {:ok, %{field_pressure: 0.0}}
  end

  def handle_cast({:pressure_update, p}, state) do
    new_pressure = (state.field_pressure + p) / 2
    {:noreply, %{state | field_pressure: new_pressure}}
  end
end
