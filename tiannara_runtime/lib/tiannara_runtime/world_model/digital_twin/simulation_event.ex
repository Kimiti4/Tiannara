defmodule TiannaraRuntime.WorldModel.DigitalTwin.SimulationEvent do
  @moduledoc """
  Phase 17.7.1 — SimulationEvent struct.
  A deterministic occurrence that modifies the twin state at a specific simulation time.
  """
  defstruct [:event_id, :name, :type, :trigger_tick, :probability, :effects, :dependencies, :metadata]

  @type event_type :: :engineering | :policy | :disaster | :discovery | :economic | :medical | :infrastructure | :environmental
  @type t :: %__MODULE__{
          event_id: String.t() | nil,
          name: String.t() | nil,
          type: event_type() | nil,
          trigger_tick: non_neg_integer() | nil,
          probability: float() | nil,
          effects: map() | nil,
          dependencies: [String.t()] | nil,
          metadata: map() | nil
        }

  def generate_id(canonical) when is_map(canonical) do
    hash = :crypto.hash(:sha256, Jason.encode!(canonical)) |> Base.encode16(case: :lower)
    "se_" <> hash
  end
end
