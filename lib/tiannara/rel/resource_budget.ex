defmodule Tiannara.REL.ResourceBudget do
  @moduledoc """
  Defines the thermodynamic state of a civilization.
  """

  @type t :: %__MODULE__{
    civilization_id: String.t(),
    shard_id: String.t(),
    energy: integer(),
    compute: integer(),
    attention: integer(),
    ontological_capital: float(),
    truth_capital: float(),
    influence_capital: float(),
    epistemic_tension: float(),
    state: :active | :starving | :dormant,
    ticks_dormant: integer()
  }
  
  @enforce_keys [:civilization_id, :shard_id]

  defstruct [
    :civilization_id,
    :shard_id,
    energy: 1000,
    compute: 1000,
    attention: 1000,
    ontological_capital: 1000.0,
    truth_capital: 0.0,
    influence_capital: 0.0,
    epistemic_tension: 0.0,
    state: :active, # :active, :starving, :dormant
    ticks_dormant: 0
  ]

  @doc "Create a new default budget for a civilization."
  def new(shard_id, civ_id) do
    %__MODULE__{
      shard_id: shard_id,
      civilization_id: civ_id
    }
  end
end
