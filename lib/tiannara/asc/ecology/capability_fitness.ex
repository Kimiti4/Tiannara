defmodule Tiannara.ASC.Ecology.CapabilityFitness do
  @moduledoc """
  Phase 15: Tracks the evolutionary fitness of a capability across missions.
  Evaluates fitness across 4 Ecological Niches to prevent mono-cultures.
  """
  
  defstruct [
    :capability_id,
    :birth_epoch,
    :lineage,             # :human_seeded | :llm_synthesis | :hybrid | :mutated
    missions_used: 0,
    successes: 0,
    failures: 0,
    total_compute_cost: 0,
    total_utility_gain: 0.0,
    # Ecological Niches
    mission_fitness: 0.1,
    research_fitness: 0.1,
    infrastructure_fitness: 0.1,
    governance_fitness: 0.1,
    # Overall metrics
    overall_fitness: 0.1,
    extinction_risk: 0.0,
    last_evaluated: nil
  ]

  @type t :: %__MODULE__{}

  @doc """
  Updates fitness metrics after an epoch/mission completes.
  """
  def record_outcome(%__MODULE__{} = profile, niche, success?, compute_cost, utility_gain) do
    profile = %{profile |
      missions_used: profile.missions_used + 1,
      successes: if(success?, do: profile.successes + 1, else: profile.successes),
      failures: if(success?, do: profile.failures, else: profile.failures + 1),
      total_compute_cost: profile.total_compute_cost + compute_cost,
      total_utility_gain: profile.total_utility_gain + utility_gain,
      last_evaluated: System.system_time(:millisecond)
    }
    
    # Calculate base performance delta
    delta = calculate_delta(success?, compute_cost, utility_gain)
    
    # Apply to specific niche
    profile = update_niche_fitness(profile, niche, delta)
    
    # Update aggregate metrics
    %{profile | 
      overall_fitness: Enum.max([profile.mission_fitness, profile.research_fitness, profile.infrastructure_fitness, profile.governance_fitness]),
      extinction_risk: calculate_extinction_risk(profile)
    }
  end

  defp calculate_delta(success?, compute_cost, utility_gain) do
    # If the mission failed, utility might be zero or negative. We still apply a baseline failure penalty.
    failure_penalty = if success?, do: 0.0, else: 5.0
    cost_penalty = compute_cost / 1000.0
    utility_gain - cost_penalty - failure_penalty
  end

  defp update_niche_fitness(profile, :mission, delta), do: %{profile | mission_fitness: max(0.0, profile.mission_fitness + delta)}
  defp update_niche_fitness(profile, :research, delta), do: %{profile | research_fitness: max(0.0, profile.research_fitness + delta)}
  defp update_niche_fitness(profile, :infrastructure, delta), do: %{profile | infrastructure_fitness: max(0.0, profile.infrastructure_fitness + delta)}
  defp update_niche_fitness(profile, :governance, delta), do: %{profile | governance_fitness: max(0.0, profile.governance_fitness + delta)}
  defp update_niche_fitness(profile, _, _delta), do: profile # fallback

  # Extinction risk is extremely conservative. We require minimum 10 missions before risk climbs rapidly.
  defp calculate_extinction_risk(%__MODULE__{} = p) do
    if p.missions_used < 10 do
      # Protection period for new capabilities
      0.0
    else
      failure_rate = p.failures / p.missions_used
      # If overall fitness is below 0.5 across all niches, it's highly at risk
      fitness_penalty = if p.overall_fitness < 0.5, do: 0.5, else: 0.0
      min(1.0, failure_rate * 0.6 + fitness_penalty)
    end
  end
end
