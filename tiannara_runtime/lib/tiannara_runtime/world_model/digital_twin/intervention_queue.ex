defmodule TiannaraRuntime.WorldModel.DigitalTwin.InterventionQueue do
  @moduledoc """
  Phase 17.7.1 — InterventionQueue struct.
  Ordered queue of scheduled interventions with dependency tracking.
  """
  defstruct [:queue_id, :interventions, :dependency_graph]

  @type t :: %__MODULE__{
          queue_id: String.t() | nil,
          interventions: [TiannaraRuntime.WorldModel.DigitalTwin.ScheduledIntervention.t()] | nil,
          dependency_graph: map() | nil
        }

  def generate_id(canonical) when is_map(canonical) do
    hash = :crypto.hash(:sha256, Jason.encode!(canonical)) |> Base.encode16(case: :lower)
    "iq_" <> hash
  end
end
