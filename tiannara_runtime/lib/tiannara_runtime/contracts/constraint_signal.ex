defmodule TiannaraRuntime.Contracts.ConstraintSignal do
  @moduledoc """
  Authoritative constraint command emitted only by SafetyCortex.
  """

  @enforce_keys [:source, :target_layer]
  defstruct [
    :source,
    :target_layer,
    :entropy_floor,
    :mutation_ceiling,
    :branch_limit,
    :execution_throttle,
    :quarantine
  ]

  @type t :: %__MODULE__{
          source: atom(),
          target_layer: :ecology | :execution,
          entropy_floor: float() | nil,
          mutation_ceiling: float() | nil,
          branch_limit: non_neg_integer() | nil,
          execution_throttle: float() | nil,
          quarantine: boolean() | nil
        }
end
