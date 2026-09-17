defmodule Tiannara.OSE.CausalCompatibilityStress do
  @moduledoc """
  Ontological Selection Ecology: Causal Compatibility Stress.
  
  Evaluates causal destabilization, semantic resilience, and topology adaptability 
  when two or more ASTs overlap.
  """
  
  require Logger

  @doc """
  Runs stress tests against active universes in the battlefield.
  Returns updated universes with calculated stress scores.
  """
  def evaluate(universes) do
    Logger.debug("⚔️ [OSE] Computing Causal Compatibility Stress across #{length(universes)} active ontologies...")
    
    Enum.map(universes, fn u ->
      stress = calculate_stress(u, universes -- [u])
      resilience = calculate_resilience(u)
      
      Logger.debug("⚔️ [OSE] #{u.id} | Stress: #{Float.round(stress, 2)} | Resilience: #{Float.round(resilience, 2)}")
      
      Map.put(u, :stress_metrics, %{
        causal_destabilization: stress,
        semantic_resilience: resilience,
        survivability: max(0.0, resilience - stress)
      })
    end)
  end

  defp calculate_stress(universe, others) do
    # Stress is higher when exposed to fundamentally incompatible primitives
    Enum.reduce(others, 0.0, fn other, acc ->
      overlap = length(universe.causal_primitives -- other.causal_primitives)
      acc + (overlap * 10.0)
    end)
  end

  defp calculate_resilience(universe) do
    # Resilience is higher if identity constraints are fluid and observer is active
    base = 50.0
    bonus1 = if universe.identity_constraints == :fluid, do: 20.0, else: 0.0
    bonus2 = if universe.observer_model == :active_participant, do: 15.0, else: 0.0
    
    base + bonus1 + bonus2
  end
end
