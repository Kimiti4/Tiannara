defmodule Tiannara.Discovery.Advanced.HypothesisDiversityEngine do
  alias Tiannara.Discovery.Domain.HypothesisSpec

  @spec assess([HypothesisSpec.t()]) :: map()
  def assess(hypotheses) when is_list(hypotheses) do
    causal_diversity = compute_causal_diversity(hypotheses)
    prediction_diversity = compute_prediction_diversity(hypotheses)
    abstraction_diversity = compute_abstraction_diversity(hypotheses)
    prior_diversity = compute_prior_diversity(hypotheses)

    composite = geometric_mean([causal_diversity, prediction_diversity, abstraction_diversity, prior_diversity])

    recommendations = generate_recommendations(hypotheses, causal_diversity, prediction_diversity, abstraction_diversity, prior_diversity)

    %{
      hypothesis_count: length(hypotheses),
      causal_diversity: causal_diversity,
      prediction_diversity: prediction_diversity,
      abstraction_diversity: abstraction_diversity,
      prior_diversity: prior_diversity,
      composite: composite,
      sufficient: composite > 0.5,
      recommendations: recommendations
    }
  end

  @spec suggest_additions([HypothesisSpec.t()]) :: [map()]
  def suggest_additions(hypotheses) when is_list(hypotheses) do
    report = assess(hypotheses)
    suggestions = []
    suggestions = if report.causal_diversity < 0.5, do: [%{type: :causal_model, suggestion: "Add hypothesis with a different causal model", priority: :high} | suggestions], else: suggestions
    suggestions = if report.prediction_diversity < 0.5, do: [%{type: :prediction, suggestion: "Add hypothesis that predicts a different outcome", priority: :high} | suggestions], else: suggestions
    suggestions = if report.prior_diversity < 0.4, do: [%{type: :prior, suggestion: "Add hypothesis with a very different prior", priority: :medium} | suggestions], else: suggestions
    suggestions = if length(hypotheses) < 3, do: [%{type: :count, suggestion: "Add more hypotheses (minimum 3 recommended)", priority: :high} | suggestions], else: suggestions
    suggestions
  end

  defp compute_causal_diversity(hypotheses) do
    models = Enum.map(hypotheses, fn h -> Map.get(h.metadata, :causal_model, :unknown) end)
    unique_models = Enum.uniq(models)
    if models == [], do: 0.0, else: length(unique_models) / length(models)
  end

  defp compute_prediction_diversity(hypotheses) do
    strategies = Enum.map(hypotheses, fn h -> Map.get(h.metadata, :strategy, :unknown) end)
    unique_strategies = Enum.uniq(strategies)
    if strategies == [], do: 0.0, else: length(unique_strategies) / length(strategies)
  end

  defp compute_abstraction_diversity(hypotheses) do
    novelties = Enum.map(hypotheses, fn h -> Map.get(h.metadata, :novelty, Map.get(h, :novelty, 0.5)) end)
    if novelties == [] do
      0.0
    else
      mean = Enum.sum(novelties) / length(novelties)
      variance = Enum.reduce(novelties, 0.0, fn n, acc -> acc + :math.pow(n - mean, 2) end) / length(novelties)
      min(1.0, variance * 4.0)
    end
  end

  defp compute_prior_diversity(hypotheses) do
    priors = Enum.map(hypotheses, & &1.prior)
    if priors == [] do
      0.0
    else
      mean = Enum.sum(priors) / length(priors)
      variance = Enum.reduce(priors, 0.0, fn p, acc -> acc + :math.pow(p - mean, 2) end) / length(priors)
      min(1.0, variance * 10.0)
    end
  end

  defp geometric_mean(values) do
    if Enum.any?(values, &(&1 <= 0.0)), do: 0.0, else: :math.pow(Enum.reduce(values, 1.0, &(&1 * &2)), 1.0 / length(values))
  end

  defp generate_recommendations(hypotheses, causal, prediction, _abstraction, _prior) do
    recommendations = []
    recommendations = if causal < 0.5, do: [%{dimension: :causal_diversity, score: causal, action: "Introduce hypotheses with different causal models"} | recommendations], else: recommendations
    recommendations = if prediction < 0.5, do: [%{dimension: :prediction_diversity, score: prediction, action: "Ensure hypotheses predict different outcomes"} | recommendations], else: recommendations
    recommendations = if length(hypotheses) < 3, do: [%{dimension: :hypothesis_count, score: 0.0, action: "Generate at least 3 competing hypotheses"} | recommendations], else: recommendations
    recommendations
  end
end
