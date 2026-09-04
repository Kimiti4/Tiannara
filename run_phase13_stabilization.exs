# Phase 13.4.1 - Constitutional Stabilization Rerun
# This script reruns Stage 4 with complete constitutional infrastructure

alias TiannaraOS.{Stage3MethodEvolution, Stage4InstitutionAdaptation, Phase13Stabilization, MissionControl}

IO.puts("=" |> String.duplicate(80))
IO.puts("Phase 13.4.1 - Constitutional Stabilization")
IO.puts("=" |> String.duplicate(80))
IO.puts("")

# Step 1: Run Stage 3 to generate MethodEvolutionResults
IO.puts("Step 1: Running Stage 3 - Method Evolution Analysis...")
stage3_results = Stage3MethodEvolution.execute_stage_3(
  "simulation_output",
  :all,
  %{
    evaluation_categories: [
      :experiment_design,
      :data_collection,
      :analysis_methods,
      :validation_procedures,
      :replication_protocols
    ],
    time_window_months: 6
  }
)

IO.puts("✓ Stage 3 complete: #{length(stage3_results.method_evolution_results)} institutions analyzed")
IO.puts("  Total improvements proposed: #{stage3_results.summary.total_improvements}")
IO.puts("")

# Step 2: Run Stage 4 with complete infrastructure
IO.puts("Step 2: Running Stage 4 - Institution Adaptation (with stabilization)...")
stage4_results = Stage4InstitutionAdaptation.execute_stage_4(
  stage3_results.method_evolution_results,
  :all,
  %{
    budget: 10000,
    pilot_programs: 1,
    simulation_generations: 3
  }
)

IO.puts("✓ Stage 4 complete: #{length(stage4_results.adaptation_results)} adaptations recorded")
IO.puts("")

# Step 3: Display adaptation results summary
IO.puts("=" |> String.duplicate(80))
IO.puts("Stage 4 Results Summary")
IO.puts("=" |> String.duplicate(80))
IO.inspect(stage4_results.summary, label: "Adaptation Summary")
IO.puts("")

# Step 4: Check lifecycle completeness
IO.puts("Step 3: Validating Lifecycle Completeness...")
lifecycle_completeness = Phase13Stabilization.calculate_lifecycle_completeness_rate(stage4_results.adaptation_results)
IO.puts("  Lifecycle Completeness Rate: #{lifecycle_completeness}%")
IO.puts("")

# Step 5: Calculate prediction accuracy
IO.puts("Step 4: Calculating Prediction Accuracy...")
prediction_accuracy = Phase13Stabilization.calculate_aggregate_prediction_accuracy(stage4_results.adaptation_results)
IO.inspect(prediction_accuracy, label: "Prediction Accuracy Metrics")
IO.puts("")

# Step 6: Generate Mission Control dashboard metrics
IO.puts("Step 5: Generating Mission Control Dashboard Metrics...")
dashboard_metrics = Phase13Stabilization.generate_dashboard_metrics(stage4_results.adaptation_results)
IO.inspect(dashboard_metrics, label: "Dashboard Metrics")
IO.puts("")

# Step 7: Display sample adaptation result details
IO.puts("=" |> String.duplicate(80))
IO.puts("Sample Adaptation Result Details")
IO.puts("=" |> String.duplicate(80))

if length(stage4_results.adaptation_results) > 0 do
  sample = List.first(stage4_results.adaptation_results)
  
  IO.puts("")
  IO.puts("Institution: #{sample.institution_id}")
  IO.puts("Adaptation ID: #{sample.id}")
  IO.puts("Status: #{inspect(sample.status)}")
  IO.puts("Adoption Decision: #{inspect(sample.adoption_decision)}")
  IO.puts("")
  
  # Show lifecycle stages
  if sample.stage_history && length(sample.stage_history) > 0 do
    IO.puts("Lifecycle Stages (#{length(sample.stage_history)}):")
    Enum.each(sample.stage_history, fn stage ->
      IO.puts("  - #{inspect(stage.stage)} at #{stage.timestamp}")
    end)
    IO.puts("")
  end
  
  # Show semantic events
  if sample.semantic_events && length(sample.semantic_events) > 0 do
    IO.puts("Semantic Events (#{length(sample.semantic_events)}):")
    Enum.take(sample.semantic_events, 5) |> Enum.each(fn event ->
      IO.puts("  - #{inspect(event.type)}")
    end)
    if length(sample.semantic_events) > 5 do
      IO.puts("  ... and #{length(sample.semantic_events) - 5} more")
    end
    IO.puts("")
  end
  
  # Show simulation results (including prediction accuracy and rollback)
  if sample.simulation_results do
    sim = sample.simulation_results
    
    IO.puts("Simulation Results:")
    if sim[:prediction_accuracy] do
      IO.puts("  Prediction Accuracy:")
      IO.inspect(sim.prediction_accuracy, pretty: true)
      IO.puts("")
    end
    
    if sim[:rollback_plan] do
      IO.puts("  Rollback Plan:")
      IO.inspect(sim.rollback_plan, pretty: true)
      IO.puts("")
    end
    
    if sim[:total_proposals_evaluated] do
      IO.puts("  Total Proposals Evaluated: #{sim.total_proposals_evaluated}")
      IO.puts("  Adoption Ratio: #{sim.adoption_ratio}")
      IO.puts("")
    end
  end
  
  # Show constitutional compliance
  if sample.constitutional_compliance do
    IO.puts("Constitutional Compliance:")
    IO.puts("  Is Compliant: #{sample.constitutional_compliance.is_compliant}")
    IO.puts("  Violations: #{length(sample.constitutional_compliance.violations)}")
    if length(sample.constitutional_compliance.violations) > 0 do
      Enum.each(sample.constitutional_compliance.violations, fn v ->
        IO.puts("    - #{v.rule}: #{v.message}")
      end)
    end
    IO.puts("")
  end
end

# Step 8: Display Mission Control dashboard data
# Note: Requires GenServer processes to be started - skipping for now
IO.puts("=" |> String.duplicate(80))
IO.puts("Mission Control Dashboard - Adaptation Quality Section")
IO.puts("=" |> String.duplicate(80))
IO.puts("(Requires full system startup - skipped in script mode)")
IO.puts("")

# Step 9: Final validation summary
IO.puts("=" |> String.duplicate(80))
IO.puts("Phase 13.4.1 Validation Summary")
IO.puts("=" |> String.duplicate(80))
IO.puts("")

IO.puts("✓ Lifecycle Tracking:")
IO.puts("  Required stages: #{length(Phase13Stabilization.required_lifecycle_stages())}")
IO.puts("  Completeness rate: #{lifecycle_completeness}%")
IO.puts("")

IO.puts("✓ Prediction Accuracy Measurement:")
if prediction_accuracy.total_assessments > 0 do
  IO.puts("  Total assessments: #{prediction_accuracy.total_assessments}")
  IO.puts("  Average absolute error: #{prediction_accuracy.average_absolute_error}")
  IO.puts("  Average relative error: #{if prediction_accuracy.average_relative_error, do: "#{prediction_accuracy.average_relative_error}%", else: "N/A"}")
  IO.puts("  Prediction reliability rate: #{prediction_accuracy.prediction_reliability_rate * 100}%")
  IO.puts("  Average calibration: #{if prediction_accuracy.average_calibration, do: prediction_accuracy.average_calibration, else: "N/A"}")
else
  IO.puts("  No predictions available yet (first generation)")
end
IO.puts("")

IO.puts("✓ Rollback Completeness:")
rollback_count = Enum.count(stage4_results.adaptation_results, fn r ->
  sim = r.simulation_results || %{}
  sim[:rollback_plan] != nil
end)
IO.puts("  Adaptations with rollback plans: #{rollback_count}/#{length(stage4_results.adaptation_results)}")
IO.puts("")

IO.puts("✓ Constitutional Compliance:")
compliant_count = Enum.count(stage4_results.adaptation_results, fn r ->
  case TiannaraOS.InstitutionAdaptationResult.validate_constitutional_compliance(r) do
    {_, violations} -> length(violations) == 0
  end
end)
IO.puts("  Constitutionally compliant: #{compliant_count}/#{length(stage4_results.adaptation_results)}")
IO.puts("")

IO.puts("=" |> String.duplicate(80))
IO.puts("Phase 13.4.1 Complete - Ready for Stage 5 (Civilization Adaptation)")
IO.puts("=" |> String.duplicate(80))
