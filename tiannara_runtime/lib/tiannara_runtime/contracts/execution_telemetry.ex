defmodule TiannaraRuntime.Contracts.ExecutionTelemetry do
  @moduledoc """
  Compressed telemetry contract emitted upward from the execution layer.
  """

  @enforce_keys [:tick_id, :scheduler_load, :kernel_pressure]
  defstruct [:tick_id, :scheduler_load, :kernel_pressure, :fault_count]

  @type t :: %__MODULE__{
          tick_id: non_neg_integer(),
          scheduler_load: float(),
          kernel_pressure: float(),
          fault_count: non_neg_integer() | nil
        }

  def from_map(map) do
    %__MODULE__{
      tick_id: Map.get(map, :tick_id, Map.get(map, "tick_id", 0)),
      scheduler_load: Map.get(map, :scheduler_load, Map.get(map, "scheduler_load", 0.0)),
      kernel_pressure: Map.get(map, :kernel_pressure, Map.get(map, "kernel_pressure", 0.0)),
      fault_count: Map.get(map, :fault_count, Map.get(map, "fault_count"))
    }
  end
end
