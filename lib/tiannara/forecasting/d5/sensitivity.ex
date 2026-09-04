defmodule Tiannara.Forecasting.D5.Sensitivity do
  @moduledoc """
  D5 Sensitivity — baseline vs perturbed effect measurement and materiality
  (contract §7.1).

  Materiality (what counts as "changed"):
    M1 recommendation flip  — A>B becomes B>A, or enters/leaves top choice
    M2 contract-threshold crossing — a decision threshold is crossed
    M3 continuous movement |Δ| > ε_material, where ε_material is a per-target
       contract parameter. Default is 10% of the declared decision-relevant
       range (D5.Thresholds.epsilon_material_fraction/0). Deviations require a
       written justification attached to the plan (pre-data).

  This module computes deltas and materiality deterministically; it does not
  itself declare robustness (see D5.Robustness).
  """

  alias Tiannara.Forecasting.D5.Thresholds

  @doc """
  Compute the signed delta between baseline and perturbed numeric values.
  """
  @spec delta(number(), number()) :: number()
  def delta(baseline, perturbed), do: perturbed - baseline

  @doc """
  Materiality of continuous movement: `|Δ| > ε_material`.
  `range` is the declared decision-relevant range for the target class; the
  default materiality threshold is `fraction * range`. A specific `epsilon`
  overrides the default and must come from the plan (pre-data justification).
  """
  @spec material?(number(), number(), number(), number() | nil) :: boolean()
  def material?(baseline, perturbed, range, epsilon \\ nil) do
    eps = epsilon || Thresholds.epsilon_material_fraction() * range
    abs(delta(baseline, perturbed)) > eps
  end

  @doc """
  Detect a recommendation flip between two ordered rankings (lists of ids).
  A flip is a relative-order change between the top elements or the top-choice
  id changing.
  """
  @spec flip?([term()], [term()]) :: boolean()
  def flip?(base_ranking, perturbed_ranking) do
    base_top = List.first(base_ranking)
    pert_top = List.first(perturbed_ranking)

    base_top != pert_top or
      (base_top != nil and relative_order_changed?(base_ranking, perturbed_ranking))
  end

  @doc """
  Detect a contract-threshold crossing: baseline and perturbed values lie on
  opposite sides of `threshold`.
  """
  @spec threshold_crossing?(number(), number(), number()) :: boolean()
  def threshold_crossing?(baseline, perturbed, threshold) do
    (baseline - threshold) * (perturbed - threshold) < 0
  end

  @doc """
  Build a full materiality finding for one dimension's baseline vs perturbed
  outputs. Returns a map with all three materiality signals plus the delta.
  """
  @spec finding(number(), number(), number(), [term()], [term()], number() | nil) :: map()
  def finding(baseline_val, perturbed_val, range, base_ranking, pert_ranking, epsilon \\ nil) do
    d = delta(baseline_val, perturbed_val)

    %{
      baseline: baseline_val,
      perturbed: perturbed_val,
      delta: d,
      material_movement: material?(baseline_val, perturbed_val, range, epsilon),
      recommendation_flip: flip?(base_ranking, pert_ranking),
      material: material?(baseline_val, perturbed_val, range, epsilon),
      # materiality via flip/crossing is categorical, always material
      threshold_crossing: nil
    }
  end

  @doc """
  Materiality across the three signals: ANY of M1/M2/M3 being true makes the
  perturbation materially changed (M2 crossings supplied explicitly as a term).
  """
  @spec materially_changed?(map()) :: boolean()
  def materially_changed?(%{material_movement: mm, recommendation_flip: flip} = f) do
    mm or flip or Map.get(f, :threshold_crossing, false) == true
  end

  @doc """
  Compute a specified threshold crossing (M2) against one declared threshold.
  Returns `true` if baseline and perturbed cross it.
  """
  @spec crosses_threshold?(number(), number(), number()) :: boolean()
  def crosses_threshold?(baseline, perturbed, threshold),
    do: threshold_crossing?(baseline, perturbed, threshold)

  # A relative order change: any two consecutive pairs differ in order, or any
  # swap among the top elements. Conservative: top-2 order change counts.
  defp relative_order_changed?(base, pert) do
    order_pairs = fn r -> r |> Enum.take(2) |> List.to_tuple() end
    order_pairs.(base) != order_pairs.(pert)
  end
end
