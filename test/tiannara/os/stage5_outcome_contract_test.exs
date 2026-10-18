defmodule TiannaraOS.Stage5OutcomeContractTest do
  @moduledoc """
  Stage 5 outcome/gate contract tests
  (certification/audit/STAGE5_OUTCOME_VOCABULARY.md).

  S5-0 locked current behavior (CT-1..CT-6, CT-8..CT-10); S5-1 replaced the
  temporary "no :outcome field" assertion with the permanent outcome contract
  (CT-7) and added CT-11 (decision→outcome mapping), CT-12 (OQ-1 violation
  tiers), CT-13 (gate_rejections attribution).

  Nothing here may be weakened to make a later change pass: the `>= 7` count
  gate stays byte-identical (CT-1/CT-10), rejected stays distinct from
  adopted/approved (CT-6/CT-7/CT-11), and :rollout_authorized must remain
  unreachable until S5-2 implements OQ-2 tier verification (CT-7/CT-12).
  """

  use ExUnit.Case, async: true

  alias TiannaraOS.{
    CivilizationAdaptationResult,
    InstitutionAdaptationResult,
    PredictionAssessment,
    Stage5CivilizationAdaptation
  }

  # ──────────────────────────────────────────────
  # Fixtures
  # ──────────────────────────────────────────────

  defp reliable_prediction do
    PredictionAssessment.new(predicted_value: 0.5, observed_value: 0.5, confidence: 1.0)
  end

  defp history(count) do
    Enum.map(1..count, fn i ->
      %{stage: :"stage_#{i}", timestamp: DateTime.utc_now(), metadata: %{}}
    end)
  end

  # Passes all four gates (count, compliance, rollback, evidence-source label).
  defp valid_input(id, opts \\ []) do
    category = Keyword.get(opts, :category, :caching)
    adopted = Keyword.get(opts, :adopted, [%{category: category, improvement_id: "imp_#{id}"}])
    prediction = Keyword.get(opts, :prediction, reliable_prediction())

    sim =
      %{adopted_proposals: adopted, evidence_source: :evidence_backed}
      |> maybe_put(:prediction_accuracy, prediction)

    %InstitutionAdaptationResult{
      id: id,
      institution_id: :"institution_#{id}",
      stage_history: history(Keyword.get(opts, :stages, 8)),
      constitutional_compliance: Keyword.get(opts, :compliance, %{is_compliant: true, violations: []}),
      rollback_available: Keyword.get(opts, :rollback, true),
      simulation_results: sim,
      lifecycle_events: [],
      semantic_events: []
    }
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  # Genuine Stage 4 evidence-mode shape: :proposal_received (from new/2) plus
  # the four stages this mode actually performs, ending :decision_recorded
  # (stage4_institution_adaptation.ex:318-332). 5 entries < 7.
  defp genuine_stage4_input(id) do
    valid_input(id,
      stages: 5,
      prediction: nil
    )
    |> Map.put(:stage_history, [
      %{stage: :proposal_received, timestamp: DateTime.utc_now(), metadata: %{}},
      %{stage: :compatibility_analyzed, timestamp: DateTime.utc_now(), metadata: %{}},
      %{stage: :risk_assessed, timestamp: DateTime.utc_now(), metadata: %{}},
      %{stage: :projected, timestamp: DateTime.utc_now(), metadata: %{}},
      %{stage: :decision_recorded, timestamp: DateTime.utc_now(), metadata: %{}}
    ])
  end

  defp blocked(inputs, opts \\ []) do
    Stage5CivilizationAdaptation.execute_stage_5(inputs, :test_civilization, opts)
  end

  defp analyze(inputs, opts \\ []) do
    result = blocked(inputs, opts)
    refute result.status == :failed, "expected analysis to run, got blocked: #{inspect(result)}"
    result
  end

  # ──────────────────────────────────────────────
  # CT-1: count-gate boundary (6 vs 7) — count-only proof
  # ──────────────────────────────────────────────

  describe "CT-1 stage_history count boundary (>= 7, count-only)" do
    test "6-entry history is rejected even when every other check passes" do
      result = blocked([valid_input("six", stages: 6)])

      assert result.status == :failed
      assert result.failure_reason == :no_valid_adaptations
      assert result.civilization_decision == :reject
    end

    test "7-entry history with arbitrary stage names passes (gate checks length, not content)" do
      result = analyze([valid_input("seven", stages: 7)])

      assert result.status == :recorded
      assert result.failure_reason == nil
    end
  end

  # ──────────────────────────────────────────────
  # CT-2: missing rollback stays blocking
  # ──────────────────────────────────────────────

  describe "CT-2 rollback gate" do
    test "rollback_available: false is rejected" do
      result = blocked([valid_input("norollback", rollback: false)])

      assert result.status == :failed
      assert result.failure_reason == :no_valid_adaptations
    end
  end

  # ──────────────────────────────────────────────
  # CT-3: noncompliant input is rejected
  # ──────────────────────────────────────────────

  describe "CT-3 compliance gate" do
    test "constitutional_compliance.is_compliant != true is rejected" do
      result =
        blocked([
          valid_input("noncompliant", compliance: %{is_compliant: false, violations: []})
        ])

      assert result.status == :failed
      assert result.failure_reason == :no_valid_adaptations
    end
  end

  # ──────────────────────────────────────────────
  # CT-4: evidence-source labeling gate
  # ──────────────────────────────────────────────

  describe "CT-4 evidence-source labeling gate" do
    test "unlabeled input is rejected fail-closed" do
      unlabeled = %{valid_input("unlabeled") | simulation_results: %{adopted_proposals: []}}
      result = blocked([unlabeled])

      assert result.status == :failed
      assert result.failure_reason == :no_valid_adaptations
    end

    test "synthetic-labeled input is accepted for analysis (restriction happens at rollout tier, not here)" do
      synthetic = %{valid_input("syn") | simulation_results: %{adopted_proposals: [], evidence_source: :synthetic}}
      result = analyze([synthetic])

      assert result.evidence_lineage.weakest_input_source == :synthetic
    end
  end

  # ──────────────────────────────────────────────
  # CT-5: success path = stage cursor :recorded, full lifecycle
  # ──────────────────────────────────────────────

  describe "CT-5 success path status/lifecycle" do
    test "analyzed result ends at cursor :recorded with all 8 required stages and no failure_reason" do
      result = analyze([valid_input("ok")])

      assert result.status == :recorded
      assert result.failure_reason == nil

      stages = Enum.map(result.lifecycle_events, & &1.stage)

      required = [
        :adaptations_collected,
        :validated,
        :families_grouped,
        :compared,
        :transferability_analyzed,
        :decision_made,
        :rollout_planned,
        :recorded
      ]

      for stage <- required, do: assert(stage in stages, "missing stage #{inspect(stage)}")
      assert length(stages) == 8
    end
  end

  # ──────────────────────────────────────────────
  # CT-6: rejected != adopted
  # ──────────────────────────────────────────────

  describe "CT-6 analyzer rejection vs adoption are distinct" do
    test "adoption decision vs reject decision are distinct and rollout plans differ" do
      adoption =
        analyze(
          [
            valid_input("ad_a", category: :caching),
            valid_input("ad_b", category: :compression)
          ],
          min_institutions: 1
        )

      rejection =
        analyze([
          valid_input("rej", adopted: [], prediction: reliable_prediction())
        ])

      assert adoption.civilization_decision == :universal_adoption
      assert rejection.civilization_decision == :reject
      assert adoption.civilization_decision != rejection.civilization_decision

      # Adoption carries institutions to spread to; rejection carries none.
      assert length(adoption.rollout_plan[:recommended_institutions]) == 2
      assert rejection.rollout_plan[:recommended_institutions] == []
    end
  end

  # ──────────────────────────────────────────────
  # CT-7 (S5-1): outcome vocabulary contract — replaces the pre-S5-1
  # "no :outcome field exists" assertion with the permanent contract.
  # ──────────────────────────────────────────────

  describe "CT-7 outcome vocabulary contract (S5-1)" do
    test "both terminal shapes carry :outcome within the five-atom vocabulary" do
      vocabulary = [
        :evidence_insufficient,
        :analysis_possible,
        :adaptation_rejected,
        :adaptation_approved,
        :rollout_authorized
      ]

      analyzed = analyze([valid_input("voc")])
      blocked = blocked([])

      assert Map.has_key?(analyzed, :outcome)
      assert Map.has_key?(blocked, :outcome)
      assert analyzed.outcome in vocabulary
      assert blocked.outcome in vocabulary
      assert blocked.outcome == :evidence_insufficient
    end

    test "no fixture produces :rollout_authorized (S5-2 verification not implemented; fails closed)" do
      # Adoption with ZERO compliance violations: still capped at
      # :adaptation_approved because rollout-tier verification is S5-2.
      zero_violation_adoption =
        analyze(
          [
            valid_input("ra_a", category: :caching),
            valid_input("ra_b", category: :compression)
          ],
          min_institutions: 1
        )

      assert zero_violation_adoption.constitutional_compliance.is_compliant == true
      assert zero_violation_adoption.outcome == :adaptation_approved
      refute zero_violation_adoption.outcome == :rollout_authorized
    end

    test "blocked input is never represented as adopted, approved, or rejected-on-merits" do
      blocked_result = blocked([valid_input("six2", stages: 6)])

      assert blocked_result.outcome == :evidence_insufficient

      refute blocked_result.outcome in [
               :adaptation_approved,
               :adaptation_rejected,
               :rollout_authorized
             ]
    end
  end

  # ──────────────────────────────────────────────
  # CT-11: decision → outcome mapping (reachable decisions)
  # ──────────────────────────────────────────────

  describe "CT-11 decision-to-outcome mapping (reachable decisions)" do
    test ":further_validation maps to :analysis_possible" do
      result = analyze([valid_input("map_fv")])

      assert result.civilization_decision == :further_validation
      assert result.outcome == :analysis_possible
    end

    test "analyzer :reject maps to :adaptation_rejected" do
      result = analyze([valid_input("map_rej", adopted: [], prediction: reliable_prediction())])

      assert result.civilization_decision == :reject
      assert result.outcome == :adaptation_rejected
    end

    test ":universal_adoption maps to :adaptation_approved" do
      result =
        analyze(
          [
            valid_input("map_ua", category: :caching),
            valid_input("map_ub", category: :compression)
          ],
          min_institutions: 1
        )

      assert result.civilization_decision == :universal_adoption
      assert result.outcome == :adaptation_approved
    end

    test ":selective_adoption (default opts) maps to :adaptation_approved" do
      adopted = Enum.map(1..7, fn i -> valid_input("sel_#{i}", category: :caching) end)
      deferred = Enum.map(8..10, fn i -> valid_input("sel_#{i}", adopted: []) end)
      result = analyze(adopted ++ deferred)

      assert result.civilization_decision == :selective_adoption
      assert result.outcome == :adaptation_approved
    end
  end

  # ──────────────────────────────────────────────
  # CT-12: compliance violations at each outcome tier (OQ-1 regression)
  # ──────────────────────────────────────────────

  describe "CT-12 compliance violations at each outcome tier (OQ-1)" do
    test "analysis tier: violations do not cap :analysis_possible" do
      result = analyze([valid_input("tier_a", prediction: nil)])

      refute result.constitutional_compliance.is_compliant
      assert result.outcome == :analysis_possible
    end

    test "approval tier: violations do not cap :adaptation_approved and stay recorded" do
      adopted = Enum.map(1..7, fn i -> valid_input("vt_#{i}", category: :caching, prediction: nil) end)
      deferred = Enum.map(8..10, fn i -> valid_input("vt_#{i}", adopted: [], prediction: nil) end)
      result = analyze(adopted ++ deferred)

      assert result.civilization_decision == :selective_adoption
      refute result.constitutional_compliance.is_compliant
      assert result.outcome == :adaptation_approved

      # Violations remain explicitly recorded — they must not disappear
      # merely because they do not block lower tiers.
      rules = Enum.map(result.constitutional_compliance.violations, & &1.rule)
      assert "prediction_history_required" in rules

      # And they are carried into the completed semantic event alongside
      # the outcome.
      completed =
        Enum.find(result.semantic_events, &(&1.type == :civilization_adaptation_completed))

      assert completed.metadata.outcome == :adaptation_approved
      assert "prediction_history_required" in completed.metadata.compliance_violation_rules
    end

    test "rollout tier: violations can never authorize rollout; S5-1 emits no rollout even when clean" do
      # Clean adoption (zero violations): still :adaptation_approved —
      # :rollout_authorized additionally requires S5-2 tier verification,
      # so violations-prevent-rollout and not-implemented-verification both
      # fail closed to approval.
      clean =
        analyze(
          [
            valid_input("cr_a", category: :caching),
            valid_input("cr_b", category: :compression)
          ],
          min_institutions: 1
        )

      assert clean.constitutional_compliance.is_compliant == true
      assert clean.outcome == :adaptation_approved
      refute clean.outcome == :rollout_authorized
    end
  end

  # ──────────────────────────────────────────────
  # CT-13: gate_rejections attribution (S5-1)
  # ──────────────────────────────────────────────

  describe "CT-13 gate_rejections attribution (S5-1)" do
    test "each failing gate produces its deterministic reason, one input per gate" do
      inputs = [
        valid_input("g1", stages: 6),
        valid_input("g2", compliance: %{is_compliant: false, violations: []}),
        valid_input("g3", rollback: false),
        %{valid_input("g4") | simulation_results: %{adopted_proposals: []}}
      ]

      result = blocked(inputs)

      assert result.outcome == :evidence_insufficient
      assert length(result.gate_rejections) == 4

      reasons_by_id =
        Map.new(result.gate_rejections, fn rejection ->
          {rejection.adaptation_result_id, rejection.reasons}
        end)

      assert reasons_by_id["g1"] == [:lifecycle_count]
      assert reasons_by_id["g2"] == [:not_compliant]
      assert reasons_by_id["g3"] == [:no_rollback]
      assert reasons_by_id["g4"] == [:unlabeled_evidence_source]

      # Attributable: institution ids preserved, input order deterministic.
      assert Enum.map(result.gate_rejections, & &1.institution_id) ==
               [:institution_g1, :institution_g2, :institution_g3, :institution_g4]
    end

    test "multi-gate failure lists every failed reason in fixed order" do
      bad = %{
        valid_input("multi", stages: 6)
        | constitutional_compliance: %{is_compliant: false, violations: []},
          rollback_available: false
      }

      result = blocked([bad])

      assert [%{adaptation_result_id: "multi", reasons: reasons}] = result.gate_rejections
      assert reasons == [:lifecycle_count, :not_compliant, :no_rollback]
    end

    test "mixed valid/invalid: analysis runs and only rejected inputs are recorded" do
      result = analyze([valid_input("ok_m"), valid_input("bad_m", stages: 6)])

      assert result.status == :recorded

      assert [%{adaptation_result_id: "bad_m", reasons: [:lifecycle_count]}] =
               result.gate_rejections
    end

    test "empty input list has no gate rejections to attribute" do
      result = blocked([])
      assert result.gate_rejections == []
    end
  end

  # ──────────────────────────────────────────────
  # CT-8: blocked shape (persistence contract covered by
  # recursive_civilization_runner_test.exs "genuine stage5 ... honest
  # blocked result" — asserts persisted status/failure_reason/decision)
  # ──────────────────────────────────────────────

  describe "CT-8 blocked result shape" do
    test "blocked result is :failed/:no_valid_adaptations/:reject with no rollout or evidence attached" do
      result = blocked([])

      assert result.status == :failed
      assert result.failure_reason == :no_valid_adaptations
      assert result.civilization_decision == :reject
      assert result.rollout_plan == nil
      assert result.supporting_institutions == nil
      assert result.evidence_lineage == nil
    end
  end

  # ──────────────────────────────────────────────
  # CT-9: compliance violations are recorded but non-blocking today
  # ──────────────────────────────────────────────

  describe "CT-9 compliance violations do not flip status or decision" do
    test "input without prediction data: decision stands while violation is recorded" do
      result = analyze([valid_input("nopred", prediction: nil)])

      assert result.status == :recorded
      assert result.civilization_decision != nil
      assert result.civilization_decision != :reject

      compliance = result.constitutional_compliance
      assert compliance.is_compliant == false
      rules = Enum.map(compliance.violations, & &1.rule)
      assert "prediction_history_required" in rules
    end
  end

  # ──────────────────────────────────────────────
  # CT-10: genuine Stage 4-shaped history is blocked by the count gate
  # (documents CURRENT blocking; Tier C must not "fix" this by loosening)
  # ──────────────────────────────────────────────

  describe "CT-10 genuine Stage 4 shape is rejected by count gate alone" do
    test "5-entry history ending :decision_recorded is rejected even with all other checks green" do
      result = blocked([genuine_stage4_input("genuine_s4")])

      assert result.status == :failed
      assert result.failure_reason == :no_valid_adaptations
      assert result.civilization_decision == :reject
    end
  end

  # ──────────────────────────────────────────────
  # Supporting invariant: CivilizationAdaptationResult.status doubles as the
  # stage cursor (advance_stage/2 reads it) — locked so S5-1 adds :outcome
  # as a SEPARATE field instead of repurposing :status.
  # ──────────────────────────────────────────────

  describe "status field is the stage cursor" do
    test "advance_stage transitions status through the cursor chain" do
      result = CivilizationAdaptationResult.new(:test_civilization, [])
      assert result.status == :pending

      result = CivilizationAdaptationResult.advance_stage(result, :adaptations_collected)
      assert result.status == :adaptations_collected

      result = CivilizationAdaptationResult.advance_stage(result, :validated)
      assert result.status == :validated
      assert length(result.lifecycle_events) == 2
    end
  end
end
