defmodule TiannaraRuntime.WorldModel.DigitalTwin.SimulationScenario do
  @moduledoc """
  Phase 17.7.1 — SimulationScenario struct.
  A complete specification of initial conditions, events, and interventions for a simulation run.
  """
  defstruct [
    :scenario_id, :name, :initial_conditions, :events, :interventions,
    :total_ticks, :metrics_config, :seed, :metadata
  ]

  @type t :: %__MODULE__{
          scenario_id: String.t() | nil,
          name: String.t() | nil,
          initial_conditions: map() | nil,
          events: [TiannaraRuntime.WorldModel.DigitalTwin.SimulationEvent.t()] | nil,
          interventions: [TiannaraRuntime.WorldModel.DigitalTwin.ScheduledIntervention.t()] | nil,
          total_ticks: non_neg_integer() | nil,
          metrics_config: [atom()] | nil,
          seed: integer() | nil,
          metadata: map() | nil
        }

  def generate_id(canonical) when is_map(canonical) do
    hash = :crypto.hash(:sha256, Jason.encode!(canonical)) |> Base.encode16(case: :lower)
    "ss_" <> hash
  end
end
