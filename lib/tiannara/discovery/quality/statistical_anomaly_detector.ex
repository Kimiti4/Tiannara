defmodule Tiannara.Discovery.Quality.StatisticalAnomalyDetector do
  alias Tiannara.Discovery.Discovery
  alias Tiannara.Discovery.Quality.Domain.QualityCheck

  @spec detect(Discovery.t()) :: QualityCheck.t()
  def detect(%Discovery{} = disc) do
    anomalies = []

    anomalies = check_perfect_confirmation(disc, anomalies)
    anomalies = check_uniform_deltas(disc, anomalies)
    anomalies = check_impossible_confidence(disc, anomalies)
    anomalies = check_count_mismatch(disc, anomalies)
    anomalies = check_confidence_without_evidence(disc, anomalies)

    score = max(0.0, 1.0 - length(anomalies) * 0.2)

    QualityCheck.new(%{
      name: "Statistical Anomaly Detection",
      category: :statistical_anomaly,
      passed: anomalies == [],
      score: score,
      details: if(anomalies == [], do: "No statistical anomalies detected", else: "#{length(anomalies)} anomalies found"),
      evidence: anomalies
    })
  end

  defp check_perfect_confirmation(%Discovery{evidence: evidence}, anomalies) do
    if length(evidence) >= 5 do
      all_confirmed = Enum.all?(evidence, &(&1.outcome == :confirmed))

      if all_confirmed do
        [%{type: :perfect_confirmation, detail: "All #{length(evidence)} evidence items confirm — statistically unlikely", count: length(evidence)} | anomalies]
      else
        anomalies
      end
    else
      anomalies
    end
  end

  defp check_uniform_deltas(%Discovery{evidence: evidence}, anomalies) do
    if length(evidence) >= 3 do
      deltas = Enum.map(evidence, & &1.confidence_delta)
      unique_deltas = Enum.uniq(deltas)

      if length(unique_deltas) == 1 and hd(deltas) != 0.0 do
        [%{type: :uniform_deltas, detail: "All confidence deltas are identical (#{hd(deltas)})", delta: hd(deltas)} | anomalies]
      else
        anomalies
      end
    else
      anomalies
    end
  end

  defp check_impossible_confidence(%Discovery{confidence: conf, uncertainty: unc}, anomalies) do
    cond do
      conf < 0.0 or conf > 1.0 ->
        [%{type: :impossible_confidence, detail: "Confidence #{conf} outside [0, 1]", value: conf} | anomalies]
      unc < 0.0 or unc > 1.0 ->
        [%{type: :impossible_uncertainty, detail: "Uncertainty #{unc} outside [0, 1]", value: unc} | anomalies]
      abs(conf + unc - 1.0) > 0.01 ->
        [%{type: :confidence_uncertainty_mismatch, detail: "Confidence + uncertainty = #{conf + unc}, expected 1.0"} | anomalies]
      true ->
        anomalies
    end
  end

  defp check_count_mismatch(%Discovery{evidence: evidence, experiments: experiments}, anomalies) do
    exp_count = length(experiments)
    ev_count = length(evidence)

    if exp_count > 0 and ev_count > exp_count * 3 do
      [%{type: :evidence_experiment_mismatch, detail: "#{ev_count} evidence items for #{exp_count} experiments — possible duplication"} | anomalies]
    else
      anomalies
    end
  end

  defp check_confidence_without_evidence(%Discovery{confidence: conf, evidence: evidence}, anomalies) do
    if conf > 0.5 and evidence == [] do
      [%{type: :confidence_without_evidence, detail: "Confidence #{conf} with zero evidence items"} | anomalies]
    else
      anomalies
    end
  end
end
