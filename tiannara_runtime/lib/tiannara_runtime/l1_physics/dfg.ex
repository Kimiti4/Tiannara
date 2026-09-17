defmodule Tiannara.L1Physics.DFG do
  @moduledoc """
  L1 - Dynamic Friction Gradients (DFG)
  
  Provides topological resistance to rapid state shifts.
  Ensures that infrastructure cannot be overwhelmed by instantaneous mutations.
  """

  @doc """
  Calculates the resistance coefficient based on the delta between states
  and the current latent energy field pressure.
  """
  def calculate_friction(delta_magnitude, current_pressure) do
    # As pressure increases or delta increases, friction scales exponentially
    base_resistance = 0.05
    pressure_factor = current_pressure / 100.0
    
    friction = base_resistance * (delta_magnitude * pressure_factor)
    
    # Cap friction to prevent absolute freezing, max 0.95
    min(friction, 0.95)
  end

  @doc """
  Applies friction to a proposed state change vector, dampening its magnitude.
  """
  def apply_dampening(proposed_vector, friction_coefficient) do
    Enum.map(proposed_vector, fn component ->
      component * (1.0 - friction_coefficient)
    end)
  end
end
