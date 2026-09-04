defmodule Tiannara.Discovery.Quality.ConfirmationBiasDetector do
  alias Tiannara.Discovery.Discovery
  alias Tiannara.Discovery.Quality.Domain.QualityCheck

  @spec detect(Discovery.t()) :: QualityCheck.t()
  def detect(%Discovery{} = disc) do
    signals = []

    {confirming, refuting} = count_evidence_symmetry(disc)
    asymmetry = compute_asymmetry(confirming, refuting)
    signals = if asymmetry > 0.8 do
      [%{type: :evidence_asymmetry, confirming: confirming, refuting: refuting, ratio: asymmetry} | signals]
    else
      signals
    end

    prior_dominance = check_prior_dominance(disc)
    signals = if prior_dominance do
      [%{type: :prior_dominance, detail: "One hypothesis has prior > 0.6, evidence cannot meaningfully update"} | signals]
    else
      signals
    end

    has_null = has_null_hypothesis(disc)
    signals = if not has_null do
      [%{type: :missing_null_hypothesis, detail: "No null/alternative hypothesis found"} | signals]
    else
      signals
    end

    selective = check_selective_reporting(disc)
    signals = if selective do
      [%{type: :selective_reporting, detail: "Refuted results appear to be excluded from evidence"} | signals]
    else
      signals
    end

    anchoring = check_anchoring(disc)
    signals = if anchoring do
      [%{type: :anchoring, detail: "First hypothesis receives disproportionate weight"} | signals]
    else
      signals
    end

    score = max(0.0, 1.0 - length(signals) * 0.25)
    passed = length(signals) == 0

    QualityCheck.new(%{
      name: "Confirmation Bias Detection",
      category: :confirmation_bias,
      passed: passed,
      score: score,
      details: if(passed, do: "No confirmation bias detected", else: "#{length(signals)} bias signals detected"),
      evidence: signals
    })
  end

  defp count_evidence_symmetry(%Discovery{evidence: evidence}) do
    confirming = Enum.count(evidence, &(&1.outcome == :confirmed))
    refuting = Enum.count(evidence, &(&1.outcome == :refuted))
    {confirming, refuting}
  end

  defp compute_asymmetry(confirming, refuting) do
    total = confirming + refuting
    if total < 3, do: 0.0, else: max(confirming, refuting) / total
  end

  defp check_prior_dominance(%Discovery{hypotheses: hypotheses}) do
    case hypotheses do
      [] -> false
      _ -> Enum.max_by(hypotheses, & &1.prior).prior > 0.6
    end
  end

  defp has_null_hypothesis(%Discovery{hypotheses: hypotheses}) do
    Enum.any?(hypotheses, fn hyp ->
      Map.get(hyp.metadata, :strategy) == :null_hypothesis or
      String.contains?(String.downcase(hyp.statement), "fluctuation") or
      String.contains?(String.downcase(hyp.statement), "artifact") or
      String.contains?(String.downcase(hyp.statement), "noise") or
      String.contains?(String.downcase(hyp.statement), "no effect")
    end)
  end

  defp check_selective_reporting(%Discovery{evidence: evidence, experiments: experiments, status: status}) do
    experiment_count = length(experiments)
    evidence_count = length(evidence)
    refuted_count = Enum.count(evidence, &(&1.outcome == :refuted))
    is_terminal = status in [:completed, :abandoned, :conclusion_reached]
    is_terminal and experiment_count > evidence_count and refuted_count == 0
  end

  defp check_anchoring(%Discovery{hypotheses: hypotheses}) do
    case hypotheses do
      [] -> false
      [first | rest] ->
        if rest == [] do
          false
        else
          avg_rest = Enum.sum(Enum.map(rest, & &1.prior)) / length(rest)
          first.prior > avg_rest * 2.0
        end
    end
  end
end
