defmodule Tiannara.Phase18.RRM.AdaptationController do
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

    diffs =
      Enum.map(keys, fn k ->
        value_delta(Map.get(old, k), Map.get(new, k))
      end)

    Enum.sum(diffs) / max(length(diffs), 1)
  end

  # Rule sets mix numbers (`:unroll_factor`) with non-numeric settings
  # (`:precision`), so a drift measure must compare values by kind: equal
  # values contribute nothing, numeric pairs contribute their magnitude, and a
  # changed non-numeric setting contributes one unit of drift.
  defp value_delta(a, b) when a == b, do: 0.0
  defp value_delta(a, b) when is_number(a) and is_number(b), do: abs(a - b)
  defp value_delta(nil, b) when is_number(b), do: abs(b)
  defp value_delta(a, nil) when is_number(a), do: abs(a)
  defp value_delta(_a, _b), do: 1.0
end