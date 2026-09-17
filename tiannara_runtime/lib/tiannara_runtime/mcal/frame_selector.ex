defmodule Tiannara.MCAL.FrameSelector do
  @moduledoc """
  MCAL: Frame Selector.
  
  Decides *how the system thinks*. By observing raw state entropy and risk,
  it selects a cognitive strategy (e.g. exploratory, immune_response) before
  processing the data further.
  """
  
  require Logger

  @doc """
  Selects the appropriate cognitive frame based on systemic stress levels.
  """
  def select(state) do
    # Map state attributes safely
    entropy = Map.get(state, :divergence, 0.0) / 100.0
    monoculture_risk = Map.get(state, :monoculture_risk, false)
    collapse_risk = entropy > 0.85
    novelty_high = Map.get(state, :novelty, 0.0) > 0.8
    
    frame = cond do
      collapse_risk -> :stabilization
      entropy > 0.75 -> :immune_response
      monoculture_risk -> :immune_response
      novelty_high -> :expansion
      entropy > 0.4 -> :exploratory
      true -> :balanced_cognition
    end
    
    Logger.info("🧭 [MCAL Frame Selector] Thermodynamic conditions evaluated. Selected cognitive frame: #{inspect(frame)}")
    frame
  end
end
