defmodule TiannaraRuntime.WorldModel.DigitalTwin.ScheduledIntervention do
  @moduledoc """
  Phase 17.7.1 — ScheduledIntervention struct.
  An intervention scheduled for execution at a specific simulation time.
  """
  defstruct [:scheduled_id, :intervention, :schedule_type, :trigger_tick, :condition, :recurrence, :dependencies, :metadata]

  @type schedule_type :: :immediate | :delayed | :conditional | :recurring | :adaptive
  @type t :: %__MODULE__{
          scheduled_id: String.t() | nil,
          intervention: map() | nil,
          schedule_type: schedule_type() | nil,
          trigger_tick: non_neg_integer() | nil,
          condition: map() | nil,
          recurrence: non_neg_integer() | nil,
          dependencies: [String.t()] | nil,
          metadata: map() | nil
        }

  def generate_id(canonical) when is_map(canonical) do
    hash = :crypto.hash(:sha256, Jason.encode!(canonical)) |> Base.encode16(case: :lower)
    "si_" <> hash
  end
end
