defmodule TiannaraOS.Stage5OutcomeContractTest do
  @moduledoc """
  Stage 5 outcome/gate contract tests
  (certification/audit/STAGE5_OUTCOME_VOCABULARY.md).

  S5-0 locked current behavior (CT-1..CT-6, CT-8..CT-10); S5-1 replaced the
  temporary "no :outcome field" assertion with the permanent outcome contract
  (CT-7) and added CT-11 (decision→outcome mapping), CT-12 (OQ-1 violation
  tiers), CT-13 (gate_rejections attribution). S5-2 added CT-14..CT-18
  (Tier C rollout-tier verification: forged claims, missing rollback, stale
  provenance, unauthorized rollout, positive wiring via injected registry).

  Nothing here may be weakened to make a later change pass: the `>= 7` count
  gate stays byte-identical (CT-1/CT-10), rejected stays distinct from
  adopted/approved (CT-6/CT-7/CT-11), and :rollout_authorized must remain
  unreachable with the production registry (CT-7/CT-12) — reachable only
  through an injected authoritative registry (CT-18).
  """

  use ExUnit.Case, async: true

  alias TiannaraOS.{
    CivilizationAdaptationResult,
    InstitutionAdaptationResult,
    PredictionAssessment,
    Stage5CivilizationAdaptation
  }

  # ──────────────────────────────────────────────
  # S5-2 fake authoritative registries (Tier C injection via
  # execute_stage_5/3 opts[:rollout_registry] and verify_rollout_tier/3)
  # ──────────────────────────────────────────────

  defmodule CompleteRegistry do
    def fetch_rollout_authorizations(ids) do
      now = DateTime.utc_now()

      {:ok,
       Map.new(ids, fn id ->
         {id,
          %{
            stages: [:piloted, :governance_reviewed],
            evidence_source: :evidence_backed,
            verified_at: now
          }}
       end)}
    end
  end

  defmodule EmptyRegistry do
    def fetch_rollout_authorizations(_ids), do: {:ok, %{}}
  end

  defmodule StaleRegistry do
    def fetch_rollout_authorizations(ids) do
      verified_at = DateTime.add(DateTime.utc_now(), -100, :day)

      {:ok,
       Map.new(ids, fn id ->
         {id,
          %{
            stages: [:piloted, :governance_reviewed],
            evidence_source: :evidence_backed,
            verified_at: verified_at
          }}
       end)}
    end
  end

  defmodule FutureDatedRegistry do
    def fetch_rollout_authorizations(ids) do
      verified_at = DateTime.add(DateTime.utc_now(), 1, :day)

      {:ok,
       Map.new(ids, fn id ->
         {id,
          %{
            stages: [:piloted, :governance_reviewed],
            evidence_source: :evidence_backed,
            verified_at: verified_at
          }}
       end)}
    end
  end

  defmodule MissingGovernanceRegistry do
    def fetch_rollout_authorizations(ids) do
      {:ok,
       Map.new(ids, fn id ->
         {id, %{stages: [:piloted], evidence_source: :evidence_backed, verified_at: DateTime.utc_now()}}
       end)}
    end
  end

  defmodule SyntheticRecordRegistry do
    def fetch_rollout_authorizations(ids) do
      {:ok,
       Map.new(ids, fn id ->
         {id,
          %{
            stages: [:piloted, :governance_reviewed],
            evidence_source: :synthetic,
            verified_at: DateTime.utc_now()
          }}
       end)}
    end
  end

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

  # ── S5-2 fixtures ──

  # Two adopted inputs in different categories + min_institutions: 1 →
  # :universal_adoption (the decision branch Tier C applies to).
  defp adoption_inputs do
    [valid_input("t_a", category: :caching), valid_input("t_b", category: :compression)]
  end

  # Self-reported Tier C named-stage claims appended to stage_history.
  # Claims alone never authorize — they must be verified against
  # authoritative records (OQ-2).
  defp with_tier_stages(input) do
    extra = [
      %{stage: :piloted, timestamp: DateTime.utc_now(), metadata: %{}},
      %{stage: :governance_reviewed, timestamp: DateTime.utc_now(), metadata: %{}}
    ]

    %{input | stage_history: input.stage_history ++ extra}
  end

  defp forged_adoption_inputs do
    Enum.map(adoption_inputs(), &with_tier_stages/1)
  end

  defp completed_event(result) do
    Enum.find(result.semantic_events, &(&1.type == :civilization_adaptation_completed))
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

    test "no fixture produces :rollout_authorized with the production registry (S5-2 verification fails closed)" do
      # Adoption with ZERO compliance violations and no tier claims: still
      # capped at :adaptation_approved — the production registry has no
      # authoritative records (fail closed).
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

    test "rollout tier: violations can never authorize rollout; clean adoption without verified tier stays approved" do
      # Clean adoption (zero violations) without verified tier records:
      # still :adaptation_approved — production registry verification fails
      # closed (violations and missing authority both block rollout only).
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
  # CT-14: forged tier claims (S5-2, OQ-2)
  # ──────────────────────────────────────────────

  describe "CT-14 forged tier claims fail closed" do
    test "claims absent from stage_history are denied before any registry lookup" do
      civ = analyze(adoption_inputs(), min_institutions: 1)

      assert {:denied, :missing_named_stage_claims} =
               Stage5CivilizationAdaptation.verify_rollout_tier(
                 adoption_inputs(),
                 civ,
                 CompleteRegistry
               )
    end

    test "claims present but no authoritative record exists → unverified tier claim" do
      civ = analyze(adoption_inputs(), min_institutions: 1)

      assert {:denied, :unverified_tier_claim} =
               Stage5CivilizationAdaptation.verify_rollout_tier(
                 forged_adoption_inputs(),
                 civ,
                 EmptyRegistry
               )
    end

    test "claims present but production registry has no records → authoritative_records_unavailable" do
      civ = analyze(adoption_inputs(), min_institutions: 1)

      assert {:denied, :authoritative_records_unavailable} =
               Stage5CivilizationAdaptation.verify_rollout_tier(forged_adoption_inputs(), civ)
    end

    test "E2E: forged claims through the engine stay :adaptation_approved, denial recorded" do
      result = analyze(forged_adoption_inputs(), min_institutions: 1)

      assert result.civilization_decision == :universal_adoption
      assert result.outcome == :adaptation_approved
      refute result.outcome == :rollout_authorized

      completed = completed_event(result)
      assert completed.metadata.rollout_tier_status == :denied
      assert completed.metadata.rollout_tier_reason == :authoritative_records_unavailable
    end
  end

  # ──────────────────────────────────────────────
  # CT-15: missing rollback evidence (S5-2, Tier C restatement)
  # ──────────────────────────────────────────────

  describe "CT-15 missing rollback evidence fails closed" do
    test "rollback_available: false denies even with complete authoritative records" do
      civ = analyze(adoption_inputs(), min_institutions: 1)

      doctored =
        forged_adoption_inputs()
        |> Enum.map(&%{&1 | rollback_available: false})

      assert {:denied, :rollback_unavailable} =
               Stage5CivilizationAdaptation.verify_rollout_tier(doctored, civ, CompleteRegistry)
    end
  end

  # ──────────────────────────────────────────────
  # CT-16: stale provenance fails closed (S5-2)
  # ──────────────────────────────────────────────

  describe "CT-16 stale provenance fails closed" do
    test "authoritative records older than the freshness window are stale" do
      civ = analyze(adoption_inputs(), min_institutions: 1)

      assert {:denied, :stale_provenance} =
               Stage5CivilizationAdaptation.verify_rollout_tier(
                 forged_adoption_inputs(),
                 civ,
                 StaleRegistry
               )
    end

    test "future-dated verified_at beyond tolerated skew is treated as forged/stale" do
      civ = analyze(adoption_inputs(), min_institutions: 1)

      assert {:denied, :stale_provenance} =
               Stage5CivilizationAdaptation.verify_rollout_tier(
                 forged_adoption_inputs(),
                 civ,
                 FutureDatedRegistry
               )
    end

    test "missing result-level evidence lineage fails closed" do
      civ = analyze(adoption_inputs(), min_institutions: 1)
      stripped = %{civ | evidence_lineage: nil}

      assert {:denied, :missing_provenance} =
               Stage5CivilizationAdaptation.verify_rollout_tier(
                 forged_adoption_inputs(),
                 stripped,
                 CompleteRegistry
               )
    end
  end

  # ──────────────────────────────────────────────
  # CT-17: unauthorized rollout fails closed (S5-2)
  # ──────────────────────────────────────────────

  describe "CT-17 unauthorized rollout fails closed" do
    test "authoritative record without :governance_reviewed denies" do
      civ = analyze(adoption_inputs(), min_institutions: 1)

      assert {:denied, :missing_governance_review} =
               Stage5CivilizationAdaptation.verify_rollout_tier(
                 forged_adoption_inputs(),
                 civ,
                 MissingGovernanceRegistry
               )
    end

    test "authoritative record declaring synthetic evidence is inconsistent and denies" do
      civ = analyze(adoption_inputs(), min_institutions: 1)

      assert {:denied, :inconsistent_evidence} =
               Stage5CivilizationAdaptation.verify_rollout_tier(
                 forged_adoption_inputs(),
                 civ,
                 SyntheticRecordRegistry
               )
    end

    test "synthetic supporting input is denied before any registry lookup" do
      synthetic = %{
        valid_input("syn_t", category: :caching)
        | simulation_results: %{adopted_proposals: [], evidence_source: :synthetic}
      }

      # Tier stage claims present so verification reaches the evidence
      # check (claims are necessary but never sufficient).
      inputs = Enum.map([synthetic, valid_input("ok_t", category: :compression)], &with_tier_stages/1)
      civ = analyze(inputs, min_institutions: 1)

      assert {:denied, :evidence_not_backed} =
               Stage5CivilizationAdaptation.verify_rollout_tier(inputs, civ, CompleteRegistry)
    end
  end

  # ──────────────────────────────────────────────
  # CT-18: rollout authorization wiring (S5-2)
  # ──────────────────────────────────────────────

  describe "CT-18 rollout authorization wiring (S5-2)" do
    test "complete verified authoritative records authorize rollout end-to-end" do
      result =
        analyze(forged_adoption_inputs(),
          min_institutions: 1,
          rollout_registry: CompleteRegistry
        )

      assert result.civilization_decision == :universal_adoption
      assert result.outcome == :rollout_authorized

      completed = completed_event(result)
      assert completed.metadata.rollout_tier_status == :authorized
      assert completed.metadata.rollout_tier_reason == nil
    end

    test "violations still block rollout even with complete verified records (OQ-1)" do
      # Selective adoption with violations (CT-12 shape: nil predictions
      # record prediction_history_required without blocking approval).
      inputs =
        (Enum.map(1..7, fn i ->
           valid_input("v_#{i}", category: :caching, prediction: nil)
         end) ++
           Enum.map(8..10, fn i ->
             valid_input("v_#{i}", adopted: [], prediction: nil)
           end))
        |> Enum.map(&with_tier_stages/1)

      result = analyze(inputs, rollout_registry: CompleteRegistry)

      assert result.civilization_decision == :selective_adoption
      refute result.constitutional_compliance.is_compliant
      assert result.outcome == :adaptation_approved
      refute result.outcome == :rollout_authorized

      completed = completed_event(result)
      assert completed.metadata.rollout_tier_status == :denied
      assert completed.metadata.rollout_tier_reason == :compliance_violations

      # Violations stay explicitly recorded (nothing disappears).
      rules = Enum.map(result.constitutional_compliance.violations, & &1.rule)
      assert "prediction_history_required" in rules
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
