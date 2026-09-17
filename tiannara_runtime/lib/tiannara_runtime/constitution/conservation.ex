defmodule Tiannara.Constitution.Conservation do
  @moduledoc """
  Constitutional Invariant: Conservation
  
  E_{total} >= 0
  
  Ensures that the total topological energy or computational expenditure
  proposed by any operation does not push the system into negative energy 
  (meaning creating action from nothing or exceeding maximum system reserves).
  """

  @doc """
  Validates if the proposed execution state violates conservation logic.
  
  Returns `:ok` or `{:error, reason}`.
  """
  def validate(current_energy, proposed_cost) do
    if current_energy - proposed_cost < 0 do
      {:error, :conservation_violation_negative_energy}
    else
      :ok
    end
  end
end
