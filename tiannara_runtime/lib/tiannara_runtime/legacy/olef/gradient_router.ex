defmodule TiannaraRuntime.Legacy.Tiannara.OLEF.GradientRouter do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_) do
    {:ok, %{routes: %{}}}
  end

  def handle_info({:route, node, gradient}, state) do
    new_routes = Map.put(state.routes, node, gradient)
    {:noreply, %{state | routes: new_routes}}
  end
end
