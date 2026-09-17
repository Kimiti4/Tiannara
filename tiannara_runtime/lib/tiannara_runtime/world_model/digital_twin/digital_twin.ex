defmodule TiannaraRuntime.WorldModel.DigitalTwin.DigitalTwin do
  @moduledoc """
  Phase 17.7.1 — DigitalTwin struct.
  A synchronized, deterministic, replayable simulation of multiple composed world models.
  """
  defstruct [
    :twin_id, :name, :parent_model_ids, :composition_id, :clock, :state,
    :intervention_queue, :scenario_registry, :event_timeline, :metrics,
    :evidence_ledger, :archaeology_root, :replay_fingerprint, :certificate, :created_at
  ]

  @type t :: %__MODULE__{
          twin_id: String.t() | nil,
          name: String.t() | nil,
          parent_model_ids: [String.t()] | nil,
          composition_id: String.t() | nil,
          clock: TiannaraRuntime.WorldModel.DigitalTwin.SimulationClock.t() | nil,
          state: TiannaraRuntime.WorldModel.DigitalTwin.TwinState.t() | nil,
          intervention_queue: TiannaraRuntime.WorldModel.DigitalTwin.InterventionQueue.t() | nil,
          scenario_registry: [TiannaraRuntime.WorldModel.DigitalTwin.SimulationScenario.t()] | nil,
          event_timeline: [TiannaraRuntime.WorldModel.DigitalTwin.SimulationEvent.t()] | nil,
          metrics: [TiannaraRuntime.WorldModel.DigitalTwin.TwinMetrics.t()] | nil,
          evidence_ledger: [map()] | nil,
          archaeology_root: String.t() | nil,
          replay_fingerprint: String.t() | nil,
          certificate: map() | nil,
          created_at: String.t() | nil
        }

  def generate_id(canonical) when is_map(canonical) do
    hash = :crypto.hash(:sha256, Jason.encode!(canonical)) |> Base.encode16(case: :lower)
    "dt_" <> hash
  end
end
