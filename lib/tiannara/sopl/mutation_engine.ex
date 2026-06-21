defmodule Tiannara.SOPL.MutationEngine do
  @moduledoc """
  SOPL-2: Law Mutation Engine
  
  Mutates LawGenomes safely. Restricts mutations to Tier 1 and Tier 2 parameters.
  Bounds the mutation magnitude using the Safe Mutation Radius.
  Enforces minimum_child_distance to prevent 20 identical clones (hill-climbing).
  """
  require Logger
  alias Tiannara.SOPL.LawGenome

  @doc """
  Generates `num_children` for a given `parent_law`.
  Enforces minimum_child_distance to ensure diverse exploration.
  """
  def generate_children(parent_law, num_children, safe_radius) do
    Logger.debug("🧬 [MutationEngine] Mutating #{parent_law.id} with radius #{Float.round(safe_radius, 3)}")
    
    # Oversample to ensure we can meet diversity requirements
    candidates = for _ <- 1..(num_children * 4) do
      mutate(parent_law, safe_radius)
    end
    
    # Enforce minimum_child_distance
    children = enforce_diversity(candidates, 0.05) |> Enum.take(num_children)
    
    Logger.debug("🧬 [MutationEngine] Generated #{length(children)} distinct variants for #{parent_law.id}.")
    children
  end

  defp mutate(law, radius) do
    # Generate random vector within radius
    shift = (:rand.uniform() * radius * 2) - radius
    
    # Apply Tier 1 (Safe) - Always applied
    law = apply_tier_1_mutation(law, shift)
    
    # Apply Tier 2 (Moderate) - 50% chance
    law = if :rand.uniform() > 0.5 do
      apply_tier_2_mutation(law, shift)
    else
      law
    end
    
    # Tier 3 (Dangerous) is explicitly LOCKED. 
    # Identity weights and causal rules are untouched.
    
    %{law | 
      id: "law_#{:crypto.strong_rand_bytes(4) |> Base.encode16()}", 
      parent_id: law.id
    }
  end

  defp apply_tier_1_mutation(law, shift) do
    # Novelty Reward, Disease Sensitivity (Virulence)
    nr = max(0.0, law.novelty_reward + (shift * 1000.0))
    vir = max(0.1, Map.get(law.disease_sensitivity, :virulence_multiplier, 1.0) + shift)
    
    %{law | 
      novelty_reward: nr, 
      disease_sensitivity: Map.put(law.disease_sensitivity, :virulence_multiplier, vir)
    }
  end

  defp apply_tier_2_mutation(law, shift) do
    # Mutation Pressure, Diversity Floor, Extinction Threshold
    mp = max(0.0, min(1.0, law.mutation_pressure + shift))
    df = max(0.0, min(1.0, law.diversity_floor + shift))
    
    ext = Map.put(law.extinction_model, :pressure_threshold, max(0.0, Map.get(law.extinction_model, :pressure_threshold, 0.5) + shift))
    
    %{law | mutation_pressure: mp, diversity_floor: df, extinction_model: ext}
  end

  defp enforce_diversity(candidates, min_distance) do
    # Greedy selection to ensure pairwise distance
    Enum.reduce(candidates, [], fn child, accepted ->
      too_close = Enum.any?(accepted, fn a -> calculate_distance(child, a) < min_distance end)
      if too_close do
        accepted
      else
        [child | accepted]
      end
    end)
  end

  defp calculate_distance(law_a, law_b) do
    # Euclidean distance between key Tier 1/2 parameters
    dm = law_a.mutation_pressure - law_b.mutation_pressure
    dd = law_a.diversity_floor - law_b.diversity_floor
    
    :math.sqrt((dm * dm) + (dd * dd))
  end
end
