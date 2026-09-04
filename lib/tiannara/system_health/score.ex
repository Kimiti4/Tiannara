defmodule Tiannara.SystemHealth.Score do
  @moduledoc """
  Computes a bounded [0.0, 1.0] stability score from raw metrics.
  """
  
  @doc """
  1.0 = Perfect Health
  0.0 = Imminent Collapse
  """
  def compute(snapshot) do
    # Simple heuristic formula for the vital signs monitor
    base = 1.0
    base = base - (snapshot.entropy * 0.2)
    base = base - (snapshot.collapse_probability * 0.5)
    base = base - (snapshot.semantic_drift * 0.3)
    
    # Floor at 0.0
    max(0.0, base)
  end
end
