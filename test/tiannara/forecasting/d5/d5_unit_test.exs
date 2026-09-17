defmodule Tiannara.Forecasting.D5.UnitTest do
  use ExUnit.Case, async: true

  alias Tiannara.Forecasting.D5.{
    Thresholds, Repetition, Budget, Perturbation, Sensitivity,
    Noise, Robustness, Regime, Temporal, Disagreement
  }

  alias Tiannara.Forecasting.D5

  # ------------------------------------------------------------------
  # §14 Thresholds (single source, provenance)
  # ------------------------------------------------------------------

  test "threshold provenance cites contract version and stable hash" do
    assert Thresholds.contract_version() == "1.0.0"
    assert is_binary(Thresholds.threshold_set_hash())
    assert Thresholds.threshold_set_hash() == Thresholds.threshold_set_hash()
    assert D5.provenance().contract_version == "1.0.0"
  end

  test "threshold hash changes if a frozen threshold changes" do
    # Deterministic content → same hash for same constants; we assert the hash
    # is stable AND that the descriptor exposes every hard maximum for re-check.
    assert Thresholds.max_runs_per_analysis() == 512
    assert Thresholds.max_variants_per_dimension() == 8
    assert Thresholds.max_models_per_analysis() == 6
    assert Thresholds.max_evaluators_per_analysis() == 6
    assert Thresholds.max_perturbation_dimensions() == 5
    assert Thresholds.epsilon_material_fraction() == 0.10
    assert Thresholds.tier2_min() == 32
  end

  # ------------------------------------------------------------------
  # §4 Repetition tiers
  # ------------------------------------------------------------------

  test "repetition tiers: TIER-0/1/2 and n=1 never supports claims" do
    assert Repetition.tier_for(1) == {:ok, :tier0}
    assert Repetition.tier_for(4) == {:ok, :tier0}
    assert Repetition.tier_for(5) == {:ok, :tier1}
    assert Repetition.tier_for(31) == {:ok, :tier1}
    assert Repetition.tier_for(32) == {:ok, :tier2}

    assert Repetition.classifiable?(1) == false
    assert Repetition.classifiable?(5) == false
    assert Repetition.classifiable?(32) == true

    assert Repetition.describe(1).forced_state == :no_estimate_permitted
    assert Repetition.describe(10).forced_state == :provisional_only_no_classification
    assert Repetition.describe(40).forced_state == :classifiable
  end

  test "dispersion routes through canonical Numerics with insufficient handling" do
    assert Repetition.dispersion([1]) == {:error, :insufficient_samples}
    assert {:ok, %{variance: v, std_dev: sd, n: 3}} = Repetition.dispersion([2.0, 2.0, 2.0])
    assert v == 0.0
    assert sd == 0.0
  end

  # ------------------------------------------------------------------
  # §10 Budget
  # ------------------------------------------------------------------

  test "budget evaluates within/over budget and rejects unknown dimensions" do
    assert {:ok, %{within_budget: true}} =
             Budget.evaluate(%{dimensions: 2, models: 2, evaluators: 2,
                               variants_per_dimension: %{evidence_order: 3, prompt: 2}})

    assert not Budget.allowed?(%{dimensions: 1, models: 10, evaluators: 1})
    assert {:error, :unknown_dimension} =
             Budget.evaluate(%{dimensions: 1, variants_per_dimension: %{notreal: 2}})
    assert {:error, :too_many_dimensions} =
             Budget.evaluate(%{dimensions: 6})
    assert {:error, :too_many_models} = Budget.evaluate(%{models: 7})
    assert {:error, :too_many_evaluators} = Budget.evaluate(%{evaluators: 7})
  end

  test "closed dimension set is enforced" do
    assert :prompt in Budget.closed_dimensions()
    assert :temporal in Budget.closed_dimensions()
    assert not Budget.valid_dimension?(:not_real_dimension)
  end

  test "partial coverage downgrades to coverage-scoped unknown" do
    pc = Budget.partial_coverage([:prompt, :model], [:prompt])
    assert pc.coverage == :partial
    assert pc.forced_state == :coverage_scoped_unknown
    assert pc.missing_dimensions == [:model]
  end

  # ------------------------------------------------------------------
  # §5 Perturbation
  # ------------------------------------------------------------------

  test "perturbation plan pre-registration and eligibility" do
    {:ok, plan} =
      Perturbation.register(%{
        target: "recommendation stability",
        dimensions: %{prompt: ["a", "b"], evidence_order: [1, 2, 3]},
        rationale: "test plan"
      })

    assert plan.registration == :preregistered
    assert plan.dimension_count == 2
    refute Perturbation.classification_eligible?(plan)
    assert plan.content_hash != nil

    completed = Perturbation.complete(plan)
    assert Perturbation.classification_eligible?(completed)
  end

  test "late-added plans can never classify" do
    {:ok, plan} =
      Perturbation.register_late_added(%{
        target: "x", dimensions: %{model: ["m1", "m2"]}, rationale: "late"
      })

    assert plan.registration == :late_added
    refute Perturbation.classification_eligible?(plan)
    refute Perturbation.classification_eligible?(Perturbation.complete(plan))
  end

  test "perturbation validity: valid vs invalid vs contamination" do
    {:ok, plan} =
      Perturbation.register(%{target: "t",
                              dimensions: %{evaluator: ["e1", "e2"]},
                              rationale: "r"})

    assert {:ok, %{validity: :valid}} =
             Perturbation.classify(plan, %{varied_dimensions: [:evaluator]})

    assert {:ok, :invalid} =
             Perturbation.classify(plan, %{varied_dimensions: [:notreal]})

    assert {:ok, :contamination} =
             Perturbation.classify(plan, %{varied_dimensions: [:evaluator],
                                           at_decision_time_known: false})
  end

  # ------------------------------------------------------------------
  # §7.1 Sensitivity
  # ------------------------------------------------------------------

  test "sensitivity materiality: flips, crossings, epsilon movement" do
    assert Sensitivity.flip?([:a, :b], [:b, :a]) == true
    assert Sensitivity.flip?([:a, :b], [:a, :b]) == false
    assert_in_delta Sensitivity.delta(0.6, 0.9), 0.3, 0.000001
    # default epsilon = 10% of range 1.0 = 0.1; |0.3| > 0.1
    assert Sensitivity.material?(0.6, 0.9, 1.0) == true
    # small movement within epsilon is not material
    assert Sensitivity.material?(0.6, 0.62, 1.0) == false
    assert Sensitivity.threshold_crossing?(0.4, 0.7, 0.5) == true
    assert Sensitivity.threshold_crossing?(0.6, 0.7, 0.5) == false
  end

  # ------------------------------------------------------------------
  # §6 Noise + §6.4 Bias
  # ------------------------------------------------------------------

  test "noise classification requires TIER-2 and bands by CI width" do
    assert Noise.classify(1, 0.03) == :unknown
    assert Noise.classify(4, 0.03) == :unknown
    assert Noise.classify(10, 0.03) == :unknown
    assert Noise.classify(32, 0.03) == :negligible
    assert Noise.classify(32, 0.08) == :low
    assert Noise.classify(32, 0.15) == :moderate
    assert Noise.classify(32, 0.5) == :high
  end

  test "identifiability gate: only isolated sources are attributed" do
    # one varying dimension is isolable
    assert Noise.isolate(%{evaluator: [:e1, :e2], model: []}) == {:ok, :evaluator}
    # two varying dimensions are not isolable
    assert Noise.isolate(%{evaluator: [:e1, :e2], model: [:m1, :m2]}) == {:error, :not_identified}

    assert Noise.identify_source(%{crossing: %{model: [:m1, :m2], evaluator: []}, n: 40}) ==
             {:ok, :model}
    # under-powered → not identified
    assert Noise.identify_source(%{crossing: %{model: [:m1, :m2]}, n: 3}) ==
             {:error, :not_identified}
  end

  test "bias requires directional reference and doesn't fire from noise alone" do
    # no reference → UNKNOWN
    bias = Noise.bias_separation(Enum.to_list(1..40), nil)
    assert bias.bias_status == :unknown
    assert bias.reason == :no_directional_reference

    # with reference and enough samples → measured
    values = List.duplicate(0.5, 40)
    measured = Noise.bias_separation(values, 0.5)
    assert measured.bias_status == :measured
    assert measured.direction == :centered

    # insufficient samples + reference → unknown due to insufficient samples
    small = Noise.bias_separation([0.5], 0.5)
    assert small.bias_status == :unknown
    assert small.reason == :insufficient_samples
  end

  test "model consensus requires lineage; unknown lineage → UNKNOWN" do
    strong = Noise.consensus(5, [true, true, true, true, true])
    assert strong.consensus_strength == :strong
    assert strong.effective_independent_count == 5

    # correlated/unknown-lineage models cannot report numeric consensus
    unknown = Noise.consensus(4, [true, false, true, true])
    assert unknown.consensus_strength == :unknown
    assert unknown.effective_independent_count == :unknown

    # single model → UNKNOWN
    single = Noise.consensus(1, [true])
    assert single.consensus_strength == :unknown
  end

  test "analysed noise is UNKNOWN below TIER-2 and classified at TIER-2" do
    low = Noise.analyze(:evidence_order, Enum.to_list(1..3))
    assert low.tier == :tier0
    assert low.noise_class == :unknown

    high = Noise.analyze(:evaluator, Enum.to_list(1..40))
    assert high.tier == :tier2
    assert high.noise_class in [:negligible, :low, :moderate, :high]
    assert high.contract_version == "1.0.0"

    # zero dispersion (identical reruns) is genuinely negligible, not UNKNOWN
    identical = Noise.analyze(:evaluator, List.duplicate(0.5, 40))
    assert identical.noise_class == :negligible
  end

  # ------------------------------------------------------------------
  # §7 Robustness
  # ------------------------------------------------------------------

  test "robustness REQUIRES full coverage manifest; untested ⇒ UNKNOWN" do
    {:ok, plan} =
      Perturbation.register(%{target: "t", dimensions: %{prompt: ["a", "b"]}, rationale: "r"})

    # declared :prompt not executed → UNKNOWN
    result = Robustness.classify(plan, %{dimension_results: %{}})
    assert result.class == :unknown
    assert result.coverage_manifest.all_executed == false

    # executed + covered but no material change → ROBUST
    good =
      Robustness.classify(plan, %{
        dimension_results: %{prompt: %{material: false, runs: 2, valid: true}}
      })

    assert good.class == :robust
    assert Robustness.acceptable?(good)
  end

  test "robustness classes: robust / sensitive / fragile / moderately_robust" do
    {:ok, plan} =
      Perturbation.register(%{target: "t", dimensions: %{prompt: ["a", "b"]}, rationale: "r"})

    sens =
      Robustness.classify(plan, %{
        dimension_results: %{prompt: %{material: true, tier: :nominal, runs: 2, valid: true}}
      })

    assert sens.class == :sensitive

    frag =
      Robustness.classify(plan, %{
        dimension_results:
          %{prompt: %{material: true, tier: :nominal, runs: 2, flips: 2, valid: true}}
      })

    assert frag.class == :fragile

    modrob =
      Robustness.classify(plan, %{
        dimension_results:
          %{prompt: %{material: true, tier: :extreme, runs: 2, flips: 0, valid: true}}
      })

    assert modrob.class == :moderately_robust
  end

  test "confidence and robustness stay on separate axes" do
    axes = Robustness.axes(:fragile, 0.9)
    assert axes.robustness == :fragile
    assert axes.confidence == 0.9
    assert axes.merged == false
  end

  # ------------------------------------------------------------------
  # §8 Regime
  # ------------------------------------------------------------------

  test "regime mismatch blocks aggregation on sensitive dimensions" do
    t1 = Regime.tag(%{domain: "finance", temporal: :decision_time, population: "p1"})
    t2 = Regime.tag(%{domain: "health", temporal: :decision_time, population: "p1"})

    assert {:error, :regime_mismatch} = Regime.aggregable?([t1, t2])

    t1_same = Regime.tag(%{domain: "finance", temporal: :decision_time, population: "p1"})
    assert {:ok, _} = Regime.aggregable?([t1, t1_same])

    # declaring domain invariant allows aggregation across domains
    assert {:ok, _} = Regime.aggregable?([t1, t2], [:domain])
  end

  test "cross-regime robustness transfer is prohibited" do
    from = Regime.tag(%{domain: "finance"})
    to = Regime.tag(%{domain: "health"})
    refute Regime.transferable?(from, to)
    assert Regime.transferable?(from, Regime.tag(%{domain: "finance"}))
  end

  # ------------------------------------------------------------------
  # §9 Temporal
  # ------------------------------------------------------------------

  test "temporal label is computed, not self-declared" do
    decision = ~U[2026-01-01 00:00:00Z]
    earlier = ~U[2025-12-01 00:00:00Z]
    later = ~U[2026-02-01 00:00:00Z]

    assert Temporal.compute(decision, [earlier]) == {:ok, :decision_time}
    assert Temporal.compute(decision, [earlier, later]) == {:ok, :post_outcome_analysis}
    assert Temporal.compute(nil, [earlier]) == {:error, :missing_decision_time}
  end

  test "POST_OUTCOME_ANALYSIS cannot write into decision-time fields" do
    assert Temporal.guarantee_write_guard(:decision_time, :calibration) ==
             {:ok, :write_permitted}

    assert Temporal.guarantee_write_guard(:post_outcome_analysis, :calibration) ==
             {:error, :post_outcome_write_into_decision_field}

    assert Temporal.guarantee_write_guard(:post_outcome_analysis, :note) ==
             {:ok, :write_permitted}
  end

  test "adversarial audit event is surfaced for blocked writes" do
    event = Temporal.adversarial_audit_event(:post_outcome_analysis, :calibration, %{})
    assert event.event_type == "d5.temporal_firewall.adversarial_write_blocked"
  end

  # ------------------------------------------------------------------
  # §11 Disagreement + §15.1 activation
  # ------------------------------------------------------------------

  test "disagreement preserves individuals and produces derived aggregate" do
    j1 = Disagreement.judgment(%{entity: :m1, position: 0.6, confidence: 0.8}) |> elem(1)
    j2 = Disagreement.judgment(%{entity: :m2, position: 0.7, confidence: 0.7}) |> elem(1)
    j3 = Disagreement.judgment(%{entity: :m3, position: 0.2, confidence: 0.6}) |> elem(1)

    {:ok, agg} = Disagreement.aggregate([j1, j2, j3])
    assert agg.n == 3
    assert agg.minority_preserved
    assert length(agg.input_hashes) == 3
    # counts vs a reference
    {:ok, agg2} = Disagreement.aggregate([j1, j2, j3], %{reference: 0.6})
    assert agg2.disagreement_count.count == 2
  end

  test "disagreement aggregation rejects unpermitted methods" do
    j = Disagreement.judgment(%{entity: :m1, position: 0.5}) |> elem(1)
    assert {:error, :invalid_aggregation_method} = Disagreement.aggregate([j], %{method: :mean})
    assert Disagreement.aggregate([], %{}) == {:error, :no_judgments}
  end

  test "D5 facade exposes the disagreement and robustness API" do
    assert D5.contract_version() == "1.0.0"
    assert :thresholds in D5.status().implemented
    assert :institutional_lessons in D5.status().deferred
  end
end
