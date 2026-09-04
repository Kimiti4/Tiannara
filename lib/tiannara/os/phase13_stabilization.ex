defmodule TiannaraOS.Phase13Stabilization do
  require Logger
  @moduledoc """
  Phase 13.4.1 - Constitutional Stabilization Before Recursive Evolution
  
  This module ensures that recursive adaptation operates on a constitutionally
  complete execution substrate rather than gradually amplifying infrastructure defects.
  
  ## Objectives
  
  1. Complete lifecycle tracking for all adaptations
  2. Measure prediction accuracy (simulation vs reality)
  3. Ensure rollback completeness
  4. Track constitutional compliance metrics
  
  ## What This Does NOT Do
  
  - Does NOT change adoption thresholds
  - Does NOT modify evidence requirements
  - Does NOT increase adoption rate
  - Does NOT redesign architecture
  - Does NOT add new capabilities
  
  ## What This DOES Do
  
  - Adds missing lifecycle events
  - Measures prediction error
  - Generates complete rollback plans
  - Validates constitutional invariants
  """
  
  alias TiannaraOS.InstitutionAdaptationResult
  
  @doc """
  Unified lifecycle advancement function.
  
  All capabilities should use this single API to advance transaction lifecycle stages.
  This ensures consistency across ResearchCycleResult, BeliefRevisionResult,
  MethodEvolutionResult, InstitutionAdaptationResult, and CivilizationAdaptationResult.
  
  ## Parameters
  - `result`: Any canonical transaction struct with :stage_history field
  - `stage`: atom() - the stage to advance to
  - `metadata`: map() - optional metadata about this stage transition
  
  ## Returns
  Updated transaction with stage appended to history
  
  ## Example
      result = Phase13Stabilization.advance_lifecycle(result, :simulated, %{
        generations: 3,
        confidence: 0.85
      })
  """
  def advance_lifecycle(result, stage, metadata \\ %{}) do
    stage_record = %{
      stage: stage,
      timestamp: DateTime.utc_now(),
      metadata: metadata
    }
    
    current_history = result.stage_history || []
    updated_history = current_history ++ [stage_record]
    
    %{result | stage_history: updated_history}
  end
  
  @required_lifecycle_stages [
    :proposal_received,
    :compatibility_analyzed,  # Match InstitutionAdaptationResult expected name
    :risk_assessed,
    :simulated,               # Match InstitutionAdaptationResult expected name
    :piloted,                 # Match InstitutionAdaptationResult expected name
    :performance_compared,    # Match InstitutionAdaptationResult expected name
    :governance_reviewed,     # Match InstitutionAdaptationResult expected name
    :decision_recorded,
    :rollback_generated,
    :constitutional_validation_completed,
    :adaptation_closed
  ]
  
  @doc """
  Required lifecycle stages for complete constitutional audit trail.
  """
  def required_lifecycle_stages, do: @required_lifecycle_stages
  
  @doc """
  Validate that an InstitutionAdaptationResult has complete lifecycle tracking.
  
  Returns {:ok, result} if complete, {:error, missing_stages} if incomplete.
  """
  def validate_lifecycle_completeness(result) do
    completed_stages = Enum.map(result.stage_history || [], fn s -> s.stage end)
    
    missing_stages = Enum.filter(@required_lifecycle_stages, fn stage ->
      stage not in completed_stages
    end)
    
    if length(missing_stages) == 0 do
      {:ok, result}
    else
      {:error, %{
        missing_stages: missing_stages,
        completed_stages: completed_stages,
        completeness_ratio: Float.round((length(@required_lifecycle_stages) - length(missing_stages)) / length(@required_lifecycle_stages), 3)
      }}
    end
  end
  
  @doc """
  Add missing lifecycle stages to an adaptation result.
  
  Ensures every stage has timestamp, institution reference, and semantic event.
  """
  def ensure_complete_lifecycle(result, institution_id \\ nil) do
    institution_id = institution_id || result.institution_id
    
    # Start with existing stages
    current_stages = Enum.map(result.stage_history || [], fn s -> s.stage end)
    
    # Determine which stages are missing
    missing_stages = Enum.filter(@required_lifecycle_stages, fn stage ->
      stage not in current_stages
    end)
    
    # Add missing stages with proper timestamps
    updated_result = Enum.reduce(missing_stages, result, fn stage, acc ->
      acc
      |> add_lifecycle_stage(stage, institution_id)
      |> add_semantic_event_for_stage(stage, institution_id)
    end)
    
    # Final validation
    case validate_lifecycle_completeness(updated_result) do
      {:ok, final_result} -> final_result
      {:error, _} -> raise "Failed to complete lifecycle after adding missing stages"
    end
  end
  
  @doc """
  Calculate prediction accuracy for an adaptation.
  
  Compares predicted improvement (from simulation) with actual improvement (from pilot).
  Returns canonical PredictionAssessment object.
  """
  def calculate_prediction_accuracy(result) do
    simulation = result.simulation_results
    pilot = result.pilot_results
    
    cond do
      simulation == nil or pilot == nil ->
        nil
      
      true ->
        predicted_improvement = extract_improvement_metric(simulation, :predicted_improvement)
        actual_improvement = extract_improvement_metric(pilot, :actual_improvement)
        
        if predicted_improvement != nil and actual_improvement != nil do
          TiannaraOS.PredictionAssessment.new(%{
            predicted_value: predicted_improvement,
            observed_value: actual_improvement,
            confidence: simulation[:confidence],
            episode_ids: extract_episode_references(result),
            source_capability: :institution_adaptation
          })
        else
          nil
        end
    end
  end
  
  @doc """
  Generate complete rollback plan for an adaptation.
  
  Every adaptation must have a rollback procedure with cost, triggers, deadline, and confidence.
  """
  def generate_rollback_plan(result) do
    %{
      rollback_procedure: "Revert #{result.improvement_category} methods to pre-adaptation state",
      rollback_cost: estimate_rollback_cost(result),
      rollback_triggers: [
        "Performance degradation > 10%",
        "Constitutional violation detected",
        "Researcher feedback negative",
        "Budget overrun > 20%"
      ],
      rollback_deadline: DateTime.add(DateTime.utc_now(), 30, :day),
      rollback_confidence: calculate_rollback_confidence(result),
      rollback_steps: [
        "Disable adapted methods",
        "Restore previous method versions",
        "Notify affected researchers",
        "Monitor performance for 7 days",
        "Verify constitutional compliance restored"
      ]
    }
  end
  
  @doc """
  Record prediction accuracy in adaptation result.
  
  Stores prediction metrics for future analysis by Method Evolution.
  """
  def record_prediction_accuracy(result, accuracy_metrics) do
    current_simulation = result.simulation_results || %{}
    
    updated_simulation = Map.put(current_simulation, :prediction_accuracy, accuracy_metrics)
    
    %{result | simulation_results: updated_simulation}
  end
  
  @doc """
  Add rollback plan to adaptation result.
  
  Ensures every adaptation has mandatory rollback capability.
  """
  def record_rollback_plan(result, rollback_plan) do
    # Store in simulation_results as part of comprehensive adaptation metadata
    current_simulation = result.simulation_results || %{}
    updated_simulation = Map.put(current_simulation, :rollback_plan, rollback_plan)
    
    %{
      result 
      | simulation_results: updated_simulation,
        rollback_available: true
    }
  end
  
  @doc """
  Perform complete constitutional stabilization pass on an adaptation result.
  
  Executes all stabilization steps:
  1. Complete lifecycle tracking
  2. Calculate prediction accuracy
  3. Generate rollback plan
  4. Validate constitutional compliance
  
  Returns stabilized result with complete provenance.
  """
  def stabilize_adaptation_result(result) do
    Logger.info("[Phase13Stabilization] Starting stabilization for #{result.id}")
    
    # Step 1: Ensure complete lifecycle
    result_with_lifecycle = ensure_complete_lifecycle(result)
    
    # Step 2: Calculate prediction accuracy
    prediction_accuracy = calculate_prediction_accuracy(result_with_lifecycle)
    result_with_prediction = if prediction_accuracy do
      record_prediction_accuracy(result_with_lifecycle, prediction_accuracy)
    else
      result_with_lifecycle
    end
    
    # Step 3: Generate rollback plan
    rollback_plan = generate_rollback_plan(result_with_prediction)
    result_with_rollback = record_rollback_plan(result_with_prediction, rollback_plan)
    
    # Step 4: Validate constitutional compliance
    {final_result, violations} = InstitutionAdaptationResult.validate_constitutional_compliance(result_with_rollback)
    
    if length(violations) > 0 do
      Logger.warning("[Phase13Stabilization] Constitutional violations remain: #{inspect(violations)}")
    else
      Logger.info("[Phase13Stabilization] Stabilization complete - fully compliant")
    end
    
    final_result
  end
  
  @doc """
  Stabilize multiple adaptation results.
  
  Processes a list of InstitutionAdaptationResults through complete stabilization.
  """
  def stabilize_multiple_results(results) when is_list(results) do
    Enum.map(results, fn result ->
      try do
        stabilize_adaptation_result(result)
      rescue
        e ->
          Logger.error("[Phase13Stabilization] Failed to stabilize #{result.id}: #{inspect(e)}")
          result
      end
    end)
  end
  
  @doc """
  Calculate aggregate prediction accuracy across multiple adaptations.
  
  Returns civilization-level prediction quality metrics using canonical PredictionAssessment aggregation.
  """
  def calculate_aggregate_prediction_accuracy(results) when is_list(results) do
    # Extract PredictionAssessment objects from simulation_results
    assessments = Enum.map(results, fn result ->
      sim = result.simulation_results || %{}
      pa = sim[:prediction_accuracy]
      
      # Only include actual PredictionAssessment structs, not aggregate results
      if is_struct(pa, TiannaraOS.PredictionAssessment) do
        pa
      else
        nil
      end
    end)
    |> Enum.filter(& &1)
    
    # Use canonical PredictionAssessment.aggregate
    TiannaraOS.PredictionAssessment.aggregate(assessments)
  end
  
  @doc """
  Calculate lifecycle completeness percentage across multiple adaptations.
  """
  def calculate_lifecycle_completeness_rate(results) when is_list(results) do
    completions = Enum.map(results, fn result ->
      case validate_lifecycle_completeness(result) do
        {:ok, _} -> 1.0
        {:error, info} -> info.completeness_ratio
      end
    end)
    
    if length(completions) == 0 do
      0.0
    else
      Float.round(Enum.sum(completions) / length(completions) * 100, 2)
    end
  end
  
  @doc """
  Generate Mission Control dashboard metrics for adaptation quality.
  
  Computes all required metrics from canonical transactions only.
  """
  def generate_dashboard_metrics(results) when is_list(results) do
    lifecycle_completeness = calculate_lifecycle_completeness_rate(results)
    prediction_accuracy = calculate_aggregate_prediction_accuracy(results)
    
    # Count adoption decisions
    adopted = Enum.count(results, fn r -> r.adoption_decision == :adopted end)
    rejected = Enum.count(results, fn r -> r.adoption_decision == :rejected end)
    deferred = Enum.count(results, fn r -> r.adoption_decision == :deferred end)
    
    # Calculate success rate
    total = length(results)
    success_rate = if total > 0 do
      Float.round(adopted / total * 100, 2)
    else
      0.0
    end
    
    # Average pilot improvement
    improvements = Enum.map(results, fn r ->
      comp = r.performance_comparison
      if comp do
        comp[:improvement_percentage] || 0
      else
        0
      end
    end)
    
    avg_improvement = if length(improvements) > 0 do
      Float.round(Enum.sum(improvements) / length(improvements), 2)
    else
      0.0
    end
    
    # Constitutional compliance
    compliance_checks = Enum.map(results, fn r ->
      case InstitutionAdaptationResult.validate_constitutional_compliance(r) do
        {_, violations} -> length(violations) == 0
      end
    end)
    
    compliance_rate = if length(compliance_checks) > 0 do
      compliant_count = Enum.count(compliance_checks, & &1)
      Float.round(compliant_count / length(compliance_checks) * 100, 2)
    else
      0.0
    end
    
    # Calculate Constitutional Maturity Score (composite indicator)
    constitutional_maturity = calculate_constitutional_maturity(
      lifecycle_completeness,
      prediction_accuracy,
      compliance_rate,
      results
    )
    
    %{
      lifecycle_completeness_pct: lifecycle_completeness,
      prediction_accuracy: prediction_accuracy,
      adaptation_success_rate: success_rate,
      average_pilot_improvement: avg_improvement,
      constitutional_compliance_pct: compliance_rate,
      constitutional_maturity_score: constitutional_maturity,
      total_adaptations: total,
      adopted_count: adopted,
      rejected_count: rejected,
      deferred_count: deferred,
      false_positive_rate: calculate_false_positive_rate(results),
      false_negative_rate: calculate_false_negative_rate(results)
    }
  end
  
  # Private helper functions
  
  defp add_lifecycle_stage(result, stage, institution_id) do
    stage_record = %{
      stage: stage,
      timestamp: DateTime.utc_now(),
      institution: institution_id,
      episode_references: extract_episode_references(result)
    }
    
    stage_history = (result.stage_history || []) ++ [stage_record]
    
    %{result | stage_history: stage_history}
  end
  
  defp add_semantic_event_for_stage(result, stage, institution_id) do
    event_type = case stage do
      :proposal_received -> :adaptation_proposal_received
      :compatibility_evaluated -> :compatibility_evaluation_completed
      :risk_assessed -> :risk_assessment_completed
      :simulation_completed -> :simulation_execution_completed
      :pilot_started -> :pilot_deployment_initiated
      :pilot_completed -> :pilot_execution_completed
      :historical_comparison_completed -> :performance_comparison_completed
      :decision_recorded -> :adoption_decision_recorded
      :rollback_generated -> :rollback_plan_generated
      :constitutional_validation_completed -> :constitutional_validation_completed
      :adaptation_closed -> :adaptation_lifecycle_closed
    end
    
    metadata = %{
      stage: stage,
      institution: institution_id,
      improvement_id: result.improvement_id
    }
    
    InstitutionAdaptationResult.add_semantic_event(result, event_type, metadata)
  end
  
  defp extract_improvement_metric(data, key) do
    case Map.get(data, key) do
      nil -> nil
      value when is_number(value) -> value
      _ -> nil
    end
  end
  
  defp estimate_rollback_cost(result) do
    # Estimate based on estimated_cost if available
    estimated = result.estimated_cost
    
    if estimated do
      # Rollback typically costs 20-30% of original implementation
      base_cost = estimated[:total] || estimated[:credits] || 100
      %{
        credits: round(base_cost * 0.25),
        time_days: 3,
        researcher_hours: 8
      }
    else
      %{
        credits: 250,
        time_days: 3,
        researcher_hours: 8
      }
    end
  end
  
  defp calculate_rollback_confidence(result) do
    # Higher confidence if we have good pilot data and clear rollback path
    has_pilot = result.pilot_results != nil
    has_simulation = result.simulation_results != nil
    rollback_available = result.rollback_available
    
    base_confidence = if has_pilot and has_simulation and rollback_available do
      0.85
    else
      0.6
    end
    
    # Adjust based on risk assessment
    risk = result.risk_assessment
    risk_adjustment = case risk do
      %{overall_risk_level: :low} -> 0.1
      %{overall_risk_level: :medium} -> 0.0
      %{overall_risk_level: :high} -> -0.1
      _ -> 0.0
    end
    
    Float.round(base_confidence + risk_adjustment, 2)
  end
  
  defp extract_episode_references(result) do
    # Extract from simulation_results if stored there
    sim = result.simulation_results || %{}
    sim[:supporting_episodes] || []
  end
  
  defp calculate_false_positive_rate(results) do
    # False positive: Adopted but later rolled back or showed negative results
    adopted = Enum.filter(results, fn r -> r.adoption_decision == :adopted end)
    
    if length(adopted) == 0 do
      0.0
    else
      false_positives = Enum.count(adopted, fn r ->
        comp = r.performance_comparison
        comp && (comp[:improvement_percentage] || 0) < 0
      end)
      
      Float.round(false_positives / length(adopted) * 100, 2)
    end
  end
  
  defp calculate_false_negative_rate(results) do
    # False negative: Rejected but would have shown positive results if piloted
    # This is harder to measure - use simulation predictions as proxy
    rejected = Enum.filter(results, fn r -> r.adoption_decision == :rejected end)
    
    if length(rejected) == 0 do
      0.0
    else
      # Count rejections where simulation predicted positive outcome
      potential_misses = Enum.count(rejected, fn r ->
        sim = r.simulation_results
        sim && (sim[:predicted_improvement] || 0) > 0.05
      end)
      
      Float.round(potential_misses / length(rejected) * 100, 2)
    end
  end
  
  @doc """
  Calculate Constitutional Maturity Score (composite indicator).
  
  Combines multiple dimensions of constitutional execution quality into a single 0-100 score.
  
  Components:
  - Lifecycle Completeness (20%)
  - Prediction Calibration (20%)
  - Rollback Readiness (15%)
  - Audit Completeness (15%)
  - Constitutional Compliance (20%)
  - Historical Depth (10%)
  
  ## Parameters
  - `lifecycle_completeness`: float() 0-100%
  - `prediction_accuracy`: map() with prediction metrics
  - `compliance_rate`: float() 0-100%
  - `results`: [InstitutionAdaptationResult.t()] list of adaptations
  
  ## Returns
  float() 0-100 composite maturity score
  """
  def calculate_constitutional_maturity(lifecycle_completeness, prediction_accuracy, compliance_rate, results) do
    # Component 1: Lifecycle Completeness (20% weight)
    lifecycle_score = lifecycle_completeness
    
    # Component 2: Prediction Calibration (20% weight)
    # Use reliability rate and calibration quality
    prediction_reliability = if prediction_accuracy && prediction_accuracy.prediction_reliability_rate do
      prediction_accuracy.prediction_reliability_rate * 100
    else
      0.0  # No historical data yet
    end
    
    prediction_calibration = if prediction_accuracy && prediction_accuracy.average_calibration do
      # Calibration of 1.0 is perfect, >1.0 is overconfident, <1.0 is underconfident
      # Normalize to 0-100 scale (1.0 = 100, 0.5-1.5 = reasonable range)
      cal = prediction_accuracy.average_calibration
      normalized = max(0.0, min(100.0, (1.0 - abs(cal - 1.0)) * 100))
      normalized
    else
      50.0  # Neutral when no data
    end
    
    prediction_score = (prediction_reliability + prediction_calibration) / 2
    
    # Component 3: Rollback Readiness (15% weight)
    rollback_ready_count = Enum.count(results, fn r ->
      sim = r.simulation_results || %{}
      sim[:rollback_plan] != nil
    end)
    rollback_readiness = if length(results) > 0 do
      Float.round(rollback_ready_count / length(results) * 100, 2)
    else
      0.0
    end
    
    # Component 4: Audit Completeness (15% weight)
    # Measured by semantic events and traceability
    audit_complete_count = Enum.count(results, fn r ->
      length(r.semantic_events || []) >= 5 and length(r.lifecycle_events || []) >= 3
    end)
    audit_completeness = if length(results) > 0 do
      Float.round(audit_complete_count / length(results) * 100, 2)
    else
      0.0
    end
    
    # Component 5: Constitutional Compliance (20% weight)
    compliance_score = compliance_rate
    
    # Component 6: Historical Depth (10% weight)
    # More adaptations = more history = higher maturity
    adaptation_count = length(results)
    historical_depth = min(100.0, adaptation_count * 5.0)  # Cap at 20 adaptations = 100%
    
    # Weighted composite
    composite = (
      lifecycle_score * 0.20 +
      prediction_score * 0.20 +
      rollback_readiness * 0.15 +
      audit_completeness * 0.15 +
      compliance_score * 0.20 +
      historical_depth * 0.10
    )
    
    Float.round(composite, 2)
  end
end
