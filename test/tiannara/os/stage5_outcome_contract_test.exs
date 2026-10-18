defmodule TiannaraOS.Stage5OutcomeContractTest do
  @moduledoc """
  S5-0 contract tests — lock CURRENT Stage 5 gate/outcome behavior before any
  outcome-vocabulary change (certification/audit/STAGE5_OUTCOME_VOCABULARY.md,
  phase S5-0).

  These tests intentionally assert today's behavior, including its defects
  (count-only gate, silent filtering, no `:outcome` field). S5-1 must keep
  CT-1..CT-6 and CT-8..CT-10 green while REPLACING CT-7 with the permanent
  outcome invariant (CT-7'). Nothing here may be weakened to make a later
  change pass.
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
  # CT-7 (pre-S5-1): no outcome vocabulary exists yet
  # ──────────────────────────────────────────────

  describe "CT-7 no rollout-authorization claim exists pre-change" do
    test "result struct has no :outcome field on either terminal shape" do
      analyzed = analyze([valid_input("nooutcome")])
      blocked = blocked([])

      refute Map.has_key?(analyzed, :outcome)
      refute Map.has_key?(blocked, :outcome)
      # Nothing in either result claims deployment/rollout authorization.
      refute Map.has_key?(analyzed, :rollout_authorized)
      refute Map.has_key?(blocked, :rollout_authorized)
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
