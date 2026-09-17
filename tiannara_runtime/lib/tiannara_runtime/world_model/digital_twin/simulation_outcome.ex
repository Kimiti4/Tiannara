defmodule TiannaraRuntime.WorldModel.DigitalTwin.SimulationOutcome do
  @moduledoc """
  Phase 17.7.1 — SimulationOutcome struct.
  The result of executing a simulation scenario.
  """
  defstruct [
    :outcome_id, :scenario_id, :final_state, :metrics, :events_executed,
    :interventions_executed, :emergent_patterns, :replay_fingerprint, :metadata
  ]

  @type t :: %__MODULE__{
          outcome_id: String.t() | nil,
          scenario_id: String.t() | nil,
          final_state: TiannaraRuntime.WorldModel.DigitalTwin.TwinState.t() | nil,
          metrics: [TiannaraRuntime.WorldModel.DigitalTwin.TwinMetrics.t()] | nil,
          events_executed: non_neg_integer() | nil,
          interventions_executed: non_neg_integer() | nil,
          emergent_patterns: [map()] | nil,
          replay_fingerprint: String.t() | nil,
          metadata: map() | nil
        }

  def generate_id(canonical) when is_map(canonical) do
    hash = :crypto.hash(:sha256, Jason.encode!(canonical)) |> Base.encode16(case: :lower)
    "so_" <> hash
  end
end
