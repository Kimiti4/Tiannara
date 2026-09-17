defmodule Tiannara.MCALv2.IdentitySelector do
  @moduledoc """
  MCAL v2: Identity Selector.
  
  Selects the best-performing identities and triggers archiving/adaptation for the rest.
  """
  
  require Logger

  @doc """
  Selects the fittest identity from a list of scored identities.
  """
  def select(identities) do
    Logger.debug("🏆 [MCAL v2 Selector] Evaluating fitness landscape for #{length(identities)} identities...")
    
    # Sort identities by fitness score descending
    sorted = Enum.sort_by(identities, & &1.fitness_score, :desc)
    
    [fittest | rest] = sorted
    
    Logger.info("👑 [MCAL v2 Selector] Fittest identity selected: #{fittest.id} (Score: #{fittest.fitness_score})")
    
    # In a full system, 'rest' would be archived or merged
    if length(rest) > 0 do
      Logger.debug("🗄️ [MCAL v2 Selector] Archiving #{length(rest)} sub-optimal identity branches.")
    end
    
    fittest
  end
end
