defmodule Tiannara.Forecasting.D5.ReplayTest do
  use ExUnit.Case, async: true

  alias Tiannara.Forecasting.D5.{
    Noise, Robustness, Perturbation, Disagreement, Thresholds, Regime, Temporal
  }

  test "identical inputs + contract version reproduce the same noise classification (determinism)" do
    values = List.duplicate(0.5, 40)

    r1 = Noise.analyze(:evaluator, values)
    r2 = Noise.analyze(:evaluator, values)

    assert r1.noise_class == r2.noise_class
    assert r1.ci_width == r2.ci_width
    assert r1.dispersion == r2.dispersion
    assert r1.threshold_set_hash == r2.threshold_set_hash
    assert r1.contract_version == r2.contract_version
  end

  test "perturbation plan content hash is deterministic across registrations" do
    attrs = %{target: "t", dimensions: %{prompt: ["a", "b"]}, rationale: "r"}

    {:ok, p1} = Perturbation.register(attrs)
    {:ok, p2} = Perturbation.register(attrs)
    assert p1.content_hash == p2.content_hash
    assert p1.dimensions == p2.dimensions
  end

  test "disagreement records are recomputable from preserved individuals" do
    js =
      Enum.map(1..40, fn i ->
        Disagreement.judgment(%{entity: {:m, i}, position: 0.5 + i / 1000}) |> elem(1)
      end)

    {:ok, a1} = Disagreement.aggregate(js)
    {:ok, a2} = Disagreement.aggregate(js)

    assert a1.method == a2.method
    assert a1.version == a2.version
    assert a1.input_hashes == a2.input_hashes
    assert a1.dispersion == a2.dispersion
    # independent verifier can recompute the aggregate from the individuals
    assert length(a1.input_hashes) == 40
  end

  test "robustness classification is reproducible under identical results" do
    {:ok, plan} =
      Perturbation.register(%{target: "t", dimensions: %{prompt: ["a", "b"]}, rationale: "r"})
    plan = Perturbation.complete(plan)

    opts = %{dimension_results: %{prompt: %{material: false, runs: 2, valid: true}}}

    r1 = Robustness.classify(plan, opts)
    r2 = Robustness.classify(plan, opts)
    assert r1.class == r2.class
    assert r1.coverage_manifest == r2.coverage_manifest
  end

  test "regime and temporal results are stable across identical calls" do
    t = Regime.tag(%{domain: "d", population: "p"})
    assert Regime.aggregable?([t, Regime.tag(%{domain: "d", population: "p"})]) ==
           Regime.aggregable?([t, Regime.tag(%{domain: "d", population: "p"})])

    decision = ~U[2026-01-01 00:00:00Z]
    inputs = [~U[2025-12-01 00:00:00Z]]
    assert Temporal.compute(decision, inputs) == Temporal.compute(decision, inputs)
  end

  test "threshold set descriptor and hash are version-stable" do
    d1 = Thresholds.set_descriptor()
    d2 = Thresholds.set_descriptor()
    assert d1 == d2
    assert Thresholds.threshold_set_hash() == Thresholds.threshold_set_hash()
  end
end
