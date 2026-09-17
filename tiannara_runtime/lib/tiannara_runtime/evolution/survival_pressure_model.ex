defmodule TiannaraRuntime.Evolution.SurvivalPressureModel do
  @moduledoc """
  PHASE 5B: Survival Pressure Model
  
  Computes selection pressure acting on each world based on multiple stress factors.
  
  Pressure Formula:
    pressure = entropy_growth_rate + CIS_intervention_density + CAL_instability_index
  
  Pressure Levels:
    - Low (0.0-0.3): Stable evolution, minimal intervention
    - Medium (0.3-0.6): Adaptation phase, moderate stress
    - High (0.6-0.8): Divergence phase, significant instability
    - Extreme (0.8-1.0): Collapse/fork territory, critical stress
  
  This model helps determine whether a world should:
    - Continue evolving normally
    - Fork to explore alternative configurations
    - Be terminated due to unmanageable instability
  """
  
  @doc """
  Compute survival pressure index for a world.
  
  Parameters:
    metrics - Map containing:
      - entropy_growth_rate: float [0.0, 1.0]
      - cis_intervention_density: float [0.0, 1.0]
      - cal_instability_index: float [0.0, 1.0]
  
  Returns:
    pressure score [0.0, 1.0]
  """
  def compute_pressure(metrics) do
    entropy_growth = Map.get(metrics, :entropy_growth_rate, 0.0)
    cis_density = Map.get(metrics, :cis_intervention_density, 0.0)
    cal_instability = Map.get(metrics, :cal_instability_index, 0.0)
    
    raw_pressure = entropy_growth + cis_density + cal_instability
    
    # Normalize to [0.0, 1.0] by dividing by max possible (3.0)
    normalized = raw_pressure / 3.0
    
    clamp(normalized, 0.0, 1.0)
  end
  
  @doc """
  Classify pressure level.
  
  Returns:
    :low - Stable evolution
    :medium - Adaptation phase
    :high - Divergence phase
    :extreme - Collapse/fork territory
  """
  def classify_pressure(pressure) do
    cond do
      pressure > 0.8 -> :extreme
      pressure > 0.6 -> :high
      pressure > 0.3 -> :medium
      true -> :low
    end
  end
  
  @doc """
  Determine recommended action based on pressure level.
  
  Returns:
    :continue - Normal operation
    :monitor - Watch closely
    :fork - Create exploratory branch
    :terminate - Consider extinction
  """
  def recommended_action(pressure, fitness) do
    case {classify_pressure(pressure), fitness} do
      {:extreme, f} when f < 0.3 -> :terminate
      {:extreme, _} -> :fork
      {:high, f} when f < 0.4 -> :fork
      {:high, _} -> :monitor
      {:medium, _} -> :continue
      {:low, _} -> :continue
    end
  end
  
  @doc """
  Compute force vectors for WebGL visualization.
  
  Returns map of forces acting on world particle:
    - F_selection: survival pressure vector
    - F_entropy: turbulence/disorder vector
    - F_cis: immune intervention shockwave
    - F_cal: coalition attraction vector
  """
  def compute_visualization_forces(world_data) do
    metrics = world_data.world.metrics
    position = Map.get(world_data, :position, {0.0, 0.0, 0.0})
    
    %{
      f_selection: selection_force(world_data.fitness, global_mean_fitness()),
      f_entropy: entropy_force(position, metrics.entropy),
      f_cis: cis_force(metrics.cis_intervention_intensity, metrics.instability_vector),
      f_cal: cal_force(metrics.coalition_positions, position)
    }
  end
  
  # ============================================================================
  # Private Functions
  # ============================================================================
  
  defp clamp(value, min_val, max_val) do
    max(min_val, min(value, max_val))
  end
  
  defp selection_force(fitness, global_mean) do
    # Selection pressure pushes toward higher fitness
    normalize(fitness - global_mean) * 0.5
  end
  
  defp entropy_force(position, entropy_level) do
    # Entropy creates turbulent random motion
    # In production, use Perlin noise here
    turbulence = :rand.uniform() * entropy_level
    turbulence * 0.3
  end
  
  defp cis_force(intensity, instability_vector) do
    # CIS pushes against instability
    intensity * (-instability_vector)
  end
  
  defp cal_force(coalition_positions, world_position) do
    # CAL attracts world toward coalition cluster center
    if length(coalition_positions) > 0 do
      {cx, cy, cz} = average_position(coalition_positions)
      {wx, wy, wz} = world_position
      {cx - wx, cy - wy, cz - wz}
    else
      {0.0, 0.0, 0.0}
    end
  end
  
  defp normalize(value) do
    # Clamp to [-1, 1]
    max(-1.0, min(1.0, value))
  end
  
  defp global_mean_fitness() do
    case TiannaraRuntime.WorldRegistry.list_worlds() do
      {:ok, worlds} when length(worlds) > 0 ->
        sum = Enum.reduce(worlds, 0.0, fn w, acc -> acc + Map.get(w, :fitness, 0.5) end)
        sum / length(worlds)
      _ ->
        0.5
    end
  end
  
  defp average_position(positions) do
    # Calculate centroid of coalition positions
    sum_x = Enum.sum(Enum.map(positions, fn {x, _, _} -> x end))
    sum_y = Enum.sum(Enum.map(positions, fn {_, y, _} -> y end))
    sum_z = Enum.sum(Enum.map(positions, fn {_, _, z} -> z end))
    
    count = length(positions)
    {sum_x / count, sum_y / count, sum_z / count}
  end
end
