# Stage 5 - Civilization Adaptation Execution Script
# This script demonstrates evidence-based civilizational evolution

alias TiannaraOS.{
  InstitutionAdaptationResult,
  CivilizationAdaptationResult,
  Stage4InstitutionAdaptation,
  Stage5CivilizationAdaptation,
  PredictionAssessment
}

IO.puts("=" |> String.duplicate(80))
IO.puts("Stage 5 - Civilization Adaptation: Evidence-Based Civilizational Evolution")
IO.puts("=" |> String.duplicate(80))
IO.puts("")

# ──────────────────────────────────────────────
# Simulate Multi-Generational Civilization Evolution
# ──────────────────────────────────────────────

defmodule Stage5Simulation do
  alias TiannaraOS.{
    InstitutionAdaptationResult,
    CivilizationAdaptationResult,
    Stage4InstitutionAdaptation,
    Stage5CivilizationAdaptation,
    PredictionAssessment
  }

  @institutions [
    :institution_alpha, :institution_beta, :institution_gamma,
    :institution_delta, :institution_epsilon, :institution_zeta,
    :institution_eta, :institution_theta, :institution_iota,
    :institution_kappa, :institution_lambda, :institution_mu,
    :institution_nu, :institution_xi, :institution_omicron,
    :institution_pi, :institution_rho, :institution_sigma,
    :institution_tau, :institution_upsilon
  ]

  def run_multi_generational_simulation(num_generations \\ 5) do
    IO.puts("Running #{num_generations}-generation civilization evolution simulation...")
    IO.puts("")

    # Track metrics across generations
    generation_metrics = Enum.map(1..num_generations, fn generation ->
      IO.puts("=" |> String.duplicate(80))
      IO.puts("Generation #{generation}")
      IO.puts("=" |> String.duplicate(80))

      # Step 1: Each institution produces adaptation results (Stage 4)
      institution_results = simulate_institution_adaptations(generation)

      IO.puts("\n✓ Generated #{length(institution_results)} institution adaptation results")

      # Step 2: Execute Stage 5 - Civilization Adaptation
      civ_result = Stage5CivilizationAdaptation.execute_stage_5(
        institution_results,
        :tiannara,
        generation: generation,
        min_institutions: 15,
        prediction_reliability_threshold: 0.6
      )

      # Step 3: Extract and display metrics
      metrics = extract_generation_metrics(civ_result, institution_results, generation)

      IO.puts("\n📊 Generation #{generation} Metrics:")
      IO.puts("  Decision: #{inspect(civ_result.civilization_decision)}")
      IO.puts("  Supporting institutions: #{length(civ_result.supporting_institutions || [])}")
      IO.puts("  Adaptation families: #{length(civ_result.adaptation_families || [])}")
      IO.puts("  Transferability categories:")
      if civ_result.transferability_analysis do
        transferability = civ_result.transferability_analysis
        IO.puts("    Universal: #{transferability.universal_count || 0}")
        IO.puts("    Domain-specific: #{transferability.domain_specific_count || 0}")
        IO.puts("    Experimental: #{transferability.experimental_count || 0}")
        IO.puts("    Institution-specific: #{transferability.institution_specific_count || 0}")
      end

      IO.puts("")
      {generation, metrics, civ_result}
    end)

    # Display longitudinal analysis
    display_longitudinal_analysis(generation_metrics)

    generation_metrics
  end

  defp simulate_institution_adaptations(generation) do
    # Simulate InstitutionAdaptationResults from Stage 4
    # In reality, these would come from actual institutional execution
    Enum.map(@institutions, fn institution_id ->
      # Create realistic adaptation results with improving quality over generations
      success_rate_base = 0.3 + (generation * 0.05)  # Improves each generation
      success_rate = min(success_rate_base + :rand.uniform() * 0.3, 0.95)

      improvement = if success_rate > 0.6 do
        :rand.uniform() * 0.15  # 0-15% improvement for successful adaptations
      else
        :rand.uniform() * 0.05 - 0.02  # Small or negative for unsuccessful
      end

      # Create prediction assessment
      predicted_improvement = improvement + (:rand.uniform() - 0.5) * 0.05
      prediction_accuracy = PredictionAssessment.new(%{
        predicted_value: predicted_improvement,
        observed_value: improvement,
        confidence: 0.7 + (generation * 0.03),  # Prediction improves over time
        source_capability: :institution_adaptation
      })

      # Build InstitutionAdaptationResult
      %InstitutionAdaptationResult{
        id: "adaptation_#{institution_id}_gen#{generation}",
        institution_id: institution_id,
        adaptation_timestamp: DateTime.utc_now(),
        current_stage: :completed,
        improvement_category: :method_evolution,
        improvement_description: "Adaptive improvement for generation #{generation}",
        adoption_decision: if(success_rate > 0.7, do: :adopt, else: :reject),
        pilot_results: %{
          success_rate: Float.round(success_rate, 4),
          actual_improvement: Float.round(improvement, 4)
        },
        simulation_results: %{
          predicted_improvement: Float.round(predicted_improvement, 4),
          confidence: prediction_accuracy.confidence,
          prediction_accuracy: prediction_accuracy
        },
        stage_history: generate_complete_lifecycle(institution_id),
        constitutional_compliance: true
      }
    end)
  end

  defp generate_rollback_plan do
    %{
      rollback_procedure: "Revert to pre-adaptation state",
      rollback_cost: %{credits: 2500, time_days: 3, researcher_hours: 8},
      rollback_triggers: ["Performance degradation > 10%", "Constitutional violation"],
      rollback_deadline: DateTime.add(DateTime.utc_now(), 30, :day),
      rollback_confidence: 0.85,
      rollback_steps: [
        "Disable adapted methods",
        "Restore previous versions",
        "Monitor for 7 days"
      ]
    }
  end

  defp generate_complete_lifecycle(institution_id) do
    stages = [
      :proposal_received,
      :compatibility_analyzed,
      :risk_assessed,
      :simulated,
      :piloted,
      :performance_compared,
      :governance_reviewed,
      :decision_recorded,
      :rollback_generated,
      :constitutional_validation_completed,
      :adaptation_closed
    ]

    Enum.map(stages, fn stage ->
      %{
        stage: stage,
        timestamp: DateTime.utc_now(),
        metadata: %{institution: institution_id}
      }
    end)
  end

  defp extract_generation_metrics(civ_result, institution_results, generation) do
    # Calculate key metrics for this generation
    adopted_count = Enum.count(institution_results, fn r -> r.adoption_decision == :adopt end)
    rejected_count = Enum.count(institution_results, fn r -> r.adoption_decision == :reject end)

    avg_improvement = if length(institution_results) > 0 do
      improvements = Enum.map(institution_results, fn r ->
        case r.pilot_results do
          %{actual_improvement: imp} -> imp
          _ -> 0.0
        end
      end)
      Float.round(Enum.sum(improvements) / length(improvements), 4)
    else
      0.0
    end

    avg_prediction_error = calculate_avg_prediction_error(institution_results)

    %{
      generation: generation,
      decision: civ_result.civilization_decision,
      total_institutions: length(institution_results),
      adopted_count: adopted_count,
      rejected_count: rejected_count,
      adoption_rate: Float.round(adopted_count / max(length(institution_results), 1) * 100, 2),
      average_improvement: avg_improvement,
      average_prediction_error: avg_prediction_error,
      supporting_institutions: length(civ_result.supporting_institutions || []),
      adaptation_families: length(civ_result.adaptation_families || [])
    }
  end

  defp calculate_avg_prediction_error(institution_results) do
    errors = Enum.map(institution_results, fn result ->
      case result.simulation_results[:prediction_accuracy] do
        %PredictionAssessment{} = pa -> pa.absolute_error
        _ -> nil
      end
    end)
    |> Enum.filter(& &1)

    if length(errors) > 0 do
      Float.round(Enum.sum(errors) / length(errors), 4)
    else
      nil
    end
  end

  defp display_longitudinal_analysis(generation_metrics) do
    IO.puts("\n" <> ("=" |> String.duplicate(80)))
    IO.puts("LONGITUDINAL ANALYSIS - Multi-Generational Evolution")
    IO.puts("=" |> String.duplicate(80))
    IO.puts("")

    # Display trends
    IO.puts("📈 Adoption Rate Trend:")
    Enum.each(generation_metrics, fn {gen, metrics, _civ} ->
      bar = String.duplicate("█", round(metrics.adoption_rate / 5))
      IO.puts("  Gen #{gen}: #{metrics.adoption_rate}% #{bar}")
    end)

    IO.puts("\n📊 Average Improvement Trend:")
    Enum.each(generation_metrics, fn {gen, metrics, _civ} ->
      direction = if gen > 1 do
        prev = Enum.at(generation_metrics, gen - 2) |> elem(1)
        if metrics.average_improvement > prev.average_improvement, do: "↑", else: "↓"
      else
        "→"
      end
      IO.puts("  Gen #{gen}: #{metrics.average_improvement * 100}% #{direction}")
    end)

    IO.puts("\n🎯 Prediction Accuracy Trend:")
    Enum.each(generation_metrics, fn {gen, metrics, _civ} ->
      if metrics.average_prediction_error do
        error_pct = metrics.average_prediction_error * 100
        direction = if gen > 1 do
          prev = Enum.at(generation_metrics, gen - 2) |> elem(1)
          if metrics.average_prediction_error < prev.average_prediction_error, do: "↓ (improving)", else: "↑"
        else
          ""
        end
        IO.puts("  Gen #{gen}: #{Float.round(error_pct, 2)}% error #{direction}")
      else
        IO.puts("  Gen #{gen}: N/A")
      end
    end)

    IO.puts("\n🏛️  Civilization Decisions:")
    Enum.each(generation_metrics, fn {gen, metrics, _civ} ->
      IO.puts("  Gen #{gen}: #{inspect(metrics.decision)}")
    end)

    IO.puts("\n✅ Constitutional Maturity Assessment:")
    final_gen = List.last(generation_metrics) |> elem(1)
    IO.puts("  Final generation adoption rate: #{final_gen.adoption_rate}%")
    IO.puts("  Final generation improvement: #{final_gen.average_improvement * 100}%")
    IO.puts("  Total adaptations evaluated: #{Enum.sum(Enum.map(generation_metrics, fn {_, m, _} -> m.total_institutions end))}")

    IO.puts("\n" <> ("=" |> String.duplicate(80)))
    IO.puts("Stage 5 Complete - Civilization can now coordinate cross-institution evolution!")
    IO.puts("=" |> String.duplicate(80))
  end
end

# Execute the simulation
Stage5Simulation.run_multi_generational_simulation(5)
