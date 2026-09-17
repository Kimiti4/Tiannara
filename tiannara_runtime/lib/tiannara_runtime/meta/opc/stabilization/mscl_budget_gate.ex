defmodule Tiannara.Meta.OPC.Stabilization.MSCLBudgetGate do
  @moduledoc """
  Phase 5F.6 — MSCL Budget Gate

  Hard gate that verifies the observer's physics proposal fits within the
  current Meta-Stability Constraint Layer (MSCL) thermodynamic budget.
  Proposals that would exceed the budget are rejected before GPU dispatch.

  ## Integration

  In production this module queries `TiannaraRuntime.MSCL.BudgetTracker`
  for the live budget. The stub implementation uses a configurable
  threshold so the pipeline can be exercised without a running MSCL.

  ## Usage

      :ok = MSCLBudgetGate.check(estimated_cost)
  """

  require Logger

  # Maximum thermodynamic cost allowed per compilation (normalised units)
  @max_budget 1.0

  @doc """
  Checks whether `estimated_cost` fits within the current MSCL budget.

  ## Parameters
  - `estimated_cost`: Normalised cost in [0.0, 1.0] returned by
    `ThermodynamicBudgetEstimator` or `EntropyEstimator`

  ## Returns
  - `:ok` — Cost within budget
  - `{:error, :mscl_budget_exceeded}` — Cost exceeds available budget
  """
  def check(estimated_cost) when is_number(estimated_cost) do
    available = fetch_available_budget()

    if estimated_cost <= available do
      Logger.debug(
        "✅ [MSCLBudgetGate] Cost #{Float.round(estimated_cost * 1.0, 4)} within budget #{Float.round(available * 1.0, 4)}"
      )

      :ok
    else
      Logger.warning(
        "🛑 [MSCLBudgetGate] Cost #{estimated_cost} exceeds available MSCL budget #{available}"
      )

      {:error, :mscl_budget_exceeded}
    end
  end

  # ── Private Functions ─────────────────────────────────────────────────────

  # Fetches the current available budget from MSCL.
  # Falls back to @max_budget when MSCL is not running.
  defp fetch_available_budget do
    case Process.whereis(TiannaraRuntime.MSCL.BudgetTracker) do
      nil ->
        # MSCL not running — use default ceiling
        @max_budget

      _pid ->
        # TODO: replace with real MSCL call when 5F.5 is wired in
        # TiannaraRuntime.MSCL.BudgetTracker.available_budget()
        @max_budget
    end
  end
end
