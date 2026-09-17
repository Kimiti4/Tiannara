defmodule Tiannara.OPC.V3.OLEF.PressureMesh do
  @moduledoc """
  Distributed Pressure Mesh for Observer Physics
  Models cognitive pressure distribution across observer network
  """

  defstruct [
    :nodes,
    :connections,
    :pressure_values,
    :boundary_conditions,
    :mesh_dimensions
  ]

  @type t :: %__MODULE__{
    nodes: map(),
    connections: list(tuple()),
    pressure_values: map(),
    boundary_conditions: map(),
    mesh_dimensions: {integer(), integer()}
  }

  @doc """
  Creates a new pressure mesh
  """
  def new(dimensions \\ {10, 10}) do
    %__MODULE__{
      nodes: initialize_nodes(dimensions),
      connections: initialize_connections(dimensions),
      pressure_values: %{},
      boundary_conditions: %{},
      mesh_dimensions: dimensions
    }
  end

  defp initialize_nodes({width, height}) do
    for x <- 0..(width-1), y <- 0..(height-1), into: %{} do
      {{x, y}, %{id: {x, y}, connected: []}}
    end
  end

  defp initialize_connections({width, height}) do
    connections = 
      for x <- 0..(width-1), y <- 0..(height-1), reduce: [] do
        acc ->
          current_pos = {x, y}
          
          neighbors = [
            {x+1, y},   # right
            {x-1, y},   # left
            {x, y+1},   # down
            {x, y-1}    # up
          ]
          
          valid_neighbors = 
            Enum.filter(neighbors, fn {nx, ny} ->
              nx >= 0 and nx < width and ny >= 0 and ny < height
            end)
          
          neighbor_connections = 
            Enum.map(valid_neighbors, fn neighbor_pos ->
              {current_pos, neighbor_pos}
            end)
          
          acc ++ neighbor_connections
      end
    
    # Remove duplicates by sorting and using MapSet
    Enum.reduce(connections, [], fn {pos1, pos2}, acc ->
      # Create canonical ordering to remove duplicates
      conn = if pos1 <= pos2, do: {pos1, pos2}, else: {pos2, pos1}
      if conn in acc, do: acc, else: [conn | acc]
    end)
  end

  @doc """
  Applies pressure to a specific coordinate in the mesh
  """
  def apply_pressure(%__MODULE__{} = mesh, source_id, pressure_value, {x, y} = coordinates) do
    # Verify coordinates are within bounds
    {width, height} = mesh.mesh_dimensions
    if x >= 0 and x < width and y >= 0 and y < height do
      updated_pressure_values = 
        Map.update(mesh.pressure_values, coordinates, 
          [%{source: source_id, value: pressure_value, timestamp: System.os_time(:millisecond)}],
          fn existing_pressures ->
            [%{source: source_id, value: pressure_value, timestamp: System.os_time(:millisecond)} | existing_pressures]
          end)
      
      # Propagate pressure to neighbors
      propagated_mesh = propagate_pressure(mesh, {x, y}, pressure_value, source_id)
      
      %{propagated_mesh | pressure_values: updated_pressure_values}
    else
      mesh  # Invalid coordinates, return unchanged mesh
    end
  end

  defp propagate_pressure(%__MODULE__{} = mesh, source_coord, pressure_value, source_id) do
    # Find direct neighbors of the source coordinate
    {width, height} = mesh.mesh_dimensions
    {x, y} = source_coord
    
    neighbors = [
      {x+1, y},   # right
      {x-1, y},   # left
      {x, y+1},   # down
      {x, y-1}    # up
    ]
    
    valid_neighbors = 
      Enum.filter(neighbors, fn {nx, ny} ->
        nx >= 0 and nx < width and ny >= 0 and ny < height
      end)
    
    # Apply reduced pressure to neighbors (attenuation)
    reduced_pressure = pressure_value * 0.7  # 70% of original pressure
    
    Enum.reduce(valid_neighbors, mesh, fn neighbor_coord, acc_mesh ->
      updated_pressures = 
        Map.update(acc_mesh.pressure_values, neighbor_coord, 
          [%{source: source_id, value: reduced_pressure, timestamp: System.os_time(:millisecond)}],
          fn existing_pressures ->
            [%{source: source_id, value: reduced_pressure, timestamp: System.os_time(:millisecond)} | existing_pressures]
          end)
      
      %{acc_mesh | pressure_values: updated_pressures}
    end)
  end

  @doc """
  Calculates the current pressure field across the mesh
  """
  def calculate_pressure_field(%__MODULE__{} = mesh) do
    # Sum all pressures at each coordinate
    Enum.reduce(mesh.pressure_values, %{}, fn {coord, pressures}, acc ->
      total_pressure = 
        Enum.reduce(pressures, 0, fn pressure_record, sum ->
          sum + pressure_record.value
        end)
      
      Map.put(acc, coord, total_pressure)
    end)
  end

  @doc """
  Checks if the mesh has reached equilibrium
  """
  def check_equilibrium(%__MODULE__{} = mesh, threshold) do
    pressure_field = calculate_pressure_field(mesh)
    
    # Check if all pressure differences are below threshold
    pressure_values = Map.values(pressure_field)
    
    if length(pressure_values) == 0 do
      true  # Empty mesh is in equilibrium
    else
      # Calculate standard deviation as measure of equilibrium
      mean_pressure = Enum.sum(pressure_values) / length(pressure_values)
      
      variance = 
        pressure_values
        |> Enum.map(fn p -> (p - mean_pressure) * (p - mean_pressure) end)
        |> Enum.sum()
        |> Kernel./(length(pressure_values))
      
      standard_deviation = :math.sqrt(variance)
      
      # Equilibrium is reached when variation is below threshold
      standard_deviation < threshold
    end
  end

  @doc """
  Gets pressure at specific coordinates
  """
  def get_pressure_at(%__MODULE__{} = mesh, coordinates) do
    case Map.get(mesh.pressure_values, coordinates) do
      nil -> 0.0
      pressures -> 
        Enum.reduce(pressures, 0, fn pressure_record, sum ->
          sum + pressure_record.value
        end)
    end
  end

  @doc """
  Updates boundary conditions for the mesh
  """
  def set_boundary_condition(%__MODULE__{} = mesh, coordinate, condition) do
    updated_conditions = Map.put(mesh.boundary_conditions, coordinate, condition)
    %{mesh | boundary_conditions: updated_conditions}
  end

  @doc """
  Resets all pressure values in the mesh
  """
  def reset(%__MODULE__{} = mesh) do
    %{mesh | pressure_values: %{}}
  end
end
