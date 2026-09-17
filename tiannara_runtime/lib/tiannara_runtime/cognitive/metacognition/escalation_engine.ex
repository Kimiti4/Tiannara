defmodule TiannaraRuntime.Cognitive.Metacognition.EscalationEngine do
  @moduledoc "Phase 18.8 — Escalation decision engine for meta-cognitive control"

  def evaluate(health, uncertainty, confidence) do
    health_status = Map.get(health, :status, :healthy)
    overall = Map.get(health, :overall, 0.0)
    unc_val = Map.get(uncertainty, :total, 0.0)
    miscal = Map.get(confidence, :miscalibration, 1.0)
    {level, reason, trigger} = cond do
      health_status == :critical -> {:critical, "Health assessment is critical", :health}
      health_status == :degraded or unc_val > 0.7 -> {:warning, "Health degraded or uncertainty high", :degraded}
      unc_val > 0.4 or miscal > 0.3 -> {:info, "Elevated uncertainty or miscalibration detected", :uncertainty}
      true -> {:normal, "All systems nominal", :stable}
    end
    {:ok, %{level: level, reason: reason, trigger: trigger, context: %{health_overall: overall, uncertainty_total: unc_val, confidence_miscalibration: miscal}, decided_at: :erlang.unique_integer([:positive])}}
  end

  def escalate(decision, level) do
    {:ok, %{decision | level: level, reason: "Escalated to #{level}", decided_at: :erlang.unique_integer([:positive])}}
  end

  def de_escalate(decision) do
    current = Map.get(decision, :level, :normal)
    lower = case current do
      :critical -> :warning
      :warning -> :info
      :info -> :normal
      :normal -> :normal
    end
    {:ok, %{decision | level: lower, decided_at: :erlang.unique_integer([:positive])}}
  end
end
