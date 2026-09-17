defmodule Tiannara.OPC.V3.OLEF.WebGLRenderer do
  @moduledoc """
  WebGL2 Pressure Field Renderer
  Provides real-time visualization of distributed pressure mesh equilibrium
  """

  alias Tiannara.OPC.V3.OLEF.PressureMesh

  defstruct [
    :canvas_size,
    :color_map,
    :render_options,
    :vertex_shader,
    :fragment_shader
  ]

  @type t :: %__MODULE__{
    canvas_size: {integer(), integer()},
    color_map: map(),
    render_options: map(),
    vertex_shader: String.t(),
    fragment_shader: String.t()
  }

  @doc """
  Creates a new WebGL renderer instance
  """
  def new(options \\ %{}) do
    canvas_size = Map.get(options, :canvas_size, {800, 600})
    color_map = Map.get(options, :color_map, default_color_map())
    render_options = Map.get(options, :render_options, %{
      show_grid: true,
      show_contours: true,
      show_vectors: false,
      intensity_scale: 1.0
    })

    %__MODULE__{
      canvas_size: canvas_size,
      color_map: color_map,
      render_options: render_options,
      vertex_shader: generate_vertex_shader(),
      fragment_shader: generate_fragment_shader()
    }
  end

  defp default_color_map do
    # Blue (low pressure) -> Green -> Yellow -> Red (high pressure)
    %{
      low: {0, 0, 255},      # Blue
      medium_low: {0, 128, 255},   # Light blue
      medium: {0, 255, 0},   # Green
      medium_high: {255, 255, 0},  # Yellow
      high: {255, 0, 0}      # Red
    }
  end

  defp generate_vertex_shader do
    """
    attribute vec2 a_position;
    attribute vec2 a_texCoord;
    varying vec2 v_texCoord;

    void main() {
      gl_Position = vec4(a_position, 0.0, 1.0);
      v_texCoord = a_texCoord;
    }
    """
  end

  defp generate_fragment_shader do
    """
    precision highp float;
    varying vec2 v_texCoord;
    uniform sampler2D u_pressureTexture;
    uniform float u_maxPressure;
    uniform float u_minPressure;
    uniform bool u_showGrid;
    uniform bool u_showContours;
    uniform float u_time;

    vec3 pressureToColor(float pressure, float minVal, float maxVal) {
      float normalized = (pressure - minVal) / (maxVal - minVal);
      
      if (normalized < 0.25) {
        // Blue to light blue
        return mix(vec3(0.0, 0.0, 1.0), vec3(0.0, 0.5, 1.0), normalized * 4.0);
      } else if (normalized < 0.5) {
        // Light blue to green
        return mix(vec3(0.0, 0.5, 1.0), vec3(0.0, 1.0, 0.0), (normalized - 0.25) * 4.0);
      } else if (normalized < 0.75) {
        // Green to yellow
        return mix(vec3(0.0, 1.0, 0.0), vec3(1.0, 1.0, 0.0), (normalized - 0.5) * 4.0);
      } else {
        // Yellow to red
        return mix(vec3(1.0, 1.0, 0.0), vec3(1.0, 0.0, 0.0), (normalized - 0.75) * 4.0);
      }
    }

    void main() {
      vec2 texSize = textureSize(u_pressureTexture, 0);
      vec2 coords = v_texCoord * texSize;
      vec2 pixelCoords = floor(coords);
      
      // Sample pressure at current pixel
      float pressure = texture(u_pressureTexture, v_texCoord).r;
      
      // Convert pressure to color
      vec3 color = pressureToColor(pressure, u_minPressure, u_maxPressure);
      
      // Add grid lines if enabled
      if (u_showGrid) {
        float gridSize = 32.0; // pixels per grid cell
        vec2 gridPos = mod(coords, vec2(gridSize));
        float gridIntensity = 1.0 - smoothstep(0.0, 2.0, min(gridPos.x, gridPos.y));
        color = mix(color, vec3(0.2), gridIntensity * 0.3);
      }
      
      // Add contour lines if enabled
      if (u_showContours) {
        float contourStep = 0.1; // contour interval
        float contourValue = mod(pressure, contourStep);
        float contourIntensity = 1.0 - smoothstep(0.0, 0.01, abs(contourValue - contourStep * 0.5));
        color = mix(color, vec3(1.0), contourIntensity * 0.2);
      }
      
      gl_FragColor = vec4(color, 1.0);
    }
    """
  end

  @doc """
  Renders the pressure field to WebGL context
  """
  def render(%__MODULE__{} = renderer, %PressureMesh{} = mesh) do
    pressure_field = PressureMesh.calculate_pressure_field(mesh)
    
    # Convert pressure field to texture data
    texture_data = convert_pressure_field_to_texture(pressure_field, mesh.mesh_dimensions)
    
    # Calculate pressure range for normalization
    {min_pressure, max_pressure} = calculate_pressure_range(pressure_field)
    
    # Prepare rendering parameters
    render_params = %{
      canvas_size: renderer.canvas_size,
      texture_data: texture_data,
      min_pressure: min_pressure,
      max_pressure: max_pressure,
      options: renderer.render_options,
      vertex_shader: renderer.vertex_shader,
      fragment_shader: renderer.fragment_shader
    }
    
    {:ok, render_params}
  end

  defp convert_pressure_field_to_texture(pressure_field, {width, height}) do
    # Create a flat array representing the texture data
    # Each element corresponds to pressure value at that coordinate
    texture_data = 
      for y <- 0..(height-1), x <- 0..(width-1) do
        Map.get(pressure_field, {x, y}, 0.0)
      end
    
    %{
      width: width,
      height: height,
      data: texture_data,
      format: :red_float
    }
  end

  defp calculate_pressure_range(pressure_field) do
    if map_size(pressure_field) == 0 do
      {0.0, 0.0}
    else
      pressures = Map.values(pressure_field)
      {Enum.min(pressures), Enum.max(pressures)}
    end
  end

  @doc """
  Updates renderer with new options
  """
  def update_options(%__MODULE__{} = renderer, new_options) when is_map(new_options) do
    updated_render_options = Map.merge(renderer.render_options, new_options)
    %{renderer | render_options: updated_render_options}
  end

  @doc """
  Generates visualization statistics for the pressure field
  """
  def generate_visualization_stats(%__MODULE__{} = _renderer, %PressureMesh{} = mesh) do
    pressure_field = PressureMesh.calculate_pressure_field(mesh)
    
    if map_size(pressure_field) == 0 do
      %{
        total_nodes: 0,
        max_pressure: 0.0,
        min_pressure: 0.0,
        avg_pressure: 0.0,
        equilibrium_state: true,
        entropy: 0.0
      }
    else
      pressures = Map.values(pressure_field)
      count = length(pressures)
      
      stats = %{
        total_nodes: count,
        max_pressure: Enum.max(pressures),
        min_pressure: Enum.min(pressures),
        avg_pressure: Enum.sum(pressures) / count,
        equilibrium_state: PressureMesh.check_equilibrium(mesh, 0.001),
        entropy: calculate_entropy(pressures)
      }
      
      stats
    end
  end

  defp calculate_entropy(pressures) when length(pressures) > 0 do
    # Simple entropy calculation based on pressure distribution
    count = length(pressures)
    avg = Enum.sum(pressures) / count
    
    # Variance as a measure of distribution spread
    variance = 
      pressures
      |> Enum.map(fn p -> (p - avg) * (p - avg) end)
      |> Enum.sum()
      |> Kernel./(count)
    
    # Entropy approximation
    if variance == 0, do: 0.0, else: :math.log(:math.sqrt(2 * :math.pi() * variance) + 1)
  end

  defp calculate_entropy(_), do: 0.0

  @doc """
  Captures a snapshot of the current visualization state
  """
  def capture_snapshot(%__MODULE__{} = renderer, %PressureMesh{} = mesh) do
    render_result = render(renderer, mesh)
    stats = generate_visualization_stats(renderer, mesh)
    
    snapshot = %{
      timestamp: System.os_time(:millisecond),
      render_result: render_result,
      stats: stats,
      mesh_dimensions: mesh.mesh_dimensions
    }
    
    {:ok, snapshot}
  end
end
