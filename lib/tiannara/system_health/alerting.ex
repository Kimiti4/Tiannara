defmodule Tiannara.SystemHealth.Alerting do
  @moduledoc """
  Monitors System Health and triggers alarms if stability drops below thresholds.
  """
  require Logger
  alias Tiannara.SystemHealth.Score

  @critical_threshold 0.3

  def evaluate(snapshot) do
    score = Score.compute(snapshot)
    
    if score < @critical_threshold do
      Logger.error("🚨 [SystemHealth] CRITICAL STABILITY ALERT! Score: #{Float.round(score, 2)}")
      Logger.error("   Entropy: #{snapshot.entropy}")
      Logger.error("   Collapse Prob: #{snapshot.collapse_probability}")
      Logger.error("   Semantic Drift: #{snapshot.semantic_drift}")
      # Tiannara.ASC.Immunity.ImmuneSystem.trigger_alarm(:civilizational_collapse)
    end
    
    score
  end
end
