defmodule Tiannara.Discovery.Validation.StatisticalValidator do
  alias Tiannara.Discovery.Discovery
  alias Tiannara.Discovery.Validation.Domain.StatisticalValidation

  @default_alpha 0.05
  @min_power 0.8
  @min_sample_size 3

  @spec validate(Discovery.t()) :: StatisticalValidation.t()
  def validate(%Discovery{} = disc) do
    evidence_count = length(disc.evidence)
    confidence_deltas = Enum.map(disc.evidence, & &1.confidence_delta)

    effect_size = compute_effect_size(confidence_deltas)
    p_value = compute_p_value(disc)
    power = compute_power(evidence_count, effect_size)
    ci = compute_confidence_interval(disc.confidence, evidence_count)

    significant = p_value < @default_alpha and effect_size > 0.2
    sufficient_power = power >= @min_power and evidence_count >= @min_sample_size

    StatisticalValidation.new(%{
      significance_level: @default_alpha,
      p_value: p_value,
      effect_size: effect_size,
      statistical_power: power,
      confidence_interval: ci,
      sample_size: evidence_count,
      sufficient_power: sufficient_power,
      significant: significant,
      details: build_details(disc, effect_size, p_value, power, sufficient_power)
    })
  end

  @spec statistically_supported?(Discovery.t()) :: boolean()
  def statistically_supported?(%Discovery{} = disc) do
    validation = validate(disc)
    validation.significant and validation.sufficient_power
  end

  defp compute_effect_size([]), do: 0.0
  defp compute_effect_size(deltas) do
    mean = Enum.sum(deltas) / length(deltas)
    variance = if length(deltas) > 1 do
      Enum.reduce(deltas, 0.0, fn d, acc -> acc + :math.pow(d - mean, 2) end) / (length(deltas) - 1)
    else
      0.0
    end
    std = :math.sqrt(variance)
    if std > 0.0, do: abs(mean / std), else: if(mean != 0.0, do: 1.0, else: 0.0)
  end

  defp compute_p_value(%Discovery{evidence: evidence, confidence: confidence}) do
    if evidence == [] do
      1.0
    else
      outcomes = Enum.map(evidence, & &1.outcome)
      confirmed = Enum.count(outcomes, &(&1 == :confirmed))
      consistency = confirmed / length(outcomes)
      strength = confidence
      p = max(0.001, 1.0 - consistency * strength)
      min(1.0, p)
    end
  end

  defp compute_power(sample_size, effect_size) do
    base_power = 1.0 - :math.exp(-0.3 * sample_size * max(0.1, effect_size))
    max(0.0, min(1.0, base_power))
  end

  defp compute_confidence_interval(confidence, sample_size) do
    if sample_size == 0 do
      {0.0, 1.0}
    else
      z = 1.96
      n = sample_size
      p = confidence
      denominator = 1 + z * z / n
      center = (p + z * z / (2 * n)) / denominator
      margin = z * :math.sqrt((p * (1 - p) + z * z / (4 * n)) / n) / denominator
      {max(0.0, center - margin), min(1.0, center + margin)}
    end
  end

  defp build_details(disc, effect_size, p_value, power, sufficient_power) do
    details = []
    details = if effect_size < 0.2, do: [%{type: :small_effect, detail: "Effect size #{Float.round(effect_size, 3)} < 0.2 (small)"} | details], else: details
    details = if p_value >= @default_alpha, do: [%{type: :not_significant, detail: "p-value #{Float.round(p_value, 3)} >= #{@default_alpha}"} | details], else: details
    details = if not sufficient_power, do: [%{type: :insufficient_power, detail: "Power #{Float.round(power, 3)} < #{@min_power} or n < #{@min_sample_size}"} | details], else: details
    details = if length(disc.evidence) < @min_sample_size, do: [%{type: :insufficient_sample, detail: "Sample size #{length(disc.evidence)} < #{@min_sample_size}"} | details], else: details
    details
  end
end
