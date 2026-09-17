defmodule TiannaraRuntime.Contracts.MetaAdjustment do
  @moduledoc """
  Parameter-space adjustment from meta-governance to constraint/execution.
  """

  @enforce_keys [:mutation_rate, :selection_pressure, :entropy_target, :exploration_temperature]
  defstruct [:mutation_rate, :selection_pressure, :entropy_target, :exploration_temperature]

  @type t :: %__MODULE__{
          mutation_rate: float(),
          selection_pressure: float(),
          entropy_target: float(),
          exploration_temperature: float()
        }
end
