defmodule Tiannara.SOPL.LawImmuneSystem do
  @moduledoc """
  SOPL-2: Law Immune System
  
  The EDM for laws. Detects `%LawPathology{}` signatures early
  and intervenes to suppress or adjust mutations before they trigger
  a full constitutional failure or ecosystem collapse.
  """
  require Logger
  alias Tiannara.SOPL.LawPathologyRegistry

  @doc """
  Evaluates a live law and dynamically corrects it if it is drifting toward a pathology.
  Returns `{:ok, law}` if safe, or `{:corrected, new_law, pathologies}` if intervened.
  """
  def intercept_and_correct(law_genome, fitness_eval, telemetry) do
    # 1. Detect active pathologies
    pathologies = LawPathologyRegistry.analyze(law_genome, fitness_eval, telemetry)
    
    if length(pathologies) > 0 do
      Logger.warning("🛡️ [SOPL-2 Law Immune System] Detected #{length(pathologies)} active pathologies in #{law_genome.id}.")
      
      # 2. Attempt correction or trigger dampening
      corrected_law = Enum.reduce(pathologies, law_genome, &apply_correction/2)
      
      {:corrected, corrected_law, pathologies}
    else
      {:ok, law_genome}
    end
  end

  defp apply_correction(%{type: :fitness_hacking}, law) do
    # Suppress meaningless operator churn by increasing the novelty reward requirement
    %{law | novelty_reward: law.novelty_reward * 1.5}
  end

  defp apply_correction(%{type: :stability_monoculture}, law) do
    # Force mutation pressure up and lower diversity floor to break stasis
    %{law | mutation_pressure: min(1.0, law.mutation_pressure + 0.1), diversity_floor: max(0.0, law.diversity_floor - 0.1)}
  end

  defp apply_correction(%{type: :novelty_explosion}, law) do
    # Suppress mutation pressure and increase causal tolerance rigidity
    extinction = %{law.extinction_model | causal_tolerance: max(0.01, Map.get(law.extinction_model, :causal_tolerance, 0.1) / 2)}
    %{law | mutation_pressure: max(0.0, law.mutation_pressure - 0.1), extinction_model: extinction}
  end

  defp apply_correction(%{type: :causal_drift}, law) do
    # Tighten causal rules
    extinction = %{law.extinction_model | causal_tolerance: max(0.0, Map.get(law.extinction_model, :causal_tolerance, 0.1) - 0.2)}
    %{law | extinction_model: extinction}
  end

  defp apply_correction(%{type: :identity_lock}, law) do
    # Loosen identity requirements to allow structural changes
    trust = %{law.trust_formula | identity_persistence_weight: max(0.0, Map.get(law.trust_formula, :identity_persistence_weight, 0.5) - 0.15)}
    %{law | trust_formula: trust}
  end

  defp apply_correction(%{type: :entropy_collapse}, law) do
    # Lower economic constraints to allow easier novelty discovery
    fw = %{law.fitness_weights | economic_cap: Map.get(law.fitness_weights, :economic_cap, 5000.0) * 0.8}
    %{law | fitness_weights: fw}
  end
end
