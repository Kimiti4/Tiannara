defmodule TiannaraOS.Stage5CivilizationAdaptation do
  @moduledoc """
  Stage 5 - Civilization Adaptation: Evidence-Based Civilizational Evolution

  This module enables the civilization to answer one constitutional question:
  "Which improvements should spread across civilization?"

  It does NOT generate improvements. It evaluates improvements already tested
  by institutions through InstitutionAdaptationResults.

  ## Constitutional Pipeline

  Phase 1: Collect & Validate InstitutionAdaptationResults
  Phase 2: Group adaptations into families
  Phase 3: Compare outcomes across institutions
  Phase 4: Transferability analysis
  Phase 5: Make civilizational decision
  Phase 6: Generate rollout plan
  Phase 7: Record CivilizationAdaptationResult

  ## Public API

  execute_stage_5(institution_adaptation_results, civilization_id, opts)

  Returns CivilizationAdaptationResult with complete provenance.
  """

  alias TiannaraOS.{CivilizationAdaptationResult, PredictionAssessment, Stage5GovernanceRegistry}

  require Logger

  # S5-2 Tier C (OQ-2): named stages every supporting input must claim AND
  # have verified in authoritative records.
  @required_tier_stages [:piloted, :governance_reviewed]

  # Provisional freshness window for authoritative verified_at timestamps
  # (pending governance policy; records older than this fail closed).
  @max_authoritative_age_days 90

  # Tolerated clock skew before a future-dated verified_at is treated as
  # forged/stale.
  @verified_at_skew_seconds 60

  @doc """
  Execute Stage 5 - Civilization Adaptation.

  Analyzes InstitutionAdaptationResults from all institutions and determines
  which improvements should spread across civilization.

  ## Parameters
  - `institution_results`: [InstitutionAdaptationResult.t()] list from all institutions
  - `civilization_id`: atom() - civilization identifier (default: :tiannara)
  - `opts`: keyword list with optional configuration:
    - :generation - integer() current generation number
    - :min_institutions - integer() minimum institutions for universal adoption
    - :prediction_reliability_threshold - float() minimum prediction quality
    - :rollout_registry - module() authoritative Tier C record source
      (default: Stage5GovernanceRegistry; tests may inject a fake)

  ## Returns
  CivilizationAdaptationResult.t()
  """
  def execute_stage_5(institution_results, civilization_id \\ :tiannara, opts \\ []) do
    generation = Keyword.get(opts, :generation, 1)
    min_institutions = Keyword.get(opts, :min_institutions, 15)  # 75% of 20 institutions
    prediction_threshold = Keyword.get(opts, :prediction_reliability_threshold, 0.6)

    Logger.info("[Stage5] ===== Activating Civilization Adaptation =====")
    Logger.info("  Institution results: #{length(institution_results)}")
    Logger.info("  Generation: #{generation}")

    # Initialize result
    result = CivilizationAdaptationResult.new(civilization_id, %{
      generation: generation,
      institutions_evaluated: length(institution_results),
      total_adaptations_analyzed: length(institution_results)
    })

    # Phase 1: Validate completeness (S5-1: classify instead of silent
    # filter — acceptance logic unchanged; per-input gate failures recorded)
    Logger.debug("[Stage5] Phase 1: Validating adaptation completeness")
    {validated_results, gate_rejections} = classify_adaptations(institution_results)

    if length(validated_results) == 0 do
      Logger.warning("[Stage5] No valid adaptations found")
      create_empty_result(result, :no_valid_adaptations, gate_rejections)
    else

    result = %{result | gate_rejections: gate_rejections}
    result = CivilizationAdaptationResult.advance_stage(result, :adaptations_collected)
    result = CivilizationAdaptationResult.advance_stage(result, :validated)

    # Phase 1b: Record evidence lineage of accepted inputs
    evidence_lineage = build_evidence_lineage(validated_results)
    result = %{result | evidence_lineage: evidence_lineage}
    Logger.info("[Stage5] Evidence lineage: weakest input source = #{inspect(evidence_lineage.weakest_input_source)}")

    # Phase 2: Group into adaptation families
    Logger.debug("[Stage5] Phase 2: Grouping adaptations into families")
    families = group_into_families(validated_results)
    result = CivilizationAdaptationResult.record_adaptation_families(result, families)
    result = CivilizationAdaptationResult.advance_stage(result, :families_grouped)

    # Phase 3: Compare outcomes across institutions
    Logger.debug("[Stage5] Phase 3: Comparing outcomes across institutions")
    comparisons = compare_outcomes(families, validated_results)
    result = CivilizationAdaptationResult.advance_stage(result, :compared)

    # Phase 4: Transferability analysis
    Logger.debug("[Stage5] Phase 4: Analyzing transferability")
    transferability = analyze_transferability(comparisons, min_institutions, prediction_threshold)
    result = CivilizationAdaptationResult.record_transferability_analysis(result, transferability)
    result = CivilizationAdaptationResult.advance_stage(result, :transferability_analyzed)

    # Phase 5: Make civilizational decision
    Logger.debug("[Stage5] Phase 5: Making civilizational decision")
    {decision, rationale} = make_civilization_decision(transferability, comparisons)
    result = CivilizationAdaptationResult.make_civilization_decision(result, decision, rationale)
    result = CivilizationAdaptationResult.advance_stage(result, :decision_made)

    # Phase 6: Generate rollout plan
    Logger.debug("[Stage5] Phase 6: Generating rollout plan")
    rollout_plan = generate_rollout_plan(decision, transferability, validated_results)
    result = CivilizationAdaptationResult.generate_rollout_plan(result, rollout_plan)
    result = CivilizationAdaptationResult.advance_stage(result, :rollout_planned)

    # Phase 7: Record supporting evidence
    Logger.debug("[Stage5] Phase 7: Recording supporting evidence")
    evidence = extract_supporting_evidence(validated_results)
    result = CivilizationAdaptationResult.record_supporting_evidence(result, evidence)

    result = CivilizationAdaptationResult.advance_stage(result, :recorded)

    # Validate constitutional compliance
    {final_result, violations} = CivilizationAdaptationResult.validate_constitutional_compliance(result)

    if length(violations) > 0 do
      Logger.warning("[Stage5] Constitutional violations detected: #{inspect(violations)}")
    else
      Logger.info("[Stage5] Civilization adaptation constitutionally compliant")
    end

    # S5-2: derive the five-atom outcome via the full §2.3 table
    # (certification/audit/STAGE5_OUTCOME_VOCABULARY.md §2.3/§4).
    # OQ-1 (approved): compliance violations block :rollout_authorized only —
    # they never cap :analysis_possible or :adaptation_approved, and no
    # violation rule is reclassified here (all remain recorded in
    # :constitutional_compliance).
    # OQ-2 (approved): :rollout_authorized additionally requires
    # verify_rollout_tier/3 == :authorized; the production registry has no
    # authoritative records, so verification fails closed to
    # :adaptation_approved with the denial reason recorded in the event.
    registry = Keyword.get(opts, :rollout_registry, Stage5GovernanceRegistry)
    {outcome, rollout_tier} = derive_outcome(final_result, validated_results, registry)

    final_result = %{final_result | outcome: outcome}

    # Semantic events: appended after outcome derivation so the completed
    # event carries the outcome, the rollout-tier decision, and the
    # violation rules considered with it.
    final_result =
      CivilizationAdaptationResult.add_semantic_event(final_result, :civilization_adaptation_completed, %{
        decision: final_result.civilization_decision,
        generation: generation,
        institutions_evaluated: length(validated_results),
        outcome: outcome,
        compliance_violation_rules: Enum.map(violations, & &1.rule),
        rollout_tier_status: Map.fetch!(rollout_tier, :rollout_tier_status),
        rollout_tier_reason: Map.get(rollout_tier, :rollout_tier_reason)
      })

    Logger.info("[Stage5] Civilization adaptation complete:")
    Logger.info("  Decision: #{inspect(final_result.civilization_decision)}")
    Logger.info("  Outcome: #{inspect(final_result.outcome)}")
    Logger.info("  Supporting institutions: #{length(final_result.supporting_institutions || [])}")

    final_result
    end
  end

  # ──────────────────────────────────────────────
  # Phase 1: Validate Adaptations
  # ──────────────────────────────────────────────

  # S5-1: acceptance logic is byte-identical to the former
  # validate_adaptations/1 (all four checks AND-ed, count gate unchanged at
  # `stage_history >= 7`), but each rejected input now carries deterministic,
  # attributable gate-rejection reasons instead of being silently dropped.
  defp classify_adaptations(institution_results) do
    institution_results
    |> Enum.reduce({[], []}, fn input, {valid, rejected} ->
      case input_gate_reasons(input) do
        [] ->
          {[input | valid], rejected}

        reasons ->
          rejection = %{
            institution_id: input.institution_id,
            adaptation_result_id: input.id,
            reasons: reasons
          }

          {valid, [rejection | rejected]}
      end
    end)
    |> then(fn {valid, rejected} -> {Enum.reverse(valid), Enum.reverse(rejected)} end)
  end

  # Returns [] when the input passes every analysis gate; otherwise the list
  # of failed gates in fixed order (deterministic and attributable).
  defp input_gate_reasons(result) do
    checks = [
      # Check 1: lifecycle completeness — count-only, never relaxed (>= 7)
      {:lifecycle_count, result.stage_history != nil and length(result.stage_history) >= 7},
      # Check 2: constitutional compliance
      {:not_compliant, match?(%{is_compliant: true}, result.constitutional_compliance)},
      # Check 3: rollback availability
      {:no_rollback, result.rollback_available == true},
      # Check 4: explicit evidence-source labeling: inputs must declare
      # whether they are evidence-backed or synthetic. Unlabeled inputs
      # are rejected - pedigree is never assumed.
      {:unlabeled_evidence_source, evidence_source_of(result) != nil}
    ]

    for {reason, passed} <- checks, passed != true, do: reason
  end

  defp evidence_source_of(result) do
    sim = result.simulation_results || %{}

    case sim[:evidence_source] do
      source when source in [:evidence_backed, :synthetic] -> source
      _ -> nil
    end
  end

  defp build_evidence_lineage(validated_results) do
    inputs =
      Enum.map(validated_results, fn r ->
        %{
          adaptation_result_id: r.id,
          institution_id: r.institution_id,
          evidence_source: evidence_source_of(r)
        }
      end)

    weakest =
      if Enum.any?(inputs, &(&1.evidence_source == :synthetic)) do
        :synthetic
      else
        :evidence_backed
      end

    %{
      weakest_input_source: weakest,
      inputs: inputs,
      note: "Output pedigree never exceeds the weakest input source; synthetic inputs are never upgraded to evidence of genuine adaptation."
    }
  end

  # ──────────────────────────────────────────────
  # Phase 2: Group Into Families
  # ──────────────────────────────────────────────

  defp group_into_families(validated_results) do
    # Group by improvement category/method
    families_map = Enum.group_by(validated_results, fn result ->
      # Extract category from simulation_results
      sim = result.simulation_results || %{}
      adopted = sim[:adopted_proposals] || []

      if length(adopted) > 0 do
        List.first(adopted)[:category] || :unknown
      else
        :rejected_or_deferred
      end
    end)

    Enum.map(families_map, fn {category, results} ->
      %{
        family_id: :"family_#{category}",
        category: category,
        institution_count: length(results),
        institutions: Enum.map(results, fn r -> r.institution_id end),
        adaptation_ids: Enum.map(results, fn r -> r.id end),
        avg_improvement: calculate_family_avg_improvement(results),
        success_rate: calculate_family_success_rate(results)
      }
    end)
  end

  defp calculate_family_avg_improvement(results) do
    improvements = Enum.map(results, fn r ->
      sim = r.simulation_results || %{}
      adopted = sim[:adopted_proposals] || []

      if length(adopted) > 0 do
        List.first(adopted)[:observed_improvement] || 0
      else
        0
      end
    end)

    if length(improvements) > 0 do
      Float.round(Enum.sum(improvements) / length(improvements), 3)
    else
      0.0
    end
  end

  defp calculate_family_success_rate(results) do
    adopted_count = Enum.count(results, fn r ->
      sim = r.simulation_results || %{}
      length(sim[:adopted_proposals] || []) > 0
    end)

    if length(results) > 0 do
      Float.round(adopted_count / length(results), 3)
    else
      0.0
    end
  end

  # ──────────────────────────────────────────────
  # Phase 3: Compare Outcomes
  # ──────────────────────────────────────────────

  defp compare_outcomes(families, validated_results) do
    Enum.map(families, fn family ->
      # Get prediction accuracy for this family's institutions
      prediction_metrics = extract_prediction_metrics_for_family(family, validated_results)

      %{
        family_id: family.family_id,
        category: family.category,
        institution_count: family.institution_count,
        avg_improvement: family.avg_improvement,
        success_rate: family.success_rate,
        prediction_accuracy: prediction_metrics,
        consistency_score: calculate_consistency_score(family, validated_results)
      }
    end)
  end

  defp extract_prediction_metrics_for_family(family, validated_results) do
    # Filter results belonging to this family
    family_results = Enum.filter(validated_results, fn r ->
      r.id in family.adaptation_ids
    end)

    # Extract prediction assessments
    assessments = Enum.map(family_results, fn r ->
      sim = r.simulation_results || %{}
      sim[:prediction_accuracy]
    end)
    |> Enum.filter(& &1)

    if length(assessments) > 0 do
      PredictionAssessment.aggregate(assessments)
    else
      nil
    end
  end

  defp calculate_consistency_score(family, validated_results) do
    # Measure how consistent outcomes are across institutions
    improvements = Enum.map(family.adaptation_ids, fn id ->
      result = Enum.find(validated_results, fn r -> r.id == id end)
      if result do
        sim = result.simulation_results || %{}
        adopted = sim[:adopted_proposals] || []
        if length(adopted) > 0 do
          List.first(adopted)[:observed_improvement] || 0
        else
          0
        end
      else
        0
      end
    end)

    if length(improvements) < 2 do
      1.0  # Single institution = perfectly consistent
    else
      # Calculate coefficient of variation (lower = more consistent)
      mean = Enum.sum(improvements) / length(improvements)
      if mean == 0 do
        0.5
      else
        variance = Enum.sum(Enum.map(improvements, fn x -> (x - mean) ** 2 end)) / length(improvements)
        std_dev = :math.sqrt(variance)
        cv = std_dev / abs(mean)

        # Convert to 0-1 score (lower CV = higher consistency)
        Float.round(max(0.0, min(1.0, 1.0 - cv)), 3)
      end
    end
  end

  # ──────────────────────────────────────────────
  # Phase 4: Transferability Analysis
  # ──────────────────────────────────────────────

  defp analyze_transferability(comparisons, min_institutions, prediction_threshold) do
    categorized = Enum.map(comparisons, fn comp ->
      category = categorize_transferability(comp, min_institutions, prediction_threshold)

      %{
        family_id: comp.family_id,
        category: comp.category,
        transferability: category,
        institution_count: comp.institution_count,
        avg_improvement: comp.avg_improvement,
        success_rate: comp.success_rate,
        prediction_accuracy: comp.prediction_accuracy,
        consistency_score: comp.consistency_score
      }
    end)

    # Count by category
    universal_count = Enum.count(categorized, fn c -> c.transferability == :universal end)
    domain_specific_count = Enum.count(categorized, fn c -> c.transferability == :domain_specific end)
    institution_specific_count = Enum.count(categorized, fn c -> c.transferability == :institution_specific end)
    experimental_count = Enum.count(categorized, fn c -> c.transferability == :experimental end)
    unsafe_count = Enum.count(categorized, fn c -> c.transferability == :unsafe end)
    rejected_count = Enum.count(categorized, fn c -> c.transferability == :rejected end)

    %{
      universal_count: universal_count,
      domain_specific_count: domain_specific_count,
      institution_specific_count: institution_specific_count,
      experimental_count: experimental_count,
      unsafe_count: unsafe_count,
      rejected_count: rejected_count,
      family_details: categorized
    }
  end

  defp categorize_transferability(comp, min_institutions, prediction_threshold) do
    cond do
      # Universal: High success rate, many institutions, good prediction accuracy
      comp.success_rate > 0.8 and comp.institution_count >= min_institutions and
         meets_prediction_threshold(comp.prediction_accuracy, prediction_threshold) ->
        :universal

      # Domain-specific: Good success but limited to specific domain
      comp.success_rate > 0.6 and comp.institution_count >= 5 ->
        :domain_specific

      # Institution-specific: Only works in few institutions
      comp.success_rate > 0.5 and comp.institution_count < 5 ->
        :institution_specific

      # Experimental: Needs more testing
      comp.success_rate > 0.3 ->
        :experimental

      # Unsafe or rejected
      comp.avg_improvement < 0 ->
        :unsafe

      true ->
        :rejected
    end
  end

  defp meets_prediction_threshold(prediction_accuracy, threshold) do
    if prediction_accuracy == nil do
      false  # No prediction data = can't trust
    else
      reliability = prediction_accuracy.prediction_reliability_rate || 0
      reliability >= threshold
    end
  end

  # ──────────────────────────────────────────────
  # Phase 5: Make Civilizational Decision
  # ──────────────────────────────────────────────

  defp make_civilization_decision(transferability, comparisons) do
    # Determine overall decision based on transferability distribution
    cond do
      # Universal adoption if multiple families qualify
      transferability.universal_count >= 2 ->
        {:universal_adoption, %{
          reasoning: "Multiple adaptation families show consistent success across institutions",
          key_factors: [
            "#{transferability.universal_count} families qualify for universal adoption",
            "High prediction reliability across institutions",
            "Consistent improvement observed"
          ],
          supporting_evidence: extract_universal_families(comparisons)
        }}

      # Selective adoption for domain-specific improvements
      transferability.domain_specific_count > 0 ->
        {:selective_adoption, %{
          reasoning: "Domain-specific improvements should spread to similar domains",
          key_factors: [
            "#{transferability.domain_specific_count} domain-specific families identified",
            "Targeted rollout to compatible institutions",
            "Preserve institutional autonomy"
          ],
          supporting_evidence: extract_domain_families(comparisons)
        }}

      # Experimental expansion for promising but unproven improvements
      transferability.experimental_count > 0 ->
        {:experimental_expansion, %{
          reasoning: "Promising improvements need broader testing before full adoption",
          key_factors: [
            "#{transferability.experimental_count} experimental families",
            "Expand pilot programs to additional institutions",
            "Gather more evidence before commitment"
          ],
          supporting_evidence: extract_experimental_families(comparisons)
        }}

      # Further validation needed
      transferability.institution_specific_count > 0 ->
        {:further_validation, %{
          reasoning: "Improvements show promise but need more validation",
          key_factors: [
            "Limited institutional success so far",
            "Require additional pilot studies",
            "Improve prediction accuracy before scaling"
          ],
          supporting_evidence: []
        }}

      # Reject unsafe or ineffective adaptations
      transferability.unsafe_count > 0 or transferability.rejected_count > 0 ->
        {:reject, %{
          reasoning: "Adaptations show negative or insufficient improvement",
          key_factors: [
            "#{transferability.unsafe_count} unsafe families detected",
            "#{transferability.rejected_count} rejected families",
            "Protect civilization from harmful changes"
          ],
          supporting_evidence: []
        }}

      # Default: Preserve diversity
      true ->
        {:preserve_diversity, %{
          reasoning: "Mixed results suggest maintaining institutional diversity",
          key_factors: [
            "No clear consensus on best approach",
            "Different institutions may need different methods",
            "Allow natural selection over time"
          ],
          supporting_evidence: []
        }}
    end
  end

  defp extract_universal_families(comparisons) do
    Enum.filter(comparisons, fn c ->
      c.success_rate > 0.8 and c.institution_count >= 15
    end)
    |> Enum.map(fn c -> inspect(c.family_id) end)
  end

  defp extract_domain_families(comparisons) do
    Enum.filter(comparisons, fn c ->
      c.success_rate > 0.6 and c.institution_count >= 5 and c.institution_count < 15
    end)
    |> Enum.map(fn c -> inspect(c.family_id) end)
  end

  defp extract_experimental_families(comparisons) do
    Enum.filter(comparisons, fn c ->
      c.success_rate > 0.3 and c.success_rate <= 0.6
    end)
    |> Enum.map(fn c -> inspect(c.family_id) end)
  end

  # ──────────────────────────────────────────────
  # Phase 6: Generate Rollout Plan
  # ──────────────────────────────────────────────

  defp generate_rollout_plan(decision, _transferability, validated_results) do
    # Simplified rollout plan - helper functions have compilation issues
    # TODO: Fix estimate_* and identify_* helper functions.
    # Labeled :simulated: resource and benefit figures are placeholders,
    # not derived from inputs.
    base_plan = %{
      rollout_plan_source: :simulated,
      deployment_order: [],
      recommended_institutions: [],
      required_resources: %{credits: 0, researcher_hours: 0, time_months: 0},
      expected_benefits: %{avg_improvement: 0.0, velocity_gain: 0.0},
      expected_risks: [],
      rollback_strategy: %{procedure: "Revert to pre-adaptation state", confidence: 0.9},
      evaluation_checkpoints: []
    }

    case decision do
      :universal_adoption ->
        %{
          base_plan |
          recommended_institutions: Enum.uniq(Enum.map(validated_results, & &1.institution_id)),
          deployment_order: [],
          required_resources: %{credits: 10000, researcher_hours: 200, time_months: 3},
          expected_benefits: %{avg_improvement: 0.1, velocity_gain: 0.15},
          expected_risks: ["Coordination complexity"],
          evaluation_checkpoints: [:week_2, :week_4, :week_8]
        }

      :selective_adoption ->
        target = Enum.take(Enum.uniq(Enum.map(validated_results, & &1.institution_id)), 10)
        %{
          base_plan |
          recommended_institutions: target,
          deployment_order: [],
          required_resources: %{credits: 5000, researcher_hours: 100, time_months: 2},
          expected_benefits: %{avg_improvement: 0.08, velocity_gain: 0.12},
          expected_risks: ["Domain mismatch"],
          evaluation_checkpoints: [:week_2, :week_4]
        }

      :experimental_expansion ->
        expand_to = Enum.take(Enum.uniq(Enum.map(validated_results, & &1.institution_id)), 5)
        %{
          base_plan |
          recommended_institutions: expand_to,
          deployment_order: [],
          required_resources: %{credits: 2500, researcher_hours: 50, time_months: 1},
          expected_benefits: %{avg_improvement: 0.0, velocity_gain: 0.0},
          expected_risks: ["Unproven in new contexts"],
          evaluation_checkpoints: [:week_1, :week_2]
        }

      _ ->
        base_plan
    end
  end



  # ──────────────────────────────────────────────
  # Phase 7: Extract Supporting Evidence
  # ──────────────────────────────────────────────

  defp extract_supporting_evidence(validated_results) do
    institutions = Enum.map(validated_results, fn r -> r.institution_id end)
    |> Enum.uniq()

    # Extract episode references from simulation_results
    episodes = Enum.flat_map(validated_results, fn r ->
      sim = r.simulation_results || %{}
      sim[:supporting_episodes] || []
    end)
    |> Enum.uniq()

    adaptation_ids = Enum.map(validated_results, fn r -> r.id end)

    # Aggregate prediction history
    prediction_assessments = Enum.map(validated_results, fn r ->
      sim = r.simulation_results || %{}
      sim[:prediction_accuracy]
    end)
    |> Enum.filter(& &1)

    prediction_history = if length(prediction_assessments) > 0 do
      PredictionAssessment.aggregate(prediction_assessments)
    else
      nil
    end

    %{
      institutions: institutions,
      episodes: episodes,
      adaptation_results: adaptation_ids,
      prediction_history: prediction_history
    }
  end

  defp create_empty_result(result, reason, gate_rejections) do
    result = CivilizationAdaptationResult.make_civilization_decision(result, :reject, %{
      reasoning: "No valid adaptations to evaluate",
      key_factors: ["#{reason}"],
      supporting_evidence: []
    })

    result =
      CivilizationAdaptationResult.add_semantic_event(result, :civilization_adaptation_blocked, %{
        outcome: :evidence_insufficient,
        failure_reason: reason,
        gate_rejection_count: length(gate_rejections)
      })

    %{
      result
      | status: :failed,
        failure_reason: reason,
        outcome: :evidence_insufficient,
        gate_rejections: gate_rejections
    }
  end

  # ──────────────────────────────────────────────
  # S5-2: Outcome derivation (five-atom vocabulary, full §2.3 table)
  # certification/audit/STAGE5_OUTCOME_VOCABULARY.md §2.3/§4
  # ──────────────────────────────────────────────

  # Returns {outcome, rollout_tier_meta}:
  #   :reject           → :adaptation_rejected
  #   adoption decision → :rollout_authorized  if verify_rollout_tier/3 authorizes
  #                     → :adaptation_approved otherwise (denial recorded)
  #   anything else     → :analysis_possible
  #
  # OQ-1 (approved): violations block :rollout_authorized ONLY (check inside
  # verify_rollout_tier/3); they never cap :analysis_possible or
  # :adaptation_approved, and no violation rule is reclassified.
  # OQ-2 (approved): Tier C verification is authoritative and fail-closed —
  # never inferred from labels, synthetic acceptance, stage-cursor position,
  # or an earlier gate passing. The production registry
  # (Stage5GovernanceRegistry) serves no authoritative records yet, so
  # production adoption resolves to :adaptation_approved.
  defp derive_outcome(final_result, validated_results, registry) do
    decision = final_result.civilization_decision

    cond do
      decision == :reject ->
        # Evidence was analyzed; the analyzer refused to spread it.
        # Rejected is never represented as adopted or approved.
        {:adaptation_rejected, %{rollout_tier_status: :not_applicable}}

      adoption_decision?(decision) ->
        case verify_rollout_tier(validated_results, final_result, registry) do
          :authorized ->
            {:rollout_authorized, %{rollout_tier_status: :authorized}}

          {:denied, reason} ->
            {:adaptation_approved,
             %{rollout_tier_status: :denied, rollout_tier_reason: reason}}
        end

      true ->
        # :further_validation, :preserve_diversity, or any unrecognized
        # decision: analysis ran but grants no adoption authority
        # (fail-safe direction — never rolls forward into approval).
        {:analysis_possible, %{rollout_tier_status: :not_applicable}}
    end
  end

  @doc """
  Tier C rollout-tier verification (S5-2, OQ-2) — design doc §4.

  Returns `:authorized` only when every check passes, in this fixed
  fail-closed order (first failure wins, deterministic):

  1. Supporting inputs exist.
  2. Every supporting input's `stage_history` claims BOTH required named
     stages (`:piloted` and `:governance_reviewed`) — necessary, not
     sufficient (a claim alone never authorizes).
  3. Every supporting input has `rollback_available == true`.
  4. Every supporting input declares
     `simulation_results.evidence_source == :evidence_backed` (synthetic
     never authorizes rollout).
  5. Civilization-level compliance violations == [] (OQ-1: violations block
     rollout only).
  6. Result-level `evidence_lineage` exists (provenance present).
  7. The authoritative registry verifies EVERY supporting input: a record
     exists, its `stages` include both required named stages, its
     `evidence_source` is `:evidence_backed`, and its `verified_at` is
     present, not future-dated beyond tolerated skew, and not older than
     the provisional freshness window (stale provenance fails closed).

  The default registry (`Stage5GovernanceRegistry`) has no authoritative
  records, so production always fails closed here — rollout authorization
  is never guessed from self-reported fields.
  """
  def verify_rollout_tier(validated_results, civilization_result, registry \\ Stage5GovernanceRegistry) do
    cond do
      validated_results == [] ->
        {:denied, :no_supporting_inputs}

      not Enum.all?(validated_results, &claims_required_tier_stages?/1) ->
        {:denied, :missing_named_stage_claims}

      not Enum.all?(validated_results, &(&1.rollback_available == true)) ->
        {:denied, :rollback_unavailable}

      not Enum.all?(validated_results, &(evidence_source_of(&1) == :evidence_backed)) ->
        {:denied, :evidence_not_backed}

      civilization_violations(civilization_result) != [] ->
        {:denied, :compliance_violations}

      missing_lineage?(civilization_result) ->
        {:denied, :missing_provenance}

      true ->
        verify_authoritative_records(validated_results, registry)
    end
  end

  defp claims_required_tier_stages?(input) do
    stages = Enum.map(input.stage_history || [], & &1.stage)
    Enum.all?(@required_tier_stages, &(&1 in stages))
  end

  defp civilization_violations(civilization_result) do
    case civilization_result.constitutional_compliance do
      %{violations: violations} when is_list(violations) -> violations
      _ -> []
    end
  end

  defp missing_lineage?(civilization_result) do
    case civilization_result.evidence_lineage do
      %{inputs: inputs} when is_list(inputs) -> inputs == []
      _ -> true
    end
  end

  defp verify_authoritative_records(validated_results, registry) do
    ids = Enum.map(validated_results, & &1.institution_id)

    case registry.fetch_rollout_authorizations(ids) do
      {:ok, records} when is_map(records) ->
        now = DateTime.utc_now()

        cond do
          Enum.any?(ids, &(not Map.has_key?(records, &1))) ->
            {:denied, :unverified_tier_claim}

          Enum.any?(records, fn {_id, record} ->
               not (is_map(record) and
                      Enum.all?(@required_tier_stages, &(&1 in (record[:stages] || []))))
             end) ->
            {:denied, :missing_governance_review}

          Enum.any?(records, fn {_id, record} ->
               not (is_map(record) and record[:evidence_source] == :evidence_backed)
             end) ->
            {:denied, :inconsistent_evidence}

          Enum.any?(records, fn {_id, record} ->
               not is_map(record) or stale_verified_at?(record[:verified_at], now)
             end) ->
            {:denied, :stale_provenance}

          true ->
            :authorized
        end

      {:error, reason} when is_atom(reason) ->
        {:denied, reason}

      _ ->
        # Malformed registry response fails closed.
        {:denied, :authoritative_records_unavailable}
    end
  end

  # Freshness: missing → stale; future-dated beyond tolerated skew → forged
  # (stale); older than the provisional window → stale.
  defp stale_verified_at?(%DateTime{} = verified_at, now) do
    too_old = DateTime.before?(verified_at, DateTime.add(now, -@max_authoritative_age_days, :day))

    future_dated =
      DateTime.after?(verified_at, DateTime.add(now, @verified_at_skew_seconds, :second))

    too_old or future_dated
  end

  defp stale_verified_at?(_verified_at, _now), do: true

  defp adoption_decision?(decision) do
    decision in [:universal_adoption, :selective_adoption, :experimental_expansion]
  end
end
