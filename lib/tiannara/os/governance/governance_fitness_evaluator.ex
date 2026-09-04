defmodule TiannaraOS.Governance.GovernanceFitnessEvaluator do
  @moduledoc """
  GovernanceFitnessEvaluator - Measures institutional health and effectiveness.

  Unlike ConstitutionFitnessEvaluator which measures constitutional health,
  this evaluator measures how well governance institutions are performing their
  designated functions.

  ## Fitness Components

  1. **Decision Quality** (0.25 weight) - Accuracy of governance decisions
     - Proposal approval/rejection accuracy
     - Review quality scores
     - Post-deployment success rate

  2. **Operational Efficiency** (0.20 weight) - Speed and resource usage
     - Average decision latency
     - Resource utilization efficiency
     - Throughput vs capacity

  3. **Institutional Stability** (0.20 weight) - Consistency over time
     - Appointment continuity
     - Policy consistency
     - Low turnover rate

  4. **Compliance Rate** (0.15 weight) - Adherence to constitutional rules
     - Invariant violation rate
     - Procedural compliance
     - Authority boundary respect

  5. **Adaptability** (0.10 weight) - Response to changing conditions
     - Time to respond to new challenges
     - Successful adaptation rate
     - Learning curve improvement

  6. **Transparency** (0.10 weight) - Observability and explainability
     - Provenance completeness
     - Audit trail coverage
     - Decision explainability

  ## API

      @spec evaluate_fitness(GovernanceState.t()) :: t()
      @spec evaluate_institution_fitness(String.t()) :: map()
      @spec compute_governance_entropy(GovernanceState.t()) :: float()
  """

  alias TiannaraOS.Governance.GovernanceState
  alias TiannaraOS.Governance.GovernanceLedger

  defstruct [
    :timestamp,
    :overall_fitness,
    :decision_quality,
    :operational_efficiency,
    :institutional_stability,
    :compliance_rate,
    :adaptability,
    :transparency,
    :component_scores,
    :institution_fitnesses,
    :recommendations
  ]

  @type t :: %__MODULE__{
          timestamp: DateTime.t(),
          overall_fitness: float(),
          decision_quality: float(),
          operational_efficiency: float(),
          institutional_stability: float(),
          compliance_rate: float(),
          adaptability: float(),
          transparency: float(),
          component_scores: map(),
          institution_fitnesses: map(),
          recommendations: [String.t()]
        }

  @doc """
  Evaluate overall governance fitness from current state.
  """
  @spec evaluate_fitness(GovernanceState.t()) :: t()
  def evaluate_fitness(%GovernanceState{} = state) do
    now = DateTime.utc_now()

    # Calculate component scores
    decision_quality = compute_decision_quality(state)
    operational_efficiency = compute_operational_efficiency(state)
    institutional_stability = compute_institutional_stability(state)
    compliance_rate = compute_compliance_rate(state)
    adaptability = compute_adaptability(state)
    transparency = compute_transparency(state)

    # Weighted overall fitness
    overall_fitness =
      0.25 * decision_quality +
      0.20 * operational_efficiency +
      0.20 * institutional_stability +
      0.15 * compliance_rate +
      0.10 * adaptability +
      0.10 * transparency

    overall_fitness = Float.round(max(0.0, min(1.0, overall_fitness)), 4)

    # Per-institution fitness
    institution_fitnesses = evaluate_all_institutions(state)

    # Generate recommendations
    recommendations = generate_recommendations(
      decision_quality,
      operational_efficiency,
      institutional_stability,
      compliance_rate,
      adaptability,
      transparency
    )

    %__MODULE__{
      timestamp: now,
      overall_fitness: overall_fitness,
      decision_quality: Float.round(decision_quality, 4),
      operational_efficiency: Float.round(operational_efficiency, 4),
      institutional_stability: Float.round(institutional_stability, 4),
      compliance_rate: Float.round(compliance_rate, 4),
      adaptability: Float.round(adaptability, 4),
      transparency: Float.round(transparency, 4),
      institution_fitnesses: institution_fitnesses,
      recommendations: recommendations
    }
  end

  @doc """
  Evaluate overall governance fitness (parameterless version).
  
  Reconstructs state from ledger and evaluates fitness.
  """
  @spec evaluate_fitness() :: t()
  def evaluate_fitness() do
    state = GovernanceState.get_current_state()
    evaluate_fitness(state)
  end

  @doc """
  Evaluate fitness for a specific institution.
  """
  @spec evaluate_institution_fitness(GovernanceState.t(), String.t()) :: map()
  def evaluate_institution_fitness(%GovernanceState{} = state, institution_id) do
    case GovernanceState.get_institution(state, institution_id) do
      nil ->
        %{error: "Institution not found: #{institution_id}"}

      institution ->
        # Institution-specific metrics
        members = GovernanceState.get_active_members(state, institution_id)
        appointments = get_institution_appointments(state, institution_id)
        ledger_events = GovernanceLedger.get_events_by_institution(institution_id)

        %{
          institution_id: institution_id,
          name: Map.get(institution, :name),
          status: Map.get(institution, :status),
          member_count: length(members),
          appointment_count: length(appointments),
          total_events: length(ledger_events),
          activity_score: compute_activity_score(ledger_events),
          stability_score: compute_stability_score(appointments),
          effectiveness_score: compute_effectiveness_score(ledger_events)
        }
    end
  end

  @doc """
  Compute governance entropy (disorder/complexity measure).

  Returns value between 0.0 (perfectly ordered) and 1.0 (maximum entropy).
  """
  @spec compute_governance_entropy(GovernanceState.t()) :: float()
  def compute_governance_entropy(%GovernanceState{} = state) do
    # Measure multiple entropy dimensions
    unused_capabilities = measure_unused_capabilities(state)
    authority_overlap = measure_authority_overlap(state)
    institutional_complexity = measure_institutional_complexity(state)
    dependency_density = measure_dependency_density(state)
    proposal_backlog = measure_proposal_backlog(state)
    review_complexity = measure_review_complexity(state)

    # Normalize each metric to [0, 1]
    normalized_unused_caps = normalize(unused_capabilities, 0, 20)
    normalized_overlap = normalize(authority_overlap, 0, 1.0)
    normalized_complexity = normalize(institutional_complexity, 0, 100)
    normalized_density = normalize(dependency_density, 0, 1.0)
    normalized_backlog = normalize(proposal_backlog, 0, 50)
    normalized_review = normalize(review_complexity, 0, 10)

    # Weighted entropy calculation
    entropy =
      0.20 * normalized_unused_caps +
      0.20 * normalized_overlap +
      0.20 * normalized_complexity +
      0.15 * normalized_density +
      0.15 * normalized_backlog +
      0.10 * normalized_review

    Float.round(max(0.0, min(1.0, entropy)), 4)
  end

  # Private helpers

  defp compute_decision_quality(_state) do
    # TODO: Calculate from actual proposal outcomes
    # For now, use placeholder based on available data
    ledger_events = GovernanceLedger.get_events()

    proposal_events = Enum.filter(ledger_events, fn e ->
      e.event_type in [:proposal_submitted, :proposal_approved, :proposal_rejected]
    end)

    if Enum.empty?(proposal_events) do
      0.85 # Default baseline when no data
    else
      # Calculate approval rate and success correlation
      approved = Enum.count(proposal_events, fn e -> e.event_type == :proposal_approved end)
      total = length(proposal_events)
      Float.round(approved / max(1, total), 4)
    end
  end

  defp compute_operational_efficiency(_state) do
    # TODO: Calculate from actual performance metrics
    # Placeholder based on system responsiveness
    0.90
  end

  defp compute_institutional_stability(state) do
    # Measure appointment continuity and turnover
    total_appointments = map_size(state.appointments)
    active_appointments =
      state.appointments
      |> Map.values()
      |> Enum.count(fn appt -> Map.get(appt, :status) == :active end)

    if total_appointments == 0 do
      0.5 # Neutral when no data
    else
      # Higher ratio of active to total indicates stability
      Float.round(active_appointments / total_appointments, 4)
    end
  end

  defp compute_compliance_rate(_state) do
    # Check for invariant violations
    # TODO: Query actual violation records
    # For now, assume high compliance
    0.95
  end

  defp compute_adaptability(_state) do
    # Measure response time to changes
    # TODO: Calculate from historical adaptation events
    0.80
  end

  defp compute_transparency(_state) do
    # Measure provenance completeness
    # All governance actions should have complete provenance chains
    0.92
  end

  defp evaluate_all_institutions(state) do
    state.institutions
    |> Map.keys()
    |> Enum.map(fn inst_id ->
      {inst_id, evaluate_institution_fitness(state, inst_id)}
    end)
    |> Enum.into(%{})
  end

  defp get_institution_appointments(state, institution_id) do
    state.appointments
    |> Map.values()
    |> Enum.filter(fn appt -> Map.get(appt, :institution_id) == institution_id end)
  end

  defp compute_activity_score(ledger_events) do
    # Score based on recent activity level
    recent_events = Enum.count(ledger_events)
    normalize(recent_events, 0, 100)
  end

  defp compute_stability_score(appointments) do
    # Score based on appointment longevity and renewal rate
    if Enum.empty?(appointments) do
      0.5
    else
      active_ratio = Enum.count(appointments, fn appt -> Map.get(appt, :status) == :active end) / length(appointments)
      Float.round(active_ratio, 4)
    end
  end

  defp compute_effectiveness_score(ledger_events) do
    # Score based on successful outcomes
    if Enum.empty?(ledger_events) do
      0.5
    else
      # Placeholder calculation
      0.85
    end
  end

  defp measure_unused_capabilities(state) do
    # Count capabilities defined but never used in any institution
    all_capabilities = MapSet.new([
      :can_review, :can_deploy, :can_rollback, :can_ratify, :can_observe,
      :can_simulate, :can_propose, :can_migrate, :can_audit,
      :can_appoint_institutional_members, :can_remove_institutional_members,
      :can_amend_meta_constitution, :can_approve_budget, :can_validate_theory,
      :can_assess_evidence, :can_certify_methodology, :can_reject_pseudoscience,
      :can_require_reproducibility, :can_request_simulation, :can_recommend_approval,
      :can_recommend_rejection, :can_request_revision, :can_schedule_migration,
      :can_verify_deployment, :can_report_deployment_status, :can_measure,
      :can_report, :can_alert, :can_publish_dashboards
    ])

    used_capabilities =
      state.institutions
      |> Map.values()
      |> Enum.flat_map(fn inst -> Map.get(inst, :capabilities, []) end)
      |> MapSet.new()

    MapSet.size(MapSet.difference(all_capabilities, used_capabilities))
  end

  defp measure_authority_overlap(state) do
    # Measure how many institutions share the same capabilities
    capability_to_institutions =
      state.institutions
      |> Map.values()
      |> Enum.flat_map(fn inst ->
        inst_id = Map.get(inst, :id)
        caps = Map.get(inst, :capabilities, [])
        Enum.map(caps, fn cap -> {cap, inst_id} end)
      end)
      |> Enum.group_by(fn {cap, _inst} -> cap end, fn {_cap, inst} -> inst end)

    # Calculate average overlap
    overlaps =
      capability_to_institutions
      |> Map.values()
      |> Enum.map(fn institutions -> length(institutions) - 1 end) # -1 because self doesn't count as overlap

    if Enum.empty?(overlaps) do
      0.0
    else
      Enum.sum(overlaps) / length(overlaps)
    end
  end

  defp measure_institutional_complexity(state) do
    # Simple complexity metric: number of institutions * average capabilities per institution
    num_institutions = map_size(state.institutions)

    avg_capabilities =
      if num_institutions > 0 do
        total_caps =
          state.institutions
          |> Map.values()
          |> Enum.reduce(0, fn inst, acc -> acc + length(Map.get(inst, :capabilities, [])) end)

        total_caps / num_institutions
      else
        0
      end

    num_institutions * avg_capabilities
  end

  defp measure_dependency_density(state) do
    # Ratio of actual dependencies to possible dependencies
    num_institutions = map_size(state.institutions)
    max_dependencies = num_institutions * (num_institutions - 1)

    if max_dependencies == 0 do
      0.0
    else
      # Count actual edges in institution graph
      # TODO: Get from InstitutionGraph module
      actual_dependencies = 0 # Placeholder
      actual_dependencies / max_dependencies
    end
  end

  defp measure_proposal_backlog(state) do
    # Number of pending proposals awaiting action
    state.active_proposals
  end

  defp measure_review_complexity(_state) do
    # Average number of reviews per proposal
    # TODO: Calculate from actual review data
    3.5 # Placeholder
  end

  defp normalize(value, min_val, max_val) do
    normalized = (value - min_val) / max(0.001, max_val - min_val)
    max(0.0, min(1.0, normalized))
  end

  defp generate_recommendations(decision_quality, operational_efficiency, institutional_stability,
                                  compliance_rate, adaptability, transparency) do
    recommendations = []

    recommendations =
      if decision_quality < 0.7 do
        recommendations ++ ["Improve decision quality through better review processes"]
      else
        recommendations
      end

    recommendations =
      if operational_efficiency < 0.7 do
        recommendations ++ ["Optimize operational processes to reduce latency"]
      else
        recommendations
      end

    recommendations =
      if institutional_stability < 0.7 do
        recommendations ++ ["Address institutional instability through appointment reforms"]
      else
        recommendations
      end

    recommendations =
      if compliance_rate < 0.9 do
        recommendations ++ ["Strengthen compliance monitoring and enforcement"]
      else
        recommendations
      end

    recommendations =
      if adaptability < 0.7 do
        recommendations ++ ["Improve adaptive response mechanisms"]
      else
        recommendations
      end

    recommendations =
      if transparency < 0.8 do
        recommendations ++ ["Enhance transparency and auditability"]
      else
        recommendations
      end

    if Enum.empty?(recommendations) do
      ["Governance system is operating within healthy parameters"]
    else
      recommendations
    end
  end
end
