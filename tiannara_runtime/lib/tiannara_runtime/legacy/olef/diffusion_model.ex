defmodule TiannaraRuntime.Legacy.Tiannara.OLEF.DiffusionModel do
  @moduledoc """
  Phase 5F.5 — OLEF Diffusion Model
  
  Implements advanced diffusion algorithms for pressure field evolution.
  Supports multiple diffusion strategies for different operational modes.
  
  ## Diffusion Strategies
  
  - **Standard**: Uniform diffusion coefficient
  - **Adaptive**: Coefficient varies based on local pressure
  - **Anisotropic**: Direction-dependent diffusion rates
  """

  @doc """
  Run standard isotropic diffusion.
  
  Applies uniform diffusion coefficient across entire field.
  """
  def standard_diffusion(field, neighborhood_map, diffusion_coefficient \\ 0.12, steps \\ 1) do
    Enum.reduce(1..steps, field, fn _step, current_field ->
      Tiannara.OLEF.PressureSolver.apply_diffusion(current_field, neighborhood_map, diffusion_coefficient)
    end)
  end

  @doc """
  Run adaptive diffusion.
  
  Diffusion coefficient adapts based on local pressure gradients.
  Higher gradients → faster diffusion.
  """
  def adaptive_diffusion(field, neighborhood_map, base_coefficient \\ 0.12, steps \\ 1) do
    Enum.reduce(1..steps, field, fn _step, current_field ->
      gradients = Tiannara.OLEF.PressureSolver.compute_gradient(current_field, neighborhood_map)
      
      adapted_field = Enum.map(current_field, fn {node, pressure} ->
        gradient_magnitude = abs(Map.get(gradients, node, 0.0))
        adaptive_coefficient = base_coefficient * (1.0 + gradient_magnitude)
        
        neighbor_values = Enum.map(Map.get(neighborhood_map, node, []), fn n ->
          Map.get(current_field, n, pressure)
        end)
        
        if length(neighbor_values) > 0 do
          avg_neighbor = Enum.sum(neighbor_values) / length(neighbor_values)
          new_pressure = pressure + (adaptive_coefficient * (avg_neighbor - pressure))
          {node, max(0.0, new_pressure)}
        else
          {node, pressure}
        end
      end)
      |> Enum.into(%{})
      
      adapted_field
    end)
  end

  @doc """
  Simulate diffusion over time.
  
  Returns time-series of field states for analysis.
  """
  def simulate_diffusion(initial_field, neighborhood_map, steps \\ 10, strategy \\ :standard) do
    Enum.scan(1..steps, initial_field, fn step, prev_field ->
      prev_field_actual = if is_map(prev_field) and Map.has_key?(prev_field, :field), do: prev_field.field, else: prev_field

      diffused_field = case strategy do
        :standard ->
          standard_diffusion(prev_field_actual, neighborhood_map, 0.12, 1)
        :adaptive ->
          adaptive_diffusion(prev_field_actual, neighborhood_map, 0.12, 1)
        :native ->
          Tiannara.OLEF.ComputeBackends.Native.diffuse(prev_field_actual, neighborhood_map, 0.12, 1)
      end
      
      %{
        step: step,
        field: diffused_field,
        total_pressure: Tiannara.OLEF.PressureSolver.total_pressure(diffused_field),
        max_pressure: Enum.max(Map.values(diffused_field), fn -> 0.0 end),
        min_pressure: Enum.min(Map.values(diffused_field), fn -> 0.0 end)
      }
    end)
  end

  @doc """
  Calculate diffusion efficiency metric.
  
  Measures how evenly distributed the pressure field is.
  Lower variance = better distribution.
  """
  def calculate_efficiency(field) do
    if map_size(field) == 0 do
      0.0
    else
      values = Map.values(field)
      mean = Enum.sum(values) / length(values)
      variance = Enum.sum(Enum.map(values, fn v -> (v - mean) ** 2 end)) / length(values)
      
      1.0 / (1.0 + variance)
    end
  end
end
