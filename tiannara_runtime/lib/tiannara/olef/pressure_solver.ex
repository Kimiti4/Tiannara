defmodule Tiannara.OLEF.PressureSolver do
  @moduledoc """
  Solves topological field pressure across OLEF.
  Subscribes to EventBus for constraint signals.
  """
  use GenServer
  alias Tiannara.EventBus

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_) do
    EventBus.subscribe("constraint.updated")
    {:ok, %{field_pressure: 0.0}}
  end

  def handle_info({:constraint_changed, %{value: p}}, state) when is_number(p) do
    new_pressure = (state.field_pressure + p) / 2
    EventBus.broadcast("field.pressure_changed", :pressure_update, %{pressure: new_pressure})
    {:noreply, %{state | field_pressure: new_pressure}}
  end
  
  def handle_info(_, state), do: {:noreply, state}
  
  def handle_cast({:pressure_update, p}, state) do
    new_pressure = (state.field_pressure + p) / 2
    EventBus.broadcast("field.pressure_changed", :pressure_update, %{pressure: new_pressure})
    {:noreply, %{state | field_pressure: new_pressure}}
  end

  def compute_gradient(field, neighborhood) do
    Enum.map(field, fn {node, pressure} ->
      neighbors = Map.get(neighborhood, node, [])
      gradient = if length(neighbors) > 0 do
        Enum.reduce(neighbors, 0.0, fn n, acc ->
          acc + (pressure - Map.get(field, n, pressure))
        end) / length(neighbors)
      else
        0.0
      end
      {node, gradient}
    end) |> Enum.into(%{})
  end

  def normalize(field) do
    values = Map.values(field)
    min_val = Enum.min(values)
    max_val = Enum.max(values)
    if max_val == min_val do
      Enum.map(field, fn {k, _v} -> {k, 0.5} end) |> Enum.into(%{})
    else
      Enum.map(field, fn {k, v} -> {k, (v - min_val) / (max_val - min_val)} end) |> Enum.into(%{})
    end
  end

  def apply_diffusion(field, neighborhood, diffusion_coefficient) do
    Enum.map(field, fn {node, pressure} ->
      neighbors = Map.get(neighborhood, node, [])
      if length(neighbors) > 0 do
        avg_neighbor = Enum.reduce(neighbors, 0.0, fn n, acc -> acc + Map.get(field, n, pressure) end) / length(neighbors)
        new_pressure = pressure + diffusion_coefficient * (avg_neighbor - pressure)
        {node, max(0.0, new_pressure)}
      else
        {node, pressure}
      end
    end) |> Enum.into(%{})
  end

  def find_equilibrium(field, neighborhood, max_iterations, tolerance) do
    find_equilibrium(field, neighborhood, max_iterations, tolerance, 0)
  end

  defp find_equilibrium(field, _neighborhood, max_iterations, _tolerance, iterations) when iterations >= max_iterations do
    {:converged, false, field, iterations}
  end

  defp find_equilibrium(field, neighborhood, max_iterations, tolerance, iterations) do
    new_field = apply_diffusion(field, neighborhood, 0.12)
    max_change = Enum.map(field, fn {node, v} -> abs(v - Map.get(new_field, node, v)) end) |> Enum.max(fn -> 0.0 end)
    if max_change < tolerance do
      {:converged, true, new_field, iterations + 1}
    else
      find_equilibrium(new_field, neighborhood, max_iterations, tolerance, iterations + 1)
    end
  end

  def total_pressure(field) do
    Enum.sum(Map.values(field))
  end

  def identify_hotspots(field, threshold) do
    Enum.filter(field, fn {_k, v} -> v > threshold end) |> Enum.into(%{})
  end
end
