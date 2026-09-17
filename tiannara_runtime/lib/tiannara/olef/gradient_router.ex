defmodule Tiannara.OLEF.GradientRouter do
  @moduledoc """
  Routes field gradients for topological stabilization.
  """
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

  def route_task(task_reqs, pressure_field, node_capacities) do
    min_capacity = Map.get(task_reqs, :min_capacity, 0)
    eligible = Enum.filter(pressure_field, fn {node, _pressure} ->
      Map.get(node_capacities, node, 0) >= min_capacity
    end)
    case eligible do
      [] -> {:error, :no_eligible_nodes}
      _ ->
        {selected, _} = Enum.min_by(eligible, fn {_node, pressure} -> pressure end)
        {:ok, selected}
    end
  end

  def calculate_routing_weights(pressure_field) do
    total_inverse = Enum.reduce(pressure_field, 0.0, fn {_k, v}, acc -> acc + (1.0 / max(v, 0.0001)) end)
    Enum.map(pressure_field, fn {k, v} ->
      {k, (1.0 / max(v, 0.0001)) / max(total_inverse, 0.0001)}
    end) |> Enum.into(%{})
  end

  def suggest_migrations(pressure_field, threshold) do
    {overloaded, underloaded} = Enum.split_with(pressure_field, fn {_k, v} -> v > threshold end)
    overloaded_nodes = Enum.map(overloaded, fn {k, _v} -> k end)
    underloaded_nodes = Enum.map(underloaded, fn {k, _v} -> k end)
    Enum.flat_map(overloaded_nodes, fn from ->
      Enum.map(underloaded_nodes, fn to ->
        %{from: from, to: to, pressure_delta: Map.get(pressure_field, from, 0.0) - Map.get(pressure_field, to, 0.0)}
      end)
    end)
  end
end
