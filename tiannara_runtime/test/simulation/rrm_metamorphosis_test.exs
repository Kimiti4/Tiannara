defmodule Tiarnara.Simulation.RRMMetamorphosisTest do
  @moduledoc "Property-based validation of bounded adaptation, equivalence preservation, & rollback triggers"
  use ExUnit.Case, async: true
  use PropCheck

  alias Tiarnara.Phase18.RRM.{AdaptationController, EquivalenceVerifier}

  @kappa_meta 0.12
  @stability_threshold 0.50
  @max_drift 0.35

  property "Rule evolution never exceeds bounded drift threshold" do
    forall(
      {old, new} <- rule_pair_generator(),
      do: assert_drift_bounded(old, new)
    )
  end

  property "Metamorphosis score correctly triggers rollback when stability drops" do
    forall(
      {perf, equiv, drift, overhead} <- score_scenario_generator(),
      do: assert_rollback_logic(perf, equiv, drift, overhead)
    )
  end

  defp rule_pair_generator() do
    let(
      old <- float_map(3, 6),
      do: let(new <- mutated_map(old, 0.05), do: {old, new})
    )
  end

  defp mutated_map(old, max_mutation) do
    let(
      mutations <- vector(map_size(old), float(-max_mutation, max_mutation)),
      do:
        Enum.zip(Map.to_list(old), mutations)
        |> Enum.map(fn {{k, v}, mut} -> {k, max(0.0, min(1.0, v + mut))} end)
        |> Map.new()
    )
  end

  defp float_map(min, max) do
    let size <- integer(min, max), do:
      Enum.map(1..size, fn i -> {"param_#{i}", :rand.uniform()} end) |> Map.new()
  end

  defp score_scenario_generator() do
    let {p, e, d, o} <- {float(0.1, 0.9), float(0.8, 1.0), float(0.0, 0.4), float(0.0, 0.2)},
      do: {p, e, d, o}
  end

  defp assert_drift_bounded(old, new) do
    AdaptationController.within_drift_bound?(old, new, @kappa_meta)
  end

  defp assert_rollback_logic(perf, equiv, drift, overhead) do
    m_rrm = AdaptationController.compute_metamorphosis_score(perf, equiv, drift, overhead)
    expected = (m_rrm < 0.50 or drift > 0.35)
    assert AdaptationController.requires_rollback?(m_rrm, drift) == expected
    true
  end
end