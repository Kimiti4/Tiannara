defmodule Tiannara.Sentinel.Contracts.TelemetryEvent do
  @moduledoc """
  The standard structure for telemetry events consumed by Sentinel.
  This ensures Sentinel does not tightly couple to MSCL, HSV, OLEF, etc.
  """
  defstruct [:source, :category, :value, :metadata, :timestamp]

  @type source :: atom()
  @type category :: atom()
  @type value :: float() | integer() | map()
  @type t :: %__MODULE__{
          source: source(),
          category: category(),
          value: value(),
          metadata: map(),
          timestamp: integer()
        }
end
