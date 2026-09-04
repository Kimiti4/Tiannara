defmodule Tiannara.Discovery.Quality.DiscoveryQualityAssessor do
  alias Tiannara.Discovery.Discovery
  alias Tiannara.Discovery.Quality.Domain.{QualityReport, QualityCheck}
  alias Tiannara.Discovery.Quality.{ConfirmationBiasDetector, CircularReasoningDetector, StatisticalAnomalyDetector}

  @pass_threshold 0.7
  @reject_threshold 0.3

  @spec assess(Discovery.t()) :: QualityReport.t()
  def assess(%Discovery{} = disc) do
    checks = [
      ConfirmationBiasDetector.detect(disc),
      CircularReasoningDetector.detect(disc),
      StatisticalAnomalyDetector.detect(disc),
      check_completeness(disc),
      check_falsifiability(disc),
      check_reproducibility(disc)
    ]

    overall_score = compute_overall_score(checks)
    warnings = Enum.filter(checks, fn c -> not c.passed and c.score >= @reject_threshold end)
    violations = Enum.filter(checks, fn c -> c.score < @reject_threshold end)

    recommendation = determine_recommendation(overall_score, violations)

    QualityReport.new(%{
      discovery_id: disc.id,
      overall_score: overall_score,
      checks: checks,
      warnings: warnings,
      violations: violations,
      recommendation: recommendation
    })
  end

  @spec passes?(Discovery.t()) :: boolean()
  def passes?(%Discovery{} = disc) do
    report = assess(disc)
    report.recommendation in [:pass, :pass_with_warnings]
  end

  @spec summarize(QualityReport.t()) :: String.t()
  def summarize(%QualityReport{} = report) do
    checks_text =
      Enum.map_join(report.checks, "\n", fn check ->
        status = if check.passed, do: "[PASS]", else: "[FAIL]"
        "  #{status} #{check.name}: #{check.details} (score: #{Float.round(check.score, 2)})"
      end)

    """
    Quality Report: #{report.discovery_id}
    Overall Score: #{Float.round(report.overall_score, 3)}
    Recommendation: #{report.recommendation}

    Checks:
    #{checks_text}

    Violations: #{length(report.violations)}
    """
  end

  defp check_completeness(%Discovery{} = disc) do
    missing = []
    missing = if disc.gap == nil, do: [:gap | missing], else: missing
    missing = if disc.hypotheses == [], do: [:hypotheses | missing], else: missing
    missing = if disc.predictions == [], do: [:predictions | missing], else: missing
    missing = if disc.experiments == [], do: [:experiments | missing], else: missing

    score = if missing == [], do: 1.0, else: max(0.0, 1.0 - length(missing) * 0.25)

    QualityCheck.new(%{
      name: "Completeness Check",
      category: :completeness,
      passed: missing == [],
      score: score,
      details: if(missing == [], do: "All pipeline stages present", else: "Missing: #{Enum.join(missing, ", ")}"),
      evidence: Enum.map(missing, fn m -> %{type: :missing_stage, stage: m} end)
    })
  end

  defp check_falsifiability(%Discovery{hypotheses: hypotheses}) do
    non_falsifiable = Enum.reject(hypotheses, & &1.falsifiable)

    score =
      if hypotheses == [] do
        0.0
      else
        1.0 - length(non_falsifiable) / length(hypotheses)
      end

    QualityCheck.new(%{
      name: "Falsifiability Check",
      category: :falsifiability,
      passed: non_falsifiable == [],
      score: score,
      details: if(non_falsifiable == [], do: "All hypotheses are falsifiable", else: "#{length(non_falsifiable)} non-falsifiable hypotheses"),
      evidence: Enum.map(non_falsifiable, fn h -> %{type: :non_falsifiable, hypothesis_id: h.id} end)
    })
  end

  defp check_reproducibility(%Discovery{experiments: experiments}) do
    reproducible = Enum.filter(experiments, fn exp ->
      exp.success_criteria != nil and exp.success_criteria != [] and
      exp.failure_criteria != nil and exp.failure_criteria != [] and
      exp.stopping_criteria != nil
    end)

    score =
      if experiments == [] do
        0.0
      else
        length(reproducible) / length(experiments)
      end

    QualityCheck.new(%{
      name: "Reproducibility Check",
      category: :reproducibility,
      passed: score >= 0.8,
      score: score,
      details: "#{length(reproducible)}/#{length(experiments)} experiments are fully reproducible",
      evidence: []
    })
  end

  defp compute_overall_score(checks) do
    if checks == [] do
      0.0
    else
      weights = %{
        confirmation_bias: 0.25,
        circular_reasoning: 0.25,
        statistical_anomaly: 0.20,
        completeness: 0.10,
        falsifiability: 0.10,
        reproducibility: 0.10
      }

      total_weight = Enum.reduce(checks, 0.0, fn c, acc -> acc + Map.get(weights, c.category, 0.1) end)
      weighted_sum = Enum.reduce(checks, 0.0, fn c, acc -> acc + c.score * Map.get(weights, c.category, 0.1) end)

      if total_weight > 0, do: weighted_sum / total_weight, else: 0.0
    end
  end

  defp determine_recommendation(score, violations) do
    cond do
      length(violations) > 0 -> :reject
      score < @reject_threshold -> :reject
      score < @pass_threshold -> :revise
      score < 0.9 -> :pass_with_warnings
      true -> :pass
    end
  end
end
