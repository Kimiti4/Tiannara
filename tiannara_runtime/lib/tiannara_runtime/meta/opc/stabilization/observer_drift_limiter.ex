defmodule Tiannara.Meta.OPC.Stabilization.ObserverDriftLimiter do
  @moduledoc """
  Phase 5F.6 — Observer Drift Limiter

  Validates that an observer's phase drift does not exceed the safe
  threshold. Excessive phase drift indicates the observer manifold is
  diverging from the causal substrate, which can cause reality
  decoherence.

  ## Constraint

  observer_state.phase_drift ≤ @max_drift (default: 0.75)

  ## Usage

      observer_state = %{phase_drift: 0.3}
      :ok = ObserverDriftLimiter.validate(observer_state)
  """

  require Logger

  @max_drift 0.75

  @doc """
  Validates that the observer's phase drift is within safe bounds.

  ## Parameters
  - `observer_state`: Map containing at least a `:phase_drift` float field

  ## Returns
  - `:ok` — Drift within bounds
  - `{:error, :observer_drift_exceeded}` — Drift exceeds threshold
  """
  def validate(%{phase_drift: drift}) do
    if drift > @max_drift do
      Logger.warning(
        "🛑 [ObserverDriftLimiter] Phase drift #{Float.round(drift, 4)} exceeds maximum #{@max_drift}"
      )

      {:error, :observer_drift_exceeded}
    else
      Logger.debug("✅ [ObserverDriftLimiter] Phase drift #{Float.round(drift, 4)} within bounds")
      :ok
    end
  end

  def validate(_observer_state) do
    # No phase_drift key — treat as zero drift (safe)
    :ok
  end
end
