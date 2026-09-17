defmodule Tiannara.Sentinel.Contracts.ShadowSeed do
  @moduledoc """
  The canonical input for Phase C.1A Epistemic Simulation.
  Clones knowledge about the runtime rather than the runtime itself.
  """
  @enforce_keys [:anomaly_snapshot, :recommendation]

  defstruct [
    :anomaly_snapshot,
    :baseline_snapshot,
    :recommendation,
    :forecast_snapshot
  ]
end
