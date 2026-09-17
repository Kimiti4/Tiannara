defmodule Tiannara.Sentinel.Shadow.ReplayCase do
  @moduledoc """
  The canonical contract for Epistemic Shadow Graph replay evaluation.
  Used exclusively in Phase C.0 to pass historical context through the replay pipeline.
  """
  @enforce_keys [
    :id,
    :anomaly,
    :recommendation,
    :actual_outcome
  ]

  defstruct [
    :id,
    :anomaly,
    :baseline_snapshot,
    :recommendation,
    :expected_impact,
    :actual_outcome,
    :reconstructed_at
  ]
end
