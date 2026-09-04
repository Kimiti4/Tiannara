defmodule Tiannara.Discovery.Validation.DiscoveryCertifier do
  alias Tiannara.Discovery.Discovery
  alias Tiannara.Discovery.Quality.DiscoveryQualityAssessor
  alias Tiannara.Discovery.Validation.{StatisticalValidator, ReplicationPlanner, EvidenceAuditor}
  alias Tiannara.Discovery.Validation.Domain.{ValidationReport, Certification}

  @certification_threshold 0.7
  @provisional_threshold 0.5
  @evidence_audit_threshold 0.6

  @spec validate(Discovery.t()) :: ValidationReport.t()
  def validate(%Discovery{} = disc) do
    stat_validation = StatisticalValidator.validate(disc)
    replication_plan = ReplicationPlanner.plan(disc)
    replication_sufficient = ReplicationPlanner.sufficiently_replicated?(disc)
    {evidence_score, evidence_findings} = EvidenceAuditor.audit(disc)
    qa_report = DiscoveryQualityAssessor.assess(disc)
    reproducibility_score = compute_reproducibility(disc)

    overall = compute_overall_score(stat_validation, replication_sufficient, evidence_score, qa_report.overall_score, reproducibility_score)
    certification = determine_certification(disc, overall, stat_validation, replication_sufficient, evidence_score, qa_report)

    ValidationReport.new(%{
      discovery_id: disc.id,
      statistical_validation: stat_validation,
      replication_status: %{plan: replication_plan, sufficient: replication_sufficient},
      reproducibility_score: reproducibility_score,
      evidence_audit: %{score: evidence_score, findings: evidence_findings},
      calibration_result: %{qa_score: qa_report.overall_score, qa_recommendation: qa_report.recommendation},
      certification: certification,
      overall_score: overall,
      recommendation: certification.level
    })
  end

  @spec certified?(Discovery.t()) :: boolean()
  def certified?(%Discovery{} = disc) do
    report = validate(disc)
    report.certification.level in [:certified, :provisional]
  end

  @spec summarize(ValidationReport.t()) :: String.t()
  def summarize(%ValidationReport{} = report) do
    """
    Validation Report: #{report.discovery_id}
    Overall Score: #{Float.round(report.overall_score, 3)}
    Certification: #{report.certification.level}

    Statistical Validation:
      Significant: #{report.statistical_validation.significant}
      P-value: #{Float.round(report.statistical_validation.p_value, 4)}
      Effect size: #{Float.round(report.statistical_validation.effect_size, 3)}
      Power: #{Float.round(report.statistical_validation.statistical_power, 3)}

    Replication: Sufficient: #{report.replication_status.sufficient}
    Evidence Audit Score: #{Float.round(report.evidence_audit.score, 3)}
    QA Score: #{Float.round(report.calibration_result.qa_score, 3)}
    Reproducibility: #{Float.round(report.reproducibility_score, 3)}
    Conditions: #{Enum.join(report.certification.conditions, "; ")}
    """
  end

  defp compute_reproducibility(%Discovery{experiments: experiments}) do
    if experiments == [] do
      0.0
    else
      reproducible = Enum.count(experiments, fn exp ->
        exp.success_criteria != nil and exp.success_criteria != [] and
        exp.failure_criteria != nil and exp.failure_criteria != [] and
        exp.stopping_criteria != nil and exp.inputs != nil and map_size(exp.inputs) > 0
      end)
      reproducible / length(experiments)
    end
  end

  defp compute_overall_score(stat, replicated, evidence_score, qa_score, reproducibility) do
    stat_score = if stat.significant and stat.sufficient_power, do: 1.0, else: stat.statistical_power
    repl_score = if replicated, do: 1.0, else: 0.3
    stat_score * 0.25 + repl_score * 0.20 + evidence_score * 0.25 + qa_score * 0.15 + reproducibility * 0.15
  end

  defp determine_certification(disc, overall, stat, replicated, evidence_score, qa_report) do
    conditions = []

    level = cond do
      qa_report.recommendation == :reject -> :rejected
      evidence_score < 0.3 -> :rejected
      overall >= @certification_threshold and stat.significant and stat.sufficient_power and replicated and evidence_score >= @evidence_audit_threshold -> :certified
      overall >= @provisional_threshold -> :provisional
      true -> :uncertified
    end

    conditions = if level == :provisional do
      conditions = if not replicated, do: ["Requires independent replication" | conditions], else: conditions
      if not stat.sufficient_power, do: ["Requires additional evidence for statistical power" | conditions], else: conditions
    else
      conditions
    end

    Certification.new(%{
      discovery_id: disc.id,
      level: level,
      confidence: disc.confidence,
      uncertainty: disc.uncertainty,
      evidence_count: length(disc.evidence),
      replication_count: if(replicated, do: 2, else: 0),
      validation_score: overall,
      conditions: conditions,
      expires_at: compute_expiry(level)
    })
  end

  defp compute_expiry(:certified), do: DateTime.add(DateTime.utc_now(), 5 * 365 * 24 * 3600, :second)
  defp compute_expiry(:provisional), do: DateTime.add(DateTime.utc_now(), 365 * 24 * 3600, :second)
  defp compute_expiry(_), do: nil
end
