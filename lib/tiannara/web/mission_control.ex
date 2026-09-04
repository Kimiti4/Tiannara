defmodule Tiannara.Web.MissionControl do
  @moduledoc """
  Hardened dashboard interface. Only queries SystemHealth, never subsystems directly.
  """
  
  def render_system_health do
    # Dashboard strictly goes through the hardened SystemHealth snapshot
    snapshot = Tiannara.Metrics.Aggregator.get_snapshot()
    score = Tiannara.SystemHealth.Score.compute(snapshot)
    
    %{
      status: if(score > 0.5, do: :healthy, else: :critical),
      score: score,
      vital_signs: %{
        entropy: snapshot.entropy,
        collapse_probability: snapshot.collapse_probability,
        semantic_drift: snapshot.semantic_drift,
        branch_count: snapshot.branch_count,
        orbit: snapshot.current_orbit
      }
    }
  end
end
