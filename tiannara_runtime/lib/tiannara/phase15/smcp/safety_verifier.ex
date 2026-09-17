defmodule Tiannara.Phase15.SMCP.SafetyVerifier do
  @moduledoc """
  Strict BFT invariant & liveness constraint checker.
  Prevents adaptation from violating quorum safety or timeout bounds.
  """
  
  @spec verify(params :: map()) :: :valid | {:error, atom()}
  def verify(%{quorum_fraction: q, view_timeout_ms: vt, commit_timeout_ms: ct}) do
    with :ok <- check_quorum_safety(q),
         :ok <- check_liveness_bounds(vt, ct),
         :ok <- check_monotonicity(vt, ct) do
      :valid
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp check_quorum_safety(q) do
    if q >= 0.667 and q <= 0.90, do: :ok, else: {:error, :quorum_below_bft_bound}
  end

  defp check_liveness_bounds(vt, ct) do
    if vt >= 200 and vt <= 5000 and ct <= vt and ct >= 100,
      do: :ok, else: {:error, :timeout_bounds_violated}
  end

  defp check_monotonicity(vt, ct) do
    # Commit timeout must be ≤ view timeout to prevent deadlocks
    if ct <= vt, do: :ok, else: {:error, :commit_view_deadlock_risk}
  end
end