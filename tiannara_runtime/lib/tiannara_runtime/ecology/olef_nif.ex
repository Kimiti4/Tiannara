defmodule Tiannara.PhysicsLaw do
  defstruct [
    :diffusion,
    :decay,
    :coupling,
    :entropy_bias,
    :novelty_response
  ]
end

defmodule Tiannara.OlefField do
  defstruct [
    :pressure,
    :entropy,
    :curvature,
    :novelty,
    :semantic,
    :width,
    :height,
    :tick,
    :population
  ]
end

defmodule Tiannara.OlefNif do
  @moduledoc """
  Rust NIF bindings for the OLEF Field Evolution SIMD Kernel.
  Falls back to Elixir stubs if NIF is not available.
  """

  if Mix.env() == :prod and Code.ensure_loaded?(Rustler) do
    use Rustler, otp_app: :tiannara_runtime, crate: "olef_physics"
  end

  def initialize(width, height) do
    grid_size = width * height
    %Tiannara.OlefField{
      pressure: List.duplicate(0.5, grid_size),
      entropy: 0.5,
      curvature: List.duplicate(0.0, grid_size),
      novelty: 0.0,
      semantic: 0.5,
      width: width,
      height: height,
      tick: 0,
      population: [
        %Tiannara.PhysicsLaw{diffusion: 0.1, decay: 0.01, coupling: 0.05, entropy_bias: 0.02, novelty_response: 0.5},
        %Tiannara.PhysicsLaw{diffusion: 0.2, decay: 0.02, coupling: 0.1, entropy_bias: 0.03, novelty_response: 0.4}
      ]
    }
  end

  def step(field) do
    %{field | tick: field.tick + 1}
  end

  def inject_novelty(field, tick) do
    %{field | novelty: :math.sin(tick * 0.1) * 0.1, tick: tick}
  end

  def clamp_pressure(field) do
    %{field | pressure: Enum.map(field.pressure, fn p -> max(0.0, min(1.0, p)) end)}
  end

  def apply_causal_smoothing(field, _prev_curvature) do
    field
  end
end
