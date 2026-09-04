defmodule Tiannara.Telemetry.Observation do
  @moduledoc """
  A single runtime observation: a timestamped snapshot of measured system state.
  The atomic input to the Sentinel's evidence-driven pipeline.

  Constitutional basis: Scientific Method (Observation), Observability,
  "Distinguish clearly between facts, evidence, assumptions."
  """

  @enforce_keys [:id, :timestamp, :source, :metrics]
  defstruct [:id, :timestamp, :source, :metrics, lineage: []]

  @type t :: %__MODULE__{}
end