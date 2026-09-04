defmodule Tiannara.Research.EvidenceAssessment do
  @moduledoc """
  Evidence-aware assessment for the Ω.2 Research Director. Answers:
    * What evidence do we have?        (`available`)
    * How strong is the evidence?      (`strength`)
    * What contradicts it?             (`contradictions`)
    * Is it sufficient to proceed?     (`sufficiency`)

  Constitutional basis: "Evidence Before Confidence" — "quantify uncertainty,
  identify missing evidence, recommend experiments, update conclusions when new
  evidence appears"; "Uncertainty should never be hidden."
  """

  defstruct available: [], strength: 0.0, contradictions: [], sufficiency: :insufficient

  def assess(opportunity) do
    available = opportunity.evidence || []
    strength = compute_strength(available, opportunity.confidence)
    contradictions = find_contradictions(available)

    sufficiency =
      cond do
        contradictions != [] -> :contradicted
        strength >= 0.7 -> :sufficient
        true -> :insufficient
      end

    %__MODULE__{
      available: available,
      strength: strength,
      contradictions: contradictions,
      sufficiency: sufficiency
    }
  end

  defp compute_strength([], _confidence), do: 0.0

  defp compute_strength(evidence, confidence) do
    n = length(evidence)
    coverage = min(1.0, n / 3)
    Float.round(coverage * 0.5 + confidence * 0.5, 4)
  end

  defp find_contradictions(evidence) do
    evidence
    |> Enum.filter(&is_map/1)
    |> Enum.group_by(&Map.get(&1, :quantity))
    |> Enum.flat_map(fn
      {nil, _items} ->
        []

      {quantity, items} ->
        values =
          items
          |> Enum.map(&Map.get(&1, :value))
          |> Enum.reject(&is_nil/1)
          |> Enum.uniq()

        if length(values) > 1,
          do: [%{quantity: quantity, conflicting_values: values}],
          else: []
    end)
  end
end