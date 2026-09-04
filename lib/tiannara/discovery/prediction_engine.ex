defmodule Tiannara.Discovery.PredictionEngine do
  alias Tiannara.Discovery.Domain.{HypothesisSpec, PredictionSpec}

  def generate(%HypothesisSpec{} = hyp), do: generate_predictions(hyp)
  def generate(%HypothesisSpec{} = hypothesis, causal_model), do: generate_predictions(hypothesis, causal_model)

  def generate_predictions(%HypothesisSpec{} = hypothesis, causal_model \\ :default) do
    templates = get_prediction_templates(causal_model)
    templates
    |> Enum.map(fn template_fn -> template_fn.(hypothesis) end)
    |> Enum.map(&validate_falsifiability/1)
  end

  def validate_falsifiability(%PredictionSpec{} = prediction) do
    has_threshold = Map.has_key?(prediction, :threshold)
    has_measurable = Map.get(prediction, :measurable_outcome, false)
    has_failure_conds = length(Map.get(prediction, :failure_conditions, [])) > 0
    falsifiable = has_threshold and has_measurable and has_failure_conds
    %{prediction | falsifiable: falsifiable}
  end

  defp get_prediction_templates(:default) do
    [
      fn h -> PredictionSpec.new(%{id: pred_id(), hypothesis_id: h.id,
        description: "If #{h.description}, then observed data will show correlation X",
        statement: "If #{h.description}, then observed data will show correlation X",
        falsification_criteria: "Result inconsistent with hypothesis (p < 0.05)",
        measurable_outcome: true, expected_outcome: :correlation, threshold: 0.05,
        failure_conditions: ["No correlation detected", "Correlation below threshold"],
        confidence: 0.6, uncertainty: 0.4, status: :proposed, falsifiable: true}) end,
      fn h -> PredictionSpec.new(%{id: pred_id(), hypothesis_id: h.id,
        description: "If #{h.description}, then intervention Y will produce effect Z",
        statement: "If #{h.description}, then intervention Y will produce effect Z",
        falsification_criteria: "Result inconsistent with hypothesis (p < 0.05)",
        measurable_outcome: true, expected_outcome: :causal_effect, threshold: 0.05,
        failure_conditions: ["Effect not detected", "Effect in opposite direction"],
        confidence: 0.6, uncertainty: 0.4, status: :proposed, falsifiable: true}) end,
    ]
  end

  defp get_prediction_templates(:causal) do
    [
      fn h -> PredictionSpec.new(%{id: pred_id(), hypothesis_id: h.id,
        description: "Manipulating upstream cause of #{h.description} will produce downstream effect",
        statement: "Manipulating upstream cause of #{h.description} will produce downstream effect",
        falsification_criteria: "Result inconsistent with hypothesis (p < 0.01)",
        measurable_outcome: true, expected_outcome: :causal_chain, threshold: 0.01,
        failure_conditions: ["No causal chain detected", "Mediating variable blocks effect"],
        confidence: 0.6, uncertainty: 0.4, status: :proposed, falsifiable: true}) end,
      fn h -> PredictionSpec.new(%{id: pred_id(), hypothesis_id: h.id,
        description: "Counterfactual: without #{h.description}, outcome differs",
        statement: "Counterfactual: without #{h.description}, outcome differs",
        falsification_criteria: "Result inconsistent with hypothesis (p < 0.05)",
        measurable_outcome: true, expected_outcome: :counterfactual, threshold: 0.05,
        failure_conditions: ["No counterfactual difference", "Outcome unchanged"],
        confidence: 0.6, uncertainty: 0.4, status: :proposed, falsifiable: true}) end,
    ]
  end

  defp get_prediction_templates(:statistical) do
    [
      fn h -> PredictionSpec.new(%{id: pred_id(), hypothesis_id: h.id,
        description: "Distribution of #{h.description} differs from null model",
        statement: "Distribution of #{h.description} differs from null model",
        falsification_criteria: "Result inconsistent with hypothesis (p < 0.05)",
        measurable_outcome: true, expected_outcome: :distribution_shift, threshold: 0.05,
        failure_conditions: ["Distribution matches null", "Effect size negligible"],
        confidence: 0.6, uncertainty: 0.4, status: :proposed, falsifiable: true}) end,
    ]
  end

  defp get_prediction_templates(_), do: get_prediction_templates(:default)

  defp pred_id, do: "pred_#{:crypto.strong_rand_bytes(6) |> Base.encode16(case: :lower)}"
end
