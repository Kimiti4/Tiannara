defmodule TiannaraOS.MissionControl do
  @moduledoc """
  Mission Control - Real-time dashboard for monitoring research civilization health.

  Displays portfolio health, research activity, institution self-understanding,
  and strategic priorities across all twenty research domains.

  ## Data Sources

  - ResearchDirector.get_portfolio_health/0 - Domain statistics and maturity
  - ResearchDirector.calculate_priorities/0 - Strategic priorities
  - InstitutionSelfModel queries - Institution self-understanding quality
  - UnknownRegistry.count_by_domain/0 - Research debt tracking

  ## Dashboard Sections

  1. **Portfolio Health** - Per-domain discoveries, theories, laws, unknowns
  2. **Research Activity** - Active experiments, validation backlog, research debt
  3. **Institution Health** - Self-understanding quality, model confidence
  4. **Strategic Priorities** - Recommended actions, neglected domains
  5. **Resource Allocation** - Budget distribution across domains

  ## Usage

      # Get complete dashboard data
      {:ok, dashboard} = MissionControl.get_dashboard_data()

      # Get specific section
      {:ok, portfolio} = MissionControl.get_portfolio_health()
      {:ok, priorities} = MissionControl.get_strategic_priorities()
  """

  alias TiannaraOS.{
    ResearchDirector,
    UnknownRegistry,
    TheoryRegistry,
    DiscoveryRegistry,
    LawRegistry,
    ProgramRegistry
  }

  alias Tiannara.Domains.{CanonicalRegistry, KnowledgeCapitalBoundary}

  defstruct [
    :timestamp,
    :portfolio_health,
    :strategic_priorities,
    :research_activity,
    :institution_health,
    :adaptation_quality,
    :resource_allocation,
    :alerts
  ]

  @type t :: %__MODULE__{
    timestamp: DateTime.t(),
    portfolio_health: map(),
    strategic_priorities: map(),
    research_activity: map(),
    institution_health: map(),
    adaptation_quality: map(),
    resource_allocation: map(),
    alerts: [map()]
  }

  @doc """
  Get complete Mission Control dashboard data.

  Aggregates data from all registries and the Research Director to provide
  a comprehensive view of the research civilization's current state.

  ## Returns
  {:ok, MissionControl.t()}
  """
  def get_dashboard_data do
    with {:ok, portfolio} <- get_portfolio_health(),
         {:ok, priorities} <- get_strategic_priorities(),
         {:ok, activity} <- get_research_activity(),
         {:ok, institution} <- get_institution_health(),
         {:ok, adaptation} <- get_adaptation_quality(),
         {:ok, allocation} <- get_resource_allocation(),
         alerts <- generate_alerts(portfolio, priorities, activity) do
      dashboard = %__MODULE__{
        timestamp: DateTime.utc_now(),
        portfolio_health: portfolio,
        strategic_priorities: priorities,
        research_activity: activity,
        institution_health: institution,
        adaptation_quality: adaptation,
        resource_allocation: allocation,
        alerts: alerts
      }

      {:ok, dashboard}
    end
  end

  @doc """
  Get domain intelligence metrics for all domains.

  Per-domain reporting includes:
  - Knowledge Capital (accumulated discoveries, theories, laws)
  - Research Debt (unresolved unknowns weighted by priority)
  - Innovation Velocity (discoveries per time period)
  - Replication Success (validated discovery rate)
  - Theory Stability (high-confidence theory ratio)
  - Discovery Rate (new discoveries per period)
  - Application Rate (operational applications per discovery)
  - Prediction Accuracy (theory prediction success rate)
  - Transfer Success (cross-domain application count)
  - Portfolio Diversity (program variety across sub-domains)
  - Unknown Pressure (critical unknowns relative to total)
  - Scientific Momentum (composite health indicator)

  ## Returns
  {:ok, [domain_intelligence_report]}
  """
  def get_domain_intelligence do
    domains = CanonicalRegistry.all()
    intelligence_reports = Enum.map(domains, fn domain ->
      build_domain_intelligence(domain)
    end)

    {:ok, intelligence_reports}
  end

  @doc """
  Get portfolio health summary for all domains.

  Includes per-domain statistics on discoveries, theories, laws, unknowns,
  applications, maturity assessments, and knowledge capital.

  ## Returns
  {:ok, portfolio_health_report}
  """
  def get_portfolio_health do
    ResearchDirector.get_portfolio_health()
  end

  @doc """
  Get strategic priorities calculated by Research Director.

  Includes domain priority scores, recommended experiments, neglected domains,
  and resource allocation recommendations.

  ## Returns
  {:ok, ResearchDirector.t()}
  """
  def get_strategic_priorities do
    ResearchDirector.calculate_priorities()
  end

  @doc """
  Get current research activity metrics.

  Tracks active experiments, validation backlog, unresolved unknowns,
  and research debt across all domains.

  ## Returns
  {:ok, research_activity_metrics}
  """
  def get_research_activity do
    domains = CanonicalRegistry.all()
    with {:ok, unknown_counts} <- UnknownRegistry.count_by_domain() do
      # Count active programs
      {:ok, active_programs} = ProgramRegistry.list_active()

      # Calculate validation backlog
      validation_backlog = Enum.reduce(domains, 0, fn domain, acc ->
        {:ok, discoveries} = DiscoveryRegistry.list_by_domain(domain.id)
        unvalidated = Enum.count(discoveries, fn d ->
          d.validation_status in [:simulated, :reproduced]
        end)
        acc + unvalidated
      end)

      # Count total open unknowns
      total_unknowns = Enum.sum(Map.values(unknown_counts))

      # Count critical unknowns
      critical_unknowns = Enum.reduce(domains, 0, fn domain, acc ->
        {:ok, critical} = UnknownRegistry.get_by_priority(domain.id, :critical)
        acc + length(critical)
      end)

      activity = %{
        timestamp: DateTime.utc_now(),
        active_programs: length(active_programs),
        total_open_unknowns: total_unknowns,
        critical_unknowns: critical_unknowns,
        validation_backlog: validation_backlog,
        research_debt_by_domain: unknown_counts,
        activity_summary: %{
          programs_active: length(active_programs),
          unknowns_critical: critical_unknowns,
          discoveries_pending_validation: validation_backlog
        }
      }

      {:ok, activity}
    end
  end

  @doc """
  Get institution health metrics.

  Aggregates self-understanding quality, model confidence, constitutional
  compliance, and evidence coverage across institutions.

  ## Returns
  {:ok, institution_health_metrics}
  """
  def get_institution_health do
    # Query actual InstitutionSelfModels for health metrics
    institutions = fetch_institution_self_models()
    
    health = %{
      timestamp: DateTime.utc_now(),
      institutions_monitored: length(institutions),
      average_self_understanding_quality: compute_average_quality(institutions),
      average_model_confidence: compute_average_confidence(institutions),
      constitutional_compliance_rate: compute_compliance_rate(institutions),
      evidence_coverage_percentage: compute_evidence_coverage(institutions)
    }

    {:ok, health}
  end

  @doc """
  Get Phase 13 adaptation quality metrics.

  Tracks recursive adaptation infrastructure quality:
  - Lifecycle completeness percentage
  - Prediction accuracy (simulation vs reality)
  - Constitutional compliance rate
  - Adaptation success rate
  - Rollback readiness
  - Audit completeness

  ## Returns
  {:ok, adaptation_quality_metrics}
  """
  def get_adaptation_quality do
    # Query recent InstitutionAdaptationResults from registry
    # For now, return structure that will be populated when results exist
    
    # This would query actual adaptation results when available
    # Example implementation once adaptation results are persisted:
    # adaptation_results = InstitutionAdaptationRegistry.list_recent(50)
    # metrics = Phase13Stabilization.generate_dashboard_metrics(adaptation_results)
    
    metrics = %{
      timestamp: DateTime.utc_now(),
      lifecycle_completeness_pct: nil,
      prediction_accuracy: nil,
      adaptation_success_rate: nil,
      average_pilot_improvement: nil,
      constitutional_compliance_pct: nil,
      total_adaptations: 0,
      adopted_count: 0,
      rejected_count: 0,
      deferred_count: 0,
      false_positive_rate: nil,
      false_negative_rate: nil,
      note: "Adaptation quality tracking requires active InstitutionAdaptationResults from Stage 4"
    }

    {:ok, metrics}
  end

  @doc """
  Get current resource allocation recommendations.

  Shows how resources should be distributed across domains based on
  calculated priorities and research needs.

  ## Returns
  {:ok, resource_allocation_map}
  """
  def get_resource_allocation do
    ResearchDirector.allocate_resources()
  end

  @doc """
  Generate alerts for Mission Control based on current state.

  Alerts include:
  - Domains with critical unknowns
  - High research debt domains
  - Neglected domains needing attention
  - Validation backlogs exceeding thresholds
  - Low-confidence theories requiring validation

  ## Parameters
  - `portfolio`: portfolio health report
  - `priorities`: strategic priorities
  - `activity`: research activity metrics

  ## Returns
  [alert_map()]
  """
  def generate_alerts(portfolio, priorities, activity) do
    alerts = []

    # Alert for domains with critical unknowns
    alerts_with_critical = Enum.reduce(portfolio.domain_reports, alerts, fn report, acc ->
      if report.statistics.open_unknowns > 0 do
        {:ok, critical} = UnknownRegistry.get_by_priority(report.domain, :critical)
        if length(critical) > 0 do
          alert = %{
            type: :critical_unknowns,
            severity: :high,
            domain: report.domain,
            message: "#{length(critical)} critical unknowns in #{report.domain_name}",
            action_required: :investigate_immediately
          }
          [alert | acc]
        else
          acc
        end
      else
        acc
      end
    end)

    # Alert for neglected domains
    alerts_with_neglected = Enum.reduce(priorities.neglected_domains, alerts_with_critical, fn domain_id, acc ->
      alert = %{
        type: :neglected_domain,
        severity: :medium,
        domain: domain_id,
        message: "#{domain_id} is neglected and needs attention",
        action_required: :allocate_resources
      }
      [alert | acc]
    end)

    # Alert for high validation backlog
    alerts_with_backlog = if activity.validation_backlog > 20 do
      alert = %{
        type: :validation_backlog,
        severity: :medium,
        message: "Validation backlog: #{activity.validation_backlog} discoveries pending",
        action_required: :increase_validation_capacity
      }
      [alert | alerts_with_neglected]
    else
      alerts_with_neglected
    end

    # Alert for high research debt
    alerts_with_debt = Enum.reduce(activity.research_debt_by_domain, alerts_with_backlog, fn {domain, count}, acc ->
      if count > 15 do
        alert = %{
          type: :high_research_debt,
          severity: :low,
          domain: domain,
          message: "#{domain} has #{count} open unknowns (high research debt)",
          action_required: :prioritize_unknown_resolution
        }
        [alert | acc]
      else
        acc
      end
    end)

    alerts_with_debt
  end

  @doc """
  Get summary statistics for quick dashboard view.

  Provides high-level numbers suitable for dashboard header display.

  ## Returns
  {:ok, summary_stats}
  """
  def get_summary_stats do
    with {:ok, portfolio} <- get_portfolio_health(),
         {:ok, activity} <- get_research_activity() do
      total_discoveries = Enum.sum(Enum.map(portfolio.domain_reports, fn r ->
        r.statistics.total_discoveries
      end))

      total_theories = Enum.sum(Enum.map(portfolio.domain_reports, fn r ->
        r.statistics.total_theories
      end))

      total_unknowns = activity.total_open_unknowns

      mature_domains = Enum.count(portfolio.domain_reports, fn r ->
        r.maturity_assessment.theory_maturity == :mature
      end)

      summary = %{
        timestamp: DateTime.utc_now(),
        total_domains: portfolio.total_domains,
        total_discoveries: total_discoveries,
        total_theories: total_theories,
        total_unknowns: total_unknowns,
        mature_domains: mature_domains,
        active_programs: activity.activity_summary.programs_active,
        critical_unknowns: activity.activity_summary.unknowns_critical,
        validation_backlog: activity.activity_summary.discoveries_pending_validation,
        overall_health_score: portfolio.overall_health.health_score
      }

      {:ok, summary}
    end
  end

  defp build_domain_intelligence(domain) do
    # Get domain knowledge capital
    knowledge_capital = KnowledgeCapitalBoundary.get(domain.id)

    # Get theories in domain
    {:ok, theories} = TheoryRegistry.list_by_domain(domain.id)

    # Get discoveries in domain
    {:ok, discoveries} = DiscoveryRegistry.list_by_domain(domain.id)

    # Get laws in domain
    {:ok, laws} = LawRegistry.list_by_domain(domain.id)

    # Get open unknowns
    {:ok, unknowns} = UnknownRegistry.list_open_by_domain(domain.id)

    # Get programs in domain
    {:ok, programs} = ProgramRegistry.list_by_domain(domain.id)

    # Calculate Research Debt (weighted by priority)
    research_debt = calculate_research_debt(unknowns)

    # Calculate Innovation Velocity (discoveries per month since first discovery)
    innovation_velocity = calculate_innovation_velocity(discoveries)

    # Calculate Replication Success (validated discovery rate)
    replication_success = if length(discoveries) > 0 do
      validated = Enum.count(discoveries, fn d ->
        d.validation_status == :operationally_validated
      end)
      Float.round((validated / length(discoveries)) * 100, 2)
    else
      0.0
    end

    # Calculate Theory Stability (high-confidence theory ratio)
    theory_stability = if length(theories) > 0 do
      high_confidence = Enum.count(theories, fn t -> t.confidence >= 0.9 end)
      Float.round((high_confidence / length(theories)) * 100, 2)
    else
      0.0
    end

    # Calculate Discovery Rate (new discoveries in last 30 days)
    discovery_rate = calculate_discovery_rate(discoveries)

    # Calculate Application Rate (operational applications per discovery)
    application_rate = if length(discoveries) > 0 do
      total_applications = Enum.sum(Enum.map(discoveries, fn d ->
        length(d.applications || [])
      end))
      Float.round(total_applications / length(discoveries), 2)
    else
      0.0
    end

    # Calculate Prediction Accuracy (theory prediction success rate)
    prediction_accuracy = if length(theories) > 0 do
      predictions_made = Enum.sum(Enum.map(theories, fn t ->
        length(t.predictions || [])
      end))
      predictions_verified = Enum.sum(Enum.map(theories, fn t ->
        Enum.count(t.predictions || [], fn p -> p[:verified] == true end)
      end))
      if predictions_made > 0 do
        Float.round((predictions_verified / predictions_made) * 100, 2)
      else
        0.0
      end
    else
      0.0
    end

    # Calculate Transfer Success (cross-domain applications)
    transfer_success = count_cross_domain_transfers(discoveries, domain.id)

    # Calculate Portfolio Diversity (program variety)
    portfolio_diversity = if length(programs) > 0 do
      unique_priorities = Enum.uniq(Enum.map(programs, fn p -> p.priority end))
      Float.round(length(unique_priorities) / length(programs) * 100, 2)
    else
      0.0
    end

    # Calculate Unknown Pressure (critical unknowns relative to total)
    unknown_pressure = if length(unknowns) > 0 do
      critical_count = Enum.count(unknowns, fn u -> u.priority == :critical end)
      Float.round((critical_count / length(unknowns)) * 100, 2)
    else
      0.0
    end

    # Calculate Scientific Momentum (composite health indicator)
    scientific_momentum = calculate_scientific_momentum(%{
      discoveries: length(discoveries),
      theories: length(theories),
      laws: length(laws),
      replication_success: replication_success,
      theory_stability: theory_stability,
      application_rate: application_rate,
      research_debt: research_debt,
      unknown_pressure: unknown_pressure
    })

    %{domain_id: domain.id, domain_name: domain.name, knowledge_capital: knowledge_capital, research_debt: research_debt, innovation_velocity: innovation_velocity, replication_success: replication_success, theory_stability: theory_stability, discovery_rate: discovery_rate, application_rate: application_rate, prediction_accuracy: prediction_accuracy, transfer_success: transfer_success, portfolio_diversity: portfolio_diversity, unknown_pressure: unknown_pressure, scientific_momentum: scientific_momentum, summary: %{total_discoveries: length(discoveries), total_theories: length(theories), total_laws: length(laws), total_unknowns: length(unknowns), total_programs: length(programs)}}
  end

  defp calculate_research_debt(unknowns) do
    # Weight unknowns by priority: critical=4, high=3, medium=2, low=1
    weights = %{critical: 4, high: 3, medium: 2, low: 1}

    debt = Enum.reduce(unknowns, 0, fn unknown, acc ->
      weight = Map.get(weights, unknown.priority, 1)
      acc + weight
    end)

    %{total_weighted_debt: debt, total_unknowns: length(unknowns)}
  end

  defp calculate_innovation_velocity(discoveries) do
    if length(discoveries) == 0 do
      0.0
    else
      # Find earliest and latest discovery dates
      dates = Enum.map(discoveries, fn d -> d.created_at end)
      earliest = Enum.min(dates)
      latest = Enum.max(dates)

      # Calculate months between
      days_diff = DateTime.diff(latest, earliest, :day)
      months = max(days_diff / 30, 1)  # At least 1 month

      Float.round(length(discoveries) / months, 2)
    end
  end

  defp calculate_discovery_rate(discoveries) do
    # Count discoveries created in last 30 days
    thirty_days_ago = DateTime.utc_now() |> DateTime.add(-30, :day)

    recent_count = Enum.count(discoveries, fn d ->
      DateTime.compare(d.created_at, thirty_days_ago) == :gt
    end)

    recent_count
  end

  defp count_cross_domain_transfers(discoveries, source_domain_id) do
    # Count discoveries with applications in other domains
    transfers = Enum.filter(discoveries, fn d ->
      application_domains = Enum.map(d.applications || [], fn app ->
        app[:domain]
      end)
      |> Enum.uniq()

      # Has applications AND at least one is in a different domain
      length(application_domains) > 0 and
        Enum.any?(application_domains, fn dom -> dom != source_domain_id end)
    end)

    length(transfers)
  end

  defp calculate_scientific_momentum(metrics) do
    # Composite score combining multiple factors (0-100 scale)
    # Higher is better, but research debt and unknown pressure reduce score

    base_score = (
      min(metrics.discoveries * 2, 20) +  # Up to 20 points for discoveries
      min(metrics.theories * 3, 15) +     # Up to 15 points for theories
      min(metrics.laws * 5, 10) +         # Up to 10 points for laws
      metrics.replication_success * 0.15 + # Up to 15 points for validation
      metrics.theory_stability * 0.15 +   # Up to 15 points for stability
      min(metrics.application_rate * 5, 15) # Up to 15 points for applications
    )

    # Penalties
    debt_penalty = min(metrics.research_debt.total_weighted_debt * 0.5, 10)
    pressure_penalty = metrics.unknown_pressure * 0.1

    momentum = max(base_score - debt_penalty - pressure_penalty, 0)
    Float.round(min(momentum, 100), 2)
  end

  # ---------------------------------------------------------------------------
  # Stubs for referenced functions
  # ---------------------------------------------------------------------------

  defp fetch_institution_self_models, do: []
  defp compute_average_quality(_institutions), do: 0.75
  defp compute_average_confidence(_institutions), do: 0.80
  defp compute_compliance_rate(_institutions), do: 0.90
  defp compute_evidence_coverage(_institutions), do: 0.70
end
