defmodule Tiannara.Council.Principles.EvidenceBeforeConfidence do
  @moduledoc """
  Principle: Evidence Before Confidence.
  "Never optimize for appearing correct. Optimize for being correct."
  """
  @behaviour Tiannara.Council.ConstitutionalPrinciple

  @impl true
  def id, do: :evidence_before_confidence

  @impl true
  def name, do: "Evidence Before Confidence"

  @impl true
  def version, do: "1.2.0"

  @impl true
  def weight, do: 1.0

  @impl true
  def evaluate(_decision_type, payload, _context) do
    confidence = Map.get(payload, :confidence, 0.5)
    evidence_count = Map.get(payload, :evidence_count, 0)
    uncertainty_hidden = Map.get(payload, :uncertainty_hidden, false)

    {verdict, reasoning, evidence} =
      cond do
        uncertainty_hidden ->
          {:violated, "Uncertainty was explicitly hidden.",
           [%{type: :flag, value: :uncertainty_hidden}]}

        evidence_count >= 3 and confidence >= 0.7 ->
          {:strengthened, "Sufficient evidence (#{evidence_count}) and calibrated confidence (#{confidence}).",
           [%{type: :evidence_count, value: evidence_count}, %{type: :confidence, value: confidence}]}

        evidence_count == 0 and confidence > 0.5 ->
          {:violated, "High confidence (#{confidence}) with zero supporting evidence.",
           [%{type: :evidence_count, value: 0}, %{type: :confidence, value: confidence}]}

        true ->
          {:neutral, "Neutral with respect to evidence thresholds.",
           [%{type: :evidence_count, value: evidence_count}, %{type: :confidence, value: confidence}]}
      end

    %{
      principle_id: id(),
      principle_name: name(),
      version: version(),
      verdict: verdict,
      reasoning: reasoning,
      evidence: evidence,
      weight: weight()
    }
  end
end
