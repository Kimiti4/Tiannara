defmodule TiannaraRuntime.WorldModel.DigitalTwin.SimulationClock do
  @moduledoc """
  Phase 17.7.1 — SimulationClock struct.
  Deterministic simulation time supporting multiple modes.
  """
  defstruct [:clock_id, :mode, :tick, :time, :delta, :total_ticks, :seed, :metadata]

  @type mode :: :fixed | :variable | :event_driven | :hybrid
  @type t :: %__MODULE__{
          clock_id: String.t() | nil,
          mode: mode() | nil,
          tick: non_neg_integer() | nil,
          time: float() | nil,
          delta: float() | nil,
          total_ticks: non_neg_integer() | nil,
          seed: integer() | nil,
          metadata: map() | nil
        }

  def generate_id(canonical) when is_map(canonical) do
    hash = :crypto.hash(:sha256, Jason.encode!(canonical)) |> Base.encode16(case: :lower)
    "sc_" <> hash
  end
end
