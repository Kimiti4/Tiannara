defmodule TiannaraOS.ProgramSelfEvaluation do
  @moduledoc """
  Program Self-Evaluation - Transforms Research Programs into living scientific organisms.
  
  Each Program continuously evaluates its own health, progress, and adaptation needs:
  
  Current progress
  ↓
  Milestone completion
  ↓
  Budget health
  ↓
  Research velocity
  ↓
  Discovery rate
  ↓
  Theory maturity
  ↓
  Unknown resolution
  ↓
  Need for collaboration
  ↓
  Need for redirection
  ↓
  Need for expansion
  ↓
  Need for termination
  
  Programs become self-aware research organisms that adapt their strategies,
  request resources, seek collaborations, and evolve their approaches while
  preserving constitutional history.
  
  ## Constitutional Invariants
  
  1. Programs never mutate frozen primitives (read-only analysis)
  2. All evaluations produce canonical transactions (traceability)
  3. Adaptation recommendations preserve reversibility
  4. Self-evaluation respects developmental lifecycle stages
  5. Resource requests compose with Research Economy
  """
  

  
  @doc """
  Execute complete program self-evaluation cycle.
  
  Returns enriched program state with adaptive recommendations.
  """
  def evaluate_program(program, current_tick, _opts \\ %{}) do
    # Step 1: Assess current progress against goals
    progress_assessment = assess_goal_progress(program)
    
    # Step 2: Evaluate milestone completion
    milestone_evaluation = evaluate_milestones(program, current_tick)
    
    # Step 3: Check budget health
    budget_health = assess_budget_health(program)
    
    # Step 4: Measure research velocity
    research_velocity = calculate_research_velocity(program, current_tick)
    
    # Step 5: Calculate discovery rate
    discovery_rate = calculate_discovery_rate(program)
    
    # Step 6: Assess theory maturity
    theory_maturity = assess_theory_maturity(program)
    
    # Step 7: Track unknown resolution
    unknown_resolution = track_unknown_resolution(program)
    
    # Step 8: Determine collaboration needs
    collaboration_needs = determine_collaboration_needs(program)
    
    # Step 9: Evaluate need for redirection
    redirection_assessment = assess_redirection_need(program, progress_assessment)
    
    # Step 10: Evaluate need for expansion
    expansion_assessment = assess_expansion_need(program, discovery_rate)
    
    # Step 11: Evaluate need for termination
    termination_assessment = assess_termination_need(program, budget_health, progress_assessment)
    
    # Step 12: Generate adaptive recommendations
    adaptive_recommendations = generate_adaptive_recommendations(
      program,
      progress_assessment,
      budget_health,
      research_velocity,
      redirection_assessment,
      expansion_assessment,
      termination_assessment
    )
    
    # Step 13: Update life stage based on tick
    updated_life_stage = update_life_stage(program, current_tick)
    
    # Step 14: Adjust strategy genome based on performance
    adjusted_genome = adjust_strategy_genome(program, research_velocity, discovery_rate)
    
    %{
      program_id: program.id,
      evaluation_tick: current_tick,
      life_stage: updated_life_stage,
      progress_assessment: progress_assessment,
      milestone_evaluation: milestone_evaluation,
      budget_health: budget_health,
      research_velocity: research_velocity,
      discovery_rate: discovery_rate,
      theory_maturity: theory_maturity,
      unknown_resolution: unknown_resolution,
      collaboration_needs: collaboration_needs,
      redirection_assessment: redirection_assessment,
      expansion_assessment: expansion_assessment,
      termination_assessment: termination_assessment,
      adaptive_recommendations: adaptive_recommendations,
      adjusted_strategy_genome: adjusted_genome,
      timestamp: DateTime.utc_now()
    }
  end
  
  # ==================== Step 1: Goal Progress Assessment ====================
  
  @doc """
  Assess current progress against program goals.
  Measures completion percentage and trajectory.
  """
  def assess_goal_progress(program) do
    total_goals = length(program.goals)
    
    if total_goals == 0 do
      %{completion_percentage: 0, status: :no_goals_defined, trajectory: :undefined}
    else
      # Estimate progress based on discoveries and evidence
      completed_indicators = length(program.discoveries) + length(program.evidence_ids)
      estimated_completion = min(1.0, completed_indicators / max(total_goals * 3, 1))
      
      %{
        completion_percentage: Float.round(estimated_completion * 100, 1),
        status: determine_progress_status(estimated_completion),
        trajectory: estimate_trajectory(program),
        goals_remaining: max(0, total_goals - floor(estimated_completion * total_goals)),
        estimated_ticks_to_completion: estimate_completion_ticks(program, estimated_completion)
      }
    end
  end
  
  defp determine_progress_status(completion) do
    cond do
      completion >= 0.9 -> :near_completion
      completion >= 0.5 -> :on_track
      completion >= 0.2 -> :behind_schedule
      true -> :significantly_behind
    end
  end
  
  defp estimate_trajectory(program) do
    # Would analyze historical velocity trends
    if program.metrics[:discovery_yield] > 0.5 do
      :accelerating
    else
      :steady
    end
  end
  
  defp estimate_completion_ticks(program, current_completion) do
    remaining = 1.0 - current_completion
    velocity = program.metrics[:discovery_yield] || 0.1
    
    if velocity > 0 do
      round(remaining / velocity * 100)
    else
      10000  # Default large estimate
    end
  end
  
  # ==================== Step 2: Milestone Evaluation ====================
  
  @doc """
  Evaluate milestone completion based on program age and expected milestones.
  """
  def evaluate_milestones(program, current_tick) do
    program_age = get_program_age(program, current_tick)
    
    expected_milestones = define_expected_milestones(program.life_stage, program_age)
    completed_milestones = identify_completed_milestones(program, expected_milestones)
    
    %{
      program_age_ticks: program_age,
      life_stage: program.life_stage,
      expected_milestones: expected_milestones,
      completed_milestones: completed_milestones,
      milestone_completion_rate: length(completed_milestones) / max(length(expected_milestones), 1),
      next_milestone: determine_next_milestone(expected_milestones, completed_milestones),
      milestone_health: assess_milestone_health(program_age, completed_milestones)
    }
  end
  
  defp get_program_age(program, current_tick) do
    if program.born_at_tick do
      current_tick - program.born_at_tick
    else
      0
    end
  end
  
  defp define_expected_milestones(:newborn, _age), do: [:survive_initial_shocks, :establish_basic_capabilities]
  defp define_expected_milestones(:juvenile, age) when age < 3000, do: [:acquire_domain_knowledge, :develop_experimental_methods]
  defp define_expected_milestones(:juvenile, _age), do: [:refine_hypotheses, :build_evidence_base]
  defp define_expected_milestones(:apprentice, _age), do: [:produce_first_discovery, :validate_candidates, :contribute_to_knowledge]
  defp define_expected_milestones(:adult, _age), do: [:sustain_discovery_rate, :mentor_juniors, :expand_frontiers]
  
  defp identify_completed_milestones(program, expected_milestones) do
    # Simplified milestone completion logic
    Enum.filter(expected_milestones, fn milestone ->
      milestone_completed?(program, milestone)
    end)
  end
  
  defp milestone_completed?(_program, :survive_initial_shocks), do: true  # Newborns are immune
  defp milestone_completed?(program, :establish_basic_capabilities), do: map_size(program.capabilities) > 0
  defp milestone_completed?(program, :produce_first_discovery), do: length(program.discoveries) > 0
  defp milestone_completed?(_program, _milestone), do: false  # Default: not completed
  
  defp determine_next_milestone(expected, completed) do
    remaining = expected -- completed
    if length(remaining) > 0, do: hd(remaining), else: :all_milestones_complete
  end
  
  defp assess_milestone_health(age, completed) do
    if length(completed) > 0 and age > 0 do
      :healthy
    else
      :needs_attention
    end
  end
  
  # ==================== Step 3: Budget Health Assessment ====================
  
  @doc """
  Assess program budget health and sustainability.
  """
  def assess_budget_health(program) do
    total_budget = program.budget.credits + program.budget.compute + program.budget.attention
    burn_rate = estimate_burn_rate(program)
    
    runway_ticks = if burn_rate > 0 do
      round(total_budget / burn_rate)
    else
      10000  # Infinite runway if no burn
    end
    
    %{
      total_resources: Float.round(total_budget, 2),
      credits_remaining: program.budget.credits,
      compute_remaining: program.budget.compute,
      attention_remaining: program.budget.attention,
      burn_rate_per_tick: Float.round(burn_rate, 3),
      runway_ticks: runway_ticks,
      budget_status: determine_budget_status(runway_ticks),
      funding_urgency: determine_funding_urgency(runway_ticks),
      resource_allocation_efficiency: calculate_resource_efficiency(program)
    }
  end
  
  defp estimate_burn_rate(program) do
    # Estimate based on active experiments and capabilities
    base_burn = 0.1
    experiment_burn = length(program.active_experiments) * 0.05
    capability_burn = map_size(program.capabilities) * 0.02
    
    base_burn + experiment_burn + capability_burn
  end
  
  defp determine_budget_status(runway_ticks) do
    cond do
      runway_ticks > 5000 -> :healthy
      runway_ticks > 1000 -> :adequate
      runway_ticks > 100 -> :concerning
      true -> :critical
    end
  end
  
  defp determine_funding_urgency(runway_ticks) do
    cond do
      runway_ticks < 100 -> :immediate
      runway_ticks < 500 -> :soon
      runway_ticks < 2000 -> :planned
      true -> :none
    end
  end
  
  defp calculate_resource_efficiency(program) do
    # Would analyze output per resource unit
    if length(program.discoveries) > 0 do
      min(1.0, length(program.discoveries) / 10)
    else
      0.1
    end
  end
  
  # ==================== Step 4: Research Velocity ====================
  
  @doc """
  Calculate research velocity (discoveries per tick).
  """
  def calculate_research_velocity(program, current_tick) do
    program_age = get_program_age(program, current_tick)
    
    if program_age > 0 do
      velocity = length(program.discoveries) / program_age
      
      %{
        discoveries_per_tick: Float.round(velocity, 4),
        total_discoveries: length(program.discoveries),
        program_age_ticks: program_age,
        velocity_trend: estimate_velocity_trend(program),
        velocity_rating: rate_velocity(velocity)
      }
    else
      %{
        discoveries_per_tick: 0.0,
        total_discoveries: 0,
        program_age_ticks: 0,
        velocity_trend: :insufficient_data,
        velocity_rating: :too_early
      }
    end
  end
  
  defp estimate_velocity_trend(program) do
    # Would compare recent vs historical velocity
    if program.metrics[:discovery_yield] > 0.3 do
      :increasing
    else
      :stable
    end
  end
  
  defp rate_velocity(velocity) do
    cond do
      velocity > 0.01 -> :excellent
      velocity > 0.005 -> :good
      velocity > 0.001 -> :moderate
      true -> :low
    end
  end
  
  # ==================== Step 5: Discovery Rate ====================
  
  @doc """
  Calculate discovery rate and quality metrics.
  """
  def calculate_discovery_rate(program) do
    candidates = program.metrics[:candidates_produced] || 0
    validated = program.metrics[:candidates_validated] || 0
    
    conversion_rate = if candidates > 0 do
      validated / candidates
    else
      0.0
    end
    
    %{
      total_candidates: candidates,
      validated_discoveries: validated,
      conversion_rate: Float.round(conversion_rate, 3),
      discovery_quality: assess_discovery_quality(program),
      discovery_diversity: measure_discovery_diversity(program),
      innovation_index: calculate_innovation_index(program)
    }
  end
  
  defp assess_discovery_quality(program) do
    # Would analyze impact and validation strength of discoveries
    if program.metrics[:retention_rate] > 0.8 do
      :high
    else
      :moderate
    end
  end
  
  defp measure_discovery_diversity(_program) do
    # Would analyze topic/domain diversity of discoveries
    :moderate  # Placeholder
  end
  
  defp calculate_innovation_index(program) do
    # Would measure novelty vs established knowledge
    program.strategy_genome[:exploration_rate] || 0.5
  end
  
  # ==================== Step 6: Theory Maturity ====================
  
  @doc """
  Assess maturity of theories developed by the program.
  """
  def assess_theory_maturity(program) do
    hypotheses_count = length(program.hypotheses)
    evidence_count = length(program.evidence_ids)
    
    support_ratio = if hypotheses_count > 0 do
      evidence_count / hypotheses_count
    else
      0
    end
    
    %{
      total_hypotheses: hypotheses_count,
      supporting_evidence: evidence_count,
      evidence_per_hypothesis: Float.round(support_ratio, 2),
      theory_maturity_level: determine_maturity_level(support_ratio),
      theoretical_gaps: identify_theoretical_gaps(program),
      confidence_score: calculate_confidence_score(program, support_ratio)
    }
  end
  
  defp determine_maturity_level(support_ratio) do
    cond do
      support_ratio > 5 -> :well_supported
      support_ratio > 2 -> :moderately_supported
      support_ratio > 0.5 -> :weakly_supported
      true -> :speculative
    end
  end
  
  defp identify_theoretical_gaps(_program) do
    # Would analyze hypothesis-evidence mismatches
    []
  end
  
  defp calculate_confidence_score(program, support_ratio) do
    base_confidence = min(1.0, support_ratio / 10)
    strategy_bonus = program.strategy_genome[:validation_priority] || 0.5
    
    Float.round((base_confidence + strategy_bonus) / 2, 2)
  end
  
  # ==================== Step 7: Unknown Resolution ====================
  
  @doc """
  Track resolution of unknowns targeted by the program.
  """
  def track_unknown_resolution(program) do
    # Would query UnknownRegistry for targeted unknowns
    %{
      unknowns_targeted: length(program.hypotheses),
      unknowns_resolved: estimate_resolved_unknowns(program),
      resolution_rate: calculate_resolution_rate(program),
      blocking_unknowns: identify_blocking_unknowns(program),
      cascade_unlock_potential: estimate_cascade_unlock(program)
    }
  end
  
  defp estimate_resolved_unknowns(program) do
    # Approximate based on discoveries
    div(length(program.discoveries), 2)
  end
  
  defp calculate_resolution_rate(program) do
    targeted = length(program.hypotheses)
    if targeted > 0 do
      Float.round(estimate_resolved_unknowns(program) / targeted, 2)
    else
      0.0
    end
  end
  
  defp identify_blocking_unknowns(_program) do
    []  # Would query Unknown Dependency Graph
  end
  
  defp estimate_cascade_unlock(_program) do
    0.0  # Would calculate from Unknown Dependency Graph
  end
  
  # ==================== Step 8: Collaboration Needs ====================
  
  @doc """
  Determine collaboration needs based on program state.
  """
  def determine_collaboration_needs(program) do
    %{
      collaboration_urgency: assess_collaboration_urgency(program),
      needed_expertise: identify_needed_expertise(program),
      potential_collaborators: suggest_collaborators(program),
      collaboration_benefits: estimate_collaboration_benefits(program),
      collaboration_barriers: identify_collaboration_barriers(program)
    }
  end
  
  defp assess_collaboration_urgency(program) do
    if program.metrics[:discovery_yield] < 0.2 and length(program.hypotheses) > 5 do
      :high
    else
      :low
    end
  end
  
  defp identify_needed_expertise(_program) do
    # Would analyze gaps in program capabilities
    ["Advanced statistical methods", "Cross-domain synthesis"]
  end
  
  defp suggest_collaborators(_program) do
    []  # Would query Civilization Atlas for complementary institutions
  end
  
  defp estimate_collaboration_benefits(_program) do
    ["Accelerated hypothesis validation", "Access to specialized equipment", "Broader perspective"]
  end
  
  defp identify_collaboration_barriers(_program) do
    ["Coordination overhead", "Knowledge transfer complexity"]
  end
  
  # ==================== Step 9: Redirection Assessment ====================
  
  @doc """
  Assess whether program needs strategic redirection.
  """
  def assess_redirection_need(program, progress_assessment) do
    completion = progress_assessment[:completion_percentage] || 0
    
    %{
      redirection_needed: completion < 20 and get_program_age_from_assessment(progress_assessment) > 5000,
      redirection_urgency: determine_redirection_urgency(completion, progress_assessment),
      suggested_directions: suggest_new_directions(program),
      redirection_risks: assess_redirection_risks(program),
      continuation_viability: assess_continuation_viability(program, progress_assessment)
    }
  end
  
  defp get_program_age_from_assessment(_progress_assessment) do
    # Would extract from context
    0
  end
  
  defp determine_redirection_urgency(completion, _progress) do
    cond do
      completion < 10 -> :critical
      completion < 30 -> :high
      completion < 50 -> :moderate
      true -> :low
    end
  end
  
  defp suggest_new_directions(_program) do
    # Would analyze adjacent research spaces
    [
      "Explore alternative hypotheses",
      "Shift to related domain with higher opportunity",
      "Focus on validation of existing candidates"
    ]
  end
  
  defp assess_redirection_risks(_program) do
    ["Sunk cost loss", "Team morale impact", "Timeline delays"]
  end
  
  defp assess_continuation_viability(program, progress) do
    completion = progress[:completion_percentage] || 0
    if completion > 50 or program.metrics[:discovery_yield] > 0.3 do
      :viable
    else
      :questionable
    end
  end
  
  # ==================== Step 10: Expansion Assessment ====================
  
  @doc """
  Assess whether program should expand scope or resources.
  """
  def assess_expansion_need(program, discovery_rate) do
    conversion_rate = discovery_rate[:conversion_rate] || 0
    
    %{
      expansion_recommended: conversion_rate > 0.5 and program.life_stage == :adult,
      expansion_type: determine_expansion_type(program, conversion_rate),
      expansion_scope: estimate_expansion_scope(program),
      required_resources: estimate_expansion_resources(program),
      expansion_risks: assess_expansion_risks(),
      expected_benefits: estimate_expansion_benefits(program)
    }
  end
  
  defp determine_expansion_type(program, conversion_rate) do
    cond do
      conversion_rate > 0.7 -> :scale_up
      program.life_stage == :adult -> :diversify
      true -> :maintain_current_scope
    end
  end
  
  defp estimate_expansion_scope(_program) do
    :moderate  # Could be :conservative, :moderate, :aggressive
  end
  
  defp estimate_expansion_resources(_program) do
    %{credits: 5000, compute: 1000, attention: 500}
  end
  
  defp assess_expansion_risks do
    ["Resource dilution", "Loss of focus", "Coordination complexity"]
  end
  
  defp estimate_expansion_benefits(_program) do
    ["Increased discovery throughput", "Broader knowledge coverage", "Enhanced resilience"]
  end
  
  # ==================== Step 11: Termination Assessment ====================
  
  @doc """
  Assess whether program should be terminated.
  """
  def assess_termination_need(program, budget_health, progress_assessment) do
    budget_status = budget_health[:budget_status]
    completion = progress_assessment[:completion_percentage] || 0
    
    %{
      termination_recommended: should_terminate?(budget_status, completion, program),
      termination_urgency: determine_termination_urgency(budget_status, completion),
      termination_rationale: build_termination_rationale(budget_status, completion, program),
      salvage_opportunities: identify_salvage_opportunities(program),
      knowledge_preservation_plan: create_preservation_plan(program)
    }
  end
  
  defp should_terminate?(budget_status, completion, program) do
    budget_critical = budget_status == :critical
    low_progress = completion < 10
    old_program = get_program_age(program, System.system_time(:millisecond)) > 10000
    
    budget_critical and low_progress and old_program
  end
  
  defp determine_termination_urgency(budget_status, completion) do
    cond do
      budget_status == :critical and completion < 5 -> :immediate
      budget_status == :critical -> :soon
      completion < 5 -> :planned
      true -> :none
    end
  end
  
  defp build_termination_rationale(budget_status, completion, program) do
    "Budget: #{budget_status}, Progress: #{completion}%, Age: #{get_program_age(program, System.system_time(:millisecond))} ticks"
  end
  
  defp identify_salvage_opportunities(_program) do
    [
      "Extract validated discoveries",
      "Archive hypotheses for future use",
      "Document lessons learned",
      "Transfer capabilities to other programs"
    ]
  end
  
  defp create_preservation_plan(program) do
    %{
      discoveries_to_archive: program.discoveries,
      hypotheses_to_preserve: program.hypotheses,
      capabilities_to_transfer: Map.keys(program.capabilities),
      documentation_required: ["Final report", "Methodology notes", "Failure analysis"]
    }
  end
  
  # ==================== Step 12: Adaptive Recommendations ====================
  
  @doc """
  Generate adaptive recommendations based on all assessments.
  """
  def generate_adaptive_recommendations(
    _program,
    _progress_assessment,
    budget_health,
    research_velocity,
    redirection_assessment,
    expansion_assessment,
    termination_assessment
  ) do
    recommendations = []
    
    # Budget recommendations
    recommendations = if budget_health[:funding_urgency] in [:immediate, :soon] do
      [%{
        type: :resource_request,
        priority: :high,
        action: "Request additional funding",
        rationale: "Budget runway: #{budget_health[:runway_ticks]} ticks",
        details: budget_health
      } | recommendations]
    else
      recommendations
    end
    
    # Collaboration recommendations
    recommendations = if redirection_assessment[:redirection_needed] do
      [%{
        type: :collaboration_seek,
        priority: :medium,
        action: "Seek external collaboration",
        rationale: "Low progress suggests need for new perspectives",
        details: redirection_assessment
      } | recommendations]
    else
      recommendations
    end
    
    # Strategy adjustment recommendations
    recommendations = if research_velocity[:velocity_rating] in [:low, :moderate] do
      [%{
        type: :strategy_adjustment,
        priority: :medium,
        action: "Adjust exploration/exploitation balance",
        rationale: "Research velocity below optimal",
        details: research_velocity
      } | recommendations]
    else
      recommendations
    end
    
    # Expansion recommendations
    recommendations = if expansion_assessment[:expansion_recommended] do
      [%{
        type: :expansion_proposal,
        priority: :low,
        action: "Propose program expansion",
        rationale: "High conversion rate supports scaling",
        details: expansion_assessment
      } | recommendations]
    else
      recommendations
    end
    
    # Termination recommendations
    recommendations = if termination_assessment[:termination_recommended] do
      [%{
        type: :termination_consideration,
        priority: :critical,
        action: "Consider program termination",
        rationale: termination_assessment[:termination_rationale],
        details: termination_assessment
      } | recommendations]
    else
      recommendations
    end
    
    Enum.reverse(recommendations)
  end
  
  # ==================== Step 13: Life Stage Update ====================
  
  @doc """
  Update program life stage based on current tick.
  """
  def update_life_stage(program, current_tick) do
    age = get_program_age(program, current_tick)
    
    cond do
      age < 1000 -> :newborn
      age < 5000 -> :juvenile
      age < 8000 -> :apprentice
      true -> :adult
    end
  end
  
  # ==================== Step 14: Strategy Genome Adjustment ====================
  
  @doc """
  Adjust strategy genome based on performance feedback.
  """
  def adjust_strategy_genome(program, _research_velocity, discovery_rate) do
    current_genome = program.strategy_genome
    
    # Adjust exploration rate based on success
    exploration_adjustment = if discovery_rate[:conversion_rate] > 0.5 do
      -0.05  # Successful → exploit more
    else
      0.05   # Unsuccessful → explore more
    end
    
    # Adjust validation priority based on retention
    validation_adjustment = if program.metrics[:retention_rate] < 0.7 do
      0.1  # Low retention → validate more
    else
      0.0
    end
    
    %{
      exploration_rate: clamp(current_genome[:exploration_rate] + exploration_adjustment, 0.0, 1.0),
      validation_priority: clamp(current_genome[:validation_priority] + validation_adjustment, 0.0, 1.0),
      cross_domain_synthesis: current_genome[:cross_domain_synthesis],
      anomaly_sensitivity: current_genome[:anomaly_sensitivity],
      risk_tolerance: current_genome[:risk_tolerance]
    }
  end
  
  defp clamp(value, min_val, max_val) do
    max(min_val, min(max_val, value))
  end
end
