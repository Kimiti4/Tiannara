defmodule Tiannara.CEL.PriorityEngine do
  alias Tiannara.CEL.Models.CivilizationalEvent

  @doc "Calculates a normalized global priority score (0.0 to 1.0)."
  def calculate_global_priority(%CivilizationalEvent{} = event) do
    impact = Map.get(event, :impact, 0.5)
    evidence = Map.get(event, :evidence, 0.5)
    confidence = Map.get(event, :confidence, 0.5)
    urgency = urgency_multiplier(event.urgency)

    risk_penalty = calculate_risk_penalty(Map.get(event, :risk, 0.0))
    resource_cost_penalty = calculate_resource_penalty(Map.get(event, :resource_cost, 0.0))
    mission_alignment = if event.mission_id, do: 1.2, else: 1.0

    raw_score = (impact * evidence * confidence * urgency * mission_alignment) - (risk_penalty + resource_cost_penalty)
    max(0.0, min(1.0, raw_score))
  end

  def healthy?, do: true

  def constitutional_score do
    %Tiannara.CEL.Kernel.ConstitutionalScore{
      service_id: :priority_engine,
      health: 1.0,
      constitutional_alignment: 0.98,
      transparency: 1.0,
      explainability: 0.95,
      evidence_quality: 0.9,
      human_oversight: 0.5,
      computed_at: DateTime.utc_now()
    }
  end

  defp urgency_multiplier(:critical), do: 2.0
  defp urgency_multiplier(:high), do: 1.5
  defp urgency_multiplier(:medium), do: 1.0
  defp urgency_multiplier(:low), do: 0.5
  defp urgency_multiplier(_), do: 0.8

  defp calculate_risk_penalty(risk), do: risk * 0.5
  defp calculate_resource_penalty(cost), do: cost * 0.2
end
