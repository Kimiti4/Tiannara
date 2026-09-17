defmodule Tiannara.OSE.Evolution.ObserverSurvivabilityIndex do
  @moduledoc """
  Ontological Selection Ecology: Observer Survivability Index (OSI).
  
  Evaluates stable observer persistence, abstraction depth, recursive reasoning capacity,
  memory continuity, and symbolic compression ability.
  
  Used as a bounded constraint layer (a filter), not a primary fitness driver, 
  to prevent the system from over-optimizing toward "safe cognition" and reducing exploration diversity.
  """
  
  require Logger

  @doc """
  Evaluates a universe's observer model against the OSI filter.
  Returns true if the observer model is viable for continued evolution.
  """
  def filter_viable(universe) do
    Logger.debug("🧠 [OSI] Evaluating Observer Survivability Index for #{universe.id}...")
    
    # Calculate base OSI score
    score = calculate_osi(universe)
    
    # OSI acts as a filter (e.g. must be above 30.0), not a fitness driver
    if score >= 30.0 do
      Logger.debug("🧠 [OSI] #{universe.id} passed cognitive survivability constraint (Score: #{score}).")
      true
    else
      Logger.warning("🧠 [OSI] #{universe.id} failed cognitive survivability constraint (Score: #{score}). Filtered.")
      false
    end
  end
  
  defp calculate_osi(universe) do
    base = 20.0
    
    # Active participants support deeper abstraction and recursive reasoning
    active_bonus = if universe.observer_model == :active_participant, do: 25.0, else: 10.0
    
    # Fluid identity supports memory continuity across causal shifts
    fluid_bonus = if universe.identity_constraints == :fluid, do: 15.0, else: 5.0
    
    base + active_bonus + fluid_bonus
  end
end
