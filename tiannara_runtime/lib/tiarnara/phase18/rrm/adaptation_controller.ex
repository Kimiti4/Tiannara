defmodule Tiarnara.Phase18.RRM.AdaptationController do
  @moduledoc """
  EMA smoothing, drift capping, and rollback gating.
  """
  @ema_alpha 0.25
  @max_drift 0.35
  @stability_threshold 0.50

  @spec within_drift_bound?(old :: map(), new :: map(), kappa :: float()) :: boolean()
  def within_drift_bound?(old, new, kappa) do
    delta = compute_drift_delta(old, new)
    delta <= kappa
  end

  @spec compute_metamorphosis_score(perf :: float(), equiv :: float(), drift :: float(), overhead :: float()) :: float()
  def compute_metamorphosis_score(perf, equiv, drift, overhead) do
    numerator = perf * equiv
    denominator = drift + overhead + 1.0e-6
    min(1.0, numerator / denominator)
  end

  @spec requires_rollback?(m_rrm :: float(), drift :: float()) :: boolean()
  def requires_rollback?(m_rrm, drift) do
    m_rrm < @stability_threshold or drift > @max_drift
  end

  @spec smooth_adaptation(current :: float(), previous :: float()) :: float()
  def smooth_adaptation(current, previous), do: @ema_alpha * current + (1 - @ema_alpha) * previous

  defp compute_drift_delta(old, new) do
    keys = Map.keys(old) ++ Map.keys(new) |> Enum.uniq()
    diffs = Enum.map(keys, fn k -> abs((old[k] || 0.0) - (new[k] || 0.0)) end)
    Enum.sum(diffs) / max(length(diffs), 1)
  end
end