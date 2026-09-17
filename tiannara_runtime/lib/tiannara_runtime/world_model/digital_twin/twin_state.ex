defmodule TiannaraRuntime.WorldModel.DigitalTwin.TwinState do
  @moduledoc """
  Phase 17.7.1 — TwinState struct.
  The state of a digital twin at a specific simulation tick.
  """
  defstruct [:state_id, :tick, :model_states, :shared_variables, :metadata]

  @type t :: %__MODULE__{
          state_id: String.t() | nil,
          tick: non_neg_integer() | nil,
          model_states: %{String.t() => map()} | nil,
          shared_variables: %{String.t() => term()} | nil,
          metadata: map() | nil
        }

  def generate_id(canonical) when is_map(canonical) do
    hash = :crypto.hash(:sha256, Jason.encode!(canonical)) |> Base.encode16(case: :lower)
    "ts_" <> hash
  end
end
