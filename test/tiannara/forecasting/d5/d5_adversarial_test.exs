defmodule Tiannara.Forecasting.D5.AdversarialTest do
  use ExUnit.Case, async: true

  alias Tiannara.Forecasting.D5.{
    Noise, Robustness, Perturbation, Temporal, Thresholds, Disagreement, Regime, Budget
  }

  test "agreement ≠ correctness: two agreeing forecasts are not deemed correct" do
    # D5 never emits a correctness verdict on agreement alone.
    # Consensus on a numeric position yields no correctness claim.
    consensus = Noise.consensus(4, [true, true, true, true])
    refute Map.has_key?(consensus, :correctness)
    refute Map.has_key?(consensus, :true)
  end

  test "disagreement ≠ error: high dispersion is not labelled an error" do
    vals = Enum.to_list(1..40)
    result = Noise.analyze(:evaluator, vals)
    # even if noise is high, it is noise classification, never "error"
    assert result.noise_class in [:negligible, :low, :moderate, :high, :unknown]
    refute Map.has_key?(result, :error)
  end

  test "variance ≠ noise: dispersion alone never yields a source claim" do
    # Identical reruns give sampling/occasion variability, and even then the
    # source is only attributed via an identifiability gate. Two varying
    # dimensions are NOT isolable to a single source.
    assert {:error, :not_identified} =
             Noise.isolate(%{model: [:m1, :m2], evaluator: [:e1, :e2]})
  end

  test "no bias inferred from insufficient observations" do
    small = Noise.bias_separation([0.9], 0.5)
    assert small.bias_status == :unknown
    assert small.reason == :insufficient_samples
  end

  test "no robustness claim without actual bounded perturbation coverage" do
    {:ok, plan} =
      Perturbation.register(%{target: "t", dimensions: %{model: ["m1", "m2"]}, rationale: "r"})

    # :model dimension never executed
    result = Robustness.classify(plan, %{dimension_results: %{}})
    assert result.class == :unknown
    refute Robustness.acceptable?(result)
  end

  test "threshold-laundering is detectable: classifications cite the threshold set" do
    a = Noise.analyze(:evaluator, List.duplicate(0.5, 40))
    assert a.threshold_set_hash == Thresholds.threshold_set_hash()
    refute a.threshold_set_hash == "altered-threshold-set"
  end

  test "selective perturbation cannot classify (late-added plans barred)" do
    {:ok, plan} = Perturbation.register_late_added(%{target: "t",
                                                     dimensions: %{model: ["m1"]}, rationale: "r"})
    refute Perturbation.classification_eligible?(Perturbation.complete(plan))
  end

  test "minority positions are never suppressed in aggregation" do
    j1 = Disagreement.judgment(%{entity: :m1, position: 0.6}) |> elem(1)
    j2 = Disagreement.judgment(%{entity: :m2, position: 0.6}) |> elem(1)
    j3 = Disagreement.judgment(%{entity: :m3, position: 0.1}) |> elem(1)

    {:ok, agg} = Disagreement.aggregate([j1, j2, j3], %{reference: 0.6})
    assert agg.disagreement_count.count == 1  # the minority is preserved, not dropped
    assert agg.minority_preserved
    assert length(agg.input_hashes) == 3
  end

  test "post-outcome analysis cannot write into decision-quality fields" do
    assert {:error, :post_outcome_write_into_decision_field} =
             Temporal.guarantee_write_guard(:post_outcome_analysis, :forecast_quality_at_decision_time)
  end

  test "regime mismatch forces aggregate UNKNOWN" do
    t1 = Regime.tag(%{domain: "finance"})
    t2 = Regime.tag(%{domain: "health"})
    assert {:error, :regime_mismatch} = Regime.aggregable?([t1, t2])
  end

  test "budget exhaustion produces deterministic rejection, not silent truncation" do
    assert {:error, :too_many_models} = Budget.evaluate(%{models: 7})
    assert {:error, :too_many_evaluators} = Budget.evaluate(%{evaluators: 7})
    # over-budget returns within_budget:false, not a silent pass
    over =
      Budget.evaluate(%{
        dimensions: 5,
        models: 6,
        evaluators: 6,
        variants_per_dimension: %{
          prompt: 8, evidence_order: 8, model: 8, evaluator: 8, parameter: 8
        }
      })
    assert {:ok, %{within_budget: false}} = over
  end

  test "variance CANNOT be used to claim robustness: total spread alone is never a class" do
    # A robustness class requires per-dimension materiality + coverage manifest.
    plain = %{class: :robust}  # no manifest present
    refute Robustness.acceptable?(Map.merge(plain, %{coverage_manifest: %{all_executed: false, all_valid: false, all_covered: false}}))
  end

  test "execution spoofing: claiming executed with zero runs is UNKNOWN, never robust" do
    # Adversary claims `executed: true` but reports `runs: 0` — zero runs cannot
    # satisfy the minimum coverage floor, so full coverage is impossible.
    {:ok, plan} =
      Perturbation.register(%{target: "t", dimensions: %{prompt: ["a", "b"]}, rationale: "r"})

    result =
      Robustness.classify(plan, %{
        dimension_results: %{prompt: %{executed: true, runs: 0, material: false, valid: true}}
      })

    assert result.class == :unknown
    assert result.coverage_manifest.entries[:prompt].covered == false
    refute Robustness.acceptable?(result)
  end

  test "contamination dominates over-budget and undeclared-dimension invalidity" do
    # The most severe verdict is CONTAMINATION because it signals a temporal
    # integrity violation; it must win even when the perturbation is also
    # over-budget or touches an undeclared dimension.
    {:ok, plan} =
      Perturbation.register(%{target: "t", dimensions: %{evaluator: ["e1", "e2"]}, rationale: "r"})

    assert {:ok, :contamination} =
             Perturbation.classify(plan, %{
               varied_dimensions: [:evaluator],
               at_decision_time_known: false
             })

    assert {:ok, :contamination} =
             Perturbation.classify(plan, %{
               varied_dimensions: [:evaluator],
               alters_decision_time_evidence: true
             })

    # even with a bogus dimension, contamination still wins
    assert {:ok, :contamination} =
             Perturbation.classify(plan, %{
               varied_dimensions: [:notreal],
               at_decision_time_known: false
             })
  end

  test "source cannot be spoofed into identifiability by inflating n alone" do
    # Two varying dimensions remain un-isolable no matter how large n grows;
    # an attacker cannot cite n=100 to force a single-source attribution.
    assert {:error, :not_identified} =
             Noise.isolate(%{evaluator: [:e1, :e2], model: [:m1, :m2], evidence_order: [:o1, :o2]})

    assert {:error, :not_identified} =
             Noise.identify_source(%{
               crossing: %{model: [:m1, :m2], evaluator: [:e1, :e2], prompt: [:p1, :p2]},
               n: 1000
             })
  end

  test "bias direction is never emitted on insufficient samples, even with a reference" do
    # A reference frame does not rescue an under-powered sample; emitting a
    # direction here would fabricate bias evidence.
    small = Noise.bias_separation([0.9], 0.5)
    assert small.bias_status == :unknown
    assert small.reason == :insufficient_samples
    refute Map.has_key?(small, :direction)
  end
end
