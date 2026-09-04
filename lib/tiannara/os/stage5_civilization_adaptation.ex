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

  alias TiannaraOS.{CivilizationAdaptationResult, PredictionAssessment}

  require Logger

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

    # Add lifecycle event
    result = CivilizationAdaptationResult.add_lifecycle_event(result, :adaptations_collected, %{
      institution_count: length(institution_results),
      timestamp: DateTime.utc_now()
    })

    # Phase 1: Validate completeness
    Logger.debug("[Stage5] Phase 1: Validating adaptation completeness")
    validated_results = validate_adaptations(institution_results)

    if length(validated_results) == 0 do
      Logger.warning("[Stage5] No valid adaptations found")
      create_empty_result(result, :no_valid_adaptations)
    else

    result = CivilizationAdaptationResult.advance_stage(result, :validated)

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

    # Add semantic events
    result = CivilizationAdaptationResult.add_semantic_event(result, :civilization_adaptation_completed, %{
      decision: decision,
      generation: generation,
      institutions_evaluated: length(validated_results)
    })

    result = CivilizationAdaptationResult.advance_stage(result, :recorded)

    # Validate constitutional compliance
    {final_result, violations} = CivilizationAdaptationResult.validate_constitutional_compliance(result)

    if length(violations) > 0 do
      Logger.warning("[Stage5] Constitutional violations detected: #{inspect(violations)}")
    else
      Logger.info("[Stage5] Civilization adaptation constitutionally compliant")
    end

    Logger.info("[Stage5] Civilization adaptation complete:")
    Logger.info("  Decision: #{inspect(final_result.civilization_decision)}")
    Logger.info("  Supporting institutions: #{length(final_result.supporting_institutions || [])}")

    final_result
    end
  end

  # ──────────────────────────────────────────────
  # Phase 1: Validate Adaptations
  # ──────────────────────────────────────────────

  defp validate_adaptations(institution_results) do
    Enum.filter(institution_results, fn result ->
      # Check lifecycle completeness
      has_lifecycle = result.stage_history && length(result.stage_history) >= 7

      # Check constitutional compliance
      is_compliant = case result.constitutional_compliance do
        %{is_compliant: true} -> true
        _ -> false
      end

      # Check rollback availability
      has_rollback = result.rollback_available == true

      # All checks must pass
      has_lifecycle and is_compliant and has_rollback
    end)
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
    # TODO: Fix estimate_* and identify_* helper functions
    base_plan = %{
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

  defp create_empty_result(result, reason) do
    result = CivilizationAdaptationResult.make_civilization_decision(result, :reject, %{
      reasoning: "No valid adaptations to evaluate",
      key_factors: ["#{reason}"],
      supporting_evidence: []
    })

    %{result | status: :failed, failure_reason: reason}
  end
end
