defmodule Tiannara.OSE.Evolution.AdaptiveNicheGenerator do
  @moduledoc """
  Ontological Selection Ecology: Adaptive Niche Generator (ANG).
  
  Proactively creates underrepresented causal environments and hostile topology gradients.
  Tied to dominance pressure and convergence saturation, not entropy alone, 
  keeping it evolutionary rather than compensatory.
  """
  
  require Logger

  @doc """
  Evaluates the current ecology. If dominance pressure is high (monoculture risk),
  injects a hostile/exotic topology gradient to force adaptation.
  """
  def evaluate_and_generate(ecology) do
    Logger.debug("🌱 [ANG] Evaluating ecological dominance pressure...")
    
    # Simple metric: if one universe has > 70% of the total budget, dominance pressure is high
    total_budget = Enum.sum(Enum.map(ecology, & &1.budget))
    dominant = Enum.find(ecology, fn u -> u.budget / total_budget > 0.7 end)
    
    if dominant do
      Logger.warning("🌱 [ANG] Convergence Saturation detected (Dominant: #{dominant.id}). Generating hostile niche gradient.")
      # Returns a gradient intended to stress the dominant primitives
      %{mutation: 0.8, diversification: 0.9, stability: 0.1, collapse: 0.8, target_stress: dominant.causal_primitives}
    else
      Logger.debug("🌱 [ANG] Ecology is diverse. No artificial niche generation required.")
      nil
    end
  end
end
