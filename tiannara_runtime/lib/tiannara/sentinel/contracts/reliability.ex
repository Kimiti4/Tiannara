defmodule Tiannara.Sentinel.Contracts.Reliability do
  @moduledoc """
  Canonical contract for observatory reliability tracking.
  Status progression: :unproven -> :provisional -> :trusted.
  """
  @enforce_keys [:observatory_id, :status, :evaluations, :accuracy, :calibration_error, :diversity_score]
  
  defstruct [
    :observatory_id,
    :status,              # :unproven, :provisional, :trusted
    :evaluations,         # non_neg_integer()
    :accuracy,            # float()
    :calibration_error,   # float()
    :diversity_score,     # float()
    :drift_score          # float()
  ]
end
