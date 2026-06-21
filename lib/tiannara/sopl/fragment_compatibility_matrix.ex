defmodule Tiannara.SOPL.FragmentCompatibilityMatrix do
  @moduledoc """
  SOPL-3: Fragment Compatibility Matrix
  
  Learns from known pathologies, ruins, and attractors to prevent toxic 
  combinations of fragments before synthesis. 
  """
  require Logger

  @doc """
  Evaluates a list of %LawFragment{} targets and returns `{:ok, synergy_score}` 
  or `{:toxic, reason}`.
  """
  def evaluate_synthesis(fragments) do
    categories = Enum.map(fragments, & &1.category)
    
    # Check for known toxic signatures derived from Pathology History
    cond do
      # 1. Novelty Explosion Risk: Massive novelty generation without a regulator
      :novelty in categories and :constraint not in categories ->
        {:toxic, :novelty_explosion_forecast}
        
      # 2. Goodhart Attractor Risk: Absolute truth/stasis without generative exploration
      :truth in categories and :novelty not in categories ->
        {:toxic, :stability_monoculture_forecast}
        
      # 3. Entropy Collapse Risk: High mutation paired with weak conservation rules
      has_high_mutation?(fragments) and weak_conservation?(fragments) ->
        {:toxic, :entropy_collapse_forecast}
        
      # 4. Identity Lock Risk: Fluid causal structures paired with extreme identity persistence
      fluid_causality?(fragments) and extreme_identity?(fragments) ->
        {:toxic, :identity_lock_forecast}
        
      true ->
        {:ok, calculate_synergy_score(fragments)}
    end
  end

  defp has_high_mutation?(fragments) do
    Enum.any?(fragments, fn f -> Map.get(f.parameters, :mutation_pressure, 0.0) > 0.6 end)
  end

  defp weak_conservation?(fragments) do
    Enum.any?(fragments, fn f -> Map.get(f.parameters, :economic_cap, 5000.0) > 10000.0 end)
  end

  defp fluid_causality?(fragments) do
    Enum.any?(fragments, fn f -> Map.get(f.parameters, :causal_tolerance, 0.1) > 0.5 end)
  end

  defp extreme_identity?(fragments) do
    Enum.any?(fragments, fn f -> Map.get(f.parameters, :identity_persistence_weight, 0.5) > 0.9 end)
  end

  defp calculate_synergy_score(fragments) do
    # Simple calculation based on diversity of categories.
    # High synergy means complementary forces (e.g. novelty + constraint).
    uniq_cats = fragments |> Enum.map(& &1.category) |> Enum.uniq() |> length()
    min(1.0, uniq_cats / 4.0) # Normalizing across Truth, Novelty, Constraint, Resilience
  end
end
